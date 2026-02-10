# Crashlytics Plugin

Crash log analysis with root cause identification, code-level fixes, and developer assignment via git blame.

**Version:** 4.1.0 — Android & iOS

---

## Prerequisites

Required:
- Git repository with commit history
- Claude Code with the `crashlytics` plugin installed

For Firebase integration (recommended):
- Firebase project with Crashlytics enabled
- Firebase CLI: `npm install -g firebase-tools`
- Authorization: `firebase login`

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
| **Firebase MCP** | Firebase Issue ID + MCP server | Auto-load via MCP (preferred) |
| **Firebase CLI API** | Firebase Issue ID + `firebase login` | Auto-load via REST API with CLI token |
| **Manual Mode** | Stack trace from logs | Same analysis, data entered manually |

The plugin falls back between modes: MCP (with retries) → CLI API → Manual.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      crashlytics v4.1.0                         │
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
2. **Firebase Fetcher** (Haiku) — loads data from Firebase (if available)
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
         "args": ["-c", "NODE_OPTIONS='--max-old-space-size=4096' npx -y firebase-tools@latest experimental:mcp"]
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

### What firebase-fetcher loads

- Issue details (title, status, event count)
- Sample events with full stack traces
- Device info (model, OS version)
- App version

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Firebase MCP unavailable" | Normal — plugin falls back to CLI API |
| "Unable to verify client" | Do not use MCP login. Authorize via `firebase login` in terminal |
| MCP Internal error | Known issue with `experimental:mcp`. Plugin retries 2x then falls to CLI API |
| "Files not found" | Make sure you're in the git repository root |
| "git blame not working" | Check that the repository has commit history |
| "Assignee = TBD" | Manual ownership analysis required |

---

## Changelog

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
