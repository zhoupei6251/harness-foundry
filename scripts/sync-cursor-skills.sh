#!/usr/bin/env bash
# sync-cursor-skills.sh — 从 harness-foundry 同步内置能力副本到 .cursor/skills/
# 实际上是通过 sync-skills.sh --target cursor 实现的

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUNDRY_DIR="$(dirname "$SCRIPT_DIR")"

echo "[sync-cursor-skills] delegating to sync-skills.sh --target cursor"
bash "$FOUNDRY_DIR/scripts/sync-skills.sh" --target cursor
