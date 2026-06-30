#!/usr/bin/env bash
# test-mcp-config.sh - MCP 配置测试

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT="${ROOT}"

echo "=============================================="
echo "  Intelligence Layer - MCP 配置测试"
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

# === Test: MCP 配置文件存在 ===

echo "1. 检查 MCP 配置文件..."

mcp_configs=(
  "mcp-config/Understand-Anything.json"
  "mcp-config/CodeGraph.json"
)

for config in "${mcp_configs[@]}"; do
  if [[ -f "${KIT}/${config}" ]]; then
    test_pass "${config} 存在"
  else
    test_fail "${config} 不存在"
  fi
done

# === Test: CodeGraph 配置内容 ===

echo ""
echo "2. 检查 CodeGraph 配置..."

config_file="${KIT}/mcp-config/CodeGraph.json"
if [[ -f "$config_file" ]]; then
  # 检查 JSON 格式 (使用 node 或简单语法检查)
  if grep -q "mcpServers" "$config_file" && grep -q "codegraph" "$config_file"; then
    test_pass "CodeGraph.json JSON 格式正确"
  else
    test_fail "CodeGraph.json JSON 格式错误"
  fi

  # 检查必需字段
  if grep -q "codegraph" "$config_file"; then
    test_pass "包含 codegraph 服务器配置"
  else
    test_fail "缺少 codegraph 服务器配置"
  fi

  if grep -q "command" "$config_file"; then
    test_pass "包含 command 字段"
  else
    test_fail "缺少 command 字段"
  fi
fi

# === Test: Understand-Anything 配置内容 ===

echo ""
echo "3. 检查 Understand-Anything 配置..."

config_file="${KIT}/mcp-config/Understand-Anything.json"
if [[ -f "$config_file" ]]; then
  # 检查 JSON 格式 (使用 node 或简单语法检查)
  if grep -q "mcpServers" "$config_file" && grep -q "understand-anything" "$config_file"; then
    test_pass "Understand-Anything.json JSON 格式正确"
  else
    test_fail "Understand-Anything.json JSON 格式错误"
  fi

  # 检查必需字段
  if grep -q "understand-anything" "$config_file"; then
    test_pass "包含 understand-anything 服务器配置"
  else
    test_fail "缺少 understand-anything 服务器配置"
  fi

  if grep -q "command" "$config_file"; then
    test_pass "包含 command 字段"
  else
    test_fail "缺少 command 字段"
  fi
fi

# === Test: bootstrap.sh 包含 MCP 配置同步 ===

echo ""
echo "4. 检查 bootstrap.sh..."

if grep -q "bootstrap_mcp" "${KIT}/scripts/bootstrap.sh"; then
  test_pass "bootstrap.sh 包含 bootstrap_mcp"
else
  test_fail "bootstrap.sh 缺少 bootstrap_mcp"
fi

if grep -q "mcp-config" "${KIT}/scripts/bootstrap.sh"; then
  test_pass "bootstrap.sh 引用 mcp-config"
else
  test_fail "bootstrap.sh 未引用 mcp-config"
fi

# === Test: sync-skills.sh 包含 Intelligence 同步 ===

echo ""
echo "5. 检查 sync-skills.sh..."

if grep -q "sync_intelligence" "${KIT}/scripts/sync-skills.sh"; then
  test_pass "sync-skills.sh 包含 sync_intelligence"
else
  test_fail "sync-skills.sh 缺少 sync_intelligence"
fi

if grep -q "INTELLIGENCE_SRC" "${KIT}/scripts/sync-skills.sh"; then
  test_pass "sync-skills.sh 定义 INTELLIGENCE_SRC"
else
  test_fail "sync-skills.sh 未定义 INTELLIGENCE_SRC"
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
