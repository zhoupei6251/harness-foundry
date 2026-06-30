#!/bin/bash
# 会话开始时加载记忆
# 用途：在 hooks/hooks.json 中配置为 PreToolUse 钩子

set -e

# 项目根目录
PROJECT_ROOT="${1:-.}"
MEMORY_FILE="$PROJECT_ROOT/MEMORY.md"

# 检查 MEMORY.md 是否存在
if [ ! -f "$MEMORY_FILE" ]; then
    echo "⚠️  MEMORY.md 不存在，将创建新记忆文件"
    exit 0
fi

# 读取记忆文件摘要（前 20 行）
echo "📖 加载项目记忆："
echo "─────────────────────────────────────"
head -20 "$MEMORY_FILE"
echo "─────────────────────────────────────"
echo ""
echo "完整记忆请查看: $MEMORY_FILE"
echo ""

# 检查记忆文件年龄（天数）
if command -v stat &> /dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        FILE_AGE=$(( ($(date +%s) - $(stat -f %m "$MEMORY_FILE")) / 86400 ))
    else
        # Linux
        FILE_AGE=$(( ($(date +%s) - $(stat -c %Y "$MEMORY_FILE")) / 86400 ))
    fi
    
    if [ "$FILE_AGE" -gt 7 ]; then
        echo "⚠️  记忆文件已 $FILE_AGE 天未更新，建议运行 /evolve 刷新"
    fi
fi

exit 0
