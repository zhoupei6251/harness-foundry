#!/bin/bash
# hooks/extract-instincts.sh - 自动提取 instinct
#
# 从 .observations.jsonl 中分析本次会话事件，
# 自动提取有价值的模式/陷阱/经验，
# 写入 references/instincts/project/<id>/instincts/
#
# 用法: bash hooks/extract-instincts.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDRY_DIR="$(dirname "$SCRIPT_DIR")"

# 获取项目标识
get_project_id() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)")
  basename "$root"
}

PROJECT_ID=$(get_project_id)
OBSERVATIONS_FILE="$FOUNDRY_DIR/.observations.jsonl"
INSTINCT_DIR="$FOUNDRY_DIR/references/instincts/project/$PROJECT_ID/instincts"
DATE_STR=$(date +"%Y%m%d")

# 没有 observations 文件则退出
if [ ! -f "$OBSERVATIONS_FILE" ]; then
  exit 0
fi

mkdir -p "$INSTINCT_DIR"

# ============================================
# 规则一：用户纠正模式检测
# ============================================
DETECT_CORRECTION() {
  # 读最近 20 条 observation
  local lines
  lines=$(tail -n 20 "$OBSERVATIONS_FILE" 2>/dev/null || true)
  [ -z "$lines" ] && return

  # 检查是否有修正标记（连续 Edit/Write → 说明用户让 AI 改了东西）
  local edit_count
  edit_count=$(echo "$lines" | grep -c '"tool":"Edit"' 2>/dev/null || echo 0)

  if [ "$edit_count" -ge 2 ]; then
    local instinct_id="instinct-code-${DATE_STR}-correct-${RANDOM}"
    local instinct_file="$INSTINCT_DIR/${instinct_id}.yaml"

    # 去重检查
    if [ -f "$instinct_file" ]; then return; fi

    cat > "$instinct_file" << 'EOF'
id: "INSTINCT_ID_PLACEHOLDER"
domain: code
type: preference
confidence: 0.5
description: "用户倾向于多次修正同一段代码，需要更谨慎的实现方式"
source:
  session_date: "DATE_PLACEHOLDER"
  trigger: "重复模式"
events:
  - type: user_affirmation
    date: "DATE_PLACEHOLDER"
    note: "自动检测到会话中存在多次编辑修正"
tags: ["code-quality", "iteration"]
body: |
  ## 发现
  本次会话中，同一代码区域被多次修改。说明初次实现未完全符合用户期望。

  ## 建议
  - 写复杂逻辑前先确认需求细节
  - 小步提交，每步都请用户确认
EOF

    # 替换占位符
    sed -i "s/INSTINCT_ID_PLACEHOLDER/${instinct_id}/g" "$instinct_file"
    sed -i "s/DATE_PLACEHOLDER/$(date +%Y-%m-%d)/g" "$instinct_file"

    echo "[instinct] 新建: $instinct_id (用户纠正模式)"
  fi
}

# ============================================
# 规则二：重复错误检测
# ============================================
DETECT_REPEATED_ERROR() {
  local lines
  lines=$(tail -n 30 "$OBSERVATIONS_FILE" 2>/dev/null || true)
  [ -z "$lines" ] && return

  # 检查是否有多次 test 运行（说明可能在修 bug）
  local test_count
  test_count=$(echo "$lines" | grep -cE '"tool":".*test"' 2>/dev/null || echo 0)

  local bash_count
  bash_count=$(echo "$lines" | grep -c '"tool":"Bash"' 2>/dev/null || echo 0)

  if [ "$test_count" -ge 3 ] || [ "$bash_count" -ge 5 ]; then
    local instinct_id="instinct-code-${DATE_STR}-debug-${RANDOM}"
    local instinct_file="$INSTINCT_DIR/${instinct_id}.yaml"

    if [ -f "$instinct_file" ]; then return; fi

    cat > "$instinct_file" << 'EOF'
id: "INSTINCT_ID_PLACEHOLDER"
domain: code
type: trap
confidence: 0.45
description: "会话中存在多次测试/运行尝试，可能遇到了反复调试的问题"
source:
  session_date: "DATE_PLACEHOLDER"
  trigger: "重复模式"
events:
  - type: successful_application
    date: "DATE_PLACEHOLDER"
    note: "自动检测到多次测试运行"
tags: ["debugging", "testing"]
body: |
  ## 发现
  本次会话中多次运行测试/Bash 命令，可能在调试某个问题。

  ## 建议
  - 如果问题最终解决，将根因记录到 traps-archive/
  - 如果问题未解决，标记为待调查
EOF

    sed -i "s/INSTINCT_ID_PLACEHOLDER/${instinct_id}/g" "$instinct_file"
    sed -i "s/DATE_PLACEHOLDER/$(date +%Y-%m-%d)/g" "$instinct_file"

    echo "[instinct] 新建: $instinct_id (重复调试模式)"
  fi
}

