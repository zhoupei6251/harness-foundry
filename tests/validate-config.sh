#!/bin/bash
# 验证 harness-foundry 配置完整性
# 用途：确保所有必需文件和目录存在

PROJECT_ROOT="${1:-.}"
HARNESS_DIR="$PROJECT_ROOT/harness-foundry"

echo "🔍 验证 harness-foundry 配置..."
echo ""

ERRORS=0
WARNINGS=0

# 1. 检查核心目录
echo "📁 检查核心目录..."
REQUIRED_DIRS=(
    "core"
    "agents"
    "skills"
    "rules"
    "references"
    "traps-archive"
    "hooks"
    "contexts"
    "commands"
    "examples"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$HARNESS_DIR/$dir" ]; then
        echo "  ❌ 缺少目录: $dir"
        ((ERRORS++))
    else
        echo "  ✅ $dir/"
    fi
done

echo ""

# 2. 检查核心文件
echo "📄 检查核心文件..."
REQUIRED_FILES=(
    "README.md"
    "RULES.md"
    "core/intent-routing.md"
    "core/NEVER.md"
    "core/tags-index.md"
    "core/orchestration/domain-config.yaml"
    "references/traps.md"
    "references/learned-patterns.md"
    "hooks/hooks.json"
    "hooks/continuous-learning.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$HARNESS_DIR/$file" ]; then
        echo "  ❌ 缺少文件: $file"
        ((ERRORS++))
    else
        echo "  ✅ $file"
    fi
done

echo ""

# 3. 检查域规则
echo "📚 检查域规则..."
DOMAINS=("code" "novel" "news")

for domain in "${DOMAINS[@]}"; do
    if [ ! -d "$HARNESS_DIR/rules/$domain" ]; then
        echo "  ❌ 缺少域规则: rules/$domain/"
        ((ERRORS++))
    else
        echo "  ✅ rules/$domain/"
    fi
done

echo ""

# 4. 检查上下文文件
echo "🎯 检查上下文文件..."
CONTEXTS=("code" "novel" "news" "review")

for ctx in "${CONTEXTS[@]}"; do
    if [ ! -f "$HARNESS_DIR/contexts/$ctx.md" ]; then
        echo "  ❌ 缺少上下文: contexts/$ctx.md"
        ((ERRORS++))
    else
        echo "  ✅ contexts/$ctx.md"
    fi
done

echo ""

# 5. 检查命令文件
echo "⚡ 检查命令文件..."
COMMANDS=("code" "novel" "news" "evolve")

for cmd in "${COMMANDS[@]}"; do
    if [ ! -f "$HARNESS_DIR/commands/$cmd.md" ]; then
        echo "  ❌ 缺少命令: commands/$cmd.md"
        ((ERRORS++))
    else
        echo "  ✅ commands/$cmd.md"
    fi
done

echo ""

# 6. 检查记忆持久化钩子
echo "🪝 检查记忆持久化钩子..."
HOOKS=(
    "memory-persistence/session-start.sh"
    "memory-persistence/session-end.sh"
    "memory-persistence/extract-patterns.sh"
    "memory-persistence/README.md"
)

for hook in "${HOOKS[@]}"; do
    if [ ! -f "$HARNESS_DIR/hooks/$hook" ]; then
        echo "  ❌ 缺少钩子: hooks/$hook"
        ((ERRORS++))
    else
        echo "  ✅ hooks/$hook"
    fi
done

echo ""

# 7. 检查 agents 和 skills 索引
echo "📋 检查索引文件..."
if [ ! -f "$HARNESS_DIR/agents/README.md" ]; then
    echo "  ❌ 缺少 agents/README.md"
    ((ERRORS++))
else
    echo "  ✅ agents/README.md"
fi

if [ ! -f "$HARNESS_DIR/skills/README.md" ]; then
    echo "  ❌ 缺少 skills/README.md"
    ((ERRORS++))
else
    echo "  ✅ skills/README.md"
fi

echo ""

# 8. 检查 hooks.json 格式
echo "🔧 验证 hooks.json 格式..."
if command -v jq &> /dev/null; then
    if jq empty "$HARNESS_DIR/hooks/hooks.json" 2>/dev/null; then
        echo "  ✅ hooks.json 格式正确"
    else
        echo "  ❌ hooks.json 格式错误"
        ((ERRORS++))
    fi
else
    echo "  ⚠️  未安装 jq，跳过 JSON 验证"
    ((WARNINGS++))
fi

echo ""

# 9. 检查 domain-config.yaml 格式
echo "🔧 验证 domain-config.yaml 格式..."
if command -v yq &> /dev/null; then
    if yq eval '.' "$HARNESS_DIR/core/orchestration/domain-config.yaml" > /dev/null 2>&1; then
        echo "  ✅ domain-config.yaml 格式正确"
    else
        echo "  ❌ domain-config.yaml 格式错误"
        ((ERRORS++))
    fi
else
    echo "  ⚠️  未安装 yq，跳过 YAML 验证"
    ((WARNINGS++))
fi

echo ""

# 10. 统计 agents 和 skills 数量
echo "📊 统计信息..."
AGENT_COUNT=$(find "$HARNESS_DIR/agents" -maxdepth 1 -name "*.md" | wc -l)
SKILL_COUNT=$(find "$HARNESS_DIR/skills" -maxdepth 1 -type d | wc -l)
echo "  Agents: $AGENT_COUNT 个"
echo "  Skills: $SKILL_COUNT 个"

echo ""
echo "═══════════════════════════════════════"

if [ $ERRORS -eq 0 ]; then
    echo "✅ 配置验证通过！"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  有 $WARNINGS 个警告"
    fi
    exit 0
else
    echo "❌ 发现 $ERRORS 个错误"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  有 $WARNINGS 个警告"
    fi
    exit 1
fi
