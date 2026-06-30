# Harness Foundry

> 跨多 IDE 平台的多智能体 AI 工作流编排框架，用于统筹代码开发、小说创作和新闻写作。

统一驱动 **Trae / Claude Code / Cursor / Codex / Mimocode** 五大平台——单一真相源，随时重建。

[English](README.en.md)

---

## 它解决什么问题

在 AI IDE 里，常见的困境是：要么 AI 各干各的（缺少流程约束），要么流程太重（强制太多、干预太频）。

Harness Foundry 的答案是：**用阶段门禁和并行派发把结构化流程做进去，但把强制权留给人类**。

```
用户意图 → 意图路由 → 域 Leader → 阶段门禁 → 并行 Worker → 验证
```

三个域共享同一套编排原语：

| 域 | 阶段门禁 | Worker |
|---|---------|--------|
| **code** | spec → plan → implement → verify | coder, debugger, reviewer, test-engineer, explorer |
| **novel** | 大纲 → 章节 → 返修 → 发布 | novel-writer, novel-planner, novel-reviewer, humanizer |
| **news** | 角度 → 草稿 → 事实核查 → 润色 → 发布 | news-writer, fact-checker, news-editor |

每个会话从读取 `core/intent-routing.md` 开始，第一行必须声明：

```
Route: <code|novel|news>
```

---

## Intelligence Layer（智能代码理解）

Harness Foundry 集成了 **Understand-Anything** 和 **CodeGraph**，提供智能代码理解能力：

| 层次 | 工具 | 能力 |
|------|------|------|
| **战略层** | Understand-Anything | 项目理解、架构分析、自然语言问答 |
| **战术层** | CodeGraph | 索引查询、符号定位、影响分析 |

**效果**：
- 5 分钟理解陌生项目
- 减少 57% Token 消耗
- 减少 71% 工具调用

### 一键安装

```bash
# Linux/macOS
bash scripts/install-intelligence-deps.sh

# Windows PowerShell
.\scripts\install-intelligence-deps.ps1

# 安装后初始化项目索引（可选）
codegraph init
codegraph index
```

详见：[用户指南](docs/intelligence-layer-user-guide.md) | [使用手册](docs/intelligence-layer-usage-guide.md) | [故障排除](docs/intelligence-layer-troubleshooting.md)

---

## 快速上手

```bash
# 1. 投影适配器到你的 IDE
bash scripts/bootstrap.sh --target all      # 所有平台
bash scripts/bootstrap.sh --target trae    # 仅 Trae
bash scripts/bootstrap.sh --target cursor  # 仅 Cursor
bash scripts/bootstrap.sh --target claude  # 仅 Claude Code

# 2. 同步 skills
bash scripts/sync-skills.sh --target all

# 3. 先预览（安全 — 不写文件）
bash scripts/bootstrap.sh --target all --dry-run
bash scripts/sync-skills.sh --target all --dry-run

# 4. 验证
bash scripts/verify.sh
```

**Windows 用户：** 使用 Git Bash 或 WSL 中的 `bash`。bootstrap 有 PowerShell 等价脚本：
```powershell
.\scripts\bootstrap.ps1 -Target all
.\scripts\sync-skills.ps1 -Target all -DryRun
```

---

## 架构

