#!/bin/bash
# transcribe.sh — transcribe video using whisper (local or API)
# Usage: transcribe.sh <video_path> <output_dir> [--api] [--language ru] [--prompt "terms"]

set -euo pipefail

VIDEO_PATH="$1"
OUTPUT_DIR="$2"
shift 2

USE_API=false
LANGUAGE="ru"
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api) USE_API=true; shift ;;
    --language) LANGUAGE="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

AUDIO_PATH="${OUTPUT_DIR}/audio.wav"
TRANSCRIPT_PATH="${OUTPUT_DIR}/transcript.json"

# Extract audio
echo "Extracting audio from video..."
ffmpeg -y -i "$VIDEO_PATH" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO_PATH" 2>/dev/null

if $USE_API; then
  echo "Transcribing via OpenAI Whisper API..."

  # API has 25MB limit per file, split if needed
  FILE_SIZE=$(stat -f%z "$AUDIO_PATH" 2>/dev/null || stat --printf="%s" "$AUDIO_PATH" 2>/dev/null)
  MAX_SIZE=$((25 * 1024 * 1024))

  if [[ $FILE_SIZE -gt $MAX_SIZE ]]; then
    echo "Audio file >25MB, compressing to mp3 for API..."
    MP3_PATH="${OUTPUT_DIR}/audio.mp3"
    ffmpeg -y -i "$AUDIO_PATH" -codec:a libmp3lame -b:a 64k "$MP3_PATH" 2>/dev/null
    UPLOAD_PATH="$MP3_PATH"
  else
    UPLOAD_PATH="$AUDIO_PATH"
  fi

  PROMPT_API_ARG=""
  if [[ -n "$PROMPT" ]]; then
    PROMPT_API_ARG="-F prompt=$PROMPT"
  fi

  RESPONSE=$(curl -s https://api.openai.com/v1/audio/transcriptions \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -F file="@${UPLOAD_PATH}" \
    -F model="whisper-1" \
    -F response_format="verbose_json" \
    -F timestamp_granularities[]="segment" \
    -F language="$LANGUAGE" \
    $PROMPT_API_ARG)

  # Convert API response to our format: [{start, end, text}, ...]
  echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
segments = [{'start': s['start'], 'end': s['end'], 'text': s['text'].strip()} for s in data.get('segments', [])]
json.dump(segments, sys.stdout, ensure_ascii=False, indent=2)
" > "$TRANSCRIPT_PATH"

else
  echo "Transcribing locally with whisper (model: large-v3)..."

  # Use whisper CLI
  PROMPT_ARG=""
  if [[ -n "$PROMPT" ]]; then
    PROMPT_ARG="--initial_prompt $PROMPT"
  fi

  if command -v whisper &>/dev/null; then
    whisper "$AUDIO_PATH" \
      --model large-v3 \
      --language "$LANGUAGE" \
      --output_format json \
      --output_dir "$OUTPUT_DIR" \
      $PROMPT_ARG \
      2>/dev/null

    # Whisper CLI outputs audio.json, convert to our format
    WHISPER_JSON="${OUTPUT_DIR}/audio.json"
    python3 -c "
import json
with open('$WHISPER_JSON') as f:
    data = json.load(f)
segments = [{'start': s['start'], 'end': s['end'], 'text': s['text'].strip()} for s in data.get('segments', [])]
with open('$TRANSCRIPT_PATH', 'w') as f:
    json.dump(segments, f, ensure_ascii=False, indent=2)
"
  else
    # Fallback: use Python module directly
    python3 -c "
import whisper, json
model = whisper.load_model('large-v3')
prompt = '$PROMPT' if '$PROMPT' else None
result = model.transcribe('$AUDIO_PATH', language='$LANGUAGE', initial_prompt=prompt)
segments = [{'start': s['start'], 'end': s['end'], 'text': s['text'].strip()} for s in result['segments']]
with open('$TRANSCRIPT_PATH', 'w') as f:
    json.dump(segments, f, ensure_ascii=False, indent=2)
"
  fi
fi

# Cleanup intermediate files
rm -f "$AUDIO_PATH" "${OUTPUT_DIR}/audio.mp3" "${OUTPUT_DIR}/audio.json"

SEGMENT_COUNT=$(python3 -c "import json; print(len(json.load(open('$TRANSCRIPT_PATH'))))")
echo "Transcription complete: $SEGMENT_COUNT segments → $TRANSCRIPT_PATH"
