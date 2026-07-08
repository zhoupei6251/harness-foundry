#!/bin/bash

# Ralph Loop Setup Script — Harness Foundry 适配版
# 来源: reference_github/claude-code/plugins/ralph-wiggum/scripts/setup-ralph-loop.sh
#
# 创建 .claude/ralph-loop.local.md 状态文件，激活 Stop Hook 拦截
#
# 用法:
#   bash hooks/ralph-loop/setup-ralph-loop.sh "任务描述" --completion-promise "DONE" --max-iterations 50
#   bash hooks/ralph-loop/setup-ralph-loop.sh --help

set -euo pipefail

# ── 解析参数 ──
PROMPT_PARTS=()
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Ralph Loop — 自指循环开发，防 AI 偷懒

USAGE:
  /ralph-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    任务描述（支持多词，无需引号）

OPTIONS:
  --max-iterations <n>           最大迭代次数后强制停止（默认: unlimited，0 = 无限）
  --completion-promise '<text>'  完成时必须输出的承诺语（多词请加引号）
  -h, --help                     显示此帮助

DESCRIPTION:
  启动 Ralph Loop。Stop Hook 将拦截会话退出，未完成时反复将同一 prompt
  重新喂入，直到 Completion Promise 满足或达到 Max Iterations。

  要退出循环，AI 必须输出: <promise>承诺语</promise>

  适用场景:
  - 需要多轮迭代和自纠错的任务
  - 有明确完成标准（测试通过、Linter 零警告）
  - 可自动验证结果的任务

EXAMPLES:
  /ralph-loop Build a todo API --completion-promise 'DONE' --max-iterations 20
  /ralph-loop --max-iterations 10 修复 auth bug
  /ralph-loop 重构缓存层  （无限运行，必须手动 rm 状态文件退出）
  /ralph-loop --completion-promise 'TASK COMPLETE' 创建 REST API

STOPPING:
  只有两个出口: 达到 --max-iterations 或检测到 --completion-promise
  没有手动停止！Ralph 默认无限运行！

MONITORING:
  # 查看当前 iteration:
  grep '^iteration:' .claude/ralph-loop.local.md

  # 查看完整状态:
  head -10 .claude/ralph-loop.local.md

  紧急取消:
  rm .claude/ralph-loop.local.md
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --max-iterations requires a number argument" >&2
        echo "   Valid: --max-iterations 10  |  --max-iterations 0 (unlimited)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "❌ Error: --completion-promise requires a text argument" >&2
        echo "   Valid: --completion-promise 'DONE'  |  --completion-promise 'TASK COMPLETE'" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    *)
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# ── 校验 prompt 非空 ──
PROMPT="${PROMPT_PARTS[*]}"
if [[ -z "$PROMPT" ]]; then
  echo "❌ Error: No prompt provided" >&2
  echo "" >&2
  echo "   Ralph needs a task description to work on." >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /ralph-loop Build a REST API for todos" >&2
  echo "     /ralph-loop Fix the auth bug --max-iterations 20" >&2
  echo "     /ralph-loop --completion-promise 'DONE' Refactor code" >&2
  echo "" >&2
  echo "   For all options: /ralph-loop --help" >&2
  exit 1
fi

# ── 创建状态文件 ──
mkdir -p .claude

# 为 YAML 准备 completion_promise 值
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

cat > .claude/ralph-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

$PROMPT
EOF

# ── 输出启动信息 ──
cat <<EOF
🔄 Ralph loop activated!

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE//\"/} (ONLY output when TRUE — do not lie!)"; else echo "none (runs forever)"; fi)

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.

To monitor: head -10 .claude/ralph-loop.local.md

⚠️  WARNING: This loop cannot be stopped manually! It will run infinitely
    unless you set --max-iterations or --completion-promise.

🔄
EOF

# 输出初始 prompt
if [[ -n "$PROMPT" ]]; then
  echo ""
  echo "$PROMPT"
fi

# 如果有 completion promise，输出关键提醒
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "CRITICAL — Ralph Loop Completion Promise"
  echo "═══════════════════════════════════════════════════════════"
  echo ""
  echo "To complete this loop, output this EXACT text:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "STRICT REQUIREMENTS (DO NOT VIOLATE):"
  echo "  ✓ Use <promise> XML tags EXACTLY as shown above"
  echo "  ✓ The statement MUST be completely and unequivocally TRUE"
  echo "  ✓ Do NOT output false statements to exit the loop"
  echo "  ✓ Do NOT lie even if you think you should exit"
  echo ""
  echo "IMPORTANT — Do not circumvent the loop:"
  echo "  Even if you believe you're stuck, the task is impossible,"
  echo "  or you've been running too long — you MUST NOT output a"
  echo "  false promise statement. The loop is designed to continue"
  echo "  until the promise is GENUINELY TRUE. Trust the process."
  echo ""
  echo "  If the loop should stop, the promise statement will become"
  echo "  true naturally. Do not force it by lying."
  echo "═══════════════════════════════════════════════════════════"
fi
