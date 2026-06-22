# Trae Harness 入口

## 优先级

1. `harness-kit/core/routing.md`
2. 本文件
3. `.trae/rules/harness-routing.md`
4. `.trae/rules/back-rule.md`（后端规范）

## 快速参考

Read `harness-kit/adapters/trae/trae-quick-ref.md`

## 强制声明

每任务首句：`「Harness：<route 或 "小改动，直接处理">」`

## 按 routing 加载

与 `intent-routing.md` § 阶段指定 skill 必用 相同。

Trae Skill 路径：

1. `.trae/skills/<slug>/SKILL.md`
2. `~/.trae/skills/<slug>/SKILL.md`
3. `.agents/skills/<slug>/SKILL.md`

## 子 Agent

7 角色见 `harness-routing.md`。正文 `harness-kit/core/orchestration/agents/*.md`。

## 与 Cursor 差异

- 无 worktree 沙箱（主 checkout）
- 编排 skill：`harness-orchestration`（非 cursor-orchestration）
- 并行通过 Task，≤5

## Bootstrap

```bash
bash harness-kit/scripts/bootstrap.sh --target trae
```
