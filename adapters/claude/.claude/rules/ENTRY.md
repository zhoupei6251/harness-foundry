---
description: Harness Foundry 入口规则 - Claude Code 平台
globs:
  - "**/*.md"
  - "**/*.txt"
alwaysApply: false
---

# Harness Foundry 入口规则（Claude Code）

> 一套框架，三域共用：代码（code）/ 小说（novel）/ 新闻（news）

## 强制声明

每任务首句必须输出：
```
「Route：<code|novel|news|CEO|"小改动，直接处理">」
```

## 意图路由

加载 `harness-foundry/core/intent-routing.md` 确定当前任务类型和领域。

## 阶段门禁

各域通用：
1. **设计** → 写 spec → 暂停等用户确认
2. **计划** → 写 plan → 暂停等用户确认
3. **实现** → 拆 WU → 并行派兵（≤5）
4. **验证** → 测试/审稿通过
5. **审查** → 五轴审查通过（或最多返修 2 次）
6. **小改动** → Leader 直做，不派兵

域特定门禁见 `harness-foundry/core/intent-routing.md` § 阶段门禁。

## 角色定义

代码域 7 角色：coder / implementer / reviewer / test-engineer / explorer / debugger / web-investigator

小说域 8 角色：leader / writer / planner / reviewer / humanizer / researcher / editor / memory-keeper

定义位置：`harness-foundry/agents/*.md`

## 技能加载

按 `harness-foundry/core/orchestration/skill-preferences.md` 路由表加载。

真相源路径：`harness-foundry/skills/<slug>/SKILL.md`

## 禁止项

详见 `harness-foundry/core/NEVER.md`

## 多 WU 并行

满足任一条件走 dispatcher：
- plan 包含 ≥2 个 WU
- 用户说"开始实现" / "并行实现"
- 连续写 ≥2 章（novel 域）

调度流程：`harness-foundry/core/orchestration/dispatcher-workflow.md`

## 记忆管理

- 全局记忆：`~/.claude/GLOBAL-MEMORY.md`
- 项目记忆：`MEMORY.md`（项目根目录）

会话开始：读全局记忆 + 项目记忆
会话结束：同步记忆

## 平台限制

- 并行上限：≤5
- worktree 沙箱：支持（code 域，`harness-foundry/scripts/harness-worktree.sh`）
- novel/news 域：local provider，无 worktree
- StructuredAsk：degraded — 使用对话式确认
- hooks.json：manual — 用户本地配置
