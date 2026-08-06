# Harness Foundry — Codex 入口

> 由 `bootstrap.sh --target codex` 投影生成。真相源在 `harness-foundry/adapters/codex/`。

## 加载

本文件是 Codex 会话入口。完整覆盖层见（按需加载，勿内联——AGENTS.md 链有 32 KiB 预算）：

```markdown
<!-- 引用覆盖层 -->
详见 <harness-foundry>/adapters/codex/AGENTS.codex-overlay.md
```

## 强制声明

每任务首句：`「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`
（见 `harness-foundry/core/intent-routing.md` 路由表）

## 阶段门禁（Codex 版）

| 阶段 | 动作 | 门禁 |
|------|------|------|
| 设计 / Spec | `superpowers:brainstorming` skill | 写产物后暂停，等用户确认 |
| 计划 | `superpowers:writing-plans` skill | 写产物后暂停，等用户确认 |
| 编码 | 直接执行 | 自主性指令满足后自动进行 |
| 验证 | `superpowers:verification-before-completion` | 编译通过 + 检查清单 |
| 审查 | `requesting-code-review` | 尾盘产物 |

## Skills 加载路径

Codex 原生 skill 发现（Anthropic Agent Skills 开放标准）：

1. `.agents/skills/<slug>/SKILL.md`（项目，与 Claude 共用投影）
2. `skills/`（工作区）
3. `~/.codex/skills/`（用户全局）

## 并行派发

`spawn_agent`（官方，默认 max_threads=6、max_depth=1）。harness 默认 ≤5 Worker 兼容。

## Bootstrap

```bash
bash harness-foundry/scripts/bootstrap.sh --target codex
```
