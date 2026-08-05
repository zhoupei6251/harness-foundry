#!/bin/bash
# L1 Static: 文档数字一致性检查
# 校验 README / agents/README 中的 agent 与 skill 数量与实际文件数一致，
# 防止 34→35 这类数字漂移复发。
#
# 校验项：
#   1. agents/README.md 声明的 Agent 数量 == agents/*.md 实际数量
#   2. README.md 的「35 个 Agent」== 实际数量
#   3. README.md 的「84 个 Skills」== skills/*/SKILL.md 实际数量
#   4. README.en.md 的「35 Agents」== 实际数量
#   5. README.en.md 的「84 Skills」== 实际数量

FOUNDRY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ISSUES=0

echo "=== L1-Static: 文档数字一致性 ==="

# --- 1. 实际数量 ---
ACTUAL_AGENTS=$(ls "$FOUNDRY_DIR"/agents/*.md 2>/dev/null | grep -v '/README\.md$' | wc -l)
ACTUAL_SKILLS=$(ls -d "$FOUNDRY_DIR"/skills/*/ 2>/dev/null | wc -l)

echo "  实际 Agent 文件数（*.md，不含 README）: $ACTUAL_AGENTS"
echo "  实际 Skill 目录数（*/SKILL.md）: $ACTUAL_SKILLS"

# --- 2. agents/README.md ---
AGENTS_README_COUNT=$(grep -oE '共 \*\*[0-9]+ 个 Agent 文件' "$FOUNDRY_DIR/agents/README.md" | grep -oE '[0-9]+' || echo "")
if [ -n "$AGENTS_README_COUNT" ]; then
    if [ "$AGENTS_README_COUNT" -eq "$ACTUAL_AGENTS" ]; then
        echo "  [ok] agents/README.md: $AGENTS_README_COUNT 个 Agent 文件"
    else
        echo "  [FAIL] agents/README.md 声明 $AGENTS_README_COUNT，实际 $ACTUAL_AGENTS"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "  [FAIL] agents/README.md 未找到数量声明（共 **N 个 Agent 文件）"
    ISSUES=$((ISSUES + 1))
fi

# --- 3. README.md 的 Agent 数 ---
README_MD_AGENTS=$(grep -oE '\*\*[0-9]+ 个 Agent\*\*' "$FOUNDRY_DIR/README.md" | grep -oE '[0-9]+' | head -1)
if [ -n "$README_MD_AGENTS" ]; then
    if [ "$README_MD_AGENTS" -eq "$ACTUAL_AGENTS" ]; then
        echo "  [ok] README.md: $README_MD_AGENTS 个 Agent"
    else
        echo "  [FAIL] README.md 声明 $README_MD_AGENTS 个 Agent，实际 $ACTUAL_AGENTS"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "  [FAIL] README.md 未找到 Agent 数量声明"
    ISSUES=$((ISSUES + 1))
fi

# --- 4. README.md 的 Skill 数 ---
README_MD_SKILLS=$(grep -oE '\*\*[0-9]+ 个 Skill[s]*\*\*' "$FOUNDRY_DIR/README.md" | grep -oE '[0-9]+' | head -1)
if [ -n "$README_MD_SKILLS" ]; then
    if [ "$README_MD_SKILLS" -eq "$ACTUAL_SKILLS" ]; then
        echo "  [ok] README.md: $README_MD_SKILLS 个 Skill"
    else
        echo "  [FAIL] README.md 声明 $README_MD_SKILLS 个 Skill，实际 $ACTUAL_SKILLS"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "  [FAIL] README.md 未找到 Skill 数量声明"
    ISSUES=$((ISSUES + 1))
fi

# --- 5. README.en.md 的 Agent 数 ---
README_EN_AGENTS=$(grep -oE '\*\*[0-9]+ Agent[s]*\*\*' "$FOUNDRY_DIR/README.en.md" | grep -oE '[0-9]+' | head -1)
if [ -n "$README_EN_AGENTS" ]; then
    if [ "$README_EN_AGENTS" -eq "$ACTUAL_AGENTS" ]; then
        echo "  [ok] README.en.md: $README_EN_AGENTS Agents"
    else
        echo "  [FAIL] README.en.md 声明 $README_EN_AGENTS Agents，实际 $ACTUAL_AGENTS"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "  [FAIL] README.en.md 未找到 Agent 数量声明"
    ISSUES=$((ISSUES + 1))
fi

# --- 6. README.en.md 的 Skill 数 ---
README_EN_SKILLS=$(grep -oE '\*\*[0-9]+ Skill[s]*\*\*' "$FOUNDRY_DIR/README.en.md" | grep -oE '[0-9]+' | head -1)
if [ -n "$README_EN_SKILLS" ]; then
    if [ "$README_EN_SKILLS" -eq "$ACTUAL_SKILLS" ]; then
        echo "  [ok] README.en.md: $README_EN_SKILLS Skills"
    else
        echo "  [FAIL] README.en.md 声明 $README_EN_SKILLS Skills，实际 $ACTUAL_SKILLS"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "  [FAIL] README.en.md 未找到 Skill 数量声明"
    ISSUES=$((ISSUES + 1))
fi

# --- 汇总 ---
echo ""
if [ "$ISSUES" -eq 0 ]; then
    echo "  ✅ 文档数字一致性检查通过"
    exit 0
else
    echo "  ❌ 文档数字一致性检查失败：$ISSUES 处不一致"
    exit 1
fi
