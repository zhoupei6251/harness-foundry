# .agents

本目录存放当前项目自己新增的 AI 规则和 skills。

## 目录约定

- `skills/`：项目自己新增的 skills。

Harness 脚手架预置编排 skill（投影后位于 `.trae/agents/` 或 `.claude/agents/`）：

- **Trae：** `harness-orchestration`（→ `core/orchestration/dispatcher-workflow.md`）
- **Claude Code：** `claude-orchestration`（同上）

其他业务 skill（专利、业务分析、发布检查等）由项目按需新增到 `.agents/skills/`。

## AI 接入方式

团队成员不需要自己照着命令逐条执行。把下面这段话交给 AI：

```text
请先读取 AGENTS.md 和 harness-foundry/core/intent-routing.md。
完成后请汇总 skills 的可用状态。
```

## 外部通用 Skills

本仓库不复制 superpowers skills。通过标准方式安装后，优先使用以下外部能力：

- `brainstorming`
- `writing-plans`
- `systematic-debugging`
- `test-driven-development`
- `verification-before-completion`
- `git-xywh`（组织 Git：分支、Angular 提交、MR）

安装后 skills 位于 `~/.trae/skills/` 或 `~/.claude/skills/` 下。

## 优先级

项目级 skill 只放真正属于本项目的能力。若与旧规则冲突，以项目级规则和 `AGENTS.md` 为准。
