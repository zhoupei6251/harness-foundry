# MiMo Code 平台绑定

| 原语 | MiMo Code 绑定 |
| --- | --- |
| `DetectPlatform()` | MiMo Code 会话 + Skill 工具 → `mimocode` |
| `SpawnWorker(role)` | actor(subagent_type=generalPurpose) + `core/orchestration/agents/<role>.md` 作 prompt 正文 |
| `SpawnWorker(reviewer)` | 新 actor 实例 + readonly 约束 |
| `ParallelBatch` | 并行 actor（对齐 `dispatching-parallel-agents`）；不传 Leader 全历史 |
| `WorktreeInit` | 同 `scripts/harness-worktree.sh` / git worktree |
| `StructuredAsk` | **degraded** — 对话式单选/确认 |
| `EmitHook` | **manual** — 用户本地 hook |
| `LoadCapability(orchestration.dispatch)` | `mimocode-orchestration` skill → core dispatcher |

**委派 prompt 必含：** WU id、wu_type、agent_role、允许文件、禁止项、done criteria、worktree_path（若启用）、本 WU Skills、返回格式。

**降级记录：** matrix 为 `degraded` 时，DISPATCH-TRACK 写 `Detail: capability <id> degraded`。