```
harness-foundry/
├── core/                              # 平台无关真相源
│   ├── intent-routing.md              # 意图路由表（每个会话第一个读）
│   ├── routing.md                    # 兼容别名 → intent-routing.md
│   ├── NEVER.md                      # 硬性禁止项（402 条陷阱规则）
│   ├── principles.md                 # 10 条核心原则
│   ├── capabilities/                 # Capability ID 注册表
│   │   ├── registry.md
│   │   └── primitives.md
│   ├── intelligence/                 # Intelligence Layer 配置
│   │   └── README.md
│   ├── memory/                       # 记忆管理协议
│   └── orchestration/               # 调度 / 角色 / Skill 路由
│       ├── domain-config.yaml     # 域 → Agent/Skill 映射
│       ├── dispatcher-workflow.md  # 并行派发工作流（≤5 Worker）
│       ├── skill-preferences.md    # WU 级 Skill 路由
│       └── execution-context/       # Worktree / local provider 协议
│
├── adapters/                         # 平台物理绑定（薄壳）
│   ├── trae/                        # Trae IDE 适配器
│   ├── cursor/                      # Cursor 适配器
│   ├── claude/                      # Claude Code 适配器
│   ├── codex/                       # Codex 适配器
│   └── mimocode/                    # Mimocode 适配器
│
├── skills/                           # ★ 194 个 Skills（扁平结构）
│   ├── INDEX.md                    # 完整 Skill 索引（自动生成）
│   ├── categories.yaml             # 26 个分类定义
│   ├── _layer.yaml                 # Skill 层分级（must-core / optional）
│   └── <slug>/SKILL.md            # 每个 Skill 独占一个目录
│
├── agents/                           # ★ 30 个 Agent（扁平结构）
│   ├── leader-code.md              # 域 Leader（code）
│   ├── leader-novel.md            # 域 Leader（novel）
│   ├── leader-news.md            # 域 Leader（news）
│   ├── coder.md                   # 代码实现
│   ├── debugger.md                # 调试专家
│   ├── reviewer.md                # 代码审查
│   ├── code-reviewer.md           # 专职审查（含 Handoff 协议）
│   ├── test-engineer.md           # 测试工程师
│   ├── explorer.md                # 代码探索
│   ├── implementer.md             # 轻量实现者
│   ├── humanizer.md               # 文本人性化
│   ├── memory-keeper.md           # 记忆管理者
│   └── *.md                      # 其他专项 Agent
│
├── hooks/                            # 自动化 Hook + Guardrail
│   ├── hooks.json                # PreToolUse / PostToolUse / Stop hook
│   ├── guardrails/               # 双层防护规则
│   │   ├── guardrail-config.json
│   │   └── rules/                # Input 5 条 + Output 5 条
│   ├── observe.sh / observe.ps1  # 运行时监控
│   └── memory-persistence/       # 记忆持久化
│
├── scripts/                         # Bootstrap 和同步脚本
│   ├── bootstrap.sh / bootstrap.ps1
│   ├── sync-skills.sh / sync-skills.ps1
│   ├── verify.sh                 # CI 验证入口
│   ├── gen-skill-index.sh / gen-skill-index.ps1
│   ├── gen-skill-graph.py        # 技能依赖图生成
│   ├── auto-fill-frontmatter.py  # frontmatter 自动填充
│   ├── classify-skills.py        # Skill 分类
│   └── harness-worktree.sh       # Git worktree 沙箱
│
├── traps-archive/               # 历史陷阱存档（402 条规则）
│   ├── code/00-all.md          # 251 条代码陷阱
│   ├── novel/00-all.md         # 82 条小说陷阱
│   └── news/00-all.md          # 69 条新闻陷阱
│
├── contexts/                       # 域专属上下文
├── rules/                          # 技术栈专属编码规则
├── references/                     # 上下文地图、Instinct
├── docs/                           # 文档
│   ├── skill-metadata-spec.md   # Skill 元数据规范
│   ├── skill-frontmatter-schema.md
│   ├── skill-dependency-graph.md # 技能依赖图
│   ├── harness-foundry-knowledge-graph.md # 知识图谱
│   └── intelligence-layer-*.md   # Intelligence Layer 文档
│
└── CLAUDE.md                  # Claude Code 上下文文件
```

---

## 意图路由

`core/intent-routing.md` 是**每个会话必须首先读取**的入口文件。它把自然语言触发词映射到域和 Capability ID：

| 触发短语 | 域 | Capability |
|---------|---|-----------|
| 写代码 / 实现 / 修 bug / 重构 | code | `roles.coder` |
| 设计 / 架构 / 方案 | code | `roles.architect` |
| 调试 / 排查 | code | `roles.debugger` |
| 审查 / review | code | `roles.reviewer` |
| 写小说 / 章节 / 续写 | novel | `roles.novel-writer` |
| 写新闻 / 报道 / 快讯 | news | `roles.news-writer` |
| 小改动 / quick fix | code | 直接处理（不派发）|

---

## Skill 系统

**194 个 Skill**，扁平目录结构 `skills/<slug>/SKILL.md`。

### 分类体系（26 类）

| 分类 | 数量 | 说明 |
|------|------|------|
| code | 11 类 | 代码开发全生命周期 |
| novel | 4 类 | 小说创作与编辑 |
| news | 2 类 | 新闻写作与核查 |
| shared | 6 类 | 跨域通用技能 |
| biz | 2 类 | 商业分析 |
| crypto | 1 类 | 加密相关 |
| science | 1 类 | 科学研究 |

### Skill 层分级

```yaml
_layer.yaml:
  must-core:   # 必须同步的核心技能（约 50 个）
  optional:    # 可选技能（约 140 个）
```

### Skill 元数据

每个 Skill 可选包含 `_meta.json`：
```json
{
  "slug": "skill-name",
  "domain": "code|novel|news|shared",
  "category": "category-id",
  "tags": ["tag1", "tag2"],
  "purpose": "简短描述",
  "requires": ["other-skill"],
  "complements": ["related-skill"],
  "conflicts": ["incompatible-skill"]
}
```

### 加载路径（以 Cursor 为例）

1. `.cursor/skills/<slug>/SKILL.md` — 投影（由 `sync-skills.sh` 生成）
2. `skills/<slug>/SKILL.md` — 真相源
3. `~/.cursor/skills/<slug>/SKILL.md` — 用户全局

---

## Agent 池

**30 个 Agent** 覆盖 3 个域。每个 Agent 是一个带 YAML frontmatter 的 Markdown 文件。

| 域 | Leader | 主要 Worker |
|---|--------|-----------|
| **code** | leader-code | coder, debugger, reviewer, test-engineer, explorer |
| **novel** | leader-novel | novel-writer, novel-planner, novel-reviewer, humanizer, memory-keeper |
| **news** | leader-news | news-writer, fact-checker, news-editor |

