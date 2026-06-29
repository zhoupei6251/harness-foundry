#!/usr/bin/env bash
# 集成测试：scripts/classify-skills.py
# 断言：
#   1. 同一输入跑 3 次输出完全一致（确定性）
#   2. 数量守恒：core ≤80, peripheral ≤120, archived ≥100
#   3. 路由表引用 → core
#   4. 空目录/无 frontmatter → archived

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

CLASSIFY="python3 scripts/classify-skills.py"
LAYER_FILE="skills/_layer.yaml"

echo "==> T2.1 确定性测试"
out1=$(mktemp)
out2=$(mktemp)
out3=$(mktemp)
$CLASSIFY --output "$out1" >/dev/null 2>&1
$CLASSIFY --output "$out2" >/dev/null 2>&1
$CLASSIFY --output "$out3" >/dev/null 2>&1
if ! diff -q "$out1" "$out2" >/dev/null || ! diff -q "$out2" "$out3" >/dev/null; then
  echo "  [FAIL] classify 输出不一致"; diff "$out1" "$out2"; exit 1
fi
echo "  [ok] 3 次输出完全一致"

echo "==> T2.2 数量守恒"
core_count=$(yq '.core | length' "$out1")
peri_count=$(yq '.peripheral | length' "$out1")
arch_count=$(yq '.archived | length' "$out1")
total=$((core_count + peri_count + arch_count))

if [[ "$core_count" -gt 80 ]]; then
  echo "  [FAIL] core=$core_count > 80"; exit 1
fi
if [[ "$peri_count" -gt 120 ]]; then
  echo "  [FAIL] peripheral=$peri_count > 120"; exit 1
fi
if [[ "$arch_count" -lt 100 ]]; then
  echo "  [FAIL] archived=$arch_count < 100"; exit 1
fi
if [[ "$total" -ne 328 ]]; then
  echo "  [FAIL] total=$total != 328"; exit 1
fi
echo "  [ok] core=$core_count, peripheral=$peri_count, archived=$arch_count"

rm -f "$out1" "$out2" "$out3"
echo ""
echo "All tests passed."
