# Harness Foundry — 统一入口规则

> 架构：用户 → Domain Leader → Worker（无 handoff 文件传递）
> 三域共用：code（代码）/ novel（小说）/ news（新闻）

## 强制声明

每轮首句必须含：`「Route：<code|novel|news|CEO|"小改动，直接处理">」`
无声明 = 违规。

## 优先级

1. `core/intent-routing.md` — 路由规则表
2. 本文件
3. `core/orchestration/dispatcher-workflow.md`

## 路由

路由规则见 `core/intent-routing.md`。当前会话 AI 担任 Domain Leader，直接对用户负责。

Leader 接收用户需求 → 路由判定 → 拆 WU → 派兵 → 整合 → 汇报用户。

## 阶段门禁

各域通用：
1. **设计** → 写 spec → 暂停等用户确认
2. **计划** → 写 plan → 暂停等用户确认
3. **实现** → 拆 WU → 并行派兵（≤5）
4. **验证** → 测试/审稿通过
5. **审查** → 五轴审查通过（或最多返修 2 次）
6. **小改动** → Leader 直做，不派兵

域特定门禁见 `core/intent-routing.md` § 阶段门禁。

## 角色定义

定义位置：`agents/*.md`

按 `core/orchestration/domain-config.yaml` 分域加载。

## 技能加载

按 `core/orchestration/skill-preferences.md` 路由表加载。

真相源路径：`skills/<slug>/SKILL.md`

## 禁止项

详见 `core/NEVER.md`

## 多 WU 并行

满足任一条件走 dispatcher：
- plan 包含 ≥2 个 WU
- 用户说"开始实现" / "并行实现"
- 连续写 ≥2 章（novel 域）

调度流程：`core/orchestration/dispatcher-workflow.md`

## 记忆管理

- 全局记忆：`~/.claude/GLOBAL-MEMORY.md`
- 项目记忆：`MEMORY.md`（项目根目录）

会话开始：读全局记忆 + 项目记忆
会话结束：同步记忆

## 平台限制

- 并行上限：≤5
- worktree 沙箱：支持（code 域，`scripts/harness-worktree.sh`）
- novel/news 域：local provider，无 worktree
- StructuredAsk：degraded — 使用对话式确认
- hooks.json：manual — 用户本地配置

## 与旧版差异

- 三域共用一套框架
- 编排通过 domain-config.yaml
- 以"项目/书/新闻集"为单位
- 原 harness-ink 已合并，不再维护独立框架
