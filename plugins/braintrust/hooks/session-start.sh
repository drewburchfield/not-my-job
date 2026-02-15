#!/usr/bin/env bash
#
# SessionStart hook: Check AI CLI availability
# Reports which CLIs (gemini, codex, claude) are installed so Claude
# knows what tools are available before the user asks.
#

# Consume hook input from stdin
cat > /dev/null

results=()

check_cli() {
  local name="$1"
  local install_hint="$2"

  if command -v "$name" > /dev/null 2>&1; then
    results+=("$name (available)")
  else
    results+=("$name (NOT FOUND - $install_hint)")
  fi
}

check_cli "gemini" "install with: npm install -g @google/gemini-cli or see https://github.com/google-gemini/gemini-cli"
check_cli "codex" "install with: npm install -g @openai/codex"
check_cli "claude" "install with: npm install -g @anthropic-ai/claude-code"

# Join results with comma separator
joined=$(printf '%s, ' "${results[@]}")
echo "Braintrust CLIs: ${joined%, }"
exit 0
