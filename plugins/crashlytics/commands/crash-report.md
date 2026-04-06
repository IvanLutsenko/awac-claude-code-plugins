---
description: "Analyze crash from Firebase Crashlytics. Auto-detects platform from config. Usage: /crash-report <issue_id | console_url | crash info>"
argument-hint: "<issue_id | console_url | crash description>"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(python3 ${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git log:*), Bash(git blame:*), Bash(git diff:*), Bash(git show:*), Bash(which firebase:*), Bash(firebase *:*), Bash(python3:*), Bash(echo:*), Bash(curl:*), Bash(mkdir:*), Bash(cat:*), Task, Read, Glob, Grep, Agent, AskUserQuestion
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

## Step 0.5: Prerequisites Check (cached)

Skip if `.claude/crashlytics-prereqs-ok` exists. Otherwise run and cache on success.

```yaml
Bash: test -f .claude/crashlytics-prereqs-ok && echo "CACHED_OK"

If not cached:
  Bash: ${CLAUDE_PLUGIN_ROOT}/scripts/check-prerequisites.sh
  Parse output: OK → pass, MISSING → fail with fix instruction
  If ALL OK → Bash: touch .claude/crashlytics-prereqs-ok
  If any MISSING → show checklist, degrade gracefully (do NOT cache)
```

Fix instructions: node → `brew install node`, firebase → `npm install -g firebase-tools`, firebase-auth → `firebase login` in terminal, python3 → `brew install python3`.

## Step 1: Parse input

| Input | How to detect | Action |
|-------|---------------|--------|
| Firebase Issue ID | 32-char hex string | Use as ISSUE_ID |
| Console URL | Contains `console.firebase.google.com` | Extract project_id, app_id, issue_id from URL |
| Stack trace / text | Multi-line or descriptive | Use as crash context, skip Firebase auto-load |
| Nothing | No argument | Ask user to provide crash info |

## Step 2: Fetch Firebase Data

Delegate to **firebase-fetcher** agent. Do NOT duplicate discovery/fetch logic here.

```yaml
Task(
  subagent_type="firebase-fetcher",
  model="haiku",
  prompt="Fetch crash data:
    Issue ID: {ISSUE_ID}
    Platform: {PLATFORM}
    Config project_id: {firebase_project_id or ''}
    Config app_id: {firebase_app_id_{PLATFORM} or ''}"
)
```

Parse result: extract issue data, events, stack traces, console_url, or fallback mode.

If fallback → generate Console URL (if project_id/app_id known) and ask user for stack trace manually.

## Step 3: Classify + Forensics

```yaml
# Classifier:
Task(
  subagent_type="crash-classifier-{PLATFORM}",
  model="haiku",
  prompt="Classify this crash:
    Stack trace: {stack_trace}
    Context: Events={event_count}, Users={user_count}%, Version={app_version}, Device={device}"
)

# Forensics:
Task(
  subagent_type="crash-forensics-{PLATFORM}",
  model="{forensics_model from config, default opus}",
  prompt="Analyze this crash with git blame:
    Classification: {classifier_output}
    Firebase data: {firebase_output}
    Stack trace: {stack_trace}
    console_url: {console_url}
    branch: {default_branch from config, default master}"
)
```

## Step 4: Quality Gate

```yaml
Bash: echo "{forensics_output}" | python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-report.py --console-url "{console_url}"
```

Parse the YAML result:
- `pass: true` → output report as-is
- `pass: false` → fill missing fields from previous steps, do NOT re-call forensics
- `pass: null` (has `needs_review` items) → evaluate those fields yourself and decide pass/fail

## Step 5: Output

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
