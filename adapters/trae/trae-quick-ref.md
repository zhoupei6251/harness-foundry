# Trae 快速参考

## Bootstrap

```bash
bash harness-foundry/scripts/bootstrap.sh --target trae
```

## 核心文件

| 文件 | 用途 |
|------|------|
| `ENTRY.md` | 统一入口（每任务必读） |
| `harness-foundry/core/intent-routing.md` | 意图路由表 |
| `harness-foundry/core/NEVER.md` | 禁止清单 |
| `harness-foundry/core/orchestration/dispatcher-workflow.md` | 多 WU 并行调度 |

## 意图路由速查

| 你说 | Harness 做 |
|------|--------|
| "设计方案" | brainstorming → 写 spec |
| "写计划" | writing-plans → 写 plan |
| "开始实现" | dispatcher 拆 WU → 并行派兵 |
| "修 bug" | Leader 直做 或 debugger |
| "代码审查" | reviewer 五轴审查 |
| "小改动" | Leader 直做，不派兵 |
| "收尾" | verification → review → 记忆同步 |

## 平台限制

- **无 worktree 沙箱** — 主 checkout 直接改，用 git 分支隔离
- **hooks.json** — 项目钩子配置（prompt 类型）
- **并行上限** — Task ≤ 5

## Skill 路径

1. `.trae/skills/<slug>/SKILL.md`（项目级）
2. `~/.trae/skills/<slug>/SKILL.md`（用户全局）
3. `.agents/skills/<slug>/SKILL.md`（真相源）

## 7 角色

| 角色 | 说明 |
|------|------|
| coder | 代码实现 |
| implementer | 轻量执行（文档/配置） |
| reviewer | 代码审查 |
| test-engineer | 测试/E2E |
| explorer | 只读探索 |
| debugger | 缺陷调查 |
| web-investigator | 调研取证 |

## 强制声明

每任务首句：`「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`（见 `core/intent-routing.md`）

## 运行时产物

- `.ai-runtime-artifacts/specs/` — 设计文档
- `.ai-runtime-artifacts/plans/` — 任务计划
- `.ai-runtime-artifacts/decisions/` — 决策记录
- `.ai-runtime-artifacts/verifications/` — 验证记录
- `.ai-runtime-artifacts/execution-logs/` — 执行日志
