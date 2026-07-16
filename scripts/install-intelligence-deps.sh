#!/usr/bin/env bash
# install-intelligence-deps.sh
# Intelligence Layer 依赖检查脚本
# codebase-memory 由 Codex skill 提供，不需要 npm 全局安装。
# 用法: bash scripts/install-intelligence-deps.sh [--init-index]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INIT_INDEX=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --init-index) INIT_INDEX=true; shift ;;
    -h|--help)
      echo "用法: bash scripts/install-intelligence-deps.sh [--init-index]"
      echo ""
      echo "选项:"
      echo "  --init-index    输出 codebase-memory 索引初始化提示"
      exit 0
      ;;
    *) echo "未知选项: $1"; exit 1 ;;
  esac
done

echo "=============================================="
echo "  Intelligence Layer 依赖检查"
echo "=============================================="
echo ""

echo ">>> 检查 codebase-memory (知识图谱)..."
if [[ -f "$ROOT/core/intelligence/tactical/_config.yaml" ]]; then
  echo "[OK] tactical 配置 (codebase-memory + ripgrep + LSP): $ROOT/core/intelligence/tactical/_config.yaml"
else
  echo "[WARN] tactical 配置未找到，请检查 core/intelligence/tactical/_config.yaml"
fi
for sk in ripgrep-search lsp-query code-insight-stack; do
  if [[ -f "$ROOT/skills/$sk/SKILL.md" ]]; then
    echo "[OK] skill/$sk 已自包含在仓库内"
  else
    echo "[WARN] skill/$sk 缺失，请同步 skills/ 目录"
  fi
done

echo ">>> 检查 ripgrep (文本搜索)..."
if command -v rg &> /dev/null; then
  echo "[OK] ripgrep: $(rg --version | head -n 1)"
else
  echo "[WARN] ripgrep 未安装；将降级到 grep + rg 文本兜底（仅 ripgrep-search skill 不可用）"
  echo "       安装: https://github.com/BurntSushi/ripgrep#installation"
fi

echo ">>> 检查 LSP (语言服务)..."
found_lsp=0
for cmd in typescript-language-server pyright gopls rust-analyzer clangd jdtls omnisharp-roslyn; do
  if command -v "$cmd" &> /dev/null; then
    echo "[OK] LSP available: $cmd"
    found_lsp=1
    break
  fi
done
if [[ $found_lsp -eq 0 ]]; then
  echo "[WARN] 未检测到任何 language server；lsp-query skill 仍可调用（由 IDE 暴露 LSP）"
fi
echo ""

echo ">>> 检查 Understand-Anything..."
UA_PATH="$ROOT/reference_github/Understand-Anything"
if [[ -d "$UA_PATH" ]]; then
  echo "[INFO] Understand-Anything 源码已存在: $UA_PATH"
else
  echo "[WARN] Understand-Anything 源码未找到（可选）"
  echo "       如需使用，请按 mcp-config/Understand-Anything.json 配置。"
fi

if [[ "$INIT_INDEX" == "true" ]]; then
  echo ""
  echo ">>> codebase-memory 索引初始化提示"
  echo "[INFO] 请在 AI 会话中调用 codebase-memory 的 index_repository 工具。"
  echo "[INFO] 不要手动删除或操作其内部索引目录。"
fi

echo ""
echo "=============================================="
echo "[SUCCESS] Intelligence Layer 检查完成"
echo "=============================================="
echo ""
echo "下一步:"
echo "  - /code-insight-stack       # 战术层统一入口（codebase-memory + ripgrep + LSP）"
echo "  - /understand-project       # 战略层：理解项目"
echo "  - /analyze-architecture     # 战略层：分析架构"
echo "  - /query-symbol             # 战术层：定位代码（图）"
echo "  - /ripgrep-search           # 战术层：定位字符串/正则"
echo "  - /lsp-query                # 战术层：权威定义/引用/类型/诊断"
echo "  - /analyze-impact           # 战术层：评估影响"
echo ""