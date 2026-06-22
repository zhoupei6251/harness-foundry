#!/usr/bin/env bash
# 从 .agents/skills 按 _manifest.yaml 投影到 .cursor/skills 和 .trae/skills
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="${ROOT}/.agents/skills/_manifest.yaml"
SRC="${ROOT}/.agents/skills"
CURSOR_DST="${ROOT}/.cursor/skills"
TRAE_DST="${ROOT}/.trae/skills"
MIMOCODE_DST="${ROOT}/harness-kit/adapters/mimocode/.agents/skills"
KIT_CURSOR_SKILLS="${ROOT}/harness-kit/adapters/cursor/.cursor/skills"

TARGET="all"
DRY_RUN=0

# 第三方来源 skill 列表（cherry-pick 自上游，不参与 sync，避免被覆盖/裁剪）
# 详见 harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md
SKIP_FROM_SYNC=(
  "subagent-driven-development"
  "dispatching-parallel-agents"
  "using-git-worktrees"
  "executing-plans"
)

usage() {
  cat <<'EOF'
Usage: sync-skills.sh [--target cursor|trae|mimocode|all] [--dry-run]

Syncs skills from .agents/skills/ to IDE projection dirs per _manifest.yaml.
Also merges harness-kit WU skill copies from adapters/cursor when present.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-all}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: manifest not found: $MANIFEST" >&2
  exit 1
fi

# Parse manifest layers into skill lists (simple grep-based, no yq dependency)
collect_layer_skills() {
  local layer="$1"
  awk -v layer="$layer" '
    $0 ~ "^  " layer ":" { in_layer=1; next }
    in_layer && $0 ~ "^  [a-z_]+:" { in_layer=0 }
    in_layer && $0 ~ "^      - " {
      gsub(/^      - /,"")
      sub(/\r$/, "")                          # 去 Windows 行尾 CR
      print
    }
  ' "$MANIFEST"
}

collect_projection_layers() {
  local platform="$1"
  awk -v p="$platform" '
    BEGIN { in_p=0 }
    # 进入新的 platform 块（"  <name>:" 行）
    /^  [a-z_]+:/ {
      if (in_p) exit                          # 已经在 platform 块中，遇到下一个 platform 就退出
      if ($0 ~ "^  " p ":") in_p=1            # 进入目标 platform 块
    }
    # 在目标 platform 块中解析 include_layers
    in_p && /include_layers:/ {
      # 兼容 inline 格式：include_layers: [wu, project]
      if (match($0, /\[([^]]+)\]/)) {
        content = substr($0, RSTART+1, RLENGTH-2)
        # 去 Windows 行尾 CR
        sub(/\r$/, "", content)
        n = split(content, arr, "[, ]+")
        for (i=1; i<=n; i++) {
          if (arr[i] != "") print arr[i]
        }
      }
    }
  ' "$MANIFEST"
}

build_target_list() {
  local platform="$1"
  local layers
  layers="$(collect_projection_layers "$platform")"
  local layer skill
  declare -A seen=()
  while IFS= read -r layer; do
    [[ -z "$layer" ]] && continue
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ -z "${seen[$skill]+x}" ]]; then
        seen[$skill]=1
        echo "$skill"
      fi
    done < <(collect_layer_skills "$layer")
  done <<< "$layers"
}

copy_skill() {
  local slug="$1"
  local dst_base="$2"
  local src_dir=""
  # 防御性：去掉 slug 末尾可能的 \r（Windows CRLF）
  slug="${slug%$'\r'}"
  if [[ -d "${SRC}/${slug}" ]]; then
    src_dir="${SRC}/${slug}"
  elif [[ -d "${KIT_CURSOR_SKILLS}/${slug}" ]]; then
    src_dir="${KIT_CURSOR_SKILLS}/${slug}"
  else
    echo "  [skip] ${slug} — not in .agents or kit adapter"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry] ${slug} -> ${dst_base}/${slug}"
    return 0
  fi
  mkdir -p "${dst_base}"
  rm -rf "${dst_base}/${slug}"
  cp -a "${src_dir}" "${dst_base}/${slug}"
  echo "  [ok] ${slug}"
}

prune_extra() {
  local dst_base="$1"
  shift
  local -a allowed=("$@")
  [[ "$DRY_RUN" -eq 1 ]] && return 0
  [[ ! -d "$dst_base" ]] && return 0
  local d slug
  for d in "${dst_base}"/*; do
    [[ -d "$d" ]] || continue
    slug="$(basename "$d")"
    [[ "$slug" == "aigc-platform-backend" ]] && continue
    [[ "$slug" == "README.md" || "$slug" == ".DS_Store" ]] && continue
    local found=0
    for a in "${allowed[@]}"; do
      [[ "$slug" == "$a" ]] && found=1 && break
    done
    if [[ "$found" -eq 0 ]]; then
      echo "  [prune] ${dst_base}/${slug}"
      rm -rf "$d"
    fi
  done
}

sync_platform() {
  local platform="$1"
  local dst=""
  case "$platform" in
    cursor) dst="$CURSOR_DST" ;;
    trae) dst="$TRAE_DST" ;;
    mimocode) dst="$MIMOCODE_DST" ;;
    *) echo "Unknown platform: $platform" >&2; return 1 ;;
  esac
  echo "==> Sync ${platform} -> ${dst}"
  mkdir -p "$dst"
  mapfile -t skills < <(build_target_list "$platform")
  local s
  for s in "${skills[@]}"; do
    # 第三方来源 skill：跳过 copy，避免被覆盖
    local is_skip=0
    for skip in "${SKIP_FROM_SYNC[@]}"; do
      if [[ "$s" == "$skip" ]]; then
        echo "  [skip-from-sync] ${s} — 第三方来源，保留本地副本"
        is_skip=1
        break
      fi
    done
    [[ "$is_skip" -eq 1 ]] && continue
    copy_skill "$s" "$dst"
  done
  # 把第三方 skill 加入 allow 列表，避免被 prune_extra 删除
  local allowed=("${skills[@]}" "${SKIP_FROM_SYNC[@]}")
  prune_extra "$dst" "${allowed[@]}"
  echo "==> ${platform}: ${#skills[@]} skills (含 ${#SKIP_FROM_SYNC[@]} 第三方 skip)"
}

case "$TARGET" in
  cursor) sync_platform cursor ;;
  trae) sync_platform trae ;;
  mimocode) sync_platform mimocode ;;
  all)
    sync_platform cursor
    sync_platform trae
    sync_platform mimocode
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    exit 1
    ;;
esac

echo "Done."
