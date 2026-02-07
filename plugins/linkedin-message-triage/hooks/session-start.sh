#!/usr/bin/env bash
#
# SessionStart hook: Check Playwright MCP availability
# Verifies that npx and the Playwright MCP package are available
# for browser automation.
#

# Consume hook input from stdin
cat > /dev/null

if ! command -v npx > /dev/null 2>&1; then
  echo "Playwright MCP: npx not found. Install Node.js to enable browser automation."
  exit 0
fi

# Use npm list instead of npx --help to avoid triggering a package download
if npm list -g @anthropic/mcp-playwright > /dev/null 2>&1 || npm list @anthropic/mcp-playwright > /dev/null 2>&1; then
  echo "Playwright MCP: available"
else
  echo "Playwright MCP: package not installed. Run 'npm install -g @anthropic/mcp-playwright' to enable browser automation."
fi
exit 0
