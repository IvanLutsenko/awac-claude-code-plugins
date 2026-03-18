---
description: Analyze iOS Crashlytics logs with mandatory git blame analysis and code-level fixes. Multi-agent architecture: classifier-ios → firebase-fetcher → forensics-ios → reviewer.
allowed-tools: Bash(git log:*), Bash(git blame:*), Bash(which firebase:*), Bash(firebase *:*), Bash(python3:*), Bash(curl:*), Bash(mkdir:*), Bash(cat:*), Task, Read, Glob
---

# iOS Crash Analysis - Multi-Agent Edition

Analyze crash errors from Firebase Crashlytics using specialized agents.

## Configuration

**Before starting**, check if a config file exists at `.claude/crashlytics.local.md`.
If it exists, read and use these settings:
- `language` — output language (default: English)
- `default_branch` — branch for git blame (default: master)
- `default_platform` — should be ios for this command
- `forensics_model` — model for forensics agent (default: opus)
- `output_format` — both / detailed_only / jira_only (default: both)
- `firebase_project_id` — pre-configured project ID (skip auto-detection if set)
- `firebase_app_id_ios` — pre-configured app ID (skip auto-detection if set)

If config doesn't exist, **auto-create it with defaults** and continue:

```yaml
Bash: mkdir -p .claude && cat <<'EOF' > .claude/crashlytics.local.md
---
language: en
default_branch: master
default_platform: ios
forensics_model: opus
output_format: both
firebase_project_id: ""
firebase_app_id_android: ""
firebase_app_id_ios: ""
---

# Crashlytics Plugin Config

Auto-created with defaults. Run `/crash-config` to customize.
EOF
```

Inform user: "Config created at `.claude/crashlytics.local.md` (defaults: ios, master, opus). Run `/crash-config` to customize."

## Multi-Agent Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     /crash-report-ios                            │
└─────────────────────────────────────────────────────────────────┘
                              │
   ┌──────────────┬───────────┼───────────┬──────────────┐
   ▼              ▼           ▼           ▼              ▼
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│classifier│→│ fetcher  │→│forensics │→│ reviewer │→│  output  │
│   iOS    │ │ (Haiku)  │ │ (Opus)   │ │ (Haiku)  │ │          │
│ (Haiku)  │ │          │ │          │ │          │ │ Detailed │
│Component │ │REST API  │ │Git blame │ │Quality   │ │+ JIRA    │
│Trigger   │ │+ MCP disc│ │Code fix  │ │Gate      │ │  Brief   │
│          │ │          │ │Assignee  │ │Checklist │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

## Workflow

### Prerequisites Check (runs first!)

Run ALL checks in a single Bash call. Display results as a checklist to the user.

```yaml
Bash: |
  echo "=== Crashlytics Prerequisites ==="
  # 1. Node.js
  if command -v node &>/dev/null; then
    echo "OK node $(node --version)"
  else
    echo "MISSING node"
  fi
  # 2. firebase-tools
  if command -v firebase &>/dev/null; then
    echo "OK firebase $(firebase --version 2>/dev/null | head -1)"
  else
    echo "MISSING firebase"
  fi
  # 3. Firebase auth (token file)
  if [ -f "$HOME/.config/configstore/firebase-tools.json" ]; then
    echo "OK firebase-auth"
  else
    echo "MISSING firebase-auth"
  fi
  # 4. python3
  if command -v python3 &>/dev/null; then
    echo "OK python3 $(python3 --version 2>&1)"
  else
    echo "MISSING python3"
  fi
```

**Parse output and show checklist to user:**

For each line:
- `OK ...` → show as passing check
- `MISSING ...` → show as failing check with fix instruction

**Fix instructions by item:**

| Missing | Instruction |
|---------|-------------|
| `node` | `brew install node` (macOS) / `sudo apt install nodejs` (Linux) / download from nodejs.org (Windows) |
| `firebase` | `npm install -g firebase-tools` — **offer to run automatically** if npm is available |
| `firebase-auth` | Run `firebase login` in terminal (opens browser, requires manual action) |
| `python3` | `brew install python3` (macOS) / `sudo apt install python3` (Linux) / download from python.org (Windows) |

**Behavior:**
- If `firebase` is MISSING and `npm` is available → ask: "Install firebase-tools? (`npm install -g firebase-tools`)" and run if confirmed
- If `firebase-auth` is MISSING → tell user to run `firebase login` in terminal, then re-run the command
- If only `node` or `python3` missing → show instructions, continue in Manual mode
- If ALL OK → proceed silently
- If any MISSING → show the checklist, then continue with whatever is available (degrade gracefully)

### STEP 0: Firebase Auto-Init (runs automatically!)

**Before starting** check and configure Firebase. Two access levels: CLI REST API → Manual.

**NEVER** use `mcp__plugin_crashlytics_firebase__firebase_login` — MCP auth is broken ("Unable to verify client"). If CLI is not authorized, ask the user to run `firebase login` in terminal.

