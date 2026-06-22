# Harness Kit

> 一套为多 IDE 设计的 AI 编码工作流框架，集成意图路由、阶段门禁、Skill 体系、Agent 编排与第三方 cherry-pick。
>
> 适用于 **Trae / Claude Code / Cursor / Codex / Mimocode** 五个平台，统一驱动。

## 特性

| 特性 | 说明 |
|------|------|
| **平台中立** | 同一份核心规则 (`harness-kit/core/`)，物理绑定在 `adapters/` |
| **阶段门禁** | spec → plan → implement → verify 五阶段，强制暂停等确认 |
| **20 Skill + 10 Agent** | 覆盖 TDD、调试、审查、UX、安全、数据库、并行派兵等场景 |
| **第三方 cherry-pick** | 从 Superpowers / ECC 精选补缺，**不装整个插件** |
| **幂等同步** | `bootstrap.sh` / `sync-skills.sh` / `sync-third-party.sh` 全支持 `--dry-run` |
| **真相源 + 投影** | git 追踪真相源，IDE 读取投影（可随时重建） |

## 快速开始

```bash
# 1. 投影到你的 IDE
bash harness-kit/scripts/bootstrap.sh --target trae       # 仅 Trae
bash harness-kit/scripts/bootstrap.sh --target cursor     # 仅 Cursor
bash harness-kit/scripts/bootstrap.sh --target all        # 全平台

# 2. 第三方 skill 投影
bash harness-kit/scripts/sync-third-party.sh

# 3. 先看计划（不实际写入）
bash harness-kit/scripts/bootstrap.sh --target all --dry-run
bash harness-kit/scripts/sync-skills.sh --target trae --dry-run
```

## 目录结构

```
harness-kit/
├── core/                          # 平台中立核心规则
│   ├── intent-routing.md         # 意图路由 + 阶段门禁（所有平台强制）
│   ├── karpathy-guidelines.md
│   ├── NEVER.md                  # 禁用清单
│   ├── capabilities/             # 能力 ID 注册表
│   └── orchestration/            # 派发/角色/技能路由
│       ├── roles.md              # 7 角色 + 按需 ECC agent
│       └── agents/               # 7 角色真相源
│
├── adapters/                     # 平台物理绑定（薄壳）
│   ├── trae/                     # Trae IDE 适配
│   ├── cursor/                   # Cursor 适配
│   ├── claude/                   # Claude Code 适配
│   ├── codex/                    # Codex 适配
│   └── mimocode/                 # Mimocode 适配
│
├── skills/                       # ★ Skill 集合（分发入口）
│   ├── README.md
│   ├── INDEX.md                  # 索引表
│   ├── harness/                  # 16 个 harness 自有 skill
│   └── third-party/              # 4 个第三方 skill + 3 个 agent
│
├── agents/                       # ★ Agent 集合（分发入口）
│   ├── README.md
│   ├── harness/                  # 7 个 harness 角色
│   └── third-party/              # 3 个 ECC 专项 agent
│
├── third-party/                  # 第三方 cherry-pick 真相源
│   ├── superpowers/skills/       # 4 个 Superpowers skill
│   └── ecc/agents/               # 3 个 ECC agent
│
├── scripts/                      # 同步与启动脚本
│   ├── bootstrap.sh / bootstrap.ps1
│   ├── sync-skills.sh / sync-skills.ps1
│   ├── sync-third-party.sh
│   ├── harness-worktree.sh
│   └── harness-worktree.test.sh
│
├── docs/                         # 设计与计划
│   └── superpowers/
│       ├── specs/
│       └── plans/
│
├── references/                   # 范例与陷阱
├── artifact-templates/           # 产物模板
├── traps-archive/                # 历史陷阱归档
└── universal/CLAUDE.md           # 通用入口
```

## 文档索引

| 我想看... | 看哪里 |
|---------|--------|
| Skill 集合详解 | [`skills/README.md`](skills/README.md) |
| Skill 索引表 | [`skills/INDEX.md`](skills/INDEX.md) |
| Agent 集合详解 | [`agents/README.md`](agents/README.md) |
| 意图路由 | [`core/intent-routing.md`](core/intent-routing.md) |
| 角色定义 | [`core/orchestration/roles.md`](core/orchestration/roles.md) |
| 三层集成设计 | [`docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md) |
| Trae 适配 | [`adapters/trae/README.md`](adapters/trae/README.md) |
| Cursor 适配 | [`adapters/cursor/bindings.md`](adapters/cursor/bindings.md) |
| Claude Code 适配 | [`adapters/claude/README.md`](adapters/claude/README.md) |

## 多平台支持矩阵

| 平台 | 入口 | 物理目录 | Skill 数 | Agent 数 |
|------|------|---------|---------|---------|
| **Trae** | `.trae/rules/harness-entry.md` | `.trae/` | 14 | 7 |
| **Cursor** | `.cursor/rules/ai-entry.mdc` | `.cursor/` | 16 | 7 |
| **Claude Code** | `CLAUDE.md` | `.claude/` | 14 | 7 |
| **Codex** | `AGENTS.md` | （无投影）| 直读 | 直读 |
| **Mimocode** | `.mimocode/` | `.mimocode/` | — | — |

## 同步机制

```
真相源（git tracked）                    投影（IDE 读取）
harness-kit/core/            ───┐
harness-kit/third-party/     ───┼──→  bootstrap.sh
harness-kit/adapters/        ───┤      sync-skills.sh
.agents/skills/              ───┘      sync-third-party.sh
                                         │
                                         ↓
                                .trae/  .cursor/  .claude/
```

**关键原则：**
- IDE 实际读的是**投影目录**（`.trae/`、`.cursor/`、`.claude/`），可随时重建
- 真相源改动后跑 `bootstrap.sh` 重新投影
- 所有同步脚本支持 `--dry-run`，可安全预览

## 防打架机制

1. **物理隔离** — Trae / Cursor / Claude 各自读自己目录，不直接打架
2. **真相源唯一** — 规则只改 `harness-kit/core/` 或 `adapters/`
3. **幂等同步** — `rm -rf` + `cp -a` 模式，反复跑结果一致
4. **dry-run 支持** — 所有同步脚本可预览不写入
5. **git tracked** — `.trae/` 等投影目录不被 git 跟踪，坏了可恢复

## 升级上游 Skill（第三方）

```bash
# 1. 临时克隆上游
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/sp
git clone --depth 1 https://github.com/affaan-m/ECC.git /tmp/ecc

# 2. diff 比对
diff -r /tmp/sp/skills/subagent-driven-development \
        harness-kit/third-party/superpowers/skills/subagent-driven-development

# 3. 手工同步变更到 third-party/
# 4. 更新 _meta.json 的 source_version
# 5. 跑 sync 投影
bash harness-kit/scripts/sync-third-party.sh

# 6. 清理
rm -rf /tmp/sp /tmp/ecc
```

详见 [`skills/README.md` § 重新同步](skills/README.md)。

## License

MIT

## 致谢

本框架借鉴并 cherry-pick 自以下开源项目：

- [obra/superpowers](https://github.com/obra/superpowers) — Skill 触发式工作流方法论
- [affaan-m/ECC](https://github.com/affaan-m/ECC) — 多语言 agent + commands