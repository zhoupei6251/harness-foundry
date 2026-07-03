#!/usr/bin/env bash
# Route: code
# 项目初始化脚本：将 harness-foundry 作为模板初始化其他项目
# 用于场景 B：作为模板初始化其他项目
#
# Usage:
#   bash scripts/init-project.sh /path/to/new-project           # 初始化项目
#   bash scripts/init-project.sh /path/to/new-project --dry-run # 预览
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR=""
DRY_RUN=0
ROUTE="code"

usage() {
  cat <<'EOF'
init-project.sh — Harness Foundry 项目初始化脚本

将 harness-foundry 作为模板，初始化其他项目。

Usage: init-project.sh <project-path> [OPTIONS]

参数:
  <project-path>                        目标项目目录（必须）

选项:
  --route <code|novel|news>            域标识 (默认: code)
  --dry-run                            预览模式，不实际写入
  --no-git                             不初始化 git 仓库
  -h, --help                           显示帮助

示例:
  bash scripts/init-project.sh ~/my-new-project
  bash scripts/init-project.sh /workspace/app --route novel
  bash scripts/init-project.sh ~/app --dry-run
EOF
}

# === 参数解析 ===
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_DIR="$1"
shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --route) ROUTE="${2:-code}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --no-git) NO_GIT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知选项: $1"; usage; exit 1 ;;
  esac
done

# === 辅助函数 ===
info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
ok() { echo "[OK] $1"; }

# 复制文件或目录
copy_file() {
  local src="$1" dst="$2" label="$3"
  if [[ ! -e "$src" ]]; then
    warn "${label}: 源不存在: $src"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] ${label}: ${src} -> ${dst}"
    return 0
  fi
  local dst_dir="$(dirname "$dst")"
  mkdir -p "$dst_dir"
  if [[ -d "$src" ]]; then
    rsync -a --exclude='.git' "${src}/" "${dst}/" 2>/dev/null || cp -a "${src}/." "${dst}/"
  else
    cp -a "$src" "$dst"
  fi
  ok "${label}: ${src} -> ${dst}"
}

# 创建目录
create_dir() {
  local dir="$1" label="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] ${label}: mkdir -p ${dir}"
    return 0
  fi
  mkdir -p "$dir"
  ok "${label}: mkdir -p ${dir}"
}

# === 主流程 ===
echo ""
echo "=============================================="
echo "  Harness Foundry 项目初始化"
echo "  目标: $TARGET_DIR"
echo "  域: $ROUTE"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "  模式: 预览 (dry-run)"
fi
echo "=============================================="
echo ""

# 检查目标目录
if [[ -d "$TARGET_DIR" ]] && [[ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
  if [[ "$DRY_RUN" -eq 0 ]]; then
    warn "目标目录非空: $TARGET_DIR"
    read -p "继续? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      info "取消初始化"
      exit 0
    fi
  else
    warn "目标目录非空: $TARGET_DIR"
  fi
fi

# 解析目标目录为绝对路径
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
info "目标目录: $TARGET_DIR"

# 创建目录结构
echo ""
echo "==> 创建目录结构"
dirs=(
  ".ai-runtime-artifacts"
  ".trae/rules"
  ".claude/rules"
)
for dir in "${dirs[@]}"; do
  create_dir "${TARGET_DIR}/${dir}" "Runtime"
done

# 根据域创建不同的运行时目录
case "$ROUTE" in
  novel)
    create_dir "${TARGET_DIR}/.harness-novel-runtime/{plans,chapters,memory}" "Novel Runtime"
    ;;
  news)
    create_dir "${TARGET_DIR}/.harness-news-runtime/{drafts,articles,memory}" "News Runtime"
    ;;
esac

# 生成 MEMORY.md
echo ""
echo "==> 生成 MEMORY.md"
mem_file="${TARGET_DIR}/MEMORY.md"
if [[ -f "$mem_file" ]] && [[ "$DRY_RUN" -eq 0 ]]; then
  warn "MEMORY.md 已存在，跳过生成"
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] 生成 MEMORY.md (Route: ${ROUTE})"
  else
    cat > "$mem_file" <<EOF
# 项目记忆 — Route: ${ROUTE}

## 项目信息
- 名称: $(basename "$TARGET_DIR")
- 创建日期: $(date +%Y-%m-%d)
- 技术栈:
- 语言:

## 关键决策
- 日期: $(date +%Y-%m-%d)

## 进行中
in_progress:
  - current_phase: init

## 阻塞项
blockers: []

## 测试状态
testing:
  framework: 待定
  last_run: 未执行

## 代码审查
review:
  status: 待配置

## 最后更新
last_updated: $(date +%Y-%m-%dT%H:%M:%S%z)
EOF
    ok "生成 MEMORY.md"
  fi
fi

# 生成 CLAUDE.md（项目级配置）
echo ""
echo "==> 生成 CLAUDE.md"
claude_file="${TARGET_DIR}/CLAUDE.md"
if [[ -f "$claude_file" ]] && [[ "$DRY_RUN" -eq 0 ]]; then
  warn "CLAUDE.md 已存在，跳过生成"
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] 生成 CLAUDE.md"
  else
    cat > "$claude_file" <<EOF
# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## 项目概述

- 名称: $(basename "$TARGET_DIR")
- 创建日期: $(date +%Y-%m-%d)
- 域: ${ROUTE}

## 项目记忆

项目状态和上下文见 [MEMORY.md](./MEMORY.md)。

## Harness Foundry

本项目使用 Harness Foundry 作为 AI 工作流编排框架。

### 快速开始

```bash
# 同步 skills 到本地投影层
bash harness-foundry/scripts/bootstrap-self.sh --target trae,claude
```

### 核心命令

| 命令 | 说明 |
|------|------|
| /brainstorming | 设计新功能 |
| /plan | 制定实施计划 |
| /test | TDD 模式 |
| /review | 代码审查 |
EOF
    ok "生成 CLAUDE.md"
  fi
fi

# 复制 harness-foundry 作为子模块（可选）
echo ""
echo "==> 提示：Harness Foundry 集成"
info "如需将 Harness Foundry 集成到此项目，可执行："
echo ""
echo "  # 方法 1: 作为 git submodule"
echo "  cd $TARGET_DIR"
echo "  git submodule add <harness-foundry-repo> harness-foundry"
echo ""
echo "  # 方法 2: 直接复制（不推荐用于生产）"
echo "  cp -r $KIT $TARGET_DIR/harness-foundry"
echo ""
echo "  # 方法 3: 引用外部 harness-foundry"
echo "  # 在 CLAUDE.md 中添加路径引用"
echo ""

# 初始化 git（可选）
if [[ -z "${NO_GIT:-}" ]] && [[ "$DRY_RUN" -eq 0 ]]; then
  if [[ ! -d "$TARGET_DIR/.git" ]]; then
    echo ""
    echo "==> 初始化 Git 仓库"
    read -p "是否初始化 git 仓库? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
      cd "$TARGET_DIR"
      git init
      ok "Git 仓库已初始化"
      echo ""
      info "建议创建初始提交:"
      echo "  git add ."
      echo "  git commit -m 'feat: initial project setup'"
    fi
  fi
fi

echo ""
echo "=============================================="
ok "项目初始化完成!"
echo "=============================================="
echo ""
echo "下一步:"
echo "  1. cd $TARGET_DIR"
echo "  2. 集成 Harness Foundry（如需要）"
echo "  3. 开始使用 /brainstorming 设计你的项目"
echo ""
