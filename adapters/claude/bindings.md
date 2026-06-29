# Claude Code 平台绑定

逻辑原语 → Claude Code API。语义以 `harness-foundry/core/capabilities/` 与 `harness-foundry/core/orchestration/` 为准。

| 原语 | Claude Code 绑定 |
| --- | --- |
| `DetectPlatform()` | `.claude/` 目录存在 → `claude` |
| `SpawnWorker(coder)` | `Agent(subagent_type=generalPurpose)` + `harness-foundry/agents/coder.md` |
| `SpawnWorker(implementer)` | `Agent(subagent_type=generalPurpose)` + `harness-foundry/agents/implementer.md` |
| `SpawnWorker(reviewer)` | `Agent(subagent_type=generalPurpose)` + `harness-foundry/agents/reviewer.md`（readonly） |
| `SpawnWorker(test-engineer)` | `Agent(subagent_type=generalPurpose)` + `harness-foundry/agents/test-engineer.md` |
| `SpawnWorker(explorer)` | `Agent(subagent_type=search)` + `harness-foundry/agents/explorer.md` |
| `SpawnWorker(debugger)` | `Agent(subagent_type=generalPurpose)` + `harness-foundry/agents/debugger.md` |
| `SpawnWorker(web-investigator)` | `Agent(subagent_type=search)` + `harness-foundry/agents/web-investigator.md` |
| `ParallelBatch` | 并行 `Agent`，≤5 |
| `WorktreeInit` | 支持 — `bash harness-foundry/scripts/harness-worktree.sh` |
| `StructuredAsk` | 平台原生确认机制 |
| `EmitHook` | **manual** — 用户本地 hook |
| `LoadCapability(orchestration.dispatch)` | `claude-orchestration` skill → `harness-foundry/core/orchestration/dispatcher-workflow.md` |

**Skill 路径：**
1. `.claude/skills/<slug>/SKILL.md`（项目级）
2. `~/.claude/skills/<slug>/SKILL.md`（用户全局）
3. `.agents/skills/<slug>/SKILL.md`（真相源）

**入口规则：** `harness-foundry/adapters/claude/.claude/rules/ENTRY.md`

**委派 prompt 必含：** WU id、wu_type、agent_role、允许文件、禁止项、done criteria、worktree_path（若启用）、本 WU Skills、返回格式。

**降级：** 见 `capability-matrix.yaml`。`interaction.structured-ask` 为 degraded（对话式确认）。
