---
description: "Transcribe a video using whisper (local or API)"
argument-hint: "<video_path> [--api] [--language ru]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

# Transcribe Video

Transcribe a video file using OpenAI Whisper. Outputs a JSON file with timestamped segments.

## Arguments

Parse `$ARGUMENTS` for:
- `<video_path>` — **required**, path to video file
- `--api` — use OpenAI Whisper API instead of local model
- `--language LANG` — language code (default: ru)

## Steps

### 1. Check dependencies

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/install-deps.sh [--api if passed]
```

### 2. Determine output location

Output directory: same directory as the video file.
Output file: `<video_name>_transcript.json`

### 3. Transcribe

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/transcribe.sh "<video_path>" "<output_dir>" [--api] [--language LANG]
```

### 4. Report

Tell the user:
- Output file path
- Number of segments
- Total duration covered
- First few lines of transcript as preview
