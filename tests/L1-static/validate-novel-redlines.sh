#!/usr/bin/env bash
# L1-9: novel AI 痕迹红线回归测试
# 验证 8 条红线扫描器对 A/B 实验语料（docs/experiments/novel-harness-vs-bare.md）：
#   A 版（裸模型）应命中「就在这时」1 次 + 红线总数 >= 1
#   B 版（harness 修正）红线 0 命中
# 防止同样的因果链/红线 bug 回归。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
CORPUS="docs/experiments/novel-harness-vs-bare.md"

# ---- 8 条红线（与 traps-archive/novel/novel-checklist.md 对齐）----
REDLINES=(
  "眼中闪过一丝光芒"
  "嘴角勾起一抹微笑"
  "深吸一口气"
  "首先|其次|最后"
  "仿佛|似乎"
  "不是[^。；!！?？]*而是"
  "就在这时|突然之间"
  "预知后事"
)

scan_redlines() {
  # $1 = 章节正文（字符串）
  # 输出：命中的红线名（去重），未命中不输出
  # 注意：必须用 here-string（<<<）而非管道——管道流被第一次 grep 读完即耗尽，
  #       后续迭代会全部读空。
  local body="$1"
  for r in "${REDLINES[@]}"; do
    if grep -oE "$r" <<< "$body" > /dev/null 2>&1; then
      echo "$r"
    fi
  done
}

# ---- 切出 A/B 两版正文（从 "## 场景 A" 到对比结果表之前）----
extract_section() {
  # $1 = 起点标题（含 "## 场景 A"）
  # 输出：该节到下一个 "## " 之间的正文
  awk -v start="$1" '
    $0 ~ /^## / { if (section) exit; if ($0 ~ start) section=1 }
    section { print }
  ' "$CORPUS"
}

A_BODY="$(extract_section "场景 A")"
B_BODY="$(extract_section "场景 B")"

echo "==> L1-9: A 版应命中「就在这时」红线"
if echo "$A_BODY" | grep -q "就在这时"; then
  echo "  [PASS] A 版命中「就在这时」×1（grep 确认）"
else
  echo "  [FAIL] A 版未命中「就在这时」——语料漂移或红线失效"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-9: B 版红线 0 命中"
B_HITS="$(scan_redlines "$B_BODY")"
if [[ -z "$B_HITS" ]]; then
  echo "  [PASS] B 版 8 条红线全部 0 命中"
else
  echo "  [FAIL] B 版命中红线："
  echo "$B_HITS"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-9: A 版红线命中数 >= 1"
A_HITS="$(scan_redlines "$A_BODY")"
A_COUNT="$(echo "$A_HITS" | grep -c . || true)"
if [[ "$A_COUNT" -ge 1 ]]; then
  echo "  [PASS] A 版红线命中 $A_COUNT 条（$A_HITS）"
else
  echo "  [FAIL] A 版红线 0 命中——语料漂移（A 版应有 AI 痕迹）"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "==> L1-9 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
