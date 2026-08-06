#!/usr/bin/env bash
# L1-8: novel-graph 校验
# 验证 scripts/novel/novel_graph.py 三命令 + 因果链熔断规则
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0

echo "==> L1-8: novel-graph 正向（示例图应通过）"
if python scripts/novel/novel_graph.py examples/novel-graph/graph.yaml validate > /tmp/ng-ok.txt 2>&1; then
  echo "  [PASS] 示例图校验通过"
else
  echo "  [FAIL] 示例图校验失败："
  cat /tmp/ng-ok.txt
  FAILED=$((FAILED + 1))
fi

echo "==> L1-8: novel-graph 负向（删先导应熔断）"
python - <<'PYEOF' || FAILED=$((FAILED + 1))
import sys
sys.path.insert(0, "scripts/novel")
import novel_graph

g = novel_graph.load_graph("examples/novel-graph/graph.yaml")
# 删掉第 12 章事件 ev-lao-gives-box 的全部先导
g["edges"] = [e for e in g["edges"]
              if e["to"] != "ev-lao-gives-box"
              and e["from"] != "ev-lao-gives-box"]
# 删掉其涉及物品 eagle-box 的持有先导（物品凭空出现）
g["edges"] = [e for e in g["edges"] if e["to"] != "eagle-box"]
problems = novel_graph.causality_check(g)
if any("ev-lao-gives-box" in p for p in problems):
    print("  [PASS] 因果链熔断正确触发")
else:
    print("  [FAIL] 熔断未触发")
    sys.exit(1)
PYEOF

echo "==> L1-8: novel-graph path 回溯"
if python scripts/novel/novel_graph.py examples/novel-graph/graph.yaml path ev-lao-gives-box | grep -q "赠予"; then
  echo "  [PASS] path 回溯含先导边"
else
  echo "  [FAIL] path 回溯失败"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-8: novel-graph outline 生成"
if python scripts/novel/novel_graph.py examples/novel-graph/graph.yaml outline | grep -q "^graph TD"; then
  echo "  [PASS] Mermaid 生成成功"
else
  echo "  [FAIL] Mermaid 生成失败"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "==> L1-8 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
