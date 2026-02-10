---
description: "Analyze crash from Firebase Crashlytics. Auto-detects platform from config. Usage: /crash-report <issue_id | console_url | crash info>"
argument-hint: "<issue_id | console_url | crash description>"
allowed-tools: Bash(git log:*), Bash(git blame:*), Bash(which firebase:*), Bash(firebase *:*), Bash(python3:*), Bash(curl:*), Bash(mkdir:*), Bash(cat:*), Task, Read, Glob, AskUserQuestion
---

# Crash Analysis

Unified crash analysis command. Reads `default_platform` from config and calls the right agents.

## Step 0: Config + Platform

```yaml
1. Check config:
   Glob: .claude/crashlytics.local.md

2. If config exists → Read it, parse YAML frontmatter.
   Set PLATFORM = default_platform (android | ios)

3. If config NOT found → auto-create with defaults:
   Bash: mkdir -p .claude && cat <<'EOF' > .claude/crashlytics.local.md
   ---
   language: en
   default_branch: master
   default_platform: android
   forensics_model: opus
   output_format: both
   firebase_project_id: ""
   firebase_app_id_android: ""
   firebase_app_id_ios: ""
   ---

   # Crashlytics Plugin Config

   Auto-created with defaults. Run `/crash-config` to customize.
   EOF

   Set PLATFORM = android
   Inform user: "Config created at `.claude/crashlytics.local.md` (defaults: android, master, opus). Run `/crash-config` to customize."
```

Config values used throughout:
- `PLATFORM` → which agents to call + console URL format
- `default_branch` → git blame branch
- `forensics_model` → model for forensics agent (default: opus)
- `output_format` → both / detailed_only / jira_only
- `firebase_project_id`, `firebase_app_id_{PLATFORM}` → skip auto-detect if set

## Step 1: Parse input

The argument can be:

| Input | How to detect | Action |
|-------|---------------|--------|
| Firebase Issue ID | 32-char hex string | Use as ISSUE_ID |
| Console URL | Contains `console.firebase.google.com` | Extract project_id, app_id, issue_id from URL |
| Stack trace / text | Multi-line or descriptive | Use as crash context, skip Firebase auto-load |
| Nothing | No argument | Ask user to provide crash info |

## Step 2: Firebase Auto-Init

**NEVER** use `mcp__plugin_crashlytics_firebase__firebase_login` — it's broken.

If `firebase_project_id` and `firebase_app_id_{PLATFORM}` are set in config — skip auto-detection.

#### Level 1: MCP (preferred)

```yaml
1. Load MCP tools:
   ToolSearch: "+firebase get_environment"

2. Try:
   mcp__plugin_crashlytics_firebase__firebase_get_environment

3. If works → use MCP for all requests
   Build console_url:
     android: "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/android:{APP_ID}/issues/{ISSUE_ID}"
     ios: "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}"
   IMPORTANT: MCP is unstable — if a call fails with "Internal error",
   retry up to 2 times before falling to Level 2.
4. If get_environment itself fails → go to Level 2
```

#### Level 2: CLI API fallback

