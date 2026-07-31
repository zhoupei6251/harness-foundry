# Harness Foundry — CLAUDE.md

> AI 编码工作流框架。统一驱动 **Claude Code** 和 **Trae**。

## 它能干什么

- **意图路由** — 关键词映射到 skill（`intent-routing.md` 的路由表是**地图不是牢房**，大任务用它导航，小改动直接处理）
- **参考书架** — 160 条代码陷阱（`traps-archive/code/00-all.md`）、NEVER 清单（`core/NEVER.md`）
- **编排层** — 大型多 task 并行派兵（`core/orchestration/dispatcher-workflow.md`）
- **角色/Skill 路由** — 子 Agent 按角色自动匹 skill（`core/orchestration/skill-preferences.md`）
- **Hooks** — PreToolUse/PostToolUse/Stop 钩子 + Guardrail 双层防护（`hooks/`）
- **三层洞察栈** — codebase-memory (Graph) + ripgrep (Text) + LSP (Semantic)（入口 `code-insight-stack` skill）

## 目录

```
core/                          # 平台无关真相源
├── intent-routing.md          # 路由表（会话开始读）
├── NEVER.md                   # 硬性禁止（241条陷阱索引）
├── principles.md              # 10 核心原则
├── intelligence/             # 洞察层配置
├── memory/                   # 三域记忆系统
└── orchestration/            # domain-config.yaml + dispatcher + skill-preferences

adapters/                      # 平台适配：trae/, claude/
skills/                        # 194 skills（flat structure）
agents/                        # 30 agents
hooks/                         # PreToolUse/PostToolUse/Stop + Guardrails
traps-archive/                # 241 条陷阱（code 160 + novel 47 + news 34）
scripts/                       # bootstrap/sync/verify
```

## 使用方式（Claude Code）

会话开始时声明 Route 即可，资源**按需**查阅不预加载：

```
「Route：code」「小改动，直接处理」
```

| 场景 | 查阅什么 |
|------|----------|
| 改动前自检 | `core/NEVER.md` |
| Java/Spring Boot | `traps-archive/code/00-all.md`（160条） |
| 审查前 | 并行派发 ecc 三合一 reviewer |
| 大型任务 | 走 brainstorming→writing-plans→implement→verify 门禁 |

## 关键命令

```bash
bash scripts/bootstrap.sh --target all --dry-run   # 预览
bash scripts/bootstrap.sh --target all             # 执行
bash scripts/sync-skills.sh --target all            # 同步 skills
bash scripts/verify.sh                              # CI 验证
```

## 已知限制

- 没有 PreMessage hook — 意图路由靠 LLM 指令跟随 + PreToolUse 补充检查
- 工作树隔离已配置但未全量布线
- CI 仅 Linux (shell); Windows 用 PowerShell 等价
- essay/math/academic 域为占位
