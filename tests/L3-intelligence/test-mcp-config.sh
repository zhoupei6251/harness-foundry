#!/usr/bin/env bash
# test-mcp-config.sh - MCP 与 codebase-memory 配置测试

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KIT="${ROOT}"
PASS=0
FAIL=0

echo "=============================================="
echo "  Intelligence Layer - 配置测试"
echo "=============================================="
echo ""

test_pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
test_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "1. 检查 MCP 配置文件..."
config_file="${KIT}/mcp-config/codebase-memory.json"
if [[ -f "$config_file" ]]; then
  test_pass "codebase-memory.json 存在"
else
  test_fail "codebase-memory.json 不存在"
fi

if [[ -f "$config_file" ]] && grep -q "mcpServers" "$config_file" && grep -q "codebase-memory" "$config_file"; then
  test_pass "codebase-memory.json 配置有效"
else
  test_fail "codebase-memory.json 配置无效"
fi

echo ""
echo "2. 检查 codebase-memory 配置..."
if grep -q "codebase-memory" "${KIT}/core/intelligence/tactical/_config.yaml"; then
  test_pass "tactical/_config.yaml 使用 codebase-memory"
else
  test_fail "tactical/_config.yaml 缺少 codebase-memory"
fi

for tool in "index_repository" "search_graph" "trace_path" "detect_changes" "ripgrep-search" "lsp-query" "code-insight-stack"; do
  if grep -q "$tool" "${KIT}/core/intelligence/tactical/_config.yaml"; then
    test_pass "配置包含 $tool"
  else
    test_fail "配置缺少 $tool"
  fi
done

echo ""
echo "3. 检查 bootstrap/sync 集成..."
if grep -q "bootstrap_mcp" "${KIT}/scripts/bootstrap.sh" && grep -q "mcp-config" "${KIT}/scripts/bootstrap.sh"; then
  test_pass "bootstrap.sh 同步 mcp-config"
else
  test_fail "bootstrap.sh 未同步 mcp-config"
fi

if grep -q "sync_intelligence" "${KIT}/scripts/sync-skills.sh" && grep -q "INTELLIGENCE_SRC" "${KIT}/scripts/sync-skills.sh"; then
  test_pass "sync-skills.sh 同步 Intelligence Layer"
else
  test_fail "sync-skills.sh 未同步 Intelligence Layer"
fi

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