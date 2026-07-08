#!/bin/bash

# Ralph Loop Stop Hook — Harness Foundry 适配版
# 来源: reference_github/claude-code/plugins/ralph-wiggum/hooks/stop-hook.sh
#
# 当 .claude/ralph-loop.local.md 存在时，拦截会话退出：
#   1. 检查 completion promise 是否在最后输出中 → 放行
#   2. 检查 max iterations 是否达到 → 放行
#   3. 都没满足 → 重新喂入原 prompt，block 退出
#
# Claude Code Stop Hook API:
#   - exit 0 + stdout: {"decision":"block","reason":"<prompt>"} → 拦截退出
#   - exit 0 + stdout 为空或无 block → 放行退出

set -euo pipefail

# 读取 hook 输入（advanced stop hook API 通过 stdin 传入 JSON）
HOOK_INPUT=$(cat)

# 状态文件路径
RALPH_STATE_FILE=".claude/ralph-loop.local.md"

# 没有活跃的 ralph loop → 放行
if [[ ! -f "$RALPH_STATE_FILE" ]]; then
  exit 0
fi

# ── JSON 解析工具选择 ──
# jq 优先，不可用时 fallback 到 python3（Windows 兼容）
json_parse() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r "$field" 2>/dev/null || echo ""
  else
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('${field#.}',''))" 2>/dev/null || echo ""
  fi
}

# ── 解析 frontmatter ──
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$RALPH_STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# ── 校验数值字段 ──
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted (iteration='$ITERATION')" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️  Ralph loop: State file corrupted (max_iterations='$MAX_ITERATIONS')" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# ── 检查 max iterations ──
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Ralph loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# ── 获取 transcript 路径 ──
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | json_parse ".transcript_path")

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Ralph loop: Transcript file not found: $TRANSCRIPT_PATH" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# ── 提取最后一条 assistant 消息 ──
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "⚠️  Ralph loop: No assistant messages in transcript" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️  Ralph loop: Failed to extract last assistant message" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# ── 从 transcript JSONL 中提取最后一条 assistant 消息的文本内容 ──
extract_assistant_text() {
  local json_line="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$json_line" | jq -r '
      .message.content |
      map(select(.type == "text")) |
      map(.text) |
      join("\n")
    ' 2>/dev/null || echo ""
  else
    echo "$json_line" | python3 -c "
import sys, json
try:
    msg = json.loads(sys.stdin.read())
    content = msg.get('message', {}).get('content', [])
    texts = [c['text'] for c in content if isinstance(c, dict) and c.get('type') == 'text']
    print('\n'.join(texts))
except Exception:
    print('')
" 2>/dev/null || echo ""
  fi
}

LAST_OUTPUT=$(extract_assistant_text "$LAST_LINE")

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️  Ralph loop: Assistant message contained no text content" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# ── 检查 completion promise ──
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  # 从输出中提取 <promise>...</promise> 标签内的文本
  # -0777: slurp entire input; s: . matches newline; .*?: non-greedy first match
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  # 用 = 做字面量比较（== 在 [[ ]] 中做 glob pattern 匹配，* / ? / [ 会出问题）
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "✅ Ralph loop: Detected <promise>$COMPLETION_PROMISE</promise>"
    rm "$RALPH_STATE_FILE"
    exit 0
  fi
fi

# ── 未完成 → 自增 iteration，重新喂入 prompt ──
NEXT_ITERATION=$((ITERATION + 1))

# 提取 prompt body（第二个 --- 之后的所有内容）
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$RALPH_STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️  Ralph loop: No prompt text found in state file" >&2
  rm "$RALPH_STATE_FILE"
  exit 0
fi

# 更新 iteration 计数（兼容 macOS / Linux）
TEMP_FILE="${RALPH_STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$RALPH_STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$RALPH_STATE_FILE"

# 构建系统消息
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION | 输出 <promise>$COMPLETION_PROMISE</promise> 即可退出（仅在陈述为真时！禁止撒谎逃逸！）"
else
  SYSTEM_MSG="🔄 Ralph iteration $NEXT_ITERATION | 无 completion promise — 循环至 max iterations"
fi

# 输出 block decision，重新喂入 prompt（JSON 生成，同样兼容 jq/python3）
if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg prompt "$PROMPT_TEXT" \
    --arg msg "$SYSTEM_MSG" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }'
else
  python3 -c "
import sys, json
prompt = sys.argv[1]
msg = sys.argv[2]
print(json.dumps({
    'decision': 'block',
    'reason': prompt,
    'systemMessage': msg
}, ensure_ascii=False))
" "$PROMPT_TEXT" "$SYSTEM_MSG"
fi

exit 0
