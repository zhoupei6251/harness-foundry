# Claude Code 适配器

> 平台绑定详见 `bindings.md`；能力对比详见 `capability-matrix.yaml`

## 接入

1. 根目录 `CLAUDE.md` 自动加载（见项目根 `CLAUDE.md`）
2. 统一行为准则来自 `harness-kit/adapters/agents/AGENTS.md`
3. 多 task 实现：Load `claude-orchestration` → `core/orchestration/dispatcher-workflow.md`

## 平台差异

| 能力 | 状态 | 说明 |
|------|------|------|
| `interaction.structured-ask` | degraded | 对话式单选，无法使用 AskUserQuestion |
| `hooks.session-lifecycle` | manual | 用户自行配置 `.claude/settings.json` |
| `orchestration.continuous-loop` | manual | 多会话 HANDOFF 人工衔接 |

parity 全表：`capability-matrix.yaml`；绑定映射：`bindings.md`
