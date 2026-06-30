#!/usr/bin/env bash
# test-agent-integration.sh - Agent 集成测试

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT="${ROOT}"

echo "=============================================="
echo "  Intelligence Layer - Agent 集成测试"
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

# === Test: Agent 文件包含 Intelligence Layer 指南 ===

echo "1. 检查 Agent 文件..."

agents=(
  "agents/coder.md"
  "agents/debugger.md"
  "agents/reviewer.md"
  "agents/leader-code.md"
)

for agent in "${agents[@]}"; do
  if [[ -f "${KIT}/${agent}" ]]; then
    # 检查 Intelligence Layer 相关内容 (宽松匹配)
    if grep -q "Intelligence" "${KIT}/${agent}" || grep -q "Understand-Anything" "${KIT}/${agent}" || grep -q "CodeGraph" "${KIT}/${agent}"; then
      test_pass "${agent} 包含 Intelligence Layer 集成"
    else
      test_fail "${agent} 缺少 Intelligence Layer 集成"
    fi
  else
    test_fail "${agent} 文件不存在"
  fi
done

# === Test: Agent 包含 MCP 或 CodeGraph 相关内容 ===

echo ""
echo "2. 检查 MCP / CodeGraph 调用示例..."

for agent in "${agents[@]}"; do
  if [[ -f "${KIT}/${agent}" ]]; then
    # 检查 MCP 调用示例或 Intelligence 相关内容
    if grep -q "MCP Call:" "${KIT}/${agent}" || grep -q "codegraph\." "${KIT}/${agent}" || grep -q "Intelligence" "${KIT}/${agent}"; then
      test_pass "${agent} 包含相关调用示例"
    else
      test_fail "${agent} 缺少相关调用示例"
    fi
  fi
done

# === Test: Agent 包含 CodeGraph 相关内容 ===

echo ""
echo "3. 检查 CodeGraph 引用..."

codegraph_terms=(
  "codegraph.search-nodes"
  "codegraph.get-callers"
  "codegraph.get-impact-radius"
)

for term in "${codegraph_terms[@]}"; do
  count=$(grep -l "$term" "${KIT}"/agents/*.md 2>/dev/null | wc -l)
  if [[ $count -gt 0 ]]; then
    test_pass "Agent 包含 $term"
  else
    test_fail "Agent 缺少 $term"
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
