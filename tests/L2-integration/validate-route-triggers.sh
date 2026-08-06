#!/usr/bin/env bash
# L2-3: 路由触发测试（意图 → 路由命中）
# 验证三域路由表覆盖高频意图，且路由表引用的 harness 内部 skill 都存在。
# 权威路由表：novel 域 = skills/novel-protocol/SKILL.md § 指令路由表（唯一权威源）
#             code/news 域 = core/intent-routing.md
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
NOVEL_ROUTES="skills/novel-protocol/SKILL.md"
INTENT_ROUTES="core/intent-routing.md"

# ---- 1. novel 域：意图 prompt → 路由表行命中 ----
echo "==> L2-3: novel 域意图 → novel-protocol 路由表命中"
NOVEL_INTENTS=(
  "写章节|写章节/续写"
  "续写|写章节/续写"
  "快速单章|快速写单章"
  "批量|批量写到第 N 章"
  "新书|新书创建"
  "恢复会话|会话恢复"
  "大纲|设计大纲/世界观/设定"
  "世界观|设计大纲/世界观/设定"
  "进度|查看进度/统计"
  "统计|查看进度/统计"
  "一致性|上下文一致性检查"
  "检查点|检查点管理"
  "复杂任务|复杂任务/完整编排"
  "审稿|审稿评分"
  "评分|审稿评分"
  "改良|改良已有作品"
  "润色|润色去 AI 味"
  "番茄|平台专项（番茄）"
  "起点|平台专项（起点）"
  "智斗|智斗/权谋类型"
  "发布质检|发布前质检"
  "番茄发布|番茄发布"
  "返修|返修/排查情节"
  "章节自查|章节自查"
  "跨章记忆|跨章记忆/统稿"
  "写前查设定|写前查设定"
)
for entry in "${NOVEL_INTENTS[@]}"; do
  intent="${entry%%|*}"
  row="${entry##*|}"
  if grep -qF "$row" "$NOVEL_ROUTES"; then
    echo "  [PASS] \"$intent\" → 路由表命中 \"$row\""
  else
    echo "  [FAIL] \"$intent\" 未在 novel-protocol 路由表命中 \"$row\""
    FAILED=$((FAILED + 1))
  fi
done

# ---- 2. novel 域：路由表装配的 skill 都存在（harness 内部 slug）----
echo ""
echo "==> L2-3: novel-protocol 装配的 skill 存在性"
NOVEL_SKILLS=(
  writing-novel novel-guidelines novel-quick-write novel-batch-write
  novel-init novel-recovery brainstorming novel-36-beats
  novel-dashboard novel-metrics novel-contexts novel-checkpoint
  novel-orchestrator novel-evaluator novel-guardian novel-improver
  humanizer-zh piqie-writing qidian-writing zhi-dou-writing
  web-novel-publishing-readiness-and-quality-check-skill
  fanqie-novel-auto-publish novel-debug novel-safe-revision
  novel-simplify memory-manager
)
for slug in "${NOVEL_SKILLS[@]}"; do
  if [[ -f "skills/${slug}/SKILL.md" ]]; then
    echo "  [PASS] skills/${slug}/SKILL.md"
  else
    echo "  [FAIL] 路由表引用 skills/${slug}/SKILL.md 不存在"
    FAILED=$((FAILED + 1))
  fi
done

# ---- 3. code 域：高频意图 → intent-routing.md 命中 ----
echo ""
echo "==> L2-3: code 域意图 → intent-routing.md 命中"
CODE_INTENTS=(
  "设计|设计、方案、架构、选型"
  "方案|设计、方案、架构、选型"
  "修bug|修bug、空指针、不工作"
  "写代码|写代码、实现、重构"
  "实现|写代码、实现、重构"
  "重构|写代码、实现、重构"
  "并行修改|多个独立修改"
  "审查|审查、review"
  "测试|测试、单测"
  "编译报错|mvn compile 报错"
  "commit|commit、merge、push、MR"
  "merge|commit、merge、push、MR"
)
for entry in "${CODE_INTENTS[@]}"; do
  intent="${entry%%|*}"
  row="${entry##*|}"
  if grep -qF "$row" "$INTENT_ROUTES"; then
    echo "  [PASS] \"$intent\" → 路由表命中 \"$row\""
  else
    echo "  [FAIL] \"$intent\" 未在 intent-routing.md 命中 \"$row\""
    FAILED=$((FAILED + 1))
  fi
done

# ---- 4. news 域：高频意图 → intent-routing.md 命中 ----
echo ""
echo "==> L2-3: news 域意图 → intent-routing.md 命中"
NEWS_INTENTS=(
  "写新闻|写稿件、写新闻"
  "写稿件|写稿件、写新闻"
  "事实核查|事实核查、核实"
  "追热点|追热点、选题"
  "审校|审校、编辑"
)
for entry in "${NEWS_INTENTS[@]}"; do
  intent="${entry%%|*}"
  row="${entry##*|}"
  if grep -qF "$row" "$INTENT_ROUTES"; then
    echo "  [PASS] \"$intent\" → 路由表命中 \"$row\""
  else
    echo "  [FAIL] \"$intent\" 未在 intent-routing.md 命中 \"$row\""
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "==> L2-3 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
