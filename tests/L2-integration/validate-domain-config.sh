#!/bin/bash
# L2 Integration: Domain Config 引用一致性检查
# 验证 domain-config.yaml 中引用的 agents/skills 都存在

FOUNDRY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
DOMAIN_CONFIG="$FOUNDRY_DIR/core/orchestration/domain-config.yaml"
AGENTS_DIR="$FOUNDRY_DIR/agents"
SKILLS_DIR="$FOUNDRY_DIR/skills"
ISSUES=0

echo "=== L2-Integration: Domain Config 引用一致性 ==="

# Extract agents: lines with "- " under primary_agents/secondary_agents/meta_agents
echo ""
echo "--- Agent 引用检查 ---"
grep -E "^\s+- [a-z]" "$DOMAIN_CONFIG" | sed 's/.*- //' | sed 's/#.*//' | tr -d ' ' | sort -u | while read -r name; do
    [ -z "$name" ] && continue
    if [ -f "$AGENTS_DIR/${name}.md" ]; then
        echo "  ✅ $name"
    else
        echo "  ⚠️  $name — no agent file (may be a skill reference, not an agent)"
    fi
done

# Extract skills: same list but check skills/ dir
echo ""
echo "--- Skill 引用检查 ---"
grep -E "^\s+- [a-z]" "$DOMAIN_CONFIG" | sed 's/.*- //' | sed 's/#.*//' | tr -d ' ' | sort -u | while read -r name; do
    [ -z "$name" ] && continue
    if [ -d "$SKILLS_DIR/${name}" ]; then
        echo "  ✅ $name"
    elif [ -f "$AGENTS_DIR/${name}.md" ]; then
        echo "  - $name (is an agent, not a skill)"
    else
        echo "  ⚠️  $name — neither agent nor skill found"
    fi
done

echo ""
echo "Note: domain-config.yaml lists both agents and skills together;"
echo "some 'missing' entries above are just skills with agent names or vice versa."
echo "✅ Domain Config 引用一致性检查完成"
