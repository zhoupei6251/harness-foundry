#!/bin/bash
# L1 Static: Agent 文件格式一致性检查
# 检查所有 agent 定义文件的格式统一性

FOUNDRY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
AGENTS_DIR="$FOUNDRY_DIR/agents"
ISSUES=0

echo "=== L1-Static: Agent 文件格式一致性 ==="

total=0
with_frontmatter=0
without_frontmatter=0
has_name=0
has_description=0
has_workflow=0
has_forbidden=0

for agent_file in "$AGENTS_DIR"/*.md; do
    [ ! -f "$agent_file" ] && continue
    name=$(basename "$agent_file")
    [ "$name" = "README.md" ] && continue

    total=$((total + 1))

    # 检查是否有 YAML frontmatter
    if head -1 "$agent_file" | grep -q "^---$"; then
        with_frontmatter=$((with_frontmatter + 1))
        has_name=$((has_name + 1))
    else
        without_frontmatter=$((without_frontmatter + 1))
        # 无 frontmatter 的文件：检查是否有 # 标题（必须）
        if grep -q "^# " "$agent_file" 2>/dev/null; then
            has_name=$((has_name + 1))
        fi
    fi

    # 检查是否有职责/工作流描述
    if grep -qE "(职责|Role|工作流程|Workflow)" "$agent_file" 2>/dev/null; then
        has_workflow=$((has_workflow + 1))
    fi

    # 检查是否有禁止项
    if grep -qE "(禁止|Forbidden|Never|🚫)" "$agent_file" 2>/dev/null; then
        has_forbidden=$((has_forbidden + 1))
    fi
done

echo ""
echo "  Agent 总数: $total"
echo "  YAML frontmatter: $with_frontmatter"
echo "  纯 Markdown: $without_frontmatter"
echo "  有标题/名称: $has_name"
echo "  有工作流描述: $has_workflow"
echo "  有禁止项: $has_forbidden"
echo ""

# 格式一致性评分
consistency_pct=0
if [ $total -gt 0 ]; then
    consistency_pct=$(( (with_frontmatter * 100) / total ))
fi

echo "  Frontmatter 覆盖率: ${consistency_pct}%"

if [ "$consistency_pct" -lt 50 ]; then
    echo "  ⚠️  Frontmatter 覆盖率低于 50%，建议渐进式迁移"
    echo "  迁移方式: 为纯 Markdown agent 增加 YAML frontmatter (name + description + tools)"
    echo "  参考模板: agents/novel-writer.md (novel 域) 或 agents/code-reviewer.md (code 域)"
fi

if [ "$has_forbidden" -lt "$total" ]; then
    missing=$((total - has_forbidden))
    echo "  ⚠️  $missing 个 agent 缺少禁止项声明"
fi

# 非阻塞警告
echo ""
echo "✅ Agent 格式检查完成（差异为 warning，不阻塞构建）"
