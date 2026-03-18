#!/bin/bash
# Check prerequisites for Crashlytics plugin
echo "=== Crashlytics Prerequisites ==="

# 1. Node.js
if command -v node &>/dev/null; then
  echo "OK node $(node --version)"
else
  echo "MISSING node"
fi

# 2. firebase-tools
if command -v firebase &>/dev/null; then
  echo "OK firebase $(firebase --version 2>/dev/null | head -1)"
else
  echo "MISSING firebase"
fi

# 3. Firebase auth (token file)
if [ -f "$HOME/.config/configstore/firebase-tools.json" ]; then
  echo "OK firebase-auth"
else
  echo "MISSING firebase-auth"
fi

# 4. python3
if command -v python3 &>/dev/null; then
  echo "OK python3 $(python3 --version 2>&1)"
else
  echo "MISSING python3"
fi
