#!/usr/bin/env bash
# 把 harness-kit/third-party/ 内容投影到 .trae/ (Trae IDE 读取路径)
#
# 用法:
#   sync-third-party.sh                  # 正向: third-party/ → .trae/
#   sync-third-party.sh --reverse        # 反向: .trae/ → third-party/  (升级/回填)
#   sync-third-party.sh --dry-run        # 仅显示计划
#
# 详见:
#   harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
THIRD_PARTY="${ROOT}/harness-kit/third-party"
TRAE_SKILLS="${ROOT}/.trae/skills"
TRAE_AGENTS="${ROOT}/.trae/agents"

DRY_RUN=0
REVERSE=0

usage() {
  cat <<EOF
Usage: sync-third-party.sh [--reverse] [--dry-run]

默认（正向）：harness-kit/third-party/ → .trae/
--reverse：   .trae/ → harness-kit/third-party/（升级或回填）
--dry-run：   仅打印，不执行
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reverse) REVERSE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 1 ;;
  esac
done

# 第三方来源清单（hard-coded，不走 manifest）
SP_SKILLS=(
  "subagent-driven-development"
  "dispatching-parallel-agents"
  "using-git-worktrees"
  "executing-plans"
)

ECC_AGENTS=(
  "ecc-java-reviewer"
  "ecc-security-reviewer"
  "ecc-database-reviewer"
)

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "    [dry] $*"
  else
    "$@"
  fi
}

sync_skill() {
  local slug="$1"
  local src dst
  if [[ "$REVERSE" -eq 1 ]]; then
    src="${TRAE_SKILLS}/${slug}"
    dst="${THIRD_PARTY}/superpowers/skills/${slug}"
  else
    src="${THIRD_PARTY}/superpowers/skills/${slug}"
    dst="${TRAE_SKILLS}/${slug}"
  fi

  if [[ ! -d "$src" ]]; then
    echo "  [skip] ${slug} — source not found: ${src}"
    return 0
  fi

  echo "  [ok] ${slug}"
  run rm -rf "$dst"
  run mkdir -p "$(dirname "$dst")"
  run cp -a "$src" "$dst"
}

sync_agent() {
  local name="$1"
  local src dst
  local src_meta dst_meta
  if [[ "$REVERSE" -eq 1 ]]; then
    src="${TRAE_AGENTS}/${name}.md"
    dst="${THIRD_PARTY}/ecc/agents/${name}.md"
    src_meta="${TRAE_AGENTS}/${name}.meta.json"
    dst_meta="${THIRD_PARTY}/ecc/agents/${name}.meta.json"
  else
    src="${THIRD_PARTY}/ecc/agents/${name}.md"
    dst="${TRAE_AGENTS}/${name}.md"
    src_meta="${THIRD_PARTY}/ecc/agents/${name}.meta.json"
    dst_meta="${TRAE_AGENTS}/${name}.meta.json"
  fi

  if [[ ! -f "$src" ]]; then
    echo "  [skip] ${name} — source not found: ${src}"
    return 0
  fi

  echo "  [ok] ${name}.md"
  run mkdir -p "$(dirname "$dst")"
  run cp "$src" "$dst"

  if [[ -f "$src_meta" ]]; then
    echo "  [ok] ${name}.meta.json"
    run cp "$src_meta" "$dst_meta"
  fi
}

# 主流程
mode="forward (third-party → .trae)"
[[ "$REVERSE" -eq 1 ]] && mode="reverse (.trae → third-party)"
[[ "$DRY_RUN" -eq 1 ]] && mode="${mode} [dry-run]"

echo "==> Sync third-party: ${mode}"
mkdir -p "${TRAE_SKILLS}" "${TRAE_AGENTS}" \
         "${THIRD_PARTY}/superpowers/skills" \
         "${THIRD_PARTY}/ecc/agents"

echo "==> Skills (${#SP_SKILLS[@]}):"
for s in "${SP_SKILLS[@]}"; do
  sync_skill "$s"
done

echo "==> Agents (${#ECC_AGENTS[@]}):"
for a in "${ECC_AGENTS[@]}"; do
  sync_agent "$a"
done

echo "Done."