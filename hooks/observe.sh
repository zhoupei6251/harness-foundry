#!/bin/bash
# hooks/observe.sh - Instinct 捕获辅助脚本
# 记录工具调用事件到 .observations.jsonl，供 instinct 提取使用
#
# 用法:
#   bash hooks/observe.sh pre <tool_name>   # PreToolUse 阶段
#   bash hooks/observe.sh post <tool_name>  # PostToolUse 阶段
#   bash hooks/observe.sh stop              # Stop 阶段（清理）
#   bash hooks/observe.sh stats             # 查看统计

set -euo pipefail

PHASE="${1:-}"
TOOL="${2:-}"

# 获取项目标识
get_project_id() {
  local root
  root=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  basename "$root"
}

PROJECT_ID=$(get_project_id)
OBSERVATIONS_FILE=".observations.jsonl"
INSTINCT_DIR="references/instincts/project/$PROJECT_ID/instincts"

case "$PHASE" in
  pre)
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
    echo "{\"timestamp\":\"$TIMESTAMP\",\"project\":\"$PROJECT_ID\",\"tool\":\"$TOOL\",\"phase\":\"pre\"}" >> "$OBSERVATIONS_FILE"
    ;;
  post)
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
    echo "{\"timestamp\":\"$TIMESTAMP\",\"project\":\"$PROJECT_ID\",\"tool\":\"$TOOL\",\"phase\":\"post\"}" >> "$OBSERVATIONS_FILE"
    ;;
  stop)
    mkdir -p "$INSTINCT_DIR"
    # 压缩过大的 observations 文件（保留最近 100 条）
    if [ -f "$OBSERVATIONS_FILE" ]; then
      LINE_COUNT=$(wc -l < "$OBSERVATIONS_FILE" 2>/dev/null || echo 0)
      if [ "$LINE_COUNT" -gt 100 ]; then
        tail -n 100 "$OBSERVATIONS_FILE" > "${OBSERVATIONS_FILE}.tmp"
        mv "${OBSERVATIONS_FILE}.tmp" "$OBSERVATIONS_FILE"
      fi
    fi
    # 输出统计信息
    INSTINCT_COUNT=$(find "$INSTINCT_DIR" -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
    echo "Instinct 统计: project=$PROJECT_ID, count=$INSTINCT_COUNT"
    ;;
  stats)
    echo "=== Instinct 统计 ==="
    echo "项目: $PROJECT_ID"
    
    if [ -d "$INSTINCT_DIR" ]; then
      COUNT=$(find "$INSTINCT_DIR" -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
      echo "项目 instinct 数量: $COUNT"
    else
      echo "项目 instinct 数量: 0 (目录不存在)"
    fi
    
    GLOBAL_DIR="references/instincts/global/instincts"
    if [ -d "$GLOBAL_DIR" ]; then
      GLOBAL_COUNT=$(find "$GLOBAL_DIR" -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
      echo "全局 instinct 数量: $GLOBAL_COUNT"
    else
      echo "全局 instinct 数量: 0"
    fi
    
    if [ -f "$OBSERVATIONS_FILE" ]; then
      OBS_COUNT=$(wc -l < "$OBSERVATIONS_FILE" 2>/dev/null || echo 0)
      echo "Observations 记录数: $OBS_COUNT"
    else
      echo "Observations 记录数: 0"
    fi
    ;;
  *)
    echo "用法: bash hooks/observe.sh {pre|post|stop|stats} [tool_name]"
    exit 1
    ;;
esac
