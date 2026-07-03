#!/usr/bin/env bash
# Route: code
# 自举脚本：将 harness-foundry 的 skills/agents 同步到本地投影层
# 用于开发 harness-foundry 自身（场景 A：自举开发）
#
# Usage:
#   bash scripts/bootstrap-self.sh --target trae,claude  # 同步到两个平台
#   bash scripts/bootstrap-self.sh --target trae           # 仅 Trae
#   bash scripts/bootstrap-self.sh --target claude        # 仅 Claude Code
#   bash scripts/bootstrap-self.sh --dry-run             # 预览
#   bash scripts/bootstrap-self.sh --force               # 强制覆盖现有文件
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KIT="$ROOT"

TARGETS=()
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
bootstrap-self.sh — Harness Foundry 自举脚本

将 harness-foundry 的 skills/agents 同步到本地投影层，用于开发 harness-foundry 自身。

Usage: bootstrap-self.sh [OPTIONS]

选项:
  --target <platform>[,<platform>]   目标平台 (trae, claude)，逗号分隔
  --dry-run                         预览模式，不实际写入
  --force                           强制覆盖现有文件
  -h, --help                        显示帮助

示例:
  bash scripts/bootstrap-self.sh --target trae,claude  # 同步到两个平台
  bash scripts/bootstrap-self.sh --target trae          # 仅 Trae
  bash scripts/bootstrap-self.sh --dry-run             # 预览
EOF
}

# === 参数解析 ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      IFS=',' read -ra TARGETS <<< "${2:-}"
      shift 2
      ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知选项: $1"; usage; exit 1 ;;
  esac
done

# 默认同步所有平台
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(trae claude)
fi

# === 辅助函数 ===
info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
ok() { echo "[OK] $1"; }

# 复制目录或文件
copy_tree() {
  local src="$1" dst="$2" label="$3"
  if [[ ! -e "$src" ]]; then
    warn "${label}: 源不存在: $src"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] ${label}: ${src} -> ${dst}"
    return 0
  fi
  mkdir -p "$dst"
  if [[ -d "$src" ]]; then
    rsync -a --delete "${src}/" "${dst}/" 2>/dev/null || cp -a "${src}/." "${dst}/"
  else
    cp -a "$src" "$dst"
  fi
  ok "${label}: ${src} -> ${dst}"
}

