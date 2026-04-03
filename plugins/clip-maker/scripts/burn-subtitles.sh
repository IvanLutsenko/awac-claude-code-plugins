#!/bin/bash
# burn-subtitles.sh — burn subtitles into clips using whisper transcript
# Uses moviepy + Pillow (no libass/freetype ffmpeg dependency)
# Usage: burn-subtitles.sh <moments_json> <transcript_json> <clips_dir>

set -euo pipefail

# Check moviepy
if ! python3 -c "import moviepy" 2>/dev/null; then
  echo "Installing moviepy + Pillow..."
  pip3 install moviepy Pillow 2>/dev/null
fi

export MOMENTS_JSON="$1"
export TRANSCRIPT_JSON="$2"
export CLIPS_DIR="$3"

python3 -c "
from moviepy import VideoFileClip, TextClip, CompositeVideoClip
import json, os, textwrap

moments_path = os.environ['MOMENTS_JSON']
transcript_path = os.environ['TRANSCRIPT_JSON']
clips_dir = os.environ['CLIPS_DIR']

with open(moments_path) as f:
    moments = json.load(f)
with open(transcript_path) as f:
    transcript = json.load(f)

for i, moment in enumerate(moments):
    moment_id = i + 1
    clip_path = os.path.join(clips_dir, f'clip_{moment_id:02d}.mp4')
    if not os.path.exists(clip_path):
        continue

    clip_start = moment['start']
    clip_end = moment['end']

    clip_segments = [
        s for s in transcript
        if s['end'] > clip_start and s['start'] < clip_end
    ]

    if not clip_segments:
        print(f'Clip {moment_id}: no subtitle segments found, skipping')
        continue

    video = VideoFileClip(clip_path)
    text_clips = []

    for seg in clip_segments:
        start_offset = max(0, seg['start'] - clip_start)
        end_offset = min(clip_end - clip_start, seg['end'] - clip_start)
        text = seg['text'].strip()
        wrapped = chr(10).join(textwrap.wrap(text, width=20))

        txt = TextClip(
            text=wrapped,
            font_size=42,
            color='white',
            stroke_color='black',
            stroke_width=3,
            size=(video.w - 40, None),
            method='caption',
            text_align='center',
        )
        txt = txt.with_start(start_offset).with_end(end_offset)
        txt = txt.with_position(('center', video.h - txt.h - 80))
        text_clips.append(txt)

    output_path = os.path.join(clips_dir, f'clip_{moment_id:02d}_sub.mp4')
    result = CompositeVideoClip([video] + text_clips)
    result.write_videofile(output_path, codec='libx264', audio_codec='aac', logger=None)
    video.close()

    os.replace(output_path, clip_path)
    print(f'Clip {moment_id}: subtitles burned ({len(clip_segments)} segments)')

print('All subtitles burned.')
"
