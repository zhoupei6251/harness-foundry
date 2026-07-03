#!/bin/bash
# L2 Integration: Domain Config 引用一致性检查
# 验证 domain-config.yaml 中引用的 agents/skills 都存在
# 支持嵌套引用（intelligence_skills 等）

FOUNDRY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DOMAIN_CONFIG="$FOUNDRY_DIR/core/orchestration/domain-config.yaml"
AGENTS_DIR="$FOUNDRY_DIR/agents"
SKILLS_DIR="$FOUNDRY_DIR/skills"
INTELLIGENCE_DIR="$FOUNDRY_DIR/core/intelligence"
ISSUES=0

echo "=== L2-Integration: Domain Config 引用一致性 ==="

# 从 domain-config 中提取所有唯一引用名
extract_refs() {
    grep -E "^\s+- [a-z]" "$DOMAIN_CONFIG" | sed 's/.*- //' | sed 's/#.*//' | tr -d ' ' | sort -u | grep -v "^$"
}

# 检查 agent 是否存在
check_agent() {
    local name="$1"
    [ -f "$AGENTS_DIR/${name}.md" ]
}

# 检查 skill 是否存在
check_skill() {
    local name="$1"
    [ -d "$SKILLS_DIR/${name}" ] || [ -d "$INTELLIGENCE_DIR/${name}" ]
}

# Agent 引用列表（只检查 primary_agents/secondary_agents/workers）
echo ""
echo "--- Agent 引用检查 ---"
grep -A 100 "^  primary_agents:" "$DOMAIN_CONFIG" | grep -A 100 "^  secondary_agents:" | grep -E "^\s+-\s+[a-z]" | sed 's/.*- //' | sed 's/#.*//' | tr -d ' ' | sort -u | while read -r name; do
    [ -z "$name" ] && continue
    if check_agent "$name"; then
        echo "  ✅ $name"
    else
        echo "  ❌ $name — no agent file"
        ISSUES=$((ISSUES + 1))
    fi
done

# 也检查 workers 列表
grep -A 100 "^    workers:" "$DOMAIN_CONFIG" | head -20 | grep -E "^\s+-\s+[a-z]" | sed 's/.*- //' | sed 's/#.*//' | tr -d ' ' | sort -u | while read -r name; do
    [ -z "$name" ] && continue
    if check_agent "$name"; then
        echo "  ✅ $name"
    else
        echo "  ❌ $name — no agent file"
        ISSUES=$((ISSUES + 1))
    fi
done

# Skill 引用列表（只检查 *_skills 区块）
echo ""
echo "--- Skill 引用检查 ---"

# 提取所有 skill 区块的引用
extract_skill_refs() {
    # 匹配 primary_skills, secondary_skills, intelligence_skills 等
    grep -E "^\s+-\s+[a-z]" "$DOMAIN_CONFIG" | sed 's/.*- //' | sed 's/#.*//' | tr -d ' ' | sort -u
}

extract_skill_refs | while read -r name; do
    [ -z "$name" ] && continue
    if check_skill "$name"; then
        echo "  ✅ $name"
    elif check_agent "$name"; then
        echo "  - $name (is an agent, not a skill)"
    else
        echo "  ⚠️  $name — no skill dir (may be optional)"
    fi
done

# 输出总结
echo ""
if [ $ISSUES -eq 0 ]; then
    echo "✅ Domain Config 引用一致性检查通过"
    exit 0
else
    echo "❌ Domain Config 引用一致性检查失败 ($ISSUES issues)"
    exit 1
fi
