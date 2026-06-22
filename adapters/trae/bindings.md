# Trae 平台绑定

逻辑原语 → Trae API。语义以 `core/capabilities/` 与 `core/orchestration/` 为准。
与 Cursor 适配器的差异：**无 worktree 沙箱**（主 checkout）、**无 hooks.json**、**无 cursor-orchestration skill**。

| 原语 | Trae 绑定 |
| --- | --- |
| `DetectPlatform()` | `.trae/` + `Task(general_purpose_task)` 可委派 → `trae` |
| `SpawnWorker(coder)` | `Task(general_purpose_task)` + system prompt `harness-coder.md` |
| `SpawnWorker(implementer)` | `Task(general_purpose_task)` + `harness-implementer.md` |
| `SpawnWorker(reviewer)` | `Task(general_purpose_task)` + `harness-reviewer.md`（reviewer 角色不得 implement） |
| `SpawnWorker(test-engineer)` | `Task(general_purpose_task)` + `harness-test-engineer.md` + TDD skill |
| `SpawnWorker(explorer)` | `Task(search)` 或 `Task(general_purpose_task)` + `harness-explorer.md` |
| `SpawnWorker(debugger)` | `Task(general_purpose_task)` + `harness-debugger.md` |
| `SpawnWorker(web-investigator)` | `Task(search)` + `agent-browser` skill + `harness-web-investigator.md` |
| `ParallelBatch` | 并行 `Task(general_purpose_task)`，≤5（Trae 平台硬上限） |
| `WorktreeInit` | **不支持** — 主 checkout 直接改；需要隔离用 git worktree 命令手工 |
| `StructuredAsk` | `AskUserQuestion` |
| `EmitHook` | **不支持** — Trae 无 hooks.json 机制；用 `Skill` 工具和会话开始首句 `Harness：<route>` 替代 |
| `LoadCapability(orchestration.dispatch)` | `harness-orchestration` skill → core dispatcher |

**Skill 路径：**
1. `.trae/skills/<slug>/SKILL.md`（bootstrap 投影）
2. `~/.trae/skills/<slug>/SKILL.md`（用户全局）
3. `.agents/skills/<slug>/SKILL.md`（真相源）

**入口规则：** `.trae/rules/harness-entry.md` + `.trae/rules/harness-routing.md` + `.trae/rules/back-rule.md`

**降级：** 见 `capability-matrix.yaml`。`worktree-sandbox` / `hooks.session-lifecycle` 不支持；其他 capability 见矩阵。