# ============================================
# 规则三：大范围文件修改检测
# ============================================
DETECT_LARGE_CHANGE() {
  local lines
  lines=$(tail -n 20 "$OBSERVATIONS_FILE" 2>/dev/null || true)
  [ -z "$lines" ] && return

  local write_count
  write_count=$(echo "$lines" | grep -cE '"tool":"(Write|Edit)"' 2>/dev/null || echo 0)

  if [ "$write_count" -ge 5 ]; then
    local instinct_id="instinct-code-${DATE_STR}-scope-${RANDOM}"
    local instinct_file="$INSTINCT_DIR/${instinct_id}.yaml"

    if [ -f "$instinct_file" ]; then return; fi

    cat > "$instinct_file" << 'EOF'
id: "INSTINCT_ID_PLACEHOLDER"
domain: code
type: lesson
confidence: 0.5
description: "大量文件修改，建议拆分为更小的工作单元"
source:
  session_date: "DATE_PLACEHOLDER"
  trigger: "有效方案"
events:
  - type: successful_application
    date: "DATE_PLACEHOLDER"
    note: "自动检测到大量 Write/Edit 操作"
tags: ["workflow", "scope-control"]
body: |
  ## 发现
  本次会话中进行了大量文件写入操作（≥5 次）。

  ## 建议
  - 大任务应拆分成更小的 WU
  - 每个 WU 聚焦 1-3 个文件
  - 减小单次变更范围可以降低错误率
EOF

    sed -i "s/INSTINCT_ID_PLACEHOLDER/${instinct_id}/g" "$instinct_file"
    sed -i "s/DATE_PLACEHOLDER/$(date +%Y-%m-%d)/g" "$instinct_file"

    echo "[instinct] 新建: $instinct_id (大范围修改模式)"
  fi
}

# ============================================
# G-2: learned files 填充
# ============================================
SYNC_LEARNED_FILES() {
  local learned_dir="$FOUNDRY_DIR/references"
  local patterns_file="$learned_dir/learned-patterns.md"
  local traps_file="$learned_dir/learned-traps.md"
  local lessons_file="$learned_dir/lessons-learned.md"

  # 统计各类型 instinct 数量
  local all_instincts
  all_instincts=$(find "$INSTINCT_DIR" -name "*.yaml" 2>/dev/null || true)
  [ -z "$all_instincts" ] && return

  local pattern_count=0 trap_count=0 lesson_count=0
  while IFS= read -r f; do
    case "$(grep "type:" "$f" 2>/dev/null | head -1)" in
      *pattern*)  ((pattern_count++)) ;;
      *trap*)     ((trap_count++)) ;;
      *lesson*)   ((lesson_count++)) ;;
    esac
  done <<< "$all_instincts"

  # pattern ≥ 3 → 追加 learned-patterns.md
  if [ "$pattern_count" -ge 3 ]; then
    if ! grep -q "自动提取 - $(date +%Y-%m-%d)" "$patterns_file" 2>/dev/null; then
      cat >> "$patterns_file" << EOF

## 自动提取 - $(date +%Y-%m-%d)

基于 ${pattern_count} 个 pattern 类型的 instinct 自动生成。

### 关键发现
- 共提取 ${pattern_count} 个代码模式
- 所在项目: ${PROJECT_ID}
- 使用 \`node scripts/instinct-cli.js stats\` 查看详情

### 建议动作
- 审查这些 pattern 是否具有复用价值
- 如果 confidence ≥ 0.7，运行 \`node scripts/instinct-cli.js evolve\` 生成 Skill
EOF
      echo "[learned] 更新 learned-patterns.md (${pattern_count} patterns)"
    fi
  fi

  # trap ≥ 3 → 追加 learned-traps.md
  if [ "$trap_count" -ge 3 ]; then
    if ! grep -q "自动提取 - $(date +%Y-%m-%d)" "$traps_file" 2>/dev/null; then
      cat >> "$traps_file" << EOF

## 自动提取 - $(date +%Y-%m-%d)

基于 ${trap_count} 个 trap 类型的 instinct 自动生成。

### 关键发现
- 共提取 ${trap_count} 个陷阱/错误模式
- 所在项目: ${PROJECT_ID}
- 这些错误重复出现，值得在 NEVER.md 中补充

### 建议动作
- 分析根因并更新 NEVER.md 或 traps-archive/
EOF
      echo "[learned] 更新 learned-traps.md (${trap_count} traps)"
    fi
  fi

  # lesson ≥ 3 → 追加 lessons-learned.md
  if [ "$lesson_count" -ge 3 ]; then
    if ! grep -q "自动提取 - $(date +%Y-%m-%d)" "$lessons_file" 2>/dev/null; then
      cat >> "$lessons_file" << EOF

## 自动提取 - $(date +%Y-%m-%d)

基于 ${lesson_count} 个 lesson 类型的 instinct 自动生成。

### 关键发现
- 共提取 ${lesson_count} 条经验教训
- 所在项目: ${PROJECT_ID}

### 建议动作
- 将高频经验转化为团队最佳实践
EOF
      echo "[learned] 更新 lessons-learned.md (${lesson_count} lessons)"
    fi
  fi
}

# ============================================
# 主流程
# ============================================
echo "[instinct] 开始自动提取..."

DETECT_CORRECTION
DETECT_REPEATED_ERROR
DETECT_LARGE_CHANGE
SYNC_LEARNED_FILES

# 统计
TOTAL_INSTINCTS=$(find "$INSTINCT_DIR" -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
echo "[instinct] 提取完成, 项目 ${PROJECT_ID} 共有 ${TOTAL_INSTINCTS} 条 instinct"
