#!/bin/bash
# L1 Static: 孤儿 Skill 检测
# 强制每个 skills/<slug>/ 目录至少被一个「真实引用源」引用。
# 真实引用源 = 路由/协议/文档/命令/适配器（非 skills/ 自身，也非目录扫描脚本）。
#
# 背景：2026-08-06 资产审计发现 4 个外来 skill 完全未被引用（Clawdbot/OpenClaw
# 生态误入）。本测试防止「存在但不可达」的孤儿资产回归：
#   每个 skill 必须被至少一个文件以 `<slug>` 单词形式提及，
#   且该文件不在 skills/ 内（排除自身/INDEX/_layer/categories 自引用）。

FOUNDRY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ISSUES=0

echo "=== L1-Static: 孤儿 Skill 检测 ==="

# 需要真实引用的 skill 目录（排除元数据文件）
mapfile -t SKILLS < <(find "$FOUNDRY_DIR/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

# 收集全部「真实引用源」文件：排除 skills/ 自身与目录扫描脚本
# 目录扫描脚本遍历整个 skills/，被提到≠被使用，会造成伪引用
SCAN_SCRIPTS_PATTERN='apply-skill-categories|_skill_meta|_must_core|add-skill-relations|heuristic-skill|rebuild-skill-meta'

mapfile -t REF_FILES < <(find "$FOUNDRY_DIR" -type f \
    \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.sh' -o -name '*.py' \) \
    ! -path '*/skills/*' \
    ! -path '*/.git/*' \
    ! -path '*/tests/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/traps-archive/*' \
    ! -name 'INDEX.md' 2>/dev/null | grep -vE "$SCAN_SCRIPTS_PATTERN")

for slug in "${SKILLS[@]}"; do
    # 在真实引用源中搜索 slug（单词边界）
    if ! grep -rqw -- "$slug" "${REF_FILES[@]}" 2>/dev/null; then
        echo "  [FAIL] 孤儿 skill: $slug（无真实引用源）"
        ISSUES=$((ISSUES + 1))
    fi
done

echo ""
if [ "$ISSUES" -eq 0 ]; then
    echo "  ✅ 全部 ${#SKILLS[@]} 个 skill 均有真实引用源"
    exit 0
else
    echo "  ❌ $ISSUES 个孤儿 skill"
    exit 1
fi
