# MiMo Code 适配器

基于 actor 工具的 Harness 编排适配。

## 接入

1. 根目录 `CLAUDE.md` + `AGENTS.md`
2. 投影 skill：`bash harness-kit/scripts/sync-skills.sh --target mimocode`
3. 多 task 实现：Load **`mimocode-orchestration`** → `core/orchestration/dispatcher-workflow.md`

## 平台检测

`CLAUDE.md` 会话 + Skill 工具 + actor 工具 → `platform: mimocode`

## 与 Claude 差异

| 能力 | 状态 |
| --- | --- |
| `interaction.structured-ask` | degraded — 对话式单选 |
| `hooks.session-lifecycle` | manual — 无自动 hook |
| `orchestration.continuous-loop` | manual — 多会话 HANDOFF |

parity 全表：`capability-matrix.yaml`。绑定：`bindings.md`。
