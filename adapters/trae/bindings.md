# Trae 平台绑定

逻辑原语 → Trae API。语义以 `harness-foundry/core/capabilities/` 与 `harness-foundry/core/orchestration/` 为准。
与 Cursor 适配器的差异：**无 worktree 沙箱**（主 checkout）、**hooks 2026-06-12 起支持**（`.trae/hooks.json`，格式与 Claude Code 同构）、**无 cursor-orchestration skill**。

| 原语 | Trae 绑定 |
| --- | --- |
| `DetectPlatform()` | `.trae/` 目录存在 → `trae` |
| `SpawnWorker(coder)` | Subagent（`.trae/agents/coder.md`，内置 Agent 按 description 自动委派）或 `Task(general_purpose_task)` + system prompt `harness-foundry/agents/coder.md` |
| `SpawnWorker(implementer)` | 同上 + `harness-foundry/agents/implementer.md` |
| `SpawnWorker(reviewer)` | Subagent 只读（`disallowedTools` 限制写工具）+ `harness-foundry/agents/reviewer.md` |
| `SpawnWorker(test-engineer)` | Subagent + `harness-foundry/agents/test-engineer.md` |
| `SpawnWorker(explorer)` | Subagent（只读）+ `harness-foundry/agents/explorer.md` |
| `SpawnWorker(debugger)` | Subagent + `harness-foundry/agents/debugger.md` |
| `SpawnWorker(web-investigator)` | Subagent（WebSearch/WebFetch）+ `harness-foundry/agents/web-investigator.md` |
| `ParallelBatch` | 并行 `Task(general_purpose_task)`，≤5（社区实测蜂群模式；官方未公布硬上限，未确认） |
| `WorktreeInit` | **不支持** — 主 checkout 直接改；需要隔离用 git 分支 |
| `StructuredAsk` | `AskUserQuestion` |
| `EmitHook` | `.trae/hooks.json`（SessionStart/UserPromptSubmit/PreToolUse/PostToolUse/Stop/Notification；与 Claude Code hooks.json 同构，官方支持合并 `.claude/settings.json` 的 hook 配置） |
| `LoadCapability(orchestration.dispatch)` | `harness-orchestration` skill → `harness-foundry/core/orchestration/dispatcher-workflow.md` |

**Skill 路径：**
1. `.trae/skills/<slug>/SKILL.md`（项目级）
2. `~/.trae/skills/<slug>/SKILL.md`（用户全局，国际版）或 `~/.trae-cn/skills/<slug>/SKILL.md`（中国版）
3. `.agents/skills/<slug>/SKILL.md`（真相源）

**入口规则：** `harness-foundry/adapters/trae/.trae/rules/ENTRY.md` + `harness-foundry/core/intent-routing.md`

**角色定义：** `harness-foundry/adapters/agents/.agents/README.md` → 引用 `harness-foundry/agents/*.md` 真相源

**降级：** `worktree-sandbox` 不支持；其他 capability 全部可用。详见 `capability-matrix.yaml`。
