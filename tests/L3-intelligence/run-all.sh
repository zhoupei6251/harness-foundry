#!/usr/bin/env bash
# run-all.sh - 运行所有 L3 Intelligence 测试

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "  Intelligence Layer - L3 集成测试"
echo "=============================================="
echo ""

PASS=0
FAIL=0

# 运行所有测试
for test in test-skill-routing.sh test-agent-integration.sh test-mcp-config.sh; do
  echo ">>> 运行 $test..."
  if bash "${SCRIPT_DIR}/${test}"; then
    echo ""
  else
    FAIL=$((FAIL + 1))
    echo ""
  fi
done

echo ""
echo "=============================================="
echo "  L3 测试完成"
echo "=============================================="
echo ""

# 运行 L1 测试
echo ">>> 运行 L1 基础测试..."
bash "${SCRIPT_DIR}/../validate-intelligence-layer.sh" || FAIL=$((FAIL + 1))

echo ""
echo "=============================================="
echo "  全部测试完成"
echo "=============================================="

if [[ $FAIL -eq 0 ]]; then
  echo "  状态: ✅ 所有测试通过"
  exit 0
else
  echo "  状态: ❌ 存在失败测试"
  exit 1
fi
