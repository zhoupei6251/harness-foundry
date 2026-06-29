# Trae 平台绑定

逻辑原语 → Trae API。语义以 `harness-foundry/core/capabilities/` 与 `harness-foundry/core/orchestration/` 为准。
与 Cursor 适配器的差异：**无 worktree 沙箱**（主 checkout）、**无 hooks.json**、**无 cursor-orchestration skill**。

| 原语 | Trae 绑定 |
| --- | --- |
| `DetectPlatform()` | `.trae/` 目录存在 → `trae` |
| `SpawnWorker(coder)` | `Task(general_purpose_task)` + system prompt `harness-foundry/agents/coder.md` |
| `SpawnWorker(implementer)` | `Task(general_purpose_task)` + `harness-foundry/agents/implementer.md` |
| `SpawnWorker(reviewer)` | `Task(general_purpose_task)` + `harness-foundry/agents/reviewer.md`（reviewer 角色不得写实现） |
| `SpawnWorker(test-engineer)` | `Task(general_purpose_task)` + `harness-foundry/agents/test-engineer.md` |
| `SpawnWorker(explorer)` | `Task(search)` 或 `Task(general_purpose_task)` + `harness-foundry/agents/explorer.md` |
| `SpawnWorker(debugger)` | `Task(general_purpose_task)` + `harness-foundry/agents/debugger.md` |
| `SpawnWorker(web-investigator)` | `Task(search)` + `harness-foundry/agents/web-investigator.md` |
| `ParallelBatch` | 并行 `Task(general_purpose_task)`，≤5（Trae 平台硬上限） |
| `WorktreeInit` | **不支持** — 主 checkout 直接改；需要隔离用 git 分支 |
| `StructuredAsk` | `AskUserQuestion` |
| `EmitHook` | **不支持** — 用 `Skill` 工具和会话开始首句 `Harness：<route>` 替代 |
| `LoadCapability(orchestration.dispatch)` | `harness-orchestration` skill → `harness-foundry/core/orchestration/dispatcher-workflow.md` |

**Skill 路径：**
1. `.trae/skills/<slug>/SKILL.md`（项目级）
2. `~/.trae/skills/<slug>/SKILL.md`（用户全局）
3. `.agents/skills/<slug>/SKILL.md`（真相源）

**入口规则：** `harness-foundry/adapters/trae/.trae/rules/ENTRY.md` + `harness-foundry/core/intent-routing.md`

**角色定义：** `harness-foundry/adapters/agents/.agents/README.md` → 引用 `harness-foundry/agents/*.md` 真相源

**降级：** `worktree-sandbox` 不支持；其他 capability 全部可用。详见 `capability-matrix.yaml`。
