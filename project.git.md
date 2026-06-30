# project.git.md — 项目 Git 规范

> 本文件定义本项目（harness-foundry）的 Git 分支策略、提交规范和 MR 流程。
> 与 `git-xywh` skill 配合使用。

## 分支策略

- **main**: 生产就绪分支，只接受 MR，禁止直接 push
- **develop**: 集成测试分支
- **feature/<slug>**: 功能分支，从 develop 拉出
- **bugfix/<slug>**: 修复分支，从 develop 拉出
- **temp/<slug>**: 临时实验分支，不合并

## 提交规范

采用 Angular 提交格式：

```
<type>(<scope>): <subject>

<body>
```

类型：`feat` | `fix` | `docs` | `refactor` | `test` | `chore` | `style` | `perf`

## MR 流程

1. 功能分支 → develop 提交 MR
2. CI 全绿 + 至少 1 人 Code Review 通过
3. Squash merge

## 本地操作

- 禁止自动 push（须用户手动确认）
- 禁止 `--force` 推送 main/develop
- 禁止 `git commit --no-verify`
