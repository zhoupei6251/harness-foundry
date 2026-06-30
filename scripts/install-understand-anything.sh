#!/usr/bin/env bash
# Route: code
# Understand-Anything 多平台集成脚本
# 集成到 Harness Foundry 支持的所有平台：Claude Code, Cursor, Trae, Codex
#
# Usage:
#   bash scripts/install-understand-anything.sh              # 交互式安装
#   bash scripts/install-understand-anything.sh --all       # 安装所有平台
#   bash scripts/install-understand-anything.sh --claude      # 仅 Claude Code
#   bash scripts/install-understand-anything.sh --trae        # 仅 Trae
#   bash scripts/install-understand-anything.sh --cursor      # 仅 Cursor
#   bash scripts/install-understand-anything.sh --codex       # 仅 Codex
#   bash scripts/install-understand-anything.sh --uninstall    # 卸载
#   bash scripts/install-understand-anything.sh --dry-run     # 预览
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Understand-Anything 源码位置
UA_REPO_DIR="${UA_REPO_DIR:-$HOME/.understand-anything/repo}"
UA_PLUGIN_DIR="${UA_REPO_DIR}/understand-anything-plugin"

# 检测本地克隆位置
if [[ -d "$ROOT/reference_github/Understand-Anything" ]]; then
  UA_LOCAL_CLONE="$ROOT/reference_github/Understand-Anything"
  UA_PLUGIN_DIR="$UA_LOCAL_CLONE/understand-anything-plugin"
fi

# Skills 源目录
UA_SKILLS_SRC="${UA_PLUGIN_DIR}/skills"

# 各平台 Skills 目标目录
CLAUDE_SKILLS="${ROOT}/.claude/skills"
CURSOR_SKILLS="${ROOT}/.cursor/skills"
TRAE_SKILLS="${ROOT}/.trae/skills"
CODEX_SKILLS="${HOME}/.agents/skills"

# 全局安装目录（Claude Code, Trae, Codex 共用）
GLOBAL_CLAUDE_SKILLS="${HOME}/.claude/skills"
GLOBAL_TRAE_SKILLS="${HOME}/.trae/skills"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

# Dry run 模式
DRY_RUN=0
UNINSTALL=0
TARGETS=()

usage() {
  cat <<'EOF'
Understand-Anything 多平台集成脚本

Usage: install-understand-anything.sh [OPTIONS]

选项:
  --all         安装到所有支持的平台
  --claude      仅 Claude Code
  --cursor      仅 Cursor
  --trae        仅 Trae
  --codex       仅 Codex
  --dry-run     预览模式，不实际执行
  --uninstall   卸载所有平台的集成
  -h, --help    显示帮助

示例:
  bash scripts/install-understand-anything.sh --all
  bash scripts/install-understand-anything.sh --trae --cursor
EOF
}

# === 参数解析 ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) TARGETS=(claude cursor trae codex); shift ;;
    --claude) TARGETS+=(claude); shift ;;
    --cursor) TARGETS+=(cursor); shift ;;
    --trae) TARGETS+=(trae); shift ;;
    --codex) TARGETS+=(codex); shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知选项: $1"; usage; exit 1 ;;
  esac
done

# 默认安装所有平台
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(claude cursor trae codex)
fi

# === 检查 Understand-Anything 是否可用 ===
check_ua() {
  if [[ ! -d "$UA_SKILLS_SRC" ]]; then
    warn "Understand-Anything skills 未找到: $UA_SKILLS_SRC"
    echo ""
    echo "请先安装 Understand-Anything:"
    echo "  git clone https://github.com/Egonex-AI/Understand-Anything.git ~/.understand-anything/repo"
    echo "  cd ~/.understand-anything/repo && pnpm install"
    echo ""
    echo "或者设置 UA_REPO_DIR 环境变量指向已克隆的目录"
    exit 1
  fi

  info "使用 Understand-Anything: $UA_PLUGIN_DIR"
  echo "  可用 Skills: $(ls -1 "$UA_SKILLS_SRC" | tr '\n' ' ') "
  echo ""
}

