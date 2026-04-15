#!/bin/bash
# Run all obsidian-tracker tests: hooks (bats) + MCP (vitest) + plugin structure
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

FAILED=0

echo -e "${BOLD}=== Obsidian Tracker Plugin Tests ===${NC}\n"

# --- Plugin Structure ---
echo -e "${BOLD}[1/3] Plugin structure validation${NC}"
if bats "$SCRIPT_DIR/plugin_structure.bats"; then
  echo -e "${GREEN}✓ Plugin structure OK${NC}\n"
else
  echo -e "${RED}✗ Plugin structure FAILED${NC}\n"
  FAILED=1
fi

# --- Hook Tests ---
echo -e "${BOLD}[2/3] Hook tests (bats)${NC}"
if bats "$SCRIPT_DIR/hooks/"*.bats; then
  echo -e "${GREEN}✓ Hook tests OK${NC}\n"
else
  echo -e "${RED}✗ Hook tests FAILED${NC}\n"
  FAILED=1
fi

# --- MCP Server Tests ---
echo -e "${BOLD}[3/3] MCP server tests (vitest)${NC}"
if (cd "$PLUGIN_ROOT/mcp" && npx vitest run --reporter=verbose 2>&1); then
  echo -e "${GREEN}✓ MCP tests OK${NC}\n"
else
  echo -e "${RED}✗ MCP tests FAILED${NC}\n"
  FAILED=1
fi

# --- Summary ---
echo -e "${BOLD}=== Summary ===${NC}"
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi
