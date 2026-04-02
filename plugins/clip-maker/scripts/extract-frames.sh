#!/bin/bash
# extract-frames.sh — extract frames from video for each moment
# Usage: extract-frames.sh <video_path> <moments_json> <output_dir>

set -euo pipefail

VIDEO_PATH="$1"
MOMENTS_JSON="$2"
OUTPUT_DIR="$3"
FRAMES_DIR="${OUTPUT_DIR}/frames"

mkdir -p "$FRAMES_DIR"

# Parse moments and extract frames
python3 -c "
import json, subprocess, os, math

with open('$MOMENTS_JSON') as f:
    moments = json.load(f)

for i, moment in enumerate(moments):
    moment_dir = '${FRAMES_DIR}/moment_' + str(i + 1).zfill(2)
    os.makedirs(moment_dir, exist_ok=True)

    start = moment['start']
    end = moment['end']
    duration = end - start

    # Extract 5 evenly spaced frames (or fewer for very short clips)
    num_frames = min(5, max(2, int(duration / 10)))
    interval = duration / num_frames

    for j in range(num_frames):
        timestamp = start + j * interval
        output_path = os.path.join(moment_dir, f'frame_{j+1:02d}.png')
        subprocess.run([
            'ffmpeg', '-y', '-ss', str(timestamp),
            '-i', '$VIDEO_PATH',
            '-vframes', '1',
            '-q:v', '2',
            output_path
        ], capture_output=True)

    print(f'Moment {i+1}: {num_frames} frames extracted ({start:.1f}s - {end:.1f}s)')
"

echo "Frames extracted to $FRAMES_DIR"
