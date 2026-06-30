#!/bin/bash
# install-codegraph.sh
# CodeGraph 安装脚本

set -e

echo "=== CodeGraph 安装脚本 ==="

# 检查 Node.js 版本
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
REQUIRED_VERSION=20

if [ "$NODE_VERSION" -lt "$REQUIRED_VERSION" ]; then
    echo "❌ Node.js 版本过低: v$(node -v)"
    echo "   CodeGraph 需要 Node.js >= 20"
    echo "   请升级 Node.js 后重试"
    exit 1
fi

echo "✓ Node.js 版本检查通过: v$(node -v)"

# 安装 CodeGraph
echo ""
echo "正在安装 CodeGraph..."

if command -v npm &> /dev/null; then
    npm install -g @colbymchenry/codegraph
elif command -v pnpm &> /dev/null; then
    pnpm add -g @colbymchenry/codegraph
else
    echo "❌ 未找到 npm 或 pnpm"
    echo "   请先安装 Node.js"
    exit 1
fi

# 验证安装
echo ""
echo "正在验证安装..."

if command -v codegraph &> /dev/null; then
    CODEGRAPH_VERSION=$(codegraph --version 2>/dev/null || echo "unknown")
    echo "✓ CodeGraph 安装成功: $CODEGRAPH_VERSION"
else
    echo "❌ CodeGraph 安装验证失败"
    exit 1
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "下一步:"
echo "  1. cd <your-project>"
echo "  2. codegraph init"
echo "  3. codegraph index"
echo ""
echo "或者使用 Harness:"
echo "  /index-project"
