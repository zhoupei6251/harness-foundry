#!/bin/bash
# 会话结束时保存记忆
# 用途：在 hooks/hooks.json 中配置为 Stop 钩子

set -e

# 项目根目录
PROJECT_ROOT="${1:-.}"
MEMORY_FILE="$PROJECT_ROOT/MEMORY.md"
SESSION_LOG="$PROJECT_ROOT/.ai-runtime-artifacts/execution-logs/session-$(date +%Y%m%d-%H%M%S).md"

# 确保目录存在
mkdir -p "$(dirname "$MEMORY_FILE")"
mkdir -p "$(dirname "$SESSION_LOG")"

echo "💾 会话结束，保存记忆..."

# 1. 提取本次会话关键信息
SESSION_SUMMARY=$(cat <<EOF
## $(date '+%Y-%m-%d %H:%M:%S') 会话

### 完成的任务
- [从会话历史提取]

### 学到的经验
- [从会话历史提取]

### 待办事项
- [从会话历史提取]

---

EOF
)

# 2. 追加到会话日志
echo "$SESSION_SUMMARY" >> "$SESSION_LOG"
echo "✅ 会话日志已保存: $SESSION_LOG"

# 3. 更新 MEMORY.md（如果存在）
if [ -f "$MEMORY_FILE" ]; then
    # 备份旧记忆
    cp "$MEMORY_FILE" "$MEMORY_FILE.bak"
    
    # 追加新内容（简化版，实际需要 AI 提取）
    echo "" >> "$MEMORY_FILE"
    echo "$SESSION_SUMMARY" >> "$MEMORY_FILE"
    
    echo "✅ 记忆已更新: $MEMORY_FILE"
    echo "   备份文件: $MEMORY_FILE.bak"
else
    echo "⚠️  MEMORY.md 不存在，跳过记忆更新"
fi

# 4. 提示用户
echo ""
echo "📝 建议操作："
echo "   - 查看完整记忆: cat $MEMORY_FILE"
echo "   - 清理过时记忆: 手动编辑 MEMORY.md"
echo "   - 自动进化: 运行 /evolve 提取经验"

exit 0
