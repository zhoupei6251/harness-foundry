#!/usr/bin/env bash
# install-intelligence-deps.sh
# Intelligence Layer 一键安装脚本
# 用法: bash scripts/install-intelligence-deps.sh [--init-index]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INIT_INDEX=false

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --init-index) INIT_INDEX=true; shift ;;
    -h|--help)
      echo "用法: bash scripts/install-intelligence-deps.sh [--init-index]"
      echo ""
      echo "选项:"
      echo "  --init-index    初始化项目索引（需要进入目标项目目录）"
      exit 0
      ;;
    *) echo "未知选项: $1"; exit 1 ;;
  esac
done

echo "=============================================="
echo "  Intelligence Layer 依赖安装"
echo "=============================================="
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# === 1. 检查 Node.js ===
echo ">>> 检查 Node.js..."
NODE_VERSION=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1) || NODE_VERSION=0

if [[ "$NODE_VERSION" -lt 20 ]]; then
  error "Node.js 版本过低: $(node -v)"
  echo "   CodeGraph 需要 Node.js >= 20"
  echo ""
  echo "   请升级 Node.js:"
  echo "   - macOS: brew install node@20"
  echo "   - Linux: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
  echo "   - Windows: https://nodejs.org/"
  exit 1
fi

info "Node.js 版本检查通过: $(node -v)"
echo ""

# === 2. 安装 CodeGraph ===
echo ">>> 安装 CodeGraph..."

if command -v codegraph &> /dev/null; then
  CODEGRAPH_VERSION=$(codegraph --version 2>/dev/null || echo "unknown")
  info "CodeGraph 已安装: $CODEGRAPH_VERSION"
else
  info "正在安装 CodeGraph..."

  if command -v npm &> /dev/null; then
    npm install -g @colbymchenry/codegraph
  elif command -v pnpm &> /dev/null; then
    pnpm add -g @colbymchenry/codegraph
  else
    error "未找到 npm 或 pnpm"
    exit 1
  fi

  if command -v codegraph &> /dev/null; then
    success "CodeGraph 安装成功: $(codegraph --version)"
  else
    error "CodeGraph 安装失败"
    exit 1
  fi
fi
echo ""

# === 3. 检查 Understand-Anything ===
echo ">>> 检查 Understand-Anything..."

UA_PATH="$ROOT/reference_github/Understand-Anything"
if [[ -d "$UA_PATH" ]]; then
  info "Understand-Anything 源码已存在: $UA_PATH"
else
  warn "Understand-Anything 源码未找到"
  echo ""
  echo "   Understand-Anything 是可选的智能代码理解工具"
  echo "   如需使用，请手动安装:"
  echo ""
  echo "   # 克隆源码"
  echo "   git clone https://github.com/Understand-Anything/understand-anything.git"
  echo "   cd understand-anything"
  echo ""
  echo "   # 安装依赖"
  echo "   pnpm install"
  echo ""
  echo "   # 构建"
  echo "   pnpm --filter @understand-anything/core build"
  echo "   pnpm --filter @understand-anything/skill build"
  echo ""
  echo "   详见: https://github.com/Understand-Anything/understand-anything"
fi
echo ""

# === 4. 初始化项目索引（可选）===
if [[ "$INIT_INDEX" == "true" ]]; then
  echo ">>> 初始化项目索引..."
  cd "$ROOT"

  if [[ -d ".git" ]]; then
    info "检测到 Git 项目: $ROOT"

    # 检查是否已有 .codegraph
    if [[ -d ".codegraph" ]]; then
      warn ".codegraph 目录已存在，将重新初始化"
      rm -rf .codegraph
    fi

    info "初始化 CodeGraph..."
    codegraph init

    info "建立代码索引..."
    codegraph index

    success "项目索引初始化完成"
    echo ""
    echo "   索引数据存储在: .codegraph/"
    echo "   如需更新索引: codegraph sync"
  else
    warn "当前目录不是 Git 项目，跳过索引初始化"
  fi
fi

# === 完成 ===
echo ""
echo "=============================================="
success "Intelligence Layer 安装完成!"
echo "=============================================="
echo ""
echo "下一步:"
echo ""
echo "  1. 在 Harness Foundry 中使用 Skills:"
echo "     - /understand-project   # 理解项目"
echo "     - /analyze-architecture # 分析架构"
echo "     - /query-symbol         # 定位代码"
echo "     - /analyze-impact       # 评估影响"
echo ""
echo "  2. 如需初始化项目索引:"
echo "     cd your-project"
echo "     codegraph init"
echo "     codegraph index"
echo ""
echo "  3. 查看文档:"
echo "     cat docs/intelligence-layer-user-guide.md"
echo ""