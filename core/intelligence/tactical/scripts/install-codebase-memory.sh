#!/bin/bash
# install-codebase-memory.sh
# Codebase Memory MCP 安装脚本（替代 CodeGraph）

set -e

echo "=== Codebase Memory MCP 安装脚本 ==="

# 检查 Node.js 版本
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
REQUIRED_VERSION=18

if [ "$NODE_VERSION" -lt "$REQUIRED_VERSION" ]; then
    echo "❌ Node.js 版本过低: v$(node -v)"
    echo "   Codebase Memory MCP 需要 Node.js >= 18"
    echo "   请升级 Node.js 后重试"
    exit 1
fi

echo "✓ Node.js 版本检查通过: v$(node -v)"

# 安装 Codebase Memory MCP
echo ""
echo "正在安装 codebase-memory-mcp..."

if command -v npm &> /dev/null; then
    npm install -g codebase-memory-mcp
elif command -v pnpm &> /dev/null; then
    pnpm add -g codebase-memory-mcp
else
    echo "❌ 未找到 npm 或 pnpm"
    echo "   请先安装 Node.js"
    exit 1
fi

# 验证安装
echo ""
echo "正在验证安装..."

if command -v codebase-memory-mcp &> /dev/null; then
    CM_VERSION=$(codebase-memory-mcp --version 2>/dev/null || echo "unknown")
    echo "✓ codebase-memory-mcp 安装成功: $CM_VERSION"
else
    echo "❌ codebase-memory-mcp 安装验证失败"
    exit 1
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "支持的 MCP 工具:"
echo "  index_repository, search_graph, query_graph, trace_path,"
echo "  get_code_snippet, get_graph_schema, get_architecture,"
echo "  search_code, list_projects, delete_project, index_status,"
echo "  detect_changes, manage_adr, ingest_traces"
echo ""
echo "下一步:"
echo "  1. cd <your-project>"
echo "  2. codebase-memory-mcp cli index_repository --repo-path . --mode fast"
echo ""
echo "或者让 AI agent 直接调用 index_repository 工具"