```yaml
1. Check CLI:
   Bash: which firebase 2>/dev/null && firebase login:list 2>/dev/null
   If not authorized → go to Level 3

2. Get project_id and app_id:
   Bash: firebase projects:list --json 2>/dev/null | python3 -c "
     import sys,json
     data = json.load(sys.stdin)
     for p in (data.get('results') or data.get('result', [])):
       print(f\"{p['projectId']} — {p.get('displayName','')}\")"

   Bash: firebase apps:list --project {PROJECT_ID} --json 2>/dev/null | python3 -c "
     import sys,json
     for a in json.load(sys.stdin)['result']:
       if a.get('platform')=='{ANDROID|IOS}':
         print(f\"{a['appId']} | {a.get('displayName','')}\")"

3. Build console_url.

4. Get crash data (single script — token never printed):
   Bash: python3 << 'PYEOF'
   import json, urllib.request, urllib.parse, os, sys

   config = json.load(open(os.path.expanduser('~/.config/configstore/firebase-tools.json')))
   token_data = urllib.parse.urlencode({
       'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
       'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi',
       'refresh_token': config['tokens']['refresh_token'],
       'grant_type': 'refresh_token'
   }).encode()
   token = json.loads(urllib.request.urlopen(
       urllib.request.Request('https://oauth2.googleapis.com/token', data=token_data)
   ).read())['access_token']

   APP_ID = "{APP_ID}"
   PROJECT_NUM = APP_ID.split(":")[1] if ":" in APP_ID else "{PROJECT_ID}"
   ISSUE_ID = "{ISSUE_ID}"
   headers = {"Authorization": f"Bearer {token}"}

   base_urls = [
       f"https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_NUM}/apps/{APP_ID}",
       f"https://firebasecrashlytics.googleapis.com/v1beta1/projects/{'{PROJECT_ID}'}/apps/{APP_ID}",
   ]
   issue_data = None
   for base in base_urls:
       try:
           req = urllib.request.Request(f"{base}/issues/{ISSUE_ID}", headers=headers)
           issue_data = json.loads(urllib.request.urlopen(req).read())
           print("ISSUE_DATA:" + json.dumps(issue_data, indent=2))
           try:
               ereq = urllib.request.Request(f"{base}/issues/{ISSUE_ID}/events?pageSize=3", headers=headers)
               events = json.loads(urllib.request.urlopen(ereq).read())
               print("EVENTS_DATA:" + json.dumps(events, indent=2))
           except Exception as e:
               print(f"WARN: Events fetch failed: {e}", file=sys.stderr)
           break
       except urllib.error.HTTPError as e:
           print(f"WARN: {base}/issues/{ISSUE_ID} → HTTP {e.code}", file=sys.stderr)
           continue
   if not issue_data:
       print("REST_FALLBACK_FAILED")
   PYEOF

5. If REST_FALLBACK_FAILED → go to Level 3
```

#### Level 3: Manual fallback

Generate Console URL and ask user to paste stack trace + context from Firebase Console.

**General rules:**
- Try levels sequentially: MCP (with retries) → CLI API → Manual
- If MCP returns "Internal error" — retry up to 2 times before falling to CLI API
- Always generate Console URL if project_id and app_id are available

## Step 3: Classify + Load data (parallel)

Launch classifier and data loading in parallel:

```yaml
# Classifier — pick by PLATFORM:
Task(
  subagent_type="crash-classifier-{PLATFORM}",  # crash-classifier-android OR crash-classifier-ios
  model="haiku",
  prompt="Classify this crash:
    Stack trace: {stack_trace}
    Context: Events={event_count}, Users={user_count}%, Version={app_version}, Device={device}"
)

# Data loading (if Issue ID available):
# MCP retry-first → REST → Manual (see Step 2)
```

**MCP retry-first:** If MCP call returns "Internal error", retry up to 2 times.
Do NOT jump to REST API on first failure.

## Step 4: Forensics

```yaml
Task(
  subagent_type="crash-forensics-{PLATFORM}",  # crash-forensics-android OR crash-forensics-ios
  model="{forensics_model from config, default opus}",
  prompt="Analyze this crash with git blame:
    Classification: {classifier_output}
    Firebase data: {firebase_output}
    Stack trace: {stack_trace}
    console_url: {console_url}
    branch: {default_branch from config, default master}"
)
```

## Step 5: Quality Gate

```yaml
Task(
  subagent_type="crash-report-reviewer",
  model="haiku",
  prompt="Validate this crash report:
    {forensics_output}
    console_url: {console_url}"
)
```

- If `pass: true` → output as-is
- If `pass: false` → fill missing fields from previous steps, do NOT re-call forensics

## Step 6: Output

Based on `output_format` from config:
- `both` (default): Detailed Analysis + JIRA Brief
- `detailed_only`: Only Detailed Analysis
- `jira_only`: Only JIRA Brief

## Pre-submit checklist

- [ ] Classification completed (component, trigger)
- [ ] Files found via Glob/Grep or reason explained
- [ ] git blame executed on configured branch
- [ ] Assignee determined with source (git blame line X)
- [ ] Report formats match config
- [ ] Reviewer passed or missing fields filled in
- [ ] console_url included in JIRA Brief