### 专项 Reviewer（ECC cherry-pick）

- `ecc-java-reviewer` — Java 专项审查
- `ecc-security-reviewer` — 安全审查
- `ecc-database-reviewer` — 数据库审查

仅在 review 阶段显式调用，不进入主流程。

### Handoff 协议

所有 Agent 文件内置 Handoff 交接协议入口，确保多 Agent 协作时的上下文传递。

---

## Hook 与 Guardrail

**PreToolUse / PostToolUse / Stop** Hook 按域定义，位于 `hooks/hooks.json`。

### 双层防护（P0-2）

| 层级 | 类型 | 规则 |
|------|------|------|
| **Input**（并行，任一失败即阻断）| prompt injection | SQL 注入 | 命令注入 | prompt 覆盖 | 路径穿越 |
| **Output**（顺序，阻塞式）| 敏感信息泄露 | canary token 泄露 | NEVER 违规 | AI 写作标记 | 语法检查 |

**配置**：`hooks/guardrails/guardrail-config.json`
**审计日志**：`.ai-runtime-artifacts/guardrail-audit.jsonl`

### Canary Token

在运行时由 `scripts/canary-rotate.sh` 生成并注入到 Agent prompt 中，用于检测 prompt 泄露。Token 文件（`core/security/canary-tokens.yaml`）在 `.gitignore` 中，不得提交到版本控制。

---

## 记忆管理

| 层级 | 路径 | 说明 |
|------|------|------|
| **全局记忆** | `~/.claude/GLOBAL-MEMORY.md` | 跨项目共享 |
| **项目记忆** | `MEMORY.md`（项目根目录）| 项目专用 |
| **会话记忆** | `memory/` | 运行时临时存储 |

详见：[hooks/memory-persistence/README.md](hooks/memory-persistence/README.md)

---

## 测试与验证

```bash
# 完整 CI 验证
bash scripts/verify.sh

# L1 静态检查
bash tests/L1-static/validate-agent-format.sh
bash tests/L1-static/validate-skill-meta.sh
bash tests/L1-static/validate-never.sh

# L2 集成检查
bash tests/L2-integration/validate-routing.sh
bash tests/L2-integration/validate-domain-config.sh

# Skill 质量检查
bash scripts/skill-quality-check.sh

# Shell 脚本语法检查
shellcheck scripts/*.sh
```

---

## 关键文件速查

| 需求 | 文件 |
|------|------|
| 本项目工作原理 | [`CLAUDE.md`](CLAUDE.md) |
| 意图路由规则 | [`core/intent-routing.md`](core/intent-routing.md) |
| 阶段门禁 | [`core/intent-routing.md` § 阶段门禁](core/intent-routing.md) |
| Skill 路由表 | [`core/orchestration/skill-preferences.md`](core/orchestration/skill-preferences.md) |
| 调度器工作流 | [`core/orchestration/dispatcher-workflow.md`](core/orchestration/dispatcher-workflow.md) |
| 域编排配置 | [`core/orchestration/domain-config.yaml`](core/orchestration/domain-config.yaml) |
| 全部 Skills | [`skills/INDEX.md`](skills/INDEX.md) |
| Skill 分类 | [`skills/categories.yaml`](skills/categories.yaml) |
| Skill 元数据规范 | [`docs/skill-metadata-spec.md`](docs/skill-metadata-spec.md) |
| 技能依赖图 | [`docs/skill-dependency-graph.md`](docs/skill-dependency-graph.md) |
| 全部 Agents | [`agents/README.md`](agents/README.md) |
| Hook 与 Guardrail | [`hooks/README.md`](hooks/README.md) |
| **Intelligence Layer** | [`docs/intelligence-layer-user-guide.md`](docs/intelligence-layer-user-guide.md) |
| 知识图谱 | [`docs/harness-foundry-knowledge-graph.md`](docs/harness-foundry-knowledge-graph.md) |
| Trae 快速参考 | [`adapters/trae/trae-quick-ref.md`](adapters/trae/trae-quick-ref.md) |

---

## 已知局限

- Canary Token 在运行时生成——不适用于离线场景
- 执行上下文 Provider（worktree/local）已有协议定义但尚未完全接入
- 三个规划中的域（essay/math/academic）在 `domain-config.yaml` 中为 stub，尚未实现
- CI 仅在 Linux 上运行（Shell 脚本）；Windows 使用 PowerShell 等价脚本

---

## License

MIT — 参见 [`LICENSE`](LICENSE)。

## 致谢

以下开源项目提供了核心灵感：

- [obra/superpowers](https://github.com/obra/superpowers) — Skill 触发的工作流方法论
- [affaan-m/ECC](https://github.com/affaan-m/ECC) — 60+ Agent、230+ Skill、跨多 harness 生态
- [Understand-Anything](https://github.com/ollama/ollama) — 战略层代码理解
- [CodeGraph](https://github.com/salesforce/codegraph) — 战术层代码索引