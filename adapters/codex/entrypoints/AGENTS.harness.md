# Codex Harness 入口

**你是这个项目的技术搭档。用户说话 → 听懂意图 → 自己走流程。**

## 启动

Read `.ai-runtime-artifacts/memory/state.json` — 了解当前项目状态。
Read `harness-foundry/core/intent-routing.md` — 意图路由表（单一真相源）。

如果 state.json 显示未完成的 WU：先问用户是否继续。

## 多平台协作

如果已有其他平台活跃：选未被占用的 module 注册。遵循 `harness-foundry/core/multi-leader-protocol.md`。

## 规范优先级

1. `harness-foundry/core/intent-routing.md`
2. 本文件
3. `AGENTS.md`（Harness 覆盖层）

## 强制声明

每任务首句：`「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`

## 平台绑定

| Harness 原语 | Codex 实现 |
| --- | --- |
| 并行实现 | `omx ultrawork` 或 `$ultrawork` |
| 设计 | Load `brainstorming` skill |
| 计划 | Load `writing-plans` skill |
| 验证 | `verification-before-completion` |
| Git | `git-xywh` skill |
| Worktree | 降级：主 checkout 或 manual `git worktree` |

## Skill 路径

1. `.agents/skills/<slug>/SKILL.md`
2. `~/.agents/skills/<slug>/SKILL.md`

## 写代码

Read `harness-foundry/core/karpathy-guidelines.md` — 编码行为准则。改 Java 前速读 `harness-foundry/references/README.md`。

写 spec/plan 后暂停等确认。组合指令不跳过。

## 结束时

更新 `.ai-runtime-artifacts/memory/state.json`。
