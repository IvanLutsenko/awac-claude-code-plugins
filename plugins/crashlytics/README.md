# Crashlytics Plugin

Crash log analysis with root cause identification, code-level fixes, and developer assignment via git blame.

**Version:** 4.2.2 — Android & iOS

---

## Prerequisites

> **The plugin checks prerequisites automatically** on every run and shows what's missing.
> If something is missing, it will show install instructions and offer to fix what it can.

### Required (without these the plugin won't analyze code)

- **Git** — repository with commit history
- **Claude Code** with the `crashlytics` plugin installed

### Required for automatic crash data loading

| # | Dependency | Install command | What it does |
|---|-----------|----------------|-------------|
| 1 | **Node.js** | `brew install node` (macOS) / `sudo apt install nodejs` (Linux) | Runtime for Firebase MCP server and CLI |
| 2 | **firebase-tools** | `npm install -g firebase-tools` | Firebase CLI — project discovery + auth token |
| 3 | **Firebase login** | `firebase login` (opens browser) | Creates token at `~/.config/configstore/firebase-tools.json` |
| 4 | **python3** | Usually pre-installed on macOS/Linux | Runs the REST API script to fetch crash data |
| 5 | **Crashlytics API** | Enable in [GCP Console](https://console.cloud.google.com/apis/library/firebasecrashlytics.googleapis.com) | Without this, REST API returns 403 |

### Quick setup (copy-paste)

```bash
# 1. Install firebase-tools (requires Node.js)
npm install -g firebase-tools

# 2. Login (opens browser)
firebase login

# 3. Set active project
firebase use your-project-id

# 4. Enable Crashlytics API (replace YOUR_PROJECT_ID)
# Option A: open in browser
open "https://console.cloud.google.com/apis/library/firebasecrashlytics.googleapis.com?project=YOUR_PROJECT_ID"
# Option B: via gcloud (if installed)
gcloud services enable firebasecrashlytics.googleapis.com --project=YOUR_PROJECT_ID
```

> **Without Firebase setup** the plugin still works — but in Manual mode (you paste the stack trace yourself).

---

## Quick Start

### Unified command (recommended)

```bash
/crash-report ca8f7f21e3ec633d0d1dca453409435b
```

Auto-detects platform from config. Accepts issue ID, console URL, or stack trace.

### Platform-specific

```bash
/crash-report-android              # Explicit Android
/crash-report-ios                  # Explicit iOS
```

### Configure the plugin

```bash
/crash-config
```

Interactive setup for language, branch, model, output format, and Firebase project.
Config auto-created with defaults on first run if missing.

---

## Operating Modes

| Mode | Requirements | What you get |
|------|-------------|--------------|
| **CLI REST API** | Firebase Issue ID + `firebase login` + Crashlytics API enabled | Auto-load crash data via REST API (primary) |
| **Enhanced Manual** | Stack trace from logs | Same analysis, guided manual data entry with Console URLs |

MCP is used **only for project/app discovery** (`firebase_get_environment`, `firebase_list_apps`). Crashlytics data tools do not exist in the Firebase MCP server — all crash data is fetched via the CLI REST API.

The plugin falls back between modes: CLI REST API → Enhanced Manual.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      crashlytics v4.2.2                         │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
     ┌─────────────────┐            ┌─────────────────┐
     │   Android        │            │      iOS        │
     │   /crash-report  │            │  /crash-report  │
     │   -android       │            │      -ios       │
     ├─────────────────┤            ├─────────────────┤
     │ classifier       │            │  classifier     │
     │ firebase-fetcher │            │  firebase-fetcher│
     │ forensics        │            │  forensics      │
     │ reviewer         │            │  reviewer       │
     └─────────────────┘            └─────────────────┘
```

### Four-step analysis

1. **Classifier** (Haiku) — determines component and trigger
2. **Firebase Fetcher** (Haiku) — loads data via CLI REST API (MCP for discovery only)
3. **Forensics** (Opus) — git blame + code-level fix + assignee
4. **Reviewer** (Haiku) — quality gate validating all mandatory fields

---

## Commands

| Command | Platform | Description |
|---------|----------|-------------|
| `/crash-report` | Auto | Unified command — auto-detects platform from config |
| `/crash-report-android` | Android | Analyze Kotlin/Java crashes |
| `/crash-report-ios` | iOS | Analyze Swift/Objective-C crashes |
| `/crash-config` | Both | Interactive plugin configuration |

---

## Configuration

Run `/crash-config` to set up:

| Setting | Default | Description |
|---------|---------|-------------|
| `language` | English | Output language |
| `default_branch` | master | Branch for git blame |
| `default_platform` | android | Default platform |
| `forensics_model` | opus | Model for forensics agent (opus/sonnet/haiku) |
| `output_format` | both | Output: both / detailed_only / jira_only |
| `firebase_project_id` | — | Firebase project ID (skip auto-detection) |
| `firebase_app_id_android` | — | Android app ID |
| `firebase_app_id_ios` | — | iOS app ID |

Config is stored in `.claude/crashlytics.local.md` (per-project, gitignored).

---

## Input Data

| Field | Required | Description |
|-------|----------|-------------|
| Stack trace | Yes | From Firebase Crashlytics or logs |
| Firebase Issue ID | No | For automatic data loading |
| Crash count | No | Context for analysis |
| % users | No | Context for analysis |
| Device / OS | No | Context |

---

## Output

The plugin returns two formats:

### 1. Detailed Analysis

```
### Crash: NullPointerException in PaymentProcessor

**Basic info**:
- Exception: NullPointerException
- Affected users: 8%
- App version: 2.5.0
- Component: payments

**Stack trace analysis**:
- PaymentProcessor.processPayment():45
- PaymentFragment.onPayClicked():89

**Checked files**:
- src/main/java/.../PaymentProcessor.java:45
  Author: John Smith (git blame)
  Commit: a1b2c3d4

**Executed commands**:
- git blame master -- PaymentProcessor.java -L 40,50
- git log master --oneline -10 -- PaymentProcessor.java

**Root cause**:
paymentProcessor not initialized before calling processPayment()

**Proposed fix**:
Before:
  paymentProcessor.processPayment(card);

After:
  paymentProcessor?.processPayment(card)
    ?: logError("PaymentProcessor not initialized")

**Assignee**: John Smith
- Source: git blame line 45 showed: John Smith

**Context & Prevention**:
- Trigger: User tapped "Pay" button
- Why now: Initialization order changed in v2.5.0
- Prevention: Add null check or lateinit validation
```

### 2. JIRA Brief

Compact format for copy-paste into a ticket, including stack trace, fix (before/after), reproduction steps, and Firebase console link.

---

## Firebase Integration

### Setup

1. Check `.mcp.json` in the plugin:
   ```json
   {
     "mcpServers": {
       "firebase": {
         "command": "sh",
         "args": ["-c", "NODE_OPTIONS='--max-old-space-size=4096' npx -y firebase-tools@latest mcp"]
       }
     }
   }
   ```

2. Authorize:
   ```bash
   firebase login
   ```

3. Set active project:
   ```bash
   firebase use your-project-id
   ```

4. **Enable Crashlytics API** (required for REST API data fetch):
   - GCP Console: `https://console.cloud.google.com/apis/library/firebasecrashlytics.googleapis.com?project=YOUR_PROJECT_ID`
   - Or via gcloud: `gcloud services enable firebasecrashlytics.googleapis.com --project=YOUR_PROJECT_ID`

### What firebase-fetcher loads

- Issue details (title, status, event count)
- Sample events with full stack traces
- Device info (model, OS version)
- App version

### How data fetching works

The Firebase MCP server does **not** provide Crashlytics data tools (`crashlytics_get_issue`, `crashlytics_list_events`, etc.). These tools are referenced in MCP resource guides but are not implemented.

Instead, the plugin:
1. Uses MCP for **project/app discovery** (`firebase_get_environment`, `firebase_list_apps`) — these work
2. Fetches crash data via **CLI REST API** using the token from `~/.config/configstore/firebase-tools.json`
3. Falls back to **Enhanced Manual mode** with Console URLs and step-by-step instructions

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| REST API returns 403/404 | Crashlytics API not enabled. Enable at: `https://console.cloud.google.com/apis/library/firebasecrashlytics.googleapis.com?project=YOUR_PROJECT_ID` |
| "Unable to verify client" | Do not use MCP login. Authorize via `firebase login` in terminal |
| MCP Internal error | Normal for discovery — plugin retries once then uses CLI fallback |
| `REST_FALLBACK_FAILED` | Check `firebase login:list` — may need to re-authenticate |
| "Files not found" | Make sure you're in the git repository root |
| "git blame not working" | Check that the repository has commit history |
| "Assignee = TBD" | Manual ownership analysis required |

---

## Changelog

### 4.2.2
- **Fixed:** Added `Bash(echo:*)` to `allowed-tools` in all crash-report commands — prerequisites check no longer requires manual approval

### 4.2.1
- **Added:** Automatic prerequisites check on every `/crash-report` run (Node.js, firebase-tools, auth, python3)
- **Added:** Auto-install offer for firebase-tools if npm is available
- **Added:** Detailed setup instructions in README with copy-paste commands
- Plugin degrades gracefully: missing tools → Manual mode instead of cryptic errors

### 4.2.0
- **Breaking:** Removed non-existent MCP Crashlytics data tools (`crashlytics_get_issue`, `crashlytics_list_events`, `crashlytics_batch_get_events`, `crashlytics_get_report`) — these were never implemented in Firebase MCP server
- **Changed:** 3-level → 2-level fallback: CLI REST API → Enhanced Manual
- **Changed:** MCP now used only for project/app discovery (working tools: `firebase_get_environment`, `firebase_list_apps`)
- **Changed:** firebase-fetcher agent rewritten: `tools: Bash, Read` instead of `ListMcpResourcesTool, ReadMcpResourceTool`
- **Added:** API_NOT_ENABLED detection with enable instructions (GCP Console URL + gcloud command)
- **Added:** Enhanced Manual fallback with step-by-step Console instructions
- **Added:** Prerequisites: Crashlytics API must be enabled in GCP
- **Fixed:** 4.1.1 changelog (previously claimed MCP tools work — they don't)

### 4.1.1
- **Fix:** `experimental:mcp` → `mcp` — Firebase MCP graduated to GA, old command didn't register tools
- Updated troubleshooting: removed obsolete `experimental:mcp` references
- Note: this fixed MCP discovery tools but Crashlytics data tools were never available

### 4.1.0
- Unified `/crash-report` command — auto-detects platform from config
- Config auto-created with defaults on first run (no more manual setup required)
- MCP retry-first strategy: retries up to 2 times before REST API fallback
- REST API fallback: single script, token never printed to stdout
- Fixed `firebase projects:list` JSON parsing for different CLI versions
- Removed duplicate REST code from Step 3

### 4.0.0
- Quality gate: `report-reviewer` agent validates all mandatory fields before output
- Interactive `/crash-config` command for plugin configuration
- Default forensics model changed to Opus (Sonnet as fallback)
- Severity/priority removed from classifiers — forensics handles context
- Full English translation of all agents and commands
- Configuration system via `.claude/crashlytics.local.md`
- `console_url` and `branch` passed explicitly to forensics agents
- Mandatory "Executed commands" section in detailed analysis
- Mandatory "Context & Prevention" (Trigger, Why now, Prevention)
- Mandatory reproduction steps and Firebase link in JIRA Brief

### 3.2.0
- 3-level Firebase fallback: MCP → CLI API (token from firebase-tools.json) → Console URL + manual input
- Blocked `firebase_login` via MCP (broken: "Unable to verify client")
- `allowed-tools` for automatic approval of Firebase CLI and curl/python3 commands
- Auto-load data by Issue ID without manual stack trace input

### 3.1.0
- Multi-agent architecture: classifier → firebase-fetcher → forensics
- iOS support

### 3.0.0
- Initial release with Android & iOS support

---

## License

MIT
