#!/usr/bin/env bash
# Harness 一键投影：adapters -> .cursor / .trae / AGENTS.md + skill sync
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT="${ROOT}/harness-kit"
TARGET="all"
FORCE=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--target cursor|trae|codex|all] [--force] [--dry-run]

Projects harness-kit adapters to workspace:
  adapters/cursor/.cursor/  -> .cursor/
  adapters/trae/.trae/      -> .trae/
  adapters/agents/AGENTS.md -> AGENTS.md
  sync-skills.sh            -> .cursor/skills + .trae/skills

--dry-run: 仅打印计划，不实际写入；同步 sync-skills.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-all}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 1 ;;
  esac
done

copy_tree() {
  local src="$1"
  local dst="$2"
  local label="$3"
  if [[ ! -d "$src" ]]; then
    echo "Warn: missing $label source: $src" >&2
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] ${label}: would copy ${src}/ -> ${dst}/"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete --dry-run --itemize-changes "${src}/" "${dst}/" 2>/dev/null | sed 's/^/    /' | head -40
    else
      for item in "${src}"/* "${src}"/.[!.]*; do
        [[ -e "$item" ]] || continue
        echo "    [dry] copy: ${item} -> ${dst}/"
      done
    fi
    return 0
  fi
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${src}/" "${dst}/"
  else
    # fallback: cp -a per top-level entry
    local item
    for item in "${src}"/* "${src}"/.[!.]*; do
      [[ -e "$item" ]] || continue
      local base
      base="$(basename "$item")"
      rm -rf "${dst}/${base}"
      cp -a "$item" "${dst}/"
    done
  fi
  echo "[ok] ${label}: ${src} -> ${dst}"
}

bootstrap_cursor() {
  # Cursor adapter：只同步 adapters/cursor/.cursor/{agents,rules,hooks,mcp} 等子目录
  # .cursor/skills/ 由 sync-skills.sh 单独管理，不在 bootstrap 范围（避免 rsync --delete 误删 hobby 层 skill）
  local src="${KIT}/adapters/cursor/.cursor"
  local dst="${ROOT}/.cursor"
  local sub

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] Cursor: would sync ${src}/{agents,rules,hooks,mcp} -> ${dst}/"
    for sub in agents rules hooks mcp; do
      if [[ -d "${src}/${sub}" ]]; then
        echo "    [dry] copy ${src}/${sub}/ -> ${dst}/${sub}/"
      fi
    done
    echo "[dry] Cursor: would check hooks.json (DRY-RUN, no write)"
    bash "${KIT}/scripts/sync-skills.sh" --target cursor --dry-run
    return 0
  fi

  for sub in agents rules hooks mcp; do
    if [[ -d "${src}/${sub}" ]]; then
      mkdir -p "${dst}/${sub}"
      if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "${src}/${sub}/" "${dst}/${sub}/"
      else
        cp -a "${src}/${sub}/." "${dst}/${sub}/" 2>/dev/null || cp -a "${src}/${sub}"/* "${dst}/${sub}/"
      fi
      echo "[ok] Cursor ${sub}: ${src}/${sub} -> ${dst}/${sub}"
    fi
  done

  # 保留项目已有 mcp/hooks.json 若存在且非 force 时不覆盖用户自定义
  if [[ -f "${dst}/hooks.json" ]] && [[ "$FORCE" -eq 0 ]]; then
    echo "[keep] .cursor/hooks.json (use --force to overwrite from example)"
  elif [[ -f "${KIT}/adapters/cursor/.cursor/hooks.json.example" ]] && [[ ! -f "${dst}/hooks.json" ]]; then
    cp "${KIT}/adapters/cursor/.cursor/hooks.json.example" "${dst}/hooks.json.example"
    echo "[hint] Copy hooks.json.example to hooks.json to enable hooks"
  fi
  bash "${KIT}/scripts/sync-skills.sh" --target cursor
}

bootstrap_trae() {
  # Trae adapter：只同步 adapters/trae/.trae/{agents,rules} 等子目录
  # .trae/skills/ 由 sync-skills.sh 单独管理，不在 bootstrap 范围（避免 rsync --delete 误删 hobby 层 skill）
  local src="${KIT}/adapters/trae/.trae"
  local dst="${ROOT}/.trae"
  local sub

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] Trae: would sync ${src}/{agents,rules} -> ${dst}/"
    for sub in agents rules; do
      if [[ -d "${src}/${sub}" ]]; then
        echo "    [dry] copy ${src}/${sub}/ -> ${dst}/${sub}/"
      fi
    done
    echo "[dry] Trae: would remove deprecated ${dst}/agents/harness-tester.md"
    bash "${KIT}/scripts/sync-skills.sh" --target trae --dry-run
    return 0
  fi

  for sub in agents rules; do
    if [[ -d "${src}/${sub}" ]]; then
      mkdir -p "${dst}/${sub}"
      if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "${src}/${sub}/" "${dst}/${sub}/"
      else
        cp -a "${src}/${sub}/." "${dst}/${sub}/" 2>/dev/null || cp -a "${src}/${sub}"/* "${dst}/${sub}/"
      fi
      echo "[ok] Trae ${sub}: ${src}/${sub} -> ${dst}/${sub}"
    fi
  done

  # 移除已废弃 harness-tester
  rm -f "${dst}/agents/harness-tester.md" 2>/dev/null || true
  bash "${KIT}/scripts/sync-skills.sh" --target trae
}

bootstrap_codex() {
  if [[ -f "${KIT}/adapters/codex/entrypoints/AGENTS.harness.md" ]]; then
    mkdir -p "${ROOT}"
    # 合并到 AGENTS.md：若已有则提示手动合并
    if [[ -f "${ROOT}/AGENTS.md" ]] && [[ "$FORCE" -eq 0 ]]; then
      echo "[keep] AGENTS.md exists; Codex section in harness-kit/adapters/codex/entrypoints/AGENTS.harness.md"
    else
      cp "${KIT}/adapters/agents/AGENTS.md" "${ROOT}/AGENTS.md"
      echo "[ok] AGENTS.md <- adapters/agents/AGENTS.md (includes Codex pointer)"
    fi
  fi
  echo "[ok] Codex: Read harness-kit/adapters/codex/entrypoints/AGENTS.harness.md"
}

bootstrap_agents() {
  cp "${KIT}/adapters/agents/AGENTS.md" "${ROOT}/AGENTS.md"
  echo "[ok] AGENTS.md"
}

mkdir -p "${ROOT}/.ai-runtime-artifacts"/{specs,plans,decisions,execution-logs/tracking,verifications,reviews,research}

case "$TARGET" in
  cursor) bootstrap_cursor ;;
  trae) bootstrap_trae ;;
  codex) bootstrap_codex ;;
  all)
    bootstrap_agents
    bootstrap_cursor
    bootstrap_trae
    bootstrap_codex
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    exit 1
    ;;
esac

echo ""
echo "Harness bootstrap complete (target=${TARGET})."
echo "Quick start: Harness：help"
echo "Docs: harness-kit/README.md | Trae: harness-kit/adapters/trae/trae-quick-ref.md"
