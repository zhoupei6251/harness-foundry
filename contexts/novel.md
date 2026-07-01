# 小说创作场景

Mode: 小说写作、大纲规划、章节续写
Focus: 先有骨架，再填血肉，最后润色

## 行为准则
- 先写正文，后解释
- 优先情节推进，不追求文笔华丽
- 写完立即自检（AI 痕迹、人设一致性）
- 每章结尾留钩子

## 优先级
1. 情节推进（故事往前走）
2. 人设一致（角色不崩）
3. 文笔自然（去 AI 味）

## 致命陷阱（82 条）
详见 `traps-archive/novel/00-all.md`

## 推荐工具
- junli-ai-novel — 长篇写作引擎
- novel-orchestrator — 小说创作总控调度器（禁止用 harness-orchestration）
- novel-evaluator — 7维审稿评分
- humanizer-zh — 轻量润色去 AI 味
- novel-ai-wash — 深度文风清洗

## 阶段门禁（6 阶段）

| 阶段 | 动作 | 门禁 |
|------|------|------|
| 0. 开书 | brainstorming 产出 spec | 用户确认设定/题材/风格 |
| 1. 规划 | planner 产出大纲 + 人物设定 | 用户确认大纲 |
| 2. 正文 | writer 逐章写作（≥2000字） | 自检（字数 + AI套路） |
| 3. 审稿 | reviewer 7维评分 + 逐条举证 | ≥70分通过，否则返修（最多2次） |
| 4. 润色 | humanizer 文风清洗 | 润色完成 + 质量检查 |
| 5. 统稿 | editor 跨章一致性检查 | 人物称呼/时间线/伏笔统一 |
| 6. 记忆 | memory-keeper 更新双轨记忆 | 自动执行 |

## 角色链

```
用户 → leader-novel → novelist-orchestrator
                          ↓
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
     novel-planner   novel-writer   shared-researcher
          ↓              ↓              ↓
     大纲/人物设定     章节正文       素材考据
          ↓              ↓              ↓
          └──────────────┼──────────────┘
                          ↓
                   novel-reviewer
                          ↓ (7维评分 ≥70分)
                          ↓
                     humanizer
                          ↓ (文风清洗)
                          ↓
                        editor
                          ↓ (跨章一致性)
                          ↓
                    memory-keeper
                          ↓
                        用户
```

## 禁止事项

- ❌ Leader 主线程直接写正文（小改动 <200字 除外）
- ❌ 未过阶段门禁就推进下一阶段
- ❌ 用 harness-orchestration 处理小说（必须用 novel-orchestrator）
- ❌ 引用不存在的 skill（novel-writing、novel-writer-structure、memory-bank 均不存在）
- ❌ AI 套路化表达（见 NEVER.md）
- ❌ 半角标点（必须全角：，。？！……）

## 产物目录

```
.novel-runtime-artifacts/
├── plans/              # 大纲/规划产物
├── reviews/            # 审稿报告
├── execution-logs/     # 执行日志
章节正文/
├── 第XXX章_标题.md
├── MEMORY.md           # 单书记忆
└── 大纲.md
```