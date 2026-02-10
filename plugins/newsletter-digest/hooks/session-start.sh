#!/usr/bin/env bash
# SessionStart hook: Verify gog CLI available

cat > /dev/null  # Consume stdin

if ! command -v gog > /dev/null 2>&1; then
  echo "newsletter-digest: gog CLI not found"
  echo "  Install: brew install steipete/tap/gogcli"
  exit 0
fi

if ! gog auth list > /dev/null 2>&1; then
  echo "newsletter-digest: gog not authenticated"
  echo "  Run: gog auth add your@gmail.com --services gmail"
  exit 0
fi

echo "newsletter-digest: Ready (gog CLI authenticated)"
exit 0
