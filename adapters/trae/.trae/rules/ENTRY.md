name: harness-foundry
description: "Harness Foundry 入口规则：Trae 平台统一入口"

# Harness Foundry 入口（Trae）

## 优先级

1. `harness-foundry/core/intent-routing.md`
2. 本文件
3. `.trae/rules/harness-routing.md`
4. `.trae/rules/back-rule.md`（后端 Java 规范，通用）

## 快速参考

Read `harness-foundry/adapters/trae/trae-quick-ref.md`

## 强制声明

每任务首句：`「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`（见 `core/intent-routing.md`）

## 按 routing 加载

与 `intent-routing.md` § 阶段指定 skill 必用 相同。

Trae Skill 路径：

1. `.trae/skills/<slug>/SKILL.md`
2. `~/.trae/skills/<slug>/SKILL.md`
3. `.agents/skills/<slug>/SKILL.md`

## 子 Agent

7 角色：coder / implementer / reviewer / test-engineer / explorer / debugger / web-investigator
定义见 `harness-foundry/agents/*.md`

## 与 Cursor 差异

- 无 worktree 沙箱（主 checkout）
- 编排 skill：`harness-orchestration`（非 cursor-orchestration）
- 并行通过 Task，≤5

## Bootstrap

```bash
bash harness-foundry/scripts/bootstrap.sh --target trae
```