# === 列出可用 Skills ===
list_skills() {
  if [[ -d "$UA_SKILLS_SRC" ]]; then
    ls -1 "$UA_SKILLS_SRC" | grep -v '^\.'
  fi
}

# === 复制 Skills 到目标目录 ===
copy_skills() {
  local src="$1"
  local dst="$2"
  local platform="$3"

  if [[ ! -d "$src" ]]; then
    error "源目录不存在: $src"
    return 1
  fi

  mkdir -p "$dst"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry] ${platform}: 复制 skills -> $dst"
    for skill in $(list_skills); do
      echo "       - $skill"
    done
    return 0
  fi

  local count=0
  for skill in $(list_skills); do
    local skill_src="$src/$skill"
    local skill_dst="$dst/$skill"

    if [[ -d "$skill_src" ]]; then
      rm -rf "$skill_dst"
      cp -a "$skill_src" "$skill_dst"
      echo "  ✓ $skill -> $dst/$skill"
      count=$((count + 1))
    fi
  done

  success "已安装 $count 个 Skills 到 $platform"
}

# === 创建符号链接 ===
link_skills() {
  local src="$1"
  local dst="$2"
  local platform="$3"

  if [[ ! -d "$src" ]]; then
    error "源目录不存在: $src"
    return 1
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry] ${platform}: 创建符号链接 -> $dst"
    for skill in $(list_skills); do
      echo "       - $skill"
    done
    return 0
  fi

  mkdir -p "$dst"

  local count=0
  for skill in $(list_skills); do
    local skill_src="$src/$skill"
    local skill_link="$dst/$skill"

    if [[ ! -d "$skill_src" ]]; then
      continue
    fi

    # Windows 使用 junction，Unix 使用 symlink
    if [[ "$(uname)" == *"CYGWIN"* ]] || [[ "$(uname)" == *"MINGW"* ]] || [[ "$(uname)" == *"MSYS"* ]]; then
      # Windows
      if [[ -e "$skill_link" ]]; then
        rm -rf "$skill_link"
      fi
      cmd //c "mklink /J \"$skill_link\" \"$skill_src\"" 2>/dev/null || \
        ln -s "$skill_src" "$skill_link"
    else
      # Unix
      rm -rf "$skill_link"
      ln -sfn "$skill_src" "$skill_link"
    fi

    echo "  ✓ $skill -> $dst/$skill"
    count=$((count + 1))
  done

  success "已创建 $count 个符号链接到 $platform"
}

# === Claude Code 安装 ===
install_claude() {
  echo ""
  echo -e "${BLUE}==> Claude Code 安装${NC}"
  echo "================================"

  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -d "$CLAUDE_SKILLS" ]]; then
      for skill in $(list_skills); do
        rm -rf "$CLAUDE_SKILLS/$skill" 2>/dev/null || true
      done
      success "已卸载 Claude Code Skills"
    else
      info "Claude Code Skills 不存在，跳过"
    fi
    return 0
  fi

  # 方法1: Marketplace 安装 (推荐)
  echo ""
  echo "Claude Code 推荐使用 Marketplace 安装:"
  echo "  1. 在 Claude Code 中运行:"
  echo "     /plugin marketplace add Egonex-AI/Understand-Anything"
  echo "     /plugin install understand-anything"
  echo ""
  echo "  2. 或者手动复制 Skills 到项目目录:"

  # 复制到项目 .claude/skills
  if [[ -d "$ROOT/.claude" ]] || [[ "$DRY_RUN" -eq 1 ]]; then
    copy_skills "$UA_SKILLS_SRC" "$CLAUDE_SKILLS" "Claude Code (项目)"
  fi

  # 复制到全局 ~/.claude/skills
  if [[ -d "$GLOBAL_CLAUDE_SKILLS" ]] || [[ "$DRY_RUN" -eq 1 ]]; then
    copy_skills "$UA_SKILLS_SRC" "$GLOBAL_CLAUDE_SKILLS" "Claude Code (全局)"
  fi
}

