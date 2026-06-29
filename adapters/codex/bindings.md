# Codex / OMX 平台绑定

逻辑原语 → Codex API / omx CLI。语义以 `harness-foundry/core/capabilities/` 与 `harness-foundry/core/orchestration/` 为准。

| 原语 | Codex 绑定 |
| --- | --- |
| `DetectPlatform()` | Codex CLI + `omx` in PATH → `codex` |
| `SpawnWorker(coder)` | `omx worker` + `harness-foundry/agents/coder.md` |
| `SpawnWorker(implementer)` | `omx worker` + `harness-foundry/agents/implementer.md` |
| `SpawnWorker(reviewer)` | `omx worker` + `harness-foundry/agents/reviewer.md` |
| `SpawnWorker(test-engineer)` | `omx worker` + `harness-foundry/agents/test-engineer.md` |
| `SpawnWorker(explorer)` | `omx worker`（research 路由） |
| `SpawnWorker(debugger)` | `omx worker` + `harness-foundry/agents/debugger.md` |
| `SpawnWorker(web-investigator)` | **degraded** — general research 路由，无专用 omx 角色 |
| `ParallelBatch` | `omx ultrawork` 并行，≤5 |
| `WorktreeInit` | **degraded** — git worktree 或 routing 跳过 |
| `StructuredAsk` | **degraded** — 对话式确认 |
| `EmitHook` | **manual** — 用户本地 hook |
| `LoadCapability(orchestration.dispatch)` | `harness-foundry/adapters/codex/entrypoints/AGENTS.harness.md` + omx ultrawork |

**Skill 路径：**
1. `harness-foundry/adapters/codex/.agents/skills/<slug>/SKILL.md`（项目级）
2. `~/.agents/skills/<slug>/SKILL.md`（用户全局）

**入口规则：** `harness-foundry/adapters/codex/entrypoints/AGENTS.harness.md`

**降级：** `worktree-sandbox` degraded；`interaction.structured-ask` degraded；`roles.web-investigator` degraded。
