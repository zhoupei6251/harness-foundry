#!/bin/bash
# 验证文件引用完整性
# 用途：确保所有文件引用都存在

set -e

PROJECT_ROOT="${1:-.}"
HARNESS_DIR="$PROJECT_ROOT/harness-foundry"

echo "验证文件引用完整性..."
echo ""

ERRORS=0

# 1. 检查 tags-index.md 中的引用
echo "[1] 检查 tags-index.md 引用..."
TAGS_INDEX="$HARNESS_DIR/core/tags-index.md"

if [ -f "$TAGS_INDEX" ]; then
    # 提取所有文件引用（使用进程替换避免子 shell 变量丢失）
    while read -r ref; do
        # 跳过常见词
        if [[ "$ref" =~ ^(md|yaml|json)$ ]]; then
            continue
        fi
        
        # 检查文件是否存在
        if [ ! -f "$HARNESS_DIR/$ref" ]; then
            echo "  [err] tags-index.md 引用了不存在的文件: $ref"
            ((ERRORS++))
        fi
    done < <(grep -oE '[a-zA-Z0-9_/-]+\.(md|yaml|json)' "$TAGS_INDEX")
else
    echo "  [err] tags-index.md 不存在"
    ((ERRORS++))
fi

echo ""

# 2. 检查 README.md 中的引用
echo "[2] 检查 README.md 引用..."
README="$HARNESS_DIR/README.md"

if [ -f "$README" ]; then
    while read -r ref; do
        if [[ "$ref" =~ ^(md|yaml|json|sh)$ ]]; then
            continue
        fi
        
        if [ ! -f "$HARNESS_DIR/$ref" ]; then
            echo "  [warn] README.md 引用了不存在的文件: $ref"
        fi
    done < <(grep -oE '[a-zA-Z0-9_/-]+\.(md|yaml|json|sh)' "$README")
else
    echo "  [err] README.md 不存在"
    ((ERRORS++))
fi

echo ""

# 3. 检查 RULES.md 中的引用
echo "[3] 检查 RULES.md 引用..."
RULES="$HARNESS_DIR/RULES.md"

if [ -f "$RULES" ]; then
    while read -r ref; do
        if [[ "$ref" =~ ^(md|yaml|json)$ ]]; then
            continue
        fi
        
        if [ ! -f "$HARNESS_DIR/$ref" ]; then
            echo "  [warn] RULES.md 引用了不存在的文件: $ref"
        fi
    done < <(grep -oE '[a-zA-Z0-9_/-]+\.(md|yaml|json)' "$RULES")
else
    echo "  [err] RULES.md 不存在"
    ((ERRORS++))
fi

echo ""

# 4. 检查 hooks.json 中的脚本引用
echo "[4] 检查 hooks.json 脚本引用..."
HOOKS_JSON="$HARNESS_DIR/hooks/hooks.json"

if [ -f "$HOOKS_JSON" ] && command -v jq &> /dev/null; then
    while read -r cmd; do
        script=$(echo "$cmd" | grep -oE 'hooks/[a-zA-Z0-9_/-]+\.sh' || true)
        
        if [ -n "$script" ] && [ ! -f "$HARNESS_DIR/$script" ]; then
            echo "  [err] hooks.json 引用了不存在的脚本: $script"
            ((ERRORS++))
        fi
    done < <(jq -r '.. | .command? // empty' "$HOOKS_JSON" 2>/dev/null)
else
    echo "  [skip] 跳过 hooks.json 检查（缺少 jq 或文件不存在）"
fi

echo ""

# 5. 检查 agents 和 skills 目录一致性
echo "[5] 检查 agents 和 skills 目录..."

AGENTS_README="$HARNESS_DIR/agents/README.md"
if [ -f "$AGENTS_README" ]; then
    echo "  [ok] agents/README.md 存在"
else
    echo "  [warn] agents/README.md 不存在"
fi

SKILLS_README="$HARNESS_DIR/skills/README.md"
if [ -f "$SKILLS_README" ]; then
    echo "  [ok] skills/README.md 存在"
else
    echo "  [warn] skills/README.md 不存在"
fi

echo ""
echo "====================================="

if [ $ERRORS -eq 0 ]; then
    echo "文件引用验证通过！"
    exit 0
else
    echo "发现 $ERRORS 个引用错误"
    exit 1
fi