# === Cursor 安装 ===
install_cursor() {
  echo ""
  echo -e "${BLUE}==> Cursor 安装${NC}"
  echo "================================"

  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -d "$CURSOR_SKILLS" ]]; then
      for skill in $(list_skills); do
        rm -rf "$CURSOR_SKILLS/$skill" 2>/dev/null || true
      done
      success "已卸载 Cursor Skills"
    else
      info "Cursor Skills 不存在，跳过"
    fi
    return 0
  fi

  copy_skills "$UA_SKILLS_SRC" "$CURSOR_SKILLS" "Cursor"
}

# === Trae 安装 ===
install_trae() {
  echo ""
  echo -e "${BLUE}==> Trae 安装${NC}"
  echo "================================"

  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -d "$TRAE_SKILLS" ]]; then
      for skill in $(list_skills); do
        rm -rf "$TRAE_SKILLS/$skill" 2>/dev/null || true
      done
      success "已卸载 Trae Skills"
    else
      info "Trae Skills 不存在，跳过"
    fi
    return 0
  fi

  # Trae 支持符号链接，使用它保持与上游同步
  link_skills "$UA_SKILLS_SRC" "$TRAE_SKILLS" "Trae"

  # 同时复制到全局目录
  if [[ -d "$GLOBAL_TRAE_SKILLS" ]] || [[ "$DRY_RUN" -eq 1 ]]; then
    link_skills "$UA_SKILLS_SRC" "$GLOBAL_TRAE_SKILLS" "Trae (全局)"
  fi
}

# === Codex 安装 ===
install_codex() {
  echo ""
  echo -e "${BLUE}==> Codex 安装${NC}"
  echo "================================"

  if [[ "$UNINSTALL" -eq 1 ]]; then
    if [[ -d "$CODEX_SKILLS" ]]; then
      for skill in $(list_skills); do
        rm -rf "$CODEX_SKILLS/$skill" 2>/dev/null || true
      done
      success "已卸载 Codex Skills"
    else
      info "Codex Skills 不存在，跳过"
    fi
    return 0
  fi

  # Codex 使用 ~/.agents/skills 作为标准位置
  link_skills "$UA_SKILLS_SRC" "$CODEX_SKILLS" "Codex"
}

# === 主流程 ===
main() {
  echo ""
  echo "=============================================="
  echo "  Understand-Anything 多平台集成"
  echo "=============================================="
  echo ""

  if [[ "$UNINSTALL" -eq 1 ]]; then
    echo "模式: 卸载"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    echo "模式: 预览 (dry-run)"
  else
    echo "模式: 安装"
  fi
  echo ""

  check_ua

  for target in "${TARGETS[@]}"; do
    case "$target" in
      claude) install_claude ;;
      cursor) install_cursor ;;
      trae) install_trae ;;
      codex) install_codex ;;
      *)
        warn "未知平台: $target"
        ;;
    esac
  done

  echo ""
  echo "=============================================="
  if [[ "$UNINSTALL" -eq 1 ]]; then
    success "卸载完成!"
  else
    success "安装完成!"
  fi
  echo "=============================================="
  echo ""
  echo "下一步:"
  echo ""
  echo "  Claude Code: 重启后使用 /understand 开始分析"
  echo "  Cursor: 重启后使用 /understand 开始分析"
  echo "  Trae: 重启后使用 /understand 开始分析"
  echo "  Codex: 重启后使用 /understand 开始分析"
  echo ""
  echo "  文档: $UA_PLUGIN_DIR/README.md"
  echo ""
}

main "$@"
