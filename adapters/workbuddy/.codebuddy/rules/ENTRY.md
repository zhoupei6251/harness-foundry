---
name: harness-foundry-entry
description: "Harness Foundry 入口规则：WorkBuddy 平台统一入口"
alwaysApply: true
---

# Harness Foundry 入口（WorkBuddy）

## 优先级

1. `harness-foundry/core/intent-routing.md`（每个会话第一个读）
2. 本文件
3. `harness-foundry/core/NEVER.md`（硬性禁止项）
4. `harness-foundry/core/principles.md`（10 条核心原则）

## 强制声明

每任务首句：`「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`
（见 `harness-foundry/core/intent-routing.md` 路由表）

## Skills 加载路径

WorkBuddy 原生支持 Anthropic Agent Skills 开放标准：

1. `.agents/skills/<slug>/SKILL.md`（项目，与 Claude/Codex 共用投影）
2. `skills/`（工作区）
3. `~/.workbuddy/skills/`（用户全局）

## 并行派发

Team Mode：主控 Orchestrator + Worker（`task` / `team_create` / `send_message`），harness 默认 ≤5 Worker。

## 阶段门禁

| 阶段 | 动作 | 门禁 |
|------|------|------|
| 设计 / Spec | `brainstorming` skill | 写产物后暂停，等用户确认 |
| 计划 | `writing-plans` skill | 写产物后暂停，等用户确认 |
| 编码 | 直接执行 | 自主性指令满足后自动进行 |
| 审查 | `requesting-code-review` | 尾盘产物 |

## Bootstrap

```bash
bash harness-foundry/scripts/bootstrap.sh --target workbuddy
```
