---
description: "Find interesting moments in a transcript or video"
argument-hint: "<transcript_or_video_path> [--duration 60]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*), Read, Agent
---

# Find Interesting Moments

Analyze a transcript (or video) to find the most engaging moments for vertical clips.

## Arguments

Parse `$ARGUMENTS` for:
- `<path>` — **required**, path to either:
  - `transcript.json` — pre-existing transcript
  - video file (`.mp4`, `.mov`, `.avi`, etc.) — will transcribe first
- `--duration N` — target moment duration in seconds (default: 60)

## Steps

### 1. Determine input type

Check the file extension:
- If `.json` → use as transcript directly
- If video file → transcribe first using:
  ```bash
  bash ${CLAUDE_PLUGIN_ROOT}/scripts/install-deps.sh
  bash ${CLAUDE_PLUGIN_ROOT}/scripts/transcribe.sh "<video_path>" "<output_dir>"
  ```

### 2. Find moments

Launch the `moment-finder` agent:

```
Agent(subagent_type="clip-maker:moment-finder", model="opus", prompt="
Analyze the transcript and find the most engaging moments.

- Transcript path: <transcript_path>
- Target duration: <duration> seconds
- Output path: <output_dir>/moments.json

Read the transcript, find the best moments, and write moments.json.
")
```

### 3. Display results

Read `moments.json` and present moments to the user as a formatted list:
- Number, title, time range (MM:SS - MM:SS), score
- The key quote from each moment
