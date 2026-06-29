# Trae Skill Binding

与 Cursor 共用 `harness-foundry/core/orchestration/skill-preferences.md` § 默认路由表。

## 搜索路径（按序）

```
.trae/skills/<slug>/SKILL.md     # 投影（bootstrap 生成）
.agents/skills/<slug>/SKILL.md   # 真相源
~/.trae/skills/<slug>/SKILL.md   # 用户全局
```

## 投影清单

见 `.agents/skills/_manifest.yaml`（由 `scripts/sync-skills.sh` 驱动）。

## Leader 专用（不投影，从 .agents 加载）

- `brainstorming`、`writing-plans`、`git-xywh`、`harness-orchestration`

## WU 级（投影到 .trae/skills）

- `test-driven-development`、`systematic-debugging`
- `requesting-code-review`、`receiving-code-review`
- `agent-browser`、`verification-before-completion`
- `ui-ux-pro-max`、`frontend-design`

## 项目专属（投影）

- `backend-doc-generator`、`architecture-patterns`
- `security-auditor`、`refactor-safely`

## 项目专属（投影）

## 第三方来源（Cherry-pick，2026-06-22）

从上游开源项目精选补缺，**不装整个插件**。`sync-skills.sh` 已加入 `SKIP_FROM_SYNC` 列表，不会被覆盖或裁剪。

| slug | 来源 | 版本 | 用途 |
| --- | --- | --- | --- |
| `subagent-driven-development` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | SDD 核心流程：每 Task 派发新 implementer + 任务级审查 + 终局大审查 |
| `dispatching-parallel-agents` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | 并行派发独立任务的判断准则（2+ 独立任务时） |
| `using-git-worktrees` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | Worktree 隔离工作流（优先平台原生，git 作为 fallback） |
| `executing-plans` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | 跨 session 执行 plan（fallback，已有 subagent 时优先 SDD） |

**升级流程：** 上游发布新版本时，diff `_meta.json` 的 `source_version`，用 `git diff` 比对本地副本后手动覆盖。

**Meta-skill 隔离：** `using-superpowers`（meta-skill，会重写 Agent 基础行为）**不引入**，避免破坏 harness-foundry 意图路由。

详见：[`docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md)

## 7 角色与路由

见 `.trae/rules/harness-routing.md`。
