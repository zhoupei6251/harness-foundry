#!/usr/bin/env bash
# test-agent-integration.sh - Agent 集成测试

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT="${ROOT}"
PASS=0
FAIL=0

echo "=============================================="
echo "  Intelligence Layer - Agent 集成测试"
echo "=============================================="
echo ""

test_pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
test_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

agents=(
  "agents/coder.md"
  "agents/debugger.md"
  "agents/code-reviewer.md"
  "agents/leader-code.md"
)

echo "1. 检查 Agent 文件..."
for agent in "${agents[@]}"; do
  if [[ -f "${KIT}/${agent}" ]]; then
    if grep -q "Intelligence" "${KIT}/${agent}" && grep -q "codebase-memory" "${KIT}/${agent}"; then
      test_pass "${agent} 包含 codebase-memory 集成"
    else
      test_fail "${agent} 缺少 codebase-memory 集成"
    fi
  else
    test_fail "${agent} 文件不存在"
  fi
done

echo ""
echo "2. 检查结构化查询工具示例..."
for term in "search_graph" "trace_path" "detect_changes" "ripgrep-search" "lsp-query" "code-insight-stack"; do
  count=$(grep -l "$term" "${KIT}"/agents/*.md 2>/dev/null | wc -l)
  if [[ $count -gt 0 ]]; then
    test_pass "Agent 包含 $term"
  else
    test_fail "Agent 缺少 $term"
  fi
done

echo ""
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