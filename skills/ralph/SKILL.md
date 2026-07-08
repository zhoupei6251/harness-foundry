---
name: ralph
description: Ralph Loop — 自指循环开发，Stop Hook 拦截会话退出，强制 AI 循环生成直到 Completion Promise 满足或达到最大迭代次数。防 AI 偷懒神器。
metadata:
  openclaw:
    emoji: 🔄
    user-invocable: true
version: 1.0.0
when_to_use: 需要防 AI 偷懒、强制循环生成直到真正完成、避免提前收工或敷衍输出时
status: peripheral
tags:
- ralph
- loop
- quality
- anti-laziness
domain: code
category: code.architecture
---

# Ralph Loop — 防 AI 偷懒循环

> "Ralph is a Bash loop." — Geoffrey Huntley

Ralph Loop 通过 **Stop Hook 拦截机制**，阻止 AI 在任务未完成时退出会话。每次 AI 试图收工，Hook 都会检查是否达到完成条件，未达到则**将同一个 prompt 重新喂入**，形成自指循环，直到任务真正完成。

## 核心原理

```
用户启动 /ralph-loop "任务描述" --completion-promise "DONE"
     │
     ▼
┌─────────────────────────────────────────────┐
│ 1. AI 执行任务                                │
│ 2. AI 尝试退出会话                            │
│ 3. Stop Hook 拦截 → 检查是否满足完成条件       │
│    ├── Completion Promise 满足? → ✅ 放行退出  │
│    ├── 达到 Max Iterations?   → 🛑 强制停止   │
│    └── 都不满足               → 🔄 重新喂 prompt │
│ 4. GOTO 1                                    │
└─────────────────────────────────────────────┘
```

### 两个退出阀

| 机制 | 说明 |
|------|------|
| **Completion Promise** | AI 必须输出 `<promise>承诺语</promise>` 才能退出。承诺语必须**完全真实**——禁止为逃出循环而说谎 |
| **Max Iterations** | 硬上限，防止无限循环。推荐始终设置 |

### 为什么有效

- **Prompt 不变**：每次循环 AI 看到的是相同的任务描述
- **文件累积**：AI 上次的工作留在文件中，下次可见
- **Git 历史**：每次迭代的改动可通过 git 追溯
- **自纠错**：AI 能读到自己的输出和文件，从而发现并修正问题

## 使用方式

### 基本用法

```bash
/ralph-loop "构建一个 REST API，包含 CRUD、输入验证、测试。完成后输出 <promise>COMPLETE</promise>" \
  --completion-promise "COMPLETE" \
  --max-iterations 50
```

### 参数

| 参数 | 必需 | 说明 |
|------|------|------|
| `PROMPT` | ✅ | 任务描述（支持多词，无需引号） |
| `--max-iterations N` | 推荐 | 最大迭代次数后强制停止（0 = 无限） |
| `--completion-promise 'TEXT'` | 推荐 | AI 完成时必须输出的承诺语 |
| `-h, --help` | — | 显示帮助 |

### 无承诺语的纯循环

```bash
/ralph-loop --max-iterations 20 "修复所有 ESLint warning 并确保测试通过"
```

无 Completion Promise 时，只能通过 `--max-iterations` 停止（无法手动取消）。

### Prompt 最佳实践

**❌ 坏的 Prompt：**
```
Build a todo API and make it good.
```

**✅ 好的 Prompt：**
```markdown
Build a REST API for todos.

When complete:
- All CRUD endpoints working
- Input validation in place
- Tests passing (coverage > 80%)
- README with API docs
- Output: <promise>COMPLETE</promise>
```

### 逃生舱口

如果任务确实无法在当前条件下完成，在 Prompt 中加入处理逻辑：

```markdown
After 15 iterations, if not complete:
- Document what's blocking progress
- List what was attempted
- Suggest alternative approaches
- Output: <promise>BLOCKED</promise>
```

## 监控

```bash
# 查看当前迭代次数
grep '^iteration:' .claude/ralph-loop.local.md

# 查看完整状态
head -10 .claude/ralph-loop.local.md
```

## 强制取消

```bash
# 如果误入循环或需要紧急停止
rm .claude/ralph-loop.local.md
```

## 适用场景

**适合：**
- 有明确完成标准的任务（测试通过、linter 零警告）
- 需要多轮迭代和自纠错的任务
- 可自动验证结果的任务
- 绿field 项目，可以放手让 AI 自己跑

**不适合：**
- 需要人类判断或设计决策的任务
- 一次性操作
- 完成标准模糊的任务
- 生产环境调试（用 targeted debugging）

## 参考

- 原始技术: https://ghuntley.com/ralph/
- Ralph Orchestrator: https://github.com/mikeyobrien/ralph-orchestrator
- 参考实现: `reference_github/claude-code/plugins/ralph-wiggum/`
