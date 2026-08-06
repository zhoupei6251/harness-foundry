#!/usr/bin/env bash
# Route: code|novel|news
# 技能同步：从 skills/ 投影到各 IDE（Trae、Claude Code）
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/.agents/skills/_manifest.yaml"
SRC="${ROOT}/skills"

# 投影目标目录
CLAUDE_DST="${ROOT}/.claude/skills"
TRAE_DST="${ROOT}/.trae/skills"
# codex/workbuddy 共用 Anthropic Agent Skills 开放标准目录（.agents/skills/）
CODEX_DST="${ROOT}/.agents/skills"
WORKBUDDY_DST="${ROOT}/.agents/skills"

# Intelligence Layer Skills 源目录
INTELLIGENCE_SRC="${ROOT}/core/intelligence"

TARGET="all"
DRY_RUN=0

# 第三方来源 skill 列表（cherry-pick 自上游，不参与 sync，避免被覆盖/裁剪）
# 2026-08-05: superpowers 副本已删除（插件运行时加载），列表留空
SKIP_FROM_SYNC=()

usage() {
  cat <<'EOF'
Usage: sync-skills.sh [--target claude|trae|codex|workbuddy|all] [--dry-run]

Syncs skills from:
  skills/          -> .claude/skills/, .trae/skills/
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
  # 用 Python 解析 _layer.yaml
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
    echo "Warn: manifest not found: $MANIFEST — 降级为按 _layer.yaml 层配置投影" >&2
    # 降级: 用 _layer.yaml 的 core+peripheral 构建目标列表（等效 manifest include_layers）
    build_target_list() {
      local platform="$1"  # 忽略（降级模式两平台同构）
      # 只投影仓库 skills/ 里实际存在的技能（插件技能由插件运行时加载，无需投影）
      python3 -c "
import yaml, os, sys
root = r'$ROOT'.replace('/d/', 'D:/', 1)
with open(root + '/skills/_layer.yaml') as f:
    d = yaml.safe_load(f)
skills_dir = root + '/skills'
for s in sorted(set(d.get('core', []) + d.get('peripheral', []))):
    if os.path.isdir(skills_dir + '/' + s):
        print(s)
"
    }
    sync_platform() {
      local platform="$1"
      local dst=""
      case "$platform" in
        claude) dst="$CLAUDE_DST" ;;
        trae) dst="$TRAE_DST" ;;
        codex|workbuddy) dst="$CODEX_DST" ;;
        *) echo "Unknown platform: $platform" >&2; return 1 ;;
      esac
      echo "==> Sync ${platform} -> ${dst}"
      mkdir -p "$dst"
      mapfile -t skills < <(build_target_list "$platform")
      local s kept=()
      for s in "${skills[@]}"; do
        local is_skip=0
        for skip in "${SKIP_FROM_SYNC[@]}"; do
          if [[ "$s" == "$skip" ]]; then
            echo "  [skip-from-sync] ${s} — 第三方来源，保留本地副本"
            is_skip=1
            break
          fi
        done
        if [[ "$is_skip" -eq 1 ]]; then continue; fi
        kept+=("$s")
        # copy_skill 内联（降级分支无法引用外层函数）
        s="${s%$'\r'}"  # 剥离 CRLF（Windows mapfile 行尾）
        if [[ -d "${SRC}/${s}" ]]; then
          if [[ "$DRY_RUN" -eq 1 ]]; then
            echo "  [dry] ${s} -> ${dst}/${s}"
          else
            mkdir -p "${dst}"
            rm -rf "${dst}/${s}"
            cp -a "${SRC}/${s}" "${dst}/${s}"
            echo "  [ok] ${s}"
          fi
        else
          echo "  [skip] ${s} — not found in skills/"
        fi
      done
      local allowed=("${kept[@]}" "${SKIP_FROM_SYNC[@]}")
      # prune_extra 定义在下方主分支，此处降级分支需自带
      if [[ "$DRY_RUN" -eq 0 && -d "$dst" ]]; then
        for d in "${dst}"/*; do
          [[ -d "$d" ]] || continue
          slug="$(basename "$d")"
          [[ "$slug" == "README.md" || "$slug" == ".DS_Store" ]] && continue
          local found=0
          for a in "${allowed[@]}"; do
            [[ "$slug" == "$a" ]] && found=1 && break
          done
          if [[ "$found" -eq 0 ]]; then
            echo "  [prune] ${dst}/${slug}"
            rm -rf "$d"
          fi
        done
      fi
      echo "==> ${platform}: kept=${#kept[@]} of ${#skills[@]} (含 ${#SKIP_FROM_SYNC[@]} 第三方 skip)"
    }
    case "$TARGET" in
      claude) sync_platform claude ;;
      trae) sync_platform trae ;;
      codex|workbuddy) sync_platform "$TARGET" ;;
      all)
        sync_platform claude
        sync_platform trae
        sync_platform codex
        sync_platform workbuddy
        ;;
      *) echo "Unknown target: $TARGET" >&2; exit 1 ;;
    esac
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
    else
      echo "  [skip] ${slug} — not found in skills/"
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
      claude) dst="$CLAUDE_DST" ;;
      trae) dst="$TRAE_DST" ;;
      codex|workbuddy) dst="$CODEX_DST" ;;
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
      # Layer 过滤：archived skill 不投影到 IDE
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
    # prune_extra 使用「最终要保留的 slugs」
    local allowed=("${kept[@]}" "${SKIP_FROM_SYNC[@]}")
    prune_extra "$dst" "${allowed[@]}"
    echo "==> ${platform}: kept=${#kept[@]} of ${#skills[@]} (含 ${#SKIP_FROM_SYNC[@]} 第三方 skip)"
  }

  case "$TARGET" in
    claude) sync_platform claude ;;
    trae) sync_platform trae ;;
    codex|workbuddy) sync_platform "$TARGET" ;;
    all)
      sync_platform claude
      sync_platform trae
      sync_platform codex
      sync_platform workbuddy
      ;;
    *)
      echo "Unknown target: $TARGET" >&2
      exit 1
      ;;
  esac
}

# ---- Intelligence Layer Skills 同步 ----
sync_intelligence() {
  if [[ ! -d "$INTELLIGENCE_SRC" ]]; then
    echo "Warn: Intelligence layer not found: $INTELLIGENCE_SRC"
    return 0
  fi

  echo "==> Syncing Intelligence Layer Skills..."

  local strategic_src="${INTELLIGENCE_SRC}/strategic"
  local tactical_src="${INTELLIGENCE_SRC}/tactical"

  for platform in claude trae; do
    local strategic_dst tactical_dst
    case "$platform" in
      claude)
        strategic_dst="${CLAUDE_DST}/../rules/intelligence/strategic"
        tactical_dst="${CLAUDE_DST}/../rules/intelligence/tactical"
        ;;
      trae)
        strategic_dst="${TRAE_DST}/../intelligence/strategic"
        tactical_dst="${TRAE_DST}/../intelligence/tactical"
        ;;
    esac

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "  [dry] ${platform}: strategic -> ${strategic_dst}"
      echo "  [dry] ${platform}: tactical -> ${tactical_dst}"
      continue
    fi

    # 同步 Strategic 层
    if [[ -d "$strategic_src" ]]; then
      mkdir -p "$(dirname "$strategic_dst")"
      rm -rf "$strategic_dst"
      cp -a "$strategic_src" "$strategic_dst"
      echo "  [ok] ${platform}: strategic layer (codebase-memory-mcp)"
    fi

    # 同步 Tactical 层
    if [[ -d "$tactical_src" ]]; then
      mkdir -p "$(dirname "$tactical_dst")"
      rm -rf "$tactical_dst"
      cp -a "$tactical_src" "$tactical_dst"
      echo "  [ok] ${platform}: tactical layer (codebase-memory + ripgrep + LSP)"
    fi
  done
}

# ---- 主流程 ----
case "$TARGET" in
  intelligence)
    sync_intelligence
    ;;
  all)
    sync_from_manifest
    sync_intelligence
    ;;
  claude|trae|codex|workbuddy)
    sync_from_manifest
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    exit 1
    ;;
esac

echo "Done."