# 同步 skills
sync_skills() {
  local platform="$1"
  local dst=""
  case "$platform" in
    trae) dst="${ROOT}/.trae/skills" ;;
    claude) dst="${ROOT}/.claude/skills" ;;
    *) echo "Unknown platform: $platform"; return 1 ;;
  esac

  echo ""
  echo "==> 同步 Skills 到 ${platform}"
  echo "    目标: $dst"

  # 获取要同步的 skills 列表（从 manifest 或全部）
  local manifest="${KIT}/.agents/skills/_manifest.yaml"
  local src="${KIT}/skills"

  if [[ -f "$manifest" ]]; then
    # 从 manifest 读取要同步的 skills
    local skill
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ -d "${src}/${skill}" ]]; then
        copy_tree "${src}/${skill}" "${dst}/${skill}" "Skill: ${skill}"
      fi
    done < <(awk '
      $0 ~ "^  " layer ":" { in_layer=1; next }
      in_layer && $0 ~ "^  [a-z_]+:" { in_layer=0 }
      in_layer && $0 ~ "^    - " {
        gsub(/^    - /,"")
        print
      }
    ' "$manifest" 2>/dev/null)
  else
    # 同步所有 skills
    if [[ -d "$src" ]]; then
      for skill_dir in "$src"/*; do
        [[ -d "$skill_dir" ]] || continue
        local skill="$(basename "$skill_dir")"
        [[ "$skill" == "_"* ]] && continue  # 跳过隐藏目录
        copy_tree "$skill_dir" "${dst}/${skill}" "Skill: ${skill}"
      done
    fi
  fi
}

# 同步 agents
sync_agents() {
  local platform="$1"
  local dst=""
  case "$platform" in
    trae) dst="${ROOT}/.trae/agents" ;;
    claude) dst="${ROOT}/.claude/agents" ;;
    *) echo "Unknown platform: $platform"; return 1 ;;
  esac

  echo ""
  echo "==> 同步 Agents 到 ${platform}"
  echo "    目标: $dst"

  local src="${KIT}/agents"
  if [[ -d "$src" ]]; then
    for agent_file in "$src"/*.md; do
      [[ -f "$agent_file" ]] || continue
      local agent="$(basename "$agent_file")"
      copy_tree "$agent_file" "${dst}/${agent}" "Agent: ${agent}"
    done
  fi
}

# 同步核心规则
sync_rules() {
  local platform="$1"
  local dst=""
  case "$platform" in
    trae) dst="${ROOT}/.trae/rules" ;;
    claude) dst="${ROOT}/.claude/rules" ;;
    *) echo "Unknown platform: $platform"; return 1 ;;
  esac

  echo ""
  echo "==> 同步核心规则到 ${platform}"
  echo "    目标: $dst"

  # 核心规则文件
  local rules=(
    "core/intent-routing.md"
    "core/NEVER.md"
    "core/principles.md"
  )

  for rule in "${rules[@]}"; do
    if [[ -f "${KIT}/${rule}" ]]; then
      local filename="$(basename "$rule")"
      copy_tree "${KIT}/${rule}" "${dst}/${filename}" "Rule: ${filename}"
    fi
  done

  # 同步 adapters 中已有的规则
  local adapter_rules=""
  case "$platform" in
    trae) adapter_rules="${KIT}/adapters/trae/.trae/rules" ;;
    claude) adapter_rules="${KIT}/adapters/claude/.claude/rules" ;;
  esac

  if [[ -d "$adapter_rules" ]]; then
    for rule_file in "$adapter_rules"/*.md "$adapter_rules"/*.mdc; do
      [[ -f "$rule_file" ]] || continue
      local filename="$(basename "$rule_file")"
      copy_tree "$rule_file" "${dst}/${filename}" "Adapter Rule: ${filename}"
    done
  fi
}

# 同步 domain-config
sync_domain_config() {
  local platform="$1"
  local dst=""
  case "$platform" in
    trae) dst="${ROOT}/.trae" ;;
    claude) dst="${ROOT}/.claude" ;;
  esac

  echo ""
  echo "==> 同步域配置到 ${platform}"

  local config="${KIT}/core/orchestration/domain-config.yaml"
  if [[ -f "$config" ]]; then
    copy_tree "$config" "${dst}/domain-config.yaml" "Domain Config"
  fi
}

# 确保投影层被 .gitignore 包含
ensure_gitignore() {
  local gitignore="${ROOT}/.gitignore"
  local entries=(
    ".trae/skills/"
    ".claude/skills/"
  )

  for entry in "${entries[@]}"; do
    if [[ -f "$gitignore" ]] && grep -q "^${entry}$" "$gitignore" 2>/dev/null; then
      continue
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[dry] 追加到 .gitignore: ${entry}"
    else
      echo "$entry" >> "$gitignore"
      ok "追加到 .gitignore: ${entry}"
    fi
  done
}

# === 主流程 ===
echo ""
echo "=============================================="
echo "  Harness Foundry 自举脚本"
echo "  目标: ${TARGETS[*]}"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  模式: 预览 (dry-run)"
fi
echo "=============================================="
echo ""

info "Harness Foundry 根目录: $KIT"
info "本地投影目录: $ROOT"
echo ""

# 同步每个目标平台
for platform in "${TARGETS[@]}"; do
  echo ""
  echo "=============================================="
  echo "  平台: ${platform}"
  echo "=============================================="

  sync_rules "$platform"
  sync_agents "$platform"
  sync_skills "$platform"
  sync_domain_config "$platform"
done

# 确保 .gitignore 包含投影层
echo ""
echo "==> 检查 .gitignore"
ensure_gitignore

echo ""
echo "=============================================="
ok "自举完成!"
echo "=============================================="
echo ""
echo "下一步:"
echo "  1. 重启 Claude Code / Trae 以加载新的 skills/agents"
echo "  2. 在新会话中使用 /brainstorming、/plan 等 skills"
echo "  3. 可以使用 agents（coder、reviewer 等）并行开发"
echo ""
echo "提示: 如需重新同步，运行: bash scripts/bootstrap-self.sh --force"
echo ""
