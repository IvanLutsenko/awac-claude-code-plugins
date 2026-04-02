#!/bin/bash
# burn-subtitles.sh — burn subtitles into clips using whisper transcript
# Usage: burn-subtitles.sh <moments_json> <transcript_json> <clips_dir>

set -euo pipefail

MOMENTS_JSON="$1"
TRANSCRIPT_JSON="$2"
CLIPS_DIR="$3"

python3 -c "
import json, subprocess, os

with open('$MOMENTS_JSON') as f:
    moments = json.load(f)
with open('$TRANSCRIPT_JSON') as f:
    transcript = json.load(f)

for i, moment in enumerate(moments):
    moment_id = i + 1
    clip_path = os.path.join('$CLIPS_DIR', f'clip_{moment_id:02d}.mp4')
    if not os.path.exists(clip_path):
        continue

    clip_start = moment['start']
    clip_end = moment['end']

    # Filter transcript segments for this clip's time range
    clip_segments = [
        s for s in transcript
        if s['end'] > clip_start and s['start'] < clip_end
    ]

    if not clip_segments:
        print(f'Clip {moment_id}: no subtitle segments found, skipping')
        continue

    # Generate SRT
    srt_path = os.path.join('$CLIPS_DIR', f'clip_{moment_id:02d}.srt')
    with open(srt_path, 'w') as srt:
        for j, seg in enumerate(clip_segments):
            # Offset timestamps relative to clip start
            start_offset = max(0, seg['start'] - clip_start)
            end_offset = min(clip_end - clip_start, seg['end'] - clip_start)

            start_h = int(start_offset // 3600)
            start_m = int((start_offset % 3600) // 60)
            start_s = int(start_offset % 60)
            start_ms = int((start_offset % 1) * 1000)

            end_h = int(end_offset // 3600)
            end_m = int((end_offset % 3600) // 60)
            end_s = int(end_offset % 60)
            end_ms = int((end_offset % 1) * 1000)

            srt.write(f'{j+1}\n')
            srt.write(f'{start_h:02d}:{start_m:02d}:{start_s:02d},{start_ms:03d} --> ')
            srt.write(f'{end_h:02d}:{end_m:02d}:{end_s:02d},{end_ms:03d}\n')
            srt.write(f'{seg[\"text\"]}\n\n')

    # Burn subtitles into clip
    output_path = os.path.join('$CLIPS_DIR', f'clip_{moment_id:02d}_sub.mp4')
    style = \"FontSize=14,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2,Alignment=2,MarginV=40\"

    cmd = [
        'ffmpeg', '-y',
        '-i', clip_path,
        '-vf', f\"subtitles={srt_path}:force_style='{style}'\",
        '-c:v', 'libx264', '-crf', '23', '-preset', 'fast',
        '-c:a', 'copy',
        output_path
    ]

    subprocess.run(cmd, capture_output=True, check=True)

    # Replace original with subtitled version
    os.replace(output_path, clip_path)
    os.remove(srt_path)
    print(f'Clip {moment_id}: subtitles burned ({len(clip_segments)} segments)')

print('All subtitles burned.')
"
