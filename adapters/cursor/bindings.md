# Cursor 平台绑定

逻辑原语 → Cursor API。语义以 `harness-foundry/core/capabilities/` 与 `harness-foundry/core/orchestration/` 为准。

| 原语 | Cursor 绑定 |
| --- | --- |
| `DetectPlatform()` | `.cursor/` 目录存在 → `cursor` |
| `SpawnWorker(coder)` | `harness-coder` subagent + `harness-foundry/agents/coder.md` |
| `SpawnWorker(implementer)` | `harness-implementer` subagent + `harness-foundry/agents/implementer.md` |
| `SpawnWorker(reviewer)` | `harness-reviewer` subagent（readonly，不得写实现） |
| `SpawnWorker(test-engineer)` | `harness-test-engineer` subagent + TDD skill |
| `SpawnWorker(explorer)` | `harness-explorer` subagent 或 Task `explore` |
| `SpawnWorker(debugger)` | `harness-debugger` subagent + systematic-debugging skill |
| `SpawnWorker(web-investigator)` | `harness-web-investigator` subagent |
| `ParallelBatch` | 并行 Task/subagent，≤5 |
| `WorktreeInit` | 支持 — `bash harness-foundry/scripts/harness-worktree.sh` |
| `StructuredAsk` | `AskUserQuestion` |
| `EmitHook` | 支持 — `.cursor/hooks.json` 机制 |
| `LoadCapability(orchestration.dispatch)` | `cursor-orchestration` skill → `harness-foundry/core/orchestration/dispatcher-workflow.md` |

**Skill 路径：**
1. `.cursor/skills/<slug>/SKILL.md`（项目级）
2. `~/.cursor/skills/<slug>/SKILL.md`（用户全局）
3. `.agents/skills/<slug>/SKILL.md`（真相源）

**入口规则：** `harness-foundry/adapters/cursor/.cursor/rules/ENTRY.mdc`

**降级：** 见 `capability-matrix.yaml`。所有核心 capability 均支持。
