#!/usr/bin/env bash
# L1-10: news 域自检清单校验
# 从 news-checklist（9 项自检 + 6 红线）提取可机器检查的子集：
#   1. 夸大词（震惊/史上最大/重磅/史诗级/前所未有/惊爆/震撼）
#   2. AI 套路表达（值得注意的是/引发热议/引发广泛关注）
#   3. 单一信源（只出现一种信源短语 → 命中红线 1）
# 用内嵌好坏稿 fixture 正负验证扫描器能抓到问题。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0

# ---- 可机器检查的项（与 traps-archive/news/news-checklist.md 对齐）----
OVERSTATED=("震惊" "史上最大" "重磅" "史诗级" "前所未有" "惊爆" "震撼")
AI_PATTERNS=("值得注意的是" "引发热议" "引发广泛关注" "引发强烈反响")
SOURCE_PHRASES=("警方通报" "目击者" "气象部门" "统计局" "知情人士" "官方通报" "公司声明" "业内人士" "相关负责人")

check_overstated() {
  # $1 = 正文；输出命中的夸大词
  local body="$1"
  for w in "${OVERSTATED[@]}"; do
    grep -qF "$w" <<< "$body" && echo "$w"
  done
  # set -e 下函数内最后一条 grep 失败会污染命令替换的退出码，强制归零
  return 0
}

check_ai_patterns() {
  local body="$1"
  for p in "${AI_PATTERNS[@]}"; do
    grep -qF "$p" <<< "$body" && echo "$p"
  done
  return 0
}

count_sources() {
  # $1 = 正文；输出出现的信源短语数（去重计数）
  local body="$1" n=0
  for s in "${SOURCE_PHRASES[@]}"; do
    grep -qF "$s" <<< "$body" && n=$((n + 1))
  done
  echo "$n"
}

# ---- fixture：好稿（含多信源 + 无夸大词）----
GOOD_ARTICLE='## 台风"海燕"登陆东南沿海 3 市启动应急响应

据气象部门消息，台风"海燕"今日 14 时在东南沿海登陆，中心附近最大风力 14 级。气象部门预计未来 24 小时仍有强降雨。

目击者称，沿海多个路段出现积水，当地已提前转移低洼地区居民。警方通报，暂无人员伤亡报告。

市应急管理局表示，已启动三级应急响应，3 市共派出救援队伍 120 支。截至发稿，供电部门正在抢修 2 条受损线路。

后续降雨影响范围将视台风路径变化，气象部门将持续发布最新情况。'

# ---- fixture：坏稿（单一信源 + 夸大词 + AI 套路）----
BAD_ARTICLE='## 史上最大规模改革方案重磅出炉

据悉，一位知情人士透露，有关部门正在酝酿一项震惊全国的改革方案，该方案将前所未有地改变行业格局。

值得注意的是，该方案尚未对外公布，业内专家也未对此发表评论。相关细节仍在酝酿阶段，引发广泛关注。

本台记者将持续跟进报道。'

echo "==> L1-10: 好稿应无夸大词"
HITS="$(check_overstated "$GOOD_ARTICLE")"
if [[ -z "$HITS" ]]; then
  echo "  [PASS] 好稿夸大词 0 命中"
else
  echo "  [FAIL] 好稿命中夸大词：$HITS"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-10: 好稿应无 AI 套路表达"
HITS="$(check_ai_patterns "$GOOD_ARTICLE")"
if [[ -z "$HITS" ]]; then
  echo "  [PASS] 好稿 AI 套路 0 命中"
else
  echo "  [FAIL] 好稿命中 AI 套路：$HITS"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-10: 好稿信源 >= 3（多信源）"
N="$(count_sources "$GOOD_ARTICLE")"
if [[ "$N" -ge 3 ]]; then
  echo "  [PASS] 好稿含 $N 种信源短语"
else
  echo "  [FAIL] 好稿信源不足（$N < 3）"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-10: 坏稿应命中夸大词（红线 5 标题不符 + 夸大）"
HITS="$(check_overstated "$BAD_ARTICLE")"
if [[ -n "$HITS" ]]; then
  echo "  [PASS] 坏稿命中夸大词：$HITS"
else
  echo "  [FAIL] 坏稿未命中夸大词——扫描器失效"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-10: 坏稿应命中 AI 套路表达"
HITS="$(check_ai_patterns "$BAD_ARTICLE")"
if [[ -n "$HITS" ]]; then
  echo "  [PASS] 坏稿命中 AI 套路：$HITS"
else
  echo "  [FAIL] 坏稿未命中 AI 套路——扫描器失效"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-10: 坏稿信源 = 1（单一信源红线）"
N="$(count_sources "$BAD_ARTICLE")"
if [[ "$N" -eq 1 ]]; then
  echo "  [PASS] 坏稿仅 1 种信源短语（单一信源红线可抓）"
else
  echo "  [FAIL] 坏稿信源 $N 种（预期 1）——fixture 漂移"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "==> L1-10 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
