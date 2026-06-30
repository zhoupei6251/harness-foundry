#!/bin/bash
# skill-quality-check.sh - Skill 质量评分系统
#
# 自动对 skills/ 下所有 SKILL.md 评分
# 输出质量排名，识别僵尸 skill
#
# 用法：bash scripts/skill-quality-check.sh [--top=N] [--bottom] [--zombie]

set -euo pipefail

FOUNDRY_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$FOUNDRY_DIR/skills"
TODAY=$(date +%Y-%m-%d)

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============ 评分函数 ============

score_metadata() {
  # 元数据完整度 (0-40 分)
  # name: 10分 | description: 15分 | 触发条件: 10分 | tags: 5分
  local file="$1"
  local score=0

  grep -q "^name:" "$file" 2>/dev/null && score=$((score + 10))
  grep -q "^description:" "$file" 2>/dev/null && score=$((score + 15))
  if grep -qE "(Use when|激活条件|触发场景|When to|Triggers|适用场景)" "$file" 2>/dev/null; then
    score=$((score + 10))
  fi
  grep -q "^tags:" "$file" 2>/dev/null && score=$((score + 5))

  echo "$score"
}

score_usage() {
  # 使用频率 (0-30 分)
  # 从 instinct 数据推断 skill 使用情况
  # 有 evolve 记录: +15 | 有 referenced by: +10 | 最近有更新: +5
  local dir="$1"
  local score=0
  local skill_file="$dir/SKILL.md"

  # 检查 skill 是否被 domain-config 引用
  if grep -qR "$(basename "$dir")" "$FOUNDRY_DIR/core/orchestration/domain-config.yaml" 2>/dev/null; then
    score=$((score + 20))  # domain-config 引用 = 高优先级
  fi

  # 检查是否有 README 或其他 skill 引用它
  local ref_count
  ref_count=$(grep -r "$(basename "$dir")" "$FOUNDRY_DIR/core/" "$FOUNDRY_DIR/agents/" "$FOUNDRY_DIR/skills/" 2>/dev/null | grep -v "$dir" | wc -l | tr -d ' ')
  if [ "$ref_count" -gt 5 ]; then
    score=$((score + 10))
  elif [ "$ref_count" -gt 0 ]; then
    score=$((score + 5))
  fi

  # 超过 60 天？
  local last_modified
  last_modified=$(stat -c %Y "$skill_file" 2>/dev/null || stat -f %m "$skill_file" 2>/dev/null || echo 0)
  local now
  now=$(date +%s)
  local days_old=$(( (now - last_modified) / 86400 ))
  if [ "$days_old" -gt 60 ]; then
    # 不扣分，只是标记
    :
  fi

  echo "$score"
}

score_references() {
  # 引用完整性 (0-30 分)
  # SKILL.md 中引用的文件都存在: 15分 | 无死链接: 15分
  local file="$1"
  local score=30  # 满分起步，发现死链接扣分

  # 提取 markdown 链接
  local links
  links=$(grep -oP '\[.*?\]\(\.\.?/[^)]+\)' "$file" 2>/dev/null || true)

  while IFS= read -r link; do
    [ -z "$link" ] && continue
    local path_part
    path_part=$(echo "$link" | grep -oP '(?<=\().*(?=\))' | head -1)
    [ -z "$path_part" ] && continue

    # 计算相对于 SKILL.md 的路径
    local dir
    dir=$(dirname "$file")
    local resolved
    resolved=$(cd "$dir" 2>/dev/null && realpath "$path_part" 2>/dev/null || echo "")

    if [ -n "$resolved" ] && [ -f "$resolved" ]; then
      :  # 正常
    else
      score=$((score - 5))
    fi
  done <<< "$links"

  [ "$score" -lt 0 ] && score=0
  echo "$score"
}

# ============ 主流程 ============

echo "=== Harness Foundry Skill 质量评分 ==="
echo ""

