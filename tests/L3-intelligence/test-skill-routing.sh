#!/usr/bin/env bash
# test-skill-routing.sh - Intelligence Layer Skill 路由测试

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT="${ROOT}"

echo "=============================================="
echo "  Intelligence Layer - Skill 路由测试"
echo "=============================================="
echo ""

PASS=0
FAIL=0

test_pass() {
  echo "  [PASS] $1"
  PASS=$((PASS + 1))
}

test_fail() {
  echo "  [FAIL] $1"
  FAIL=$((FAIL + 1))
}

# === Test: skill-preferences.md 包含 Intelligence 配置 ===

echo "1. 检查 skill-preferences.md..."

if grep -q "Intelligence Layer Skills" "${KIT}/core/orchestration/skill-preferences.md"; then
  test_pass "skill-preferences.md 包含 Intelligence Layer 配置"
else
  test_fail "skill-preferences.md 缺少 Intelligence Layer 配置"
fi

# Strategic Skills
for skill in "understand-project" "analyze-architecture" "query-knowledge-graph"; do
  if grep -q "$skill" "${KIT}/core/orchestration/skill-preferences.md"; then
    test_pass "包含 $skill"
  else
    test_fail "缺少 $skill"
  fi
done

# Tactical Skills
for skill in "index-project" "query-symbol" "get-callers" "get-callees" "analyze-impact"; do
  if grep -q "$skill" "${KIT}/core/orchestration/skill-preferences.md"; then
    test_pass "包含 $skill"
  else
    test_fail "缺少 $skill"
  fi
done

# === Test: domain-config.yaml 包含 intelligence_skills ===

echo ""
echo "2. 检查 domain-config.yaml..."

if grep -q "intelligence_skills:" "${KIT}/core/orchestration/domain-config.yaml"; then
  test_pass "domain-config.yaml 包含 intelligence_skills"
else
  test_fail "domain-config.yaml 缺少 intelligence_skills"
fi

if grep -q "strategic:" "${KIT}/core/orchestration/domain-config.yaml"; then
  test_pass "包含 strategic 层配置"
else
  test_fail "缺少 strategic 层配置"
fi

if grep -q "tactical:" "${KIT}/core/orchestration/domain-config.yaml"; then
  test_pass "包含 tactical 层配置"
else
  test_fail "缺少 tactical 层配置"
fi

# === Test: Skill 文件 frontmatter 完整性 ===

echo ""
echo "3. 检查 Skill 文件 frontmatter..."

skills=(
  "core/intelligence/strategic/understand-project.md"
  "core/intelligence/strategic/analyze-architecture.md"
  "core/intelligence/strategic/query-knowledge-graph.md"
  "core/intelligence/tactical/index-project.md"
  "core/intelligence/tactical/query-symbol.md"
  "core/intelligence/tactical/get-callers.md"
  "core/intelligence/tactical/get-callees.md"
  "core/intelligence/tactical/analyze-impact.md"
)

for skill in "${skills[@]}"; do
  if [[ -f "${KIT}/${skill}" ]]; then
    # 检查 frontmatter
    if grep -q "^---" "${KIT}/${skill}" && grep -q "^name:" "${KIT}/${skill}"; then
      test_pass "${skill} frontmatter 完整"
    else
      test_fail "${skill} frontmatter 不完整"
    fi

    # 检查 layer 标签
    if grep -q "^layer:" "${KIT}/${skill}"; then
      test_pass "${skill} 包含 layer 标签"
    else
      test_fail "${skill} 缺少 layer 标签"
    fi
  else
    test_fail "${skill} 文件不存在"
  fi
done

# === 总结 ===

echo ""
echo "=============================================="
echo "  测试结果"
echo "=============================================="
echo "  通过: ${PASS}"
echo "  失败: ${FAIL}"
echo "=============================================="

if [[ $FAIL -eq 0 ]]; then
  echo "  状态: ✅ 所有测试通过"
  exit 0
else
  echo "  状态: ❌ 存在失败测试"
  exit 1
fi
