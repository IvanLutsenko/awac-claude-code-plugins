---
# Crashlytics Plugin Configuration
# Copy this file to your project: .claude/crashlytics.local.md
# Then customize the values below.

# Output language for reports (en, ru, es, de, etc.)
language: en

# Default branch for git blame analysis
default_branch: master

# Default platform when not specified (android | ios)
default_platform: android

# Forensics agent model (opus | sonnet). Opus recommended for deeper analysis.
forensics_model: opus

# Output format: both | detailed_only | jira_only
output_format: both

# Firebase project ID (auto-detected if empty)
firebase_project_id: ""

# Firebase App IDs (auto-detected if empty)
firebase_app_id_android: ""
firebase_app_id_ios: ""
---

# Crashlytics Plugin Config

This file stores your project-specific settings for the Crashlytics plugin.

## How to customize

1. Copy this file to your project root: `.claude/crashlytics.local.md`
2. Edit the YAML frontmatter values above
3. The plugin will automatically read your config on next run

## Settings reference

| Setting | Default | Description |
|---------|---------|-------------|
| `language` | `en` | Report output language |
| `default_branch` | `master` | Branch for git blame (master, main, develop) |
| `default_platform` | `android` | Default platform (android, ios) |
| `forensics_model` | `opus` | Model for forensics agent (opus, sonnet) |
| `output_format` | `both` | Report format: both, detailed_only, jira_only |
| `firebase_project_id` | auto | Firebase project (auto-detected if empty) |
| `firebase_app_id_android` | auto | Android app ID (auto-detected if empty) |
| `firebase_app_id_ios` | auto | iOS app ID (auto-detected if empty) |
