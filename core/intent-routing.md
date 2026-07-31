---
name: intent-routing
description: "意图路由表：听到同样的话，所有平台做同样的事。包含 Never 清单索引。"
tags: [Rules, Runbook]
---

# 意图路由表（单一真相源）

> 所有平台共用。听到同样的话 → 做同样的事。
> 规则分类：Rules（声明式）/ Runbooks（按需过程）/ Memories（经验积累）
>
> **本路由表是地图，不是牢房。** 大型任务用它导航走门禁；小改动声明 Route 后直接处理，无需逐条对表。当 AI 在本会话已通过其他方式继承了项目上下文时，不必为了"合规"而重复加载已加载过的 skill。

## 意图路由

只要用户的话里**包含**下表任一关键词，就匹配该意图。

| 用户说的话 | 意图 | 动作 |
|-----------|------|------|
| 设计、方案、怎么搞、怎么弄、架构、选型 | design | `/brainstorming` → 写 spec → **暂停等确认** |
| 计划、拆分、列出任务、WBS、排期 | plan | `/writing-plans` → 写 plan → **暂停等确认** |
| OK、可以、开始、做吧、执行、就按这个、批准了 | implement | 拆 WU → 并行派兵 |
| 写代码、实现、重构、加功能、写个、帮我写 | code-write | `/karpathy-guidelines` + `/springboot-patterns` FIRST → TDD → `/simplify` + `/silent-failure-hunter` → ecc 三合一 review |
| 修、bug、改一下、加行日志、改个名、空指针、小问题 | quick-fix | Leader 直改，不派兵（仍须 karpathy-guidelines + springboot-patterns） |
| 调试、排查、debug、为什么、不工作、报错 | debug | `/systematic-debugging` FIRST → 复现→定位→修复 |
| 测试、单测、E2E、写test、补测试 | test | `/test-driven-development` |
| 审查、review、code review | review | `/java-reviewer` ∥ `/security-reviewer` ∥ `/database-reviewer`（ecc 三合一并行审查） |
| 简化、精简、清理、优化代码 | simplify | `/simplify` + `/silent-failure-hunter`（写后自查简洁度 + 静默失败） |
| 安全重构、重构但、不改行为 | safe-refactor | `/refactor-safely` |
| commit、merge、rebase、push、MR | git | `/git-xywh` |
| 查、搜、调研、资料、怎么回事 | research | WebSearch → WebFetch |
| 写小说、写章节、续写、大纲、分卷 | novel | `/novel-guidelines` FIRST → 36-beats → writer |
| 情节矛盾、角色冲突、伏笔遗漏 | novel-debug | `/novel-debug` → 排查 → 修复 |
| 章节自查、简洁度检查 | novel-simplify | `/novel-simplify` → 写后审稿前自查 |
| 审稿、评分、评价小说 | novel-review | `/novel-evaluator` |
| 返修、小改、章节修改 | novel-revision | `/novel-safe-revision` → 小步返修 |
| 润色、去AI味、文风清洗 | novel-polish | `/humanizer-zh` |
| 写新闻、写稿、新闻稿、报道 | news-write | `/news-generator` → fact-check → polish |
| 事实核查、核实新闻、验证信息 | fact-check | `/fact-check`（新闻域必做） |
| 新闻编辑、审校、排版 | news-edit | `/news-polish` → news-editor |
| 卖给、产品化、大学生、前端页面、后端接口 | product | `/brainstorming` → 场景路由 → **code 域前端/后端交付** |

## Never 清单

Read `harness-foundry/core/NEVER.md` — 所有禁止项的详细说明。

## Token 节流策略

**按任务类型决定读什么，不要每次全读。**

| 任务类型 | 必读 | 可选 | 可跳 |
|----------|------|------|------|
| 小改动（修 typo、改一行） | `NEVER.md` | — | 所有其他 |
| 写新代码 | `karpathy-guidelines.md` + `springboot-patterns.md` + `NEVER.md` | `references/traps.md` | orchestration 层 |
| 改 Spring Boot | `karpathy-guidelines.md` + `springboot-patterns.md` + `NEVER.md` | `references/traps.md` | orchestration 层 |
| 写小说章节 | `novel-orchestrator` + `NEVER.md` | `traps-archive/novel/00-all.md` | orchestration 层 |
| 并行实现 | `dispatcher-workflow.md` | 按角色读 `agents/*.md` | 其他 |
| 写 spec/plan | brainstorming / writing-plans skill | — | orchestration 层 |
| Code Review | `java-reviewer` + `security-reviewer` + `database-reviewer`（ecc 三合一） | — | orchestration 层 |
| 写完自检 | `simplify` + `silent-failure-hunter`（ecc） | — | orchestration 层 |
| 产品交付（卖给大学生等） | `brainstorming` + product 域配置 | `domain-config.yaml` § scenarios | — |

**会话开始只读两件事：**
1. `state.json`（如果存在）— 了解上下文
2. 本文件（intent-routing）— 决定接下来读什么

**不要**在会话开始预读所有文件。只读当前任务需要的。

## 阶段门禁（不可跳过）

1. 写了 spec/plan → **必须暂停**等确认。同轮不改业务代码。
2. 用户确认后 → 才能进入实现阶段。
3. 实现完成 → 尾盘测试 + 审查。

## 各平台调用方式

| 平台 | 编排 | 派兵 |
|------|------|------|
| Claude Code | `/claude-orchestration` | Agent(subagent_type=generalPurpose) |
| Cursor | `/cursor-orchestration` | harness-coder 等 subagent |
| Trae | `/harness-orchestration` | Task(general_purpose_task) |
| Codex | `omx ultrawork` | omx worker |

## 沟通语言

- 对用户：**中文**
- 对子 Agent：中文派发 prompt（固定键名可保留英文）