**NOTE:** Crashlytics data tools (`crashlytics_get_issue`, `crashlytics_list_events`, etc.) do NOT exist in Firebase MCP server. Do not attempt to call them. MCP is used only for project/app discovery.

If `firebase_project_id` and `firebase_app_id_ios` are set in config — skip auto-detection and use those values directly.

#### Discovery: MCP or CLI

```yaml
1. Try MCP discovery first:
   ToolSearch: "+firebase get_environment"
   mcp__plugin_crashlytics_firebase__firebase_get_environment

   If works → extract project_id, then:
     mcp__plugin_crashlytics_firebase__firebase_list_apps (platform: "ios")
     Extract app_id.

   If MCP fails → retry once, then use CLI discovery:

2. CLI discovery fallback:
   Bash: which firebase 2>/dev/null && firebase login:list 2>/dev/null

   If CLI not authorized → go to Level 2 (Manual)

   Bash: firebase projects:list --json 2>/dev/null | python3 -c "
     import sys,json
     data = json.load(sys.stdin)
     for p in (data.get('results') or data.get('result', [])):
       print(f\"{p['projectId']} — {p.get('displayName','')}\")"

   Bash: firebase apps:list --project {PROJECT_ID} --json 2>/dev/null | python3 -c "
     import sys,json
     for a in json.load(sys.stdin)['result']:
       if a.get('platform')=='IOS':
         print(f\"{a['appId']} | {a.get('displayName','')}\")"

3. Build console_url immediately after getting project_id and app_id:
   console_url = "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}"
```

#### Level 1: CLI REST API (primary data fetch)

```yaml
1. Get crash data via REST API (single script — token never printed to stdout):

   NOTE: client_id and client_secret are public OAuth credentials from Firebase CLI
   (embedded in firebase-tools source code, this is an installed app OAuth flow).
   The access token MUST stay inside the script — never print or log it.

   Bash: python3 << 'PYEOF'
   import json, urllib.request, urllib.parse, os, sys

   # Get access token (stays internal)
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

   # Extract numeric project number from APP_ID format "1:PROJECT_NUM:ios:hash"
   APP_ID = "{APP_ID}"
   PROJECT_NUM = APP_ID.split(":")[1] if ":" in APP_ID else "{PROJECT_ID}"
   ISSUE_ID = "{ISSUE_ID}"
   headers = {"Authorization": f"Bearer {token}"}

   # Try Crashlytics REST API with different URL formats
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
           err_body = e.read().decode() if hasattr(e, 'read') else ''
           print(f"WARN: {base}/issues/{ISSUE_ID} → HTTP {e.code}", file=sys.stderr)
           if e.code == 403 and 'not been used' in err_body:
               print("API_NOT_ENABLED")
           continue
       except Exception as e:
           print(f"WARN: {base} → {e}", file=sys.stderr)
           continue

   if not issue_data:
       print("REST_FALLBACK_FAILED")
       print("All Crashlytics REST API URLs failed. The API may need to be enabled in Google Cloud Console.", file=sys.stderr)
   PYEOF

2. Parse output:
   - Lines starting with `ISSUE_DATA:` contain issue JSON
   - Lines starting with `EVENTS_DATA:` contain events JSON
   - `API_NOT_ENABLED` → show enable instructions, then go to Level 2
   - `REST_FALLBACK_FAILED` → go to Level 2
   - Extract: title, type (FATAL/NON_FATAL), status, stack traces, device info, event count
```

#### Level 2: Enhanced Manual Fallback

If REST API failed or Firebase not configured:

```yaml
1. If API_NOT_ENABLED was detected:
   Show: "Firebase Crashlytics API is not enabled for project {PROJECT_ID}.
   Enable it:
     - GCP Console: https://console.cloud.google.com/apis/library/firebasecrashlytics.googleapis.com?project={PROJECT_ID}
     - gcloud: gcloud services enable firebasecrashlytics.googleapis.com --project={PROJECT_ID}
   After enabling, re-run the command."

2. MUST generate a Firebase Console link (if project_id and app_id known):
   https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}

3. Step-by-step instructions for the user:
   a. Open the Console URL above (or go to https://console.firebase.google.com/ → Crashlytics)
   b. Find the issue (by ID or search)
   c. Go to the "Events" tab
   d. Copy the full stack trace from the latest event
   e. Also note: crash title, event count, % affected users, app version, device

4. Ask user to paste:
   - Stack trace (required)
   - Crash title
   - Event count, % users, version
```

**General rules:**
- MCP is for project/app discovery only — crash data tools don't exist
- CLI REST API is the primary method for fetching crash data
- Always generate Console URL if project_id and app_id are available
- If Issue ID exists — always try to get data automatically via REST API

### STEP 1: Get data

**If user provided a Firebase Issue ID** — first try loading data automatically (Level 1). Only ask for stack trace and context if auto-loading failed.

**If no Issue ID** — ask to provide:
- **Stack trace** (required)
- **Context**: crash count, % users, device, iOS version

### STEP 2: Call crash-classifier-ios