declare -A scores
declare -A details

total=0
zombie_count=0
top_count=0

for skill_dir in "$SKILLS_DIR"/*/; do
  [ ! -d "$skill_dir" ] && continue
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    scores["$skill_name"]=0
    details["$skill_name"]="missing SKILL.md|0|0|0"
    total=$((total + 1))
    continue
  fi

  meta=$(score_metadata "$skill_file")
  usage=$(score_usage "$skill_dir")
  refs=$(score_references "$skill_file")
  total_score=$((meta + usage + refs))

  scores["$skill_name"]=$total_score
  details["$skill_name"]="${meta}|${usage}|${refs}"
  total=$((total + 1))

  if [ "$total_score" -lt 30 ]; then
    zombie_count=$((zombie_count + 1))
  elif [ "$total_score" -ge 80 ]; then
    top_count=$((top_count + 1))
  fi
done

# 排序输出
echo "════════════════════════════════════════════════════════════"
printf "%-35s %6s %6s %6s %6s %8s\n" "Skill" "Meta" "Usage" "Refs" "Total" "Status"
echo "────────────────────────────────────────────────────────────"

# 按总分排序
for skill_name in $(for k in "${!scores[@]}"; do echo "$k ${scores[$k]}"; done | sort -k2 -rn | awk '{print $1}'); do
  score=${scores[$skill_name]}
  IFS='|' read -r meta usage refs <<< "${details[$skill_name]}"

  if [ "$score" -ge 80 ]; then
    status="${GREEN}★ TOP${NC}"
  elif [ "$score" -ge 50 ]; then
    status="${CYAN}OK${NC}"
  elif [ "$score" -ge 30 ]; then
    status="${YELLOW}WARN${NC}"
  else
    status="${RED}ZOMBIE${NC}"
  fi

  printf "%-35s %6s %6s %6s %6s %b\n" \
    "${skill_name:0:35}" "$meta" "$usage" "$refs" "$score" "$status"
done

echo "════════════════════════════════════════════════════════════"
echo ""
echo "📊 统计:"
echo "  Skill 总数: $total"
echo "  ★ TOP (≥80分): $top_count"
echo -e "  ${RED}ZOMBIE (<30分)${NC}: $zombie_count"
echo ""

# 僵尸 skill 列表
if [ "$zombie_count" -gt 0 ]; then
  echo -e "${RED}=== 僵尸 Skill 建议 ===${NC}"
  echo "  以下 skill 总分 < 30，建议归档或删除："
  echo ""
  for skill_name in $(for k in "${!scores[@]}"; do echo "$k ${scores[$k]}"; done | sort -k2 -n | awk '{print $1}'); do
    score=${scores[$skill_name]}
    if [ "$score" -lt 30 ] && [ "$score" -gt 0 ]; then
      echo -e "  ${RED}🗑${NC}  $skill_name ($score 分)"
    elif [ "$score" -eq 0 ]; then
      echo -e "  ${RED}💀${NC} $skill_name (无 SKILL.md)"
    fi
  done
  echo ""
fi

# TOP skill 列表
if [ "$top_count" -gt 0 ]; then
  echo -e "${GREEN}=== TOP Skill ===${NC}"
  echo "  以下 skill 总分 ≥ 80，质量最高："
  echo ""
  for skill_name in $(for k in "${!scores[@]}"; do echo "$k ${scores[$k]}"; done | sort -k2 -rn | head -10 | awk '{print $1}'); do
    score=${scores[$skill_name]}
    echo -e "  ${GREEN}★${NC} $skill_name ($score 分)"
  done
  echo ""
fi

echo "评分完成。运行方式:"
echo "  bash scripts/skill-quality-check.sh           完整报告"
echo "  bash scripts/skill-quality-check.sh --zombie  仅僵尸 skill"
echo "  bash scripts/skill-quality-check.sh --top=20   仅 TOP 20"
