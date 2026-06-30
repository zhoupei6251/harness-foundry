#!/bin/bash
# init-codegraph.sh
# CodeGraph 项目索引初始化脚本

set -e

PROJECT_PATH="${1:-.}"
LANGUAGES="${2:-}"

echo "=== CodeGraph 项目索引初始化 ==="
echo "项目路径: $PROJECT_PATH"

# 进入项目目录
cd "$PROJECT_PATH" || exit 1

# 检查 CodeGraph 是否安装
if ! command -v codegraph &> /dev/null; then
    echo "❌ CodeGraph 未安装"
    echo ""
    echo "请先安装 CodeGraph:"
    echo "  bash core/intelligence/tactical/scripts/install-codegraph.sh"
    exit 1
fi

# 初始化项目
echo ""
echo "正在初始化 CodeGraph..."
codegraph init

# 建立索引
echo ""
echo "正在建立代码索引..."

if [ -n "$LANGUAGES" ]; then
    echo "语言: $LANGUAGES"
    codegraph index --languages "$LANGUAGES"
else
    echo "语言: auto (自动检测)"
    codegraph index
fi

# 启动后台监视
echo ""
echo "正在启动文件监视..."
codegraph watch &

echo ""
echo "=== 索引初始化完成 ==="
echo ""
echo "索引数据存储在: $PROJECT_PATH/.codegraph/"
echo ""
echo "下一步:"
echo "  /query-symbol <符号名>  # 搜索符号"
echo "  /get-callers <符号名>   # 查找调用方"
echo "  /analyze-impact <符号>  # 评估影响"
