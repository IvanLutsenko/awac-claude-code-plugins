---
description: Analyze iOS Crashlytics logs with mandatory git blame analysis and code-level fixes. Multi-agent architecture: classifier-ios → firebase-fetcher → forensics-ios → reviewer.
allowed-tools: Bash(git log:*), Bash(git blame:*), Bash(which firebase:*), Bash(firebase *:*), Bash(python3:*), Bash(curl:*), Task
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

If config doesn't exist, use defaults and suggest running `/crash-config` to set up.

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
│Component │ │Firebase  │ │Git blame │ │Quality   │ │+ JIRA    │
│Trigger   │ │Stacks    │ │Code fix  │ │Gate      │ │  Brief   │
│          │ │Device    │ │Assignee  │ │Checklist │ │          │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

## Workflow

### STEP 0: Firebase Auto-Init (runs automatically!)

**Before starting** check and configure Firebase. Three access levels: MCP → CLI API → Manual.

**NEVER** use `mcp__plugin_crashlytics_firebase__firebase_login` — MCP auth is broken ("Unable to verify client"). If CLI is not authorized, ask the user to run `firebase login` in terminal.

If `firebase_project_id` and `firebase_app_id_ios` are set in config — skip auto-detection and use those values directly.

#### Level 1: MCP (preferred)

```yaml
1. Load MCP tools:
   ToolSearch: "+firebase get_environment"

2. Try:
   mcp__plugin_crashlytics_firebase__firebase_get_environment

3. If works → use MCP for all requests (Steps 1-5)
   Build console_url: "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}"
4. If error → go to Level 2
```

#### Level 2: CLI API fallback (via Firebase CLI token)

If MCP unavailable but Firebase CLI is authorized — get data via REST API:

```yaml
1. Check CLI:
   Bash: which firebase 2>/dev/null && firebase login:list 2>/dev/null

   If CLI not authorized → go to Level 3

2. Get project_id and app_id via CLI:
   Bash: firebase projects:list --json 2>/dev/null | python3 -c "
     import sys,json
     for p in json.load(sys.stdin)['results']:
       print(f\"{p['projectId']} — {p.get('displayName','')}\")"

   Bash: firebase apps:list --project {PROJECT_ID} --json 2>/dev/null | python3 -c "
     import sys,json
     for a in json.load(sys.stdin)['result']:
       if a.get('platform')=='IOS':
         print(f\"{a['appId']} | {a.get('displayName','')}\")"

3. Build console_url immediately after getting project_id and app_id:
   console_url = "https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}"
   Save this URL — it's needed for forensics and reviewer.

4. Get access_token from saved Firebase CLI credentials:
   Bash: python3 -c "
     import json, urllib.request, urllib.parse, os
     config = json.load(open(os.path.expanduser('~/.config/configstore/firebase-tools.json')))
     refresh_token = config['tokens']['refresh_token']
     data = urllib.parse.urlencode({
       'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
       'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi',
       'refresh_token': refresh_token,
       'grant_type': 'refresh_token'
     }).encode()
     req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
     resp = json.loads(urllib.request.urlopen(req).read())
     print(resp['access_token'])"

   NOTE: client_id and client_secret are public OAuth credentials from Firebase CLI

5. Get crash data via Crashlytics REST API:
   Bash: curl -s -H "Authorization: Bearer {ACCESS_TOKEN}" \
     "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}"

   Bash: curl -s -H "Authorization: Bearer {ACCESS_TOKEN}" \
     "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}/events?pageSize=3"

6. Parse JSON response via python3 and extract:
   - title, type (FATAL/NON_FATAL), status
   - stack traces from events
   - device info, app version
   - event count
```

#### Level 3: Manual fallback (link + manual input)

If neither MCP nor API worked:

```yaml
1. MUST generate a Firebase Console link:
   https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}

   If project_id/app_id known from CLI (Level 2, step 2) — substitute them.
   If not — ask the user to go to Firebase Console manually.

2. Ask the user to copy from Firebase Console:
   - Stack trace (required)
   - Crash title
   - Event count, % users, version
```

**General rules:**
- Try levels sequentially: MCP → CLI API → Manual
- DO NOT stop on MCP error — immediately try CLI API
- Always generate Console URL if project_id and app_id are available
- If Issue ID exists — always try to get data automatically

### STEP 1: Get data

**If user provided a Firebase Issue ID** — first try loading data automatically (Step 3). Only ask for stack trace and context if auto-loading failed.

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

If a **Firebase Issue ID** was provided, data is loaded by priority:

**Option A: MCP works (Step 0, Level 1 succeeded)**

```yaml
Task(
  subagent_type="firebase-fetcher",
  model="haiku",
  prompt="Get crash details from Firebase:

    Issue ID: {issue_id}
    App ID: {app_id} (iOS)
  "
)
```

**Option B: CLI API (Step 0, Level 2 — MCP didn't work)**

If at Step 0 you got project_id, app_id, access_token — request data directly:

```bash
curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}"

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firebasecrashlytics.googleapis.com/v1beta1/projects/{PROJECT_ID}/apps/{APP_ID}/issues/{ISSUE_ID}/events?pageSize=3"
```

**Option C: Manual fallback** — Console URL + manual input:
```
https://console.firebase.google.com/project/{PROJECT_ID}/crashlytics/app/ios:{APP_ID}/issues/{ISSUE_ID}
```

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
[Calls firebase-fetcher]

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