```yaml
Task(
  subagent_type="crash-classifier-ios",
  model="haiku",
  prompt="Classify this iOS crash:

    Stack trace:
    {stack_trace}

    Context:
    - Events: {event_count}
    - Users: {user_count}%
    - Version: {app_version}
    - Device: {device}
    - iOS: {ios_version}
  "
)
```

**Expected output:**
```yaml
crash_type: Fatal error / SIGABRT / NSException
component: UI/Network/Database/Services/Background
trigger: user_action/background_task/lifecycle_event/async_operation
```

### STEP 3: Get data from Firebase (optional)

If a **Firebase Issue ID** was provided, load crash data using this priority:

**Option A: CLI REST API (primary)**

Use the Python script from Step 0, Level 1 (token stays internal, never printed).
Substitute `{APP_ID}`, `{PROJECT_ID}`, `{ISSUE_ID}` with actual values.

**Option B: Via firebase-fetcher agent (alternative)**

```yaml
Task(
  subagent_type="firebase-fetcher",
  model="haiku",
  prompt="Get crash details from Firebase:
    Issue ID: {issue_id}
    App ID: {app_id} (iOS)
    Project ID: {project_id}
    Platform: ios
  "
)
```

**Option C: Enhanced Manual fallback**

If REST API failed — generate Console URL and ask for manual input with step-by-step instructions (see Step 0, Level 2).

### STEP 4: Call crash-forensics-ios

Use `forensics_model` from config (default: opus). If opus is unavailable, fall back to sonnet.

```yaml
Task(
  subagent_type="crash-forensics-ios",
  model="{forensics_model from config, default opus}",
  prompt="Analyze this iOS crash with git blame:

    Classification: {classifier_output}
    Firebase data: {firebase_output}
    Stack trace: {stack_trace}

    console_url: {console_url}
    branch: {default_branch from config, default master}
  "
)
```

The agent will:
1. Search Swift/Objective-C files in the codebase
2. Git blame analysis (on the configured branch)
3. Determine assignee
4. Propose a fix (Swift/Objective-C)

### STEP 4.5: Call crash-report-reviewer (Quality Gate)

After receiving the result from forensics, **before outputting to user**:

```yaml
Task(
  subagent_type="crash-report-reviewer",
  model="haiku",
  prompt="Validate this crash report against mandatory fields:

    {forensics_output}

    console_url: {console_url}
  "
)
```

**Handling the reviewer result:**
- If `pass: true` — output the report as-is
- If `pass: false` — fill in missing fields yourself:
  - Use data from previous steps (classifier, firebase, forensics)
  - If data for a field is unavailable — mark as `[DATA UNAVAILABLE]`
  - **DO NOT re-call forensics** — fill in at the command level

### STEP 5: Output results

The crash-forensics-ios agent returns two formats:

**Format 1: Detailed Analysis**
- Basic info
- Stack trace analysis
- Checked files with git blame
- Root cause
- Fix (before/after in Swift/Objective-C)
- Assignee with justification
- Context and prevention

**Format 2: JIRA Brief**
- Name and problem
- Key stack trace lines
- Root cause (1-2 sentences)
- Code fix (ready to copy-paste)
- Component, assignee
- Reproduction steps

## Fallback mode (if agents unavailable)

If Task tool cannot call agents, perform analysis directly:

1. **Classification**: Determine type, component, trigger
2. **File search**: Glob/Grep by classes from stack trace
3. **Git blame**: `git blame master -- file.swift -L X,Y`
4. **Assignee**: Select 2-3 candidates with justification
5. **Fix**: Propose code-level solution (Swift/Objective-C)
6. **Output**: Detailed analysis + JIRA Brief

## Pre-submit checklist

### MUST verify:
- [ ] Classification completed (component, trigger)
- [ ] .swift/.m files found via Glob/Grep or reason explained
- [ ] git blame executed on configured branch with real commands
- [ ] Assignee determined with source (git blame line X)
- [ ] Report formats match config (both by default)
- [ ] Reviewer passed (`pass: true`) or missing fields filled in
- [ ] console_url included in JIRA Brief

### DO NOT SUBMIT IF:
- Code search was not performed
- No git blame for found files
- Assignee = "TBD" without analysis
- Only one report format (when both required)
- Reviewer returned `pass: false` and fields were NOT filled in

## Usage example

```
User: /crash-report-ios

Claude: iOS Crash Analysis - Multi-Agent

Please provide:
1. Stack trace (required)
2. Firebase Issue ID (if available)
3. Crash count and % users
4. Device and iOS version

---

[User provides data]

Claude:
Step 1: Classification...
[Calls crash-classifier-ios]

Step 2: Loading from Firebase...
[REST API fetch]

Step 3: Git blame analysis...
[Calls crash-forensics-ios]

Step 4: Quality check...
[Calls report-reviewer]

Analysis complete.

### Detailed Analysis
[...(detailed analysis)]

### JIRA Brief
[...(JIRA format)]
```

## Important

```yaml
Git blame + code search = MANDATORY
"TBD" = "I analyzed and ownership is unclear", NOT "I didn't check"
Document exact executed commands
Every report must have git blame with output
```
