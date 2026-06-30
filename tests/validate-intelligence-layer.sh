#!/usr/bin/env bash
# validate-intelligence-layer.sh
# Intelligence Layer 集成测试

set -euo pipefail

# ROOT 是项目根目录（harness-foundry）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# KIT 指向 core/ 的父目录（即 harness-foundry 根目录）
KIT="${ROOT}"

echo "=============================================="
echo "  Intelligence Layer 集成测试"
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

# === Test 1: 检查目录结构 ===
echo "1. 检查目录结构..."
if [[ -d "${KIT}/core/intelligence" ]]; then
  test_pass "core/intelligence/ 目录存在"
else
  test_fail "core/intelligence/ 目录不存在"
fi

if [[ -d "${KIT}/core/intelligence/strategic" ]]; then
  test_pass "strategic/ 目录存在"
else
  test_fail "strategic/ 目录不存在"
fi

if [[ -d "${KIT}/core/intelligence/tactical" ]]; then
  test_pass "tactical/ 目录存在"
else
  test_fail "tactical/ 目录不存在"
fi

# === Test 2: 检查 Skill 文件 ===
echo ""
echo "2. 检查 Skill 文件..."

strategic_skills=(
  "understand-project.md"
  "analyze-architecture.md"
  "query-knowledge-graph.md"
)

tactical_skills=(
  "index-project.md"
  "query-symbol.md"
  "get-callers.md"
  "get-callees.md"
  "analyze-impact.md"
)

for skill in "${strategic_skills[@]}"; do
  if [[ -f "${KIT}/core/intelligence/strategic/${skill}" ]]; then
    test_pass "strategic/${skill} 存在"
  else
    test_fail "strategic/${skill} 不存在"
  fi
done

for skill in "${tactical_skills[@]}"; do
  if [[ -f "${KIT}/core/intelligence/tactical/${skill}" ]]; then
    test_pass "tactical/${skill} 存在"
  else
    test_fail "tactical/${skill} 不存在"
  fi
done

# === Test 3: 检查 Skill frontmatter ===
echo ""
echo "3. 检查 Skill frontmatter..."

check_frontmatter() {
  local file="$1"
  local name="$2"
  if grep -q "^---" "$file" && grep -q "^name:" "$file"; then
    test_pass "${name}: frontmatter 格式正确"
  else
    test_fail "${name}: frontmatter 格式错误"
  fi
}

check_frontmatter "${KIT}/core/intelligence/strategic/understand-project.md" "understand-project"
check_frontmatter "${KIT}/core/intelligence/tactical/query-symbol.md" "query-symbol"

# === Test 4: 检查 MCP 配置 ===
echo ""
echo "4. 检查 MCP 配置..."

if [[ -f "${KIT}/mcp-config/Understand-Anything.json" ]]; then
  test_pass "Understand-Anything.json 存在"
else
  test_fail "Understand-Anything.json 不存在"
fi

if [[ -f "${KIT}/mcp-config/CodeGraph.json" ]]; then
  test_pass "CodeGraph.json 存在"
else
  test_fail "CodeGraph.json 不存在"
fi

# === Test 5: 检查配置内容 ===
echo ""
echo "5. 检查配置内容..."

if grep -q "codegraph" "${KIT}/mcp-config/CodeGraph.json"; then
  test_pass "CodeGraph.json 包含 codegraph 配置"
else
  test_fail "CodeGraph.json 缺少 codegraph 配置"
fi

if grep -q "understand-anything" "${KIT}/mcp-config/Understand-Anything.json"; then
  test_pass "Understand-Anything.json 包含 understand-anything 配置"
else
  test_fail "Understand-Anything.json 缺少 understand-anything 配置"
fi

# === Test 6: 检查 skill-preferences.md ===
echo ""
echo "6. 检查 skill-preferences.md..."

if grep -q "Intelligence Layer" "${KIT}/core/orchestration/skill-preferences.md"; then
  test_pass "skill-preferences.md 包含 Intelligence Layer 配置"
else
  test_fail "skill-preferences.md 缺少 Intelligence Layer 配置"
fi

if grep -q "understand-project" "${KIT}/core/orchestration/skill-preferences.md"; then
  test_pass "skill-preferences.md 包含 understand-project"
else
  test_fail "skill-preferences.md 缺少 understand-project"
fi

if grep -q "query-symbol" "${KIT}/core/orchestration/skill-preferences.md"; then
  test_pass "skill-preferences.md 包含 query-symbol"
else
  test_fail "skill-preferences.md 缺少 query-symbol"
fi

# === Test 7: 检查 domain-config.yaml ===
echo ""
echo "7. 检查 domain-config.yaml..."

if grep -q "intelligence_skills" "${KIT}/core/orchestration/domain-config.yaml"; then
  test_pass "domain-config.yaml 包含 intelligence_skills"
else
  test_fail "domain-config.yaml 缺少 intelligence_skills"
fi

# === Test 8: 检查 Agent 更新 ===
echo ""
echo "8. 检查 Agent 更新..."

if grep -q "Intelligence Layer Skills" "${KIT}/agents/coder.md"; then
  test_pass "coder.md 包含 Intelligence Layer 指南"
else
  test_fail "coder.md 缺少 Intelligence Layer 指南"
fi

if grep -q "Intelligence Layer Skills" "${KIT}/agents/debugger.md"; then
  test_pass "debugger.md 包含 Intelligence Layer 指南"
else
  test_fail "debugger.md 缺少 Intelligence Layer 指南"
fi

if grep -q "Intelligence Layer Skills" "${KIT}/agents/reviewer.md"; then
  test_pass "reviewer.md 包含 Intelligence Layer 指南"
else
  test_fail "reviewer.md 缺少 Intelligence Layer 指南"
fi

# === Test 9: 检查脚本更新 ===
echo ""
echo "9. 检查脚本更新..."

if grep -q "bootstrap_mcp" "${KIT}/scripts/bootstrap.sh"; then
  test_pass "bootstrap.sh 包含 bootstrap_mcp"
else
  test_fail "bootstrap.sh 缺少 bootstrap_mcp"
fi

if grep -q "sync_intelligence" "${KIT}/scripts/sync-skills.sh"; then
  test_pass "sync-skills.sh 包含 sync_intelligence"
else
  test_fail "sync-skills.sh 缺少 sync_intelligence"
fi

# === Test 10: 检查脚本语法 ===
echo ""
echo "10. 检查脚本语法..."

if bash -n "${KIT}/core/intelligence/tactical/scripts/install-codegraph.sh" 2>/dev/null; then
  test_pass "install-codegraph.sh 语法正确"
else
  test_fail "install-codegraph.sh 语法错误"
fi

if bash -n "${KIT}/core/intelligence/tactical/scripts/init-index.sh" 2>/dev/null; then
  test_pass "init-index.sh 语法正确"
else
  test_fail "init-index.sh 语法错误"
fi

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
