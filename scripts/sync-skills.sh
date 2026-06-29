#!/usr/bin/env bash
# Route: code|novel|news
# 技能同步：从 .agents/skills 按 _manifest.yaml 投影到各 IDE（Skills 已扁平化，无 shared 子目录）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/.agents/skills/_manifest.yaml"
SRC="${ROOT}/.agents/skills"
# Skills 已扁平化，不再使用 shared 子目录
# SHARED_SRC="${ROOT}/skills/shared"  # 已废弃
CURSOR_DST="${ROOT}/.cursor/skills"
TRAE_DST="${ROOT}/.trae/skills"
MIMOCODE_DST="${ROOT}/adapters/mimocode/.agents/skills"
KIT_CURSOR_SKILLS="${ROOT}/adapters/cursor/.cursor/skills"

TARGET="all"
DRY_RUN=0

# 第三方来源 skill 列表（cherry-pick 自上游，不参与 sync，避免被覆盖/裁剪）
SKIP_FROM_SYNC=(
  "subagent-driven-development"
  "dispatching-parallel-agents"
  "using-git-worktrees"
  "executing-plans"
)

usage() {
  cat <<'EOF'
Usage: sync-skills.sh [--target cursor|trae|mimocode|all] [--dry-run]

Syncs skills from:
  .agents/skills/          -> IDE projection dirs per _manifest.yaml
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

# === Layer filtering (per spec 2026-06-29-skill-engineering-frontmatter-and-meta) ===
LAYER_FILE="${LAYER_FILE:-skills/_layer.yaml}"
SKIP_ARCHIVED="${SKIP_ARCHIVED:-true}"
ALLOWED_SLUGS=""
if [[ "$SKIP_ARCHIVED" == "true" && -f "$LAYER_FILE" ]]; then
  # 用 Python 解析 _layer.yaml（避免 yq 路径问题 + trailing newline 问题）
  ALLOWED_SLUGS=$(python3 -c "
import yaml
with open('$LAYER_FILE') as f:
    data = yaml.safe_load(f)
print(' '.join(sorted(set(data.get('core', []) + data.get('peripheral', [])))))
" 2>/dev/null || echo "")
  if [[ -n "$ALLOWED_SLUGS" ]]; then
    echo "==> Layer filter: $(echo $ALLOWED_SLUGS | tr ' ' '\n' | grep -c .) allowed slugs (core + peripheral) from $LAYER_FILE"
  else
    echo "Warn: $LAYER_FILE exists but failed to parse; SKIP_ARCHIVED disabled" >&2
    SKIP_ARCHIVED="false"
  fi
fi
# === End layer filtering ===

# ---- 基于 manifest 的平台同步 ----
sync_from_manifest() {
  if [[ ! -f "$MANIFEST" ]]; then
    echo "Warn: manifest not found: $MANIFEST" >&2
    return 0
  fi

  collect_layer_skills() {
    local layer="$1"
    awk -v layer="$layer" '
      $0 ~ "^  " layer ":" { in_layer=1; next }
      in_layer && $0 ~ "^  [a-z_]+:" { in_layer=0 }
      in_layer && $0 ~ "^    - " {
        gsub(/^    - /,"")
        sub(/\r$/, "")
        print
      }
    ' "$MANIFEST"
  }

  collect_projection_layers() {
    local platform="$1"
    awk -v p="$platform" '
      BEGIN { in_p=0 }
      /^  [a-z_]+:/ {
        if (in_p) exit
        if ($0 ~ "^  " p ":") in_p=1
      }
      in_p && /include_layers:/ {
        if (match($0, /\[([^]]+)\]/)) {
          content = substr($0, RSTART+1, RLENGTH-2)
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
    slug="${slug%$'\r'}"
    if [[ -d "${SRC}/${slug}" ]]; then
      src_dir="${SRC}/${slug}"
    elif [[ -d "${KIT_CURSOR_SKILLS}/${slug}" ]]; then
      src_dir="${KIT_CURSOR_SKILLS}/${slug}"
    elif [[ -d "${ROOT}/skills/${slug}" ]]; then
      src_dir="${ROOT}/skills/${slug}"
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
    local kept=()
    for s in "${skills[@]}"; do
      local is_skip=0
      for skip in "${SKIP_FROM_SYNC[@]}"; do
        if [[ "$s" == "$skip" ]]; then
          echo "  [skip-from-sync] ${s} — 第三方来源，保留本地副本"
          is_skip=1
          break
        fi
      done
      # Layer 过滤：archived skill 不投影到 IDE（除非 SKIP_ARCHIVED=false）
      if [[ "$is_skip" -eq 0 && "$SKIP_ARCHIVED" == "true" && -n "$ALLOWED_SLUGS" ]]; then
        if [[ " $ALLOWED_SLUGS " != *" $s "* ]]; then
          echo "  [skip-archived] ${s} — 归档层不投影"
          is_skip=1
        fi
      fi
      if [[ "$is_skip" -eq 1 ]]; then
        continue
      fi
      kept+=("$s")
      copy_skill "$s" "$dst"
    done
    # prune_extra 使用「最终要保留的 slugs」= 实际同步的 + 第三方保留
    local allowed=("${kept[@]}" "${SKIP_FROM_SYNC[@]}")
    prune_extra "$dst" "${allowed[@]}"
    echo "==> ${platform}: kept=${#kept[@]} of ${#skills[@]} (含 ${#SKIP_FROM_SYNC[@]} 第三方 skip)"
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
}

# ---- Shared Skills 同步（已废弃） ----
# Skills 已扁平化，所有 skill 都在同一层级，不再有 shared 子目录概念
sync_shared() {
  echo "==> [skip] sync_shared: Skills 已扁平化，不再使用 shared 子目录"
}

# ---- 主流程 ----
case "$TARGET" in
  shared)
    sync_shared
    ;;
  all)
    sync_from_manifest
    sync_shared
    ;;
  cursor|trae|mimocode)
    sync_from_manifest
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    exit 1
    ;;
esac

echo "Done."
