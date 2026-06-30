#!/bin/bash
# 从会话日志中提取模式
# 用途：配合 /evolve 命令使用

set -e

# 项目根目录
PROJECT_ROOT="${1:-.}"
LOGS_DIR="$PROJECT_ROOT/.ai-runtime-artifacts/execution-logs"
PATTERNS_FILE="$PROJECT_ROOT/references/learned-patterns.md"

# 检查日志目录
if [ ! -d "$LOGS_DIR" ]; then
    echo "⚠️  日志目录不存在: $LOGS_DIR"
    exit 1
fi

echo "🔍 扫描会话日志，提取模式..."
echo ""

# 1. 统计日志数量
LOG_COUNT=$(find "$LOGS_DIR" -name "session-*.md" | wc -l)
echo "找到 $LOG_COUNT 个会话日志"

# 2. 提取高频关键词（简化版）
echo ""
echo "📊 高频关键词："
echo "─────────────────────────────────────"

# 提取所有日志中的关键词（排除常见词）
grep -h -o -E '(完成|修复|优化|添加|创建|实现|测试|审查)' "$LOGS_DIR"/session-*.md 2>/dev/null | \
    sort | uniq -c | sort -rn | head -10

echo "─────────────────────────────────────"

# 3. 提取错误模式
echo ""
echo "🐛 错误模式："
echo "─────────────────────────────────────"

grep -h -i -E '(错误|失败|bug|问题|修复)' "$LOGS_DIR"/session-*.md 2>/dev/null | \
    head -5 || echo "未发现明显错误模式"

echo "─────────────────────────────────────"

# 4. 提示
echo ""
echo "💡 建议操作："
echo "   - 手动审查日志: ls $LOGS_DIR"
echo "   - 运行 /evolve 自动提取经验"
echo "   - 更新模式文件: $PATTERNS_FILE"

exit 0
