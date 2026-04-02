#!/bin/bash
# install-deps.sh — check and install ffmpeg + whisper
# Usage: install-deps.sh [--api]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_api=false
for arg in "$@"; do
  [[ "$arg" == "--api" ]] && check_api=true
done

errors=0

# ffmpeg
if command -v ffmpeg &>/dev/null; then
  echo -e "${GREEN}✓${NC} ffmpeg found: $(ffmpeg -version 2>&1 | head -1)"
else
  echo -e "${YELLOW}⟳${NC} Installing ffmpeg..."
  if command -v brew &>/dev/null; then
    brew install ffmpeg
  else
    echo -e "${RED}✗${NC} brew not found. Install ffmpeg manually: https://ffmpeg.org/download.html"
    errors=$((errors + 1))
  fi
fi

# whisper (local mode)
if ! $check_api; then
  if command -v whisper &>/dev/null; then
    echo -e "${GREEN}✓${NC} whisper CLI found"
  elif python3 -c "import whisper" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} whisper Python module found"
  else
    echo -e "${YELLOW}⟳${NC} Installing openai-whisper..."
    if command -v pip3 &>/dev/null; then
      pip3 install openai-whisper
    elif command -v uv &>/dev/null; then
      uv pip install openai-whisper
    else
      echo -e "${RED}✗${NC} pip3/uv not found. Install whisper manually: pip install openai-whisper"
      errors=$((errors + 1))
    fi
  fi
fi

# API mode — check OPENAI_API_KEY
if $check_api; then
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    echo -e "${GREEN}✓${NC} OPENAI_API_KEY is set"
  else
    echo -e "${RED}✗${NC} OPENAI_API_KEY not set. Export it: export OPENAI_API_KEY=sk-..."
    errors=$((errors + 1))
  fi
fi

if [[ $errors -gt 0 ]]; then
  echo -e "\n${RED}$errors dependency issue(s) found. Fix them before proceeding.${NC}"
  exit 1
fi

echo -e "\n${GREEN}All dependencies OK.${NC}"
