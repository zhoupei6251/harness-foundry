---
name: routing-compat
description: "兼容别名：旧文档引用 `core/routing.md` 的入口。真相源已迁移至 `core/intent-routing.md`，本文件仅保留以避免散落在 agents/、orchestration/、docs/ 中的 30+ 处引用全部失效。"
tags: [Rules]
---

# 意图路由（兼容别名）

> **真相源：[`intent-routing.md`](./intent-routing.md)**
>
> 本文件仅为兼容旧引用保留。下游文档若仍写 `harness-kit/core/routing.md`，自动指向 [intent-routing.md](./intent-routing.md)。
>
> **新文档请直接引用 `core/intent-routing.md`。**

## 单一真相源

所有平台共用的意图路由表、阶段门禁、Token 节流策略见：

```
harness-kit/core/intent-routing.md
```

包含：

- 意图路由表（design / plan / implement / quick-fix / review / test / git / research）
- Never 清单索引（指向 `NEVER.md`）
- Token 节流策略（按任务类型决定读什么）
- 阶段门禁（不可跳过）
- 各平台调用方式（Claude Code / Cursor / Trae / Codex）

## 阶段指定 skill 必用（与 intent-routing.md § 阶段门禁 一致）

| 阶段 | 必 Load 的 skill |
|------|-----------------|
| design | `brainstorming` |
| plan | `writing-plans` |
| implement | `harness-orchestration`（Trae）/ `cursor-orchestration`（Cursor）/ `/claude-orchestration`（Claude Code）|
| verify | `verification-before-completion` |
| review | `requesting-code-review` / `code-review` |
| git | `git-xywh` |

## 沟通语言

中文（与 intent-routing.md § 沟通语言 一致）。

## 维护说明

历史原因：早期版本路由表写在 `core/routing.md`，后拆出 `intent-routing.md` 但未迁移所有引用。本文件作为兼容层。

**下一步可清理**：把 `agents/`、`core/orchestration/`、`docs/superpowers/specs/`、`skills/`、`adapters/agents/AGENTS.md` 中所有对 `core/routing.md` 的引用改为 `core/intent-routing.md`，然后删除本文件。