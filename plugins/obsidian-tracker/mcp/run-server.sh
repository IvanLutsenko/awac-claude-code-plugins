#!/bin/sh
# Obsidian Tracker MCP Server Launcher
# Ensures the server runs from the correct directory

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$SCRIPT_DIR/dist/index.js"
