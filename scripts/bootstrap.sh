#!/usr/bin/env bash
# Route: code|novel|news
# Harness Foundry 一键初始化：检查环境，投影 adapters，创建运行时目录，生成 MEMORY.md
# 仅支持 Trae 和 Claude Code
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIT="${ROOT}"
TARGET="all"
ROUTE="code"
FORCE=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--target trae|claude|workbuddy|all] [--route code|novel|news] [--force] [--dry-run]

Projects harness-foundry adapters to workspace:
  adapters/trae/.trae/       -> .trae/
  adapters/claude/.claude/   -> .claude/
  adapters/workbuddy/        -> .codebuddy/
  adapters/agents/AGENTS.md  -> AGENTS.md

--route:   域标识 (code|novel|news)，影响 MEMORY.md 模板与运行时目录
--dry-run: 仅打印计划，不实际写入
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-all}"; shift 2 ;;
    --route)  ROUTE="${2:-code}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 1 ;;
  esac
done

# 环境检查
check_env() {
  local missing=0
  for cmd in bash mkdir cp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "[error] 缺少必要命令: $cmd" >&2
      missing=1
    fi
  done
  if [[ "$missing" -eq 1 ]]; then
    exit 1
  fi
  echo "[ok] 环境检查通过"
}

copy_tree() {
  local src="$1" dst="$2" label="$3"
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
    local item
    for item in "${src}"/* "${src}"/.[!.]*; do
      [[ -e "$item" ]] || continue
      local base; base="$(basename "$item")"
      rm -rf "${dst}/${base}"
      cp -a "$item" "${dst}/"
    done
  fi
  echo "[ok] ${label}: ${src} -> ${dst}"
}

# ---- Adapter 投影 ----

# Trae 投影
bootstrap_trae() {
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
  bash "${KIT}/scripts/sync-skills.sh" --target trae
}

# Claude Code 投影
bootstrap_claude() {
  local src="${KIT}/adapters/claude/.claude"
  local dst="${ROOT}/.claude"
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    copy_tree "$src" "$dst" "Claude Code"
    # 同步 skills
    bash "${KIT}/scripts/sync-skills.sh" --target claude
  fi
}

bootstrap_agents() {
  cp "${KIT}/adapters/agents/AGENTS.md" "${ROOT}/AGENTS.md"
  echo "[ok] AGENTS.md"
}

# WorkBuddy 投影（腾讯，= CodeBuddy 双品牌；配置面 .codebuddy/）
bootstrap_workbuddy() {
  local src="${KIT}/adapters/workbuddy"
  local dst="${ROOT}/.codebuddy"
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    # agents/ 子目录（若有）投影
    if [[ -d "${src}/.codebuddy/agents" ]]; then
      copy_tree "${src}/.codebuddy/agents" "${dst}/agents" "WorkBuddy agents"
    fi
    # 规则投影（若有）
    if [[ -d "${src}/.codebuddy/rules" ]]; then
      copy_tree "${src}/.codebuddy/rules" "${dst}/rules" "WorkBuddy rules"
    fi
    echo "[hint] WorkBuddy 技能投影复用 .agents/skills/（SKILL.md 开放标准，与 Claude 共用真相源）"
  else
    echo "Warn: missing WorkBuddy source: $src" >&2
  fi
}

# ---- MCP 配置同步 (Intelligence Layer) ----
bootstrap_mcp() {
  local src="${KIT}/mcp-config"
  local dst="${ROOT}/.mcp-config"
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    copy_tree "$src" "$dst" "MCP Config (Intelligence Layer)"
    echo "[hint] MCP configs: codebase-memory-mcp (npx codebase-memory-mcp)"
  fi
}

# ---- 运行时目录（按域） ----
create_runtime_dirs() {
  case "$ROUTE" in
    code)
      mkdir -p "${ROOT}/.ai-runtime-artifacts"/{specs,plans,decisions,execution-logs/tracking,verifications,reviews,research}
      echo "[ok] 代码域运行时目录: .ai-runtime-artifacts/"
      ;;
    novel)
      mkdir -p "${ROOT}/.harness-novel-runtime"/{plans,execution-logs,tracking,memory}
      echo "[ok] 小说域运行时目录: .harness-novel-runtime/"
      ;;
    news)
      mkdir -p "${ROOT}/.harness-news-runtime"/{plans,execution-logs,tracking,memory,articles}
      echo "[ok] 新闻域运行时目录: .harness-news-runtime/"
      ;;
  esac
}

# ---- 生成 MEMORY.md ----
generate_memory() {
  local mem_file="${ROOT}/MEMORY.md"
  if [[ -f "$mem_file" ]] && [[ "$FORCE" -eq 0 ]]; then
    echo "[keep] MEMORY.md 已存在 (use --force to overwrite)"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry] 会创建 MEMORY.md"
    return 0
  fi

  case "$ROUTE" in
    code)
      cat > "$mem_file" <<EOF
# 项目记忆 — Route: code

## 项目信息
- 名称:
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
      ;;
    novel)
      cat > "$mem_file" <<EOF
# 项目记忆 — Route: novel

## 项目信息
- 书名:
- 题材:
- 核心卖点:
- 目标字数:

## 人物状态追踪
characters: []

## 伏笔追踪
foreshadowing: []

## 章节索引+一句话摘要
chapter_index: []

## 进行中
in_progress:
  - current_phase: init

## 阻塞项
blockers: []

## 最后更新
last_updated: $(date +%Y-%m-%dT%H:%M:%S%z)
EOF
      ;;
    news)
      cat > "$mem_file" <<EOF
# 项目记忆 — Route: news

## 项目信息
- 集名:
- 领域:
- 更新频率:

## 进行中
in_progress:
  - current_phase: init

## 阻塞项
blockers: []

## 最后更新
last_updated: $(date +%Y-%m-%dT%H:%M:%S%z)
EOF
      ;;
  esac
  echo "[ok] MEMORY.md 已创建 (Route: ${ROUTE})"
}

# ---- 主流程 ----
check_env

case "$TARGET" in
  trae) bootstrap_trae ;;
  claude) bootstrap_claude ;;
  workbuddy) bootstrap_workbuddy ;;
  all)
    bootstrap_agents
    bootstrap_trae
    bootstrap_claude
    bootstrap_workbuddy
    bootstrap_mcp
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    exit 1
    ;;
esac

create_runtime_dirs
generate_memory

echo ""
echo "Harness Foundry bootstrap complete (target=${TARGET}, route=${ROUTE})."
echo "Quick start: 见 core/intent-routing.md 路由表"
echo "Docs: harness-foundry/README.md"
