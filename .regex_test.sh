#!/usr/bin/env bash
content="---
name: test
"
if [[ "$content" =~ ^---[[:space:]]*$ ]]; then
  echo "MATCH"
else
  echo "NO_MATCH"
fi

# Test simpler regex
if [[ "$content" =~ ^--- ]]; then
  echo "STARTS_WITH_DASH"
else
  echo "NO_DASH"
fi