---
description: "Analyze crash from Firebase Crashlytics. Auto-detects platform from config. Usage: /crash-report <issue_id | console_url | crash info>"
argument-hint: "<issue_id | console_url | crash description>"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git log:*), Bash(git blame:*), Bash(which firebase:*), Bash(firebase *:*), Bash(python3:*), Bash(echo:*), Bash(curl:*), Bash(mkdir:*), Bash(cat:*), Task, Read, Glob, AskUserQuestion
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

## Step 0.5: Prerequisites Check

Run ALL checks in a single Bash call. Display results as a checklist to the user.

```yaml
Bash: ${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh
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
- If `firebase-auth` is MISSING → tell user to run `firebase login` in terminal, then re-run `/crash-report`
- If only `node` or `python3` missing → show instructions, continue in Manual mode
- If ALL OK → proceed silently (don't spam the user with "all good" messages)
- If any MISSING → show the checklist, then continue with whatever is available (degrade gracefully)

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

### Level 1: MCP Discovery + CLI REST API (primary)

MCP is used **only for project/app discovery** (these tools work). Crash data is fetched via REST API.

**NOTE:** Crashlytics data tools (`crashlytics_get_issue`, `crashlytics_list_events`, etc.) do NOT exist in Firebase MCP server. Do not attempt to call them.

```yaml
1. Load MCP tools:
   ToolSearch: "+firebase get_environment"

2. Try MCP discovery:
   mcp__plugin_crashlytics_firebase__firebase_get_environment

3. If works → extract project_id, then:
   mcp__plugin_crashlytics_firebase__firebase_list_apps (platform: PLATFORM)
   Extract app_id.

   If MCP discovery fails → retry once, then use CLI discovery (see below).

4. Build console_url:
   android: "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/android:{APP_ID}/issues/{ISSUE_ID}"
   ios: "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}"

5. If Issue ID available → fetch crash data via REST API:
   Bash: python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-crash-data.py "{APP_ID}" "{ISSUE_ID}" "{PROJECT_ID}"

6. Parse output:
   - ISSUE_DATA: → issue JSON
   - EVENTS_DATA: → events JSON
   - API_NOT_ENABLED → show enable instructions, then go to Level 2
   - REST_FALLBACK_FAILED → go to Level 2
```

**CLI discovery fallback** (if MCP discovery failed):

```yaml
Bash: which firebase 2>/dev/null && firebase login:list 2>/dev/null
If authorized → use firebase projects:list / apps:list to get project_id and app_id.
Then use REST API script above for crash data.
If not authorized → go to Level 2.
```

### Level 2: Enhanced Manual Fallback

If REST API failed or Firebase not configured:

```yaml
1. If API_NOT_ENABLED was detected:
   Show: "Firebase Crashlytics API is not enabled for project {PROJECT_ID}.
   Enable it:
     - GCP Console: https://console.cloud.google.com/apis/library/firebasecrashlytics.googleapis.com?project={PROJECT_ID}
     - gcloud: gcloud services enable firebasecrashlytics.googleapis.com --project={PROJECT_ID}
   After enabling, re-run the command."

2. Generate Firebase Console URL (if project_id and app_id known):
   https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/{PLATFORM}:{APP_ID}/issues/{ISSUE_ID}

3. Ask user to provide from Firebase Console:
   - Stack trace (required) — "Issues → select issue → Events tab → copy stack trace"
   - Crash title
   - Event count, % affected users
   - App version, device info

4. If project_id/app_id unknown:
   Ask user to go to https://console.firebase.google.com/ and navigate to Crashlytics manually.
```

**General rules:**
- MCP is for project/app discovery only — crash data tools don't exist
- CLI REST API is the primary method for fetching crash data
- Always generate Console URL if project_id and app_id are available
- If Issue ID exists — always try to get data automatically via REST API

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
# REST API → Manual (see Step 2)
```

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
