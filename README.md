# Harness Foundry

> 跨多 IDE 平台的多智能体 AI 工作流编排框架，用于统筹代码开发、小说创作和新闻写作。

统一驱动 **Trae** 和 **Claude Code** 两个平台——单一真相源，随时重建。

[English](README.en.md)

---

## 🚀 快速集成到你的项目

### 5 分钟开始

```bash
# 1. 克隆到你的项目根目录
cd your-project/
git clone https://github.com/your-org/harness-foundry.git

# 2. 复制配置模板
cp harness-foundry/docs/CLAUDE-TEMPLATE.md .claude/CLAUDE.md

# 3. 在 Claude Code 中开始使用
```

### 立即可用

```
用户：请用 brainstorming 设计用户登录功能
Claude：[触发设计流程，提问确认需求...]
```

### 常用命令

```bash
cd harness-foundry

# Dashboard（可视化浏览）
npm run dashboard

# 安全扫描
node scripts/security/scan.js

# 测试 Skills
node scripts/eval/run-skill-eval.js --all
```

### 核心功能

| 功能 | 说明 |
|------|------|
| **强制设计门禁** | 实现前必须先设计并获得批准 |
| **两阶段审查** | 先检查 Spec 合规，再检查代码质量 |
| **连续学习** | 从会话中自动提取有用的模式 |
| **Token 优化** | 模型选择策略 + 上下文压缩 |
| **Eval 测试** | 验证 Skill 是否按预期工作 |
| **安全审计** | 扫描配置安全问题 |

---

## 📖 详细文档

| 文档 | 说明 |
|------|------|
| [快速开始](docs/QUICKSTART.md) | 5 分钟入门 |
| [用户指南](docs/USER-GUIDE.md) | 完整使用说明 |
| [CLI 参考](docs/CLI-REFERENCE.md) | 命令行速查 |
| [CLAUDE 模板](docs/CLAUDE-TEMPLATE.md) | 项目集成模板 |

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

Harness Foundry 集成了 **Understand-Anything** 和 **codebase-memory / ripgrep / LSP** 三层查询栈，提供智能代码理解能力：

| 层次 | 工具 | 能力 |
|------|------|------|
| **战略层** | Understand-Anything | 项目理解、架构分析、自然语言问答 |
| **战术层·知识图谱** | codebase-memory (`search_graph` / `trace_path` / `detect_changes`) | 跨文件结构关系、调用图、影响面 |
| **战术层·文本搜索** | ripgrep (`rg`) | 字符串 / 注释 / 路径 / TODO 兜底 |
| **战术层·语言服务** | LSP (`textDocument/definition` / `references` / `hover` / `diagnostic`) | 编译器级定义、引用、类型、诊断 |
| **战术编排** | `code-insight-stack` | 统一入口，按场景选最便宜的工具组合 |

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
index_repository(project_path="<project>")
```

架构详见 [v2.1 架构文档](docs/specs/harness-foundry-v2.1-architecture.md)；使用详见 [用户指南](docs/intelligence-layer-user-guide.md) | [故障排除](docs/intelligence-layer-troubleshooting.md)

---

## 快速上手

```bash
cd harness-foundry

# 1. 投影适配器到你的 IDE
bash scripts/bootstrap.sh --target all      # 所有平台 (trae, claude)
bash scripts/bootstrap.sh --target trae    # 仅 Trae
bash scripts/bootstrap.sh --target claude  # 仅 Claude Code

# 2. 同步 skills
bash scripts/sync-skills.sh --target all

# 3. 先预览（安全 — 不写文件）
bash scripts/bootstrap.sh --target all --dry-run
bash scripts/sync-skills.sh --target all --dry-run

# 4. 验证
bash scripts/verify.sh
```

**Windows 用户：** 使用 Git Bash 或 WSL 中的 `bash`。

## 自举开发

在开发 harness-foundry 自身时，使用自举脚本将 skills/agents 同步到本地投影层：

```bash
bash scripts/bootstrap-self.sh --target trae,claude  # 同步到两个平台
bash scripts/bootstrap-self.sh --target trae         # 仅 Trae
bash scripts/bootstrap-self.sh --dry-run             # 预览
```

## 模板初始化

将 harness-foundry 作为模板初始化其他项目：

```bash
bash scripts/init-project.sh /path/to/new-project
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
│   ├── trae/                        # Trae IDE 适配器（含 Trae Work / CLI 提示）
│   ├── claude/                      # Claude Code 适配器（含桌面版支持）
│   ├── codex/                       # Codex 适配器（ChatGPT 桌面版 / CLI 共用）
│   ├── workbuddy/                   # WorkBuddy 适配器（腾讯，= CodeBuddy 双品牌）
│   └── agents/                      # AGENTS.md 统一行为准则
│
├── skills/                           # ★ 84 个 Skills（扁平结构，已与 ecc/superpowers 去重）
│   ├── INDEX.md                    # 完整 Skill 索引（自动生成）
│   ├── categories.yaml             # 57 个分类定义
│   ├── _layer.yaml                 # Skill 层分级（core / peripheral）
│   └── <slug>/SKILL.md            # 每个 Skill 独占一个目录
│
├── agents/                           # ★ 35 个 Agent（扁平结构）
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
├── scripts/                         # Bootstrap 和同步脚本
│   ├── bootstrap.sh               # 投影适配器到 IDE
│   ├── bootstrap-self.sh           # 自举脚本（开发 harness 自身）
│   ├── init-project.sh            # 模板化项目初始化
│   ├── sync-skills.sh             # 同步 skills 到 IDE
│   ├── verify.sh                  # CI 验证入口
│   ├── gen-skill-index.sh         # Skill 索引生成
│   └── harness-worktree.sh        # Git worktree 沙箱
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
│   ├── skill-frontmatter-schema.md # Skill 元数据规范
│   ├── plans/                   # 设计文档
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

**84 个 Skill**（2026-08-05 与 ecc/superpowers 去重后），扁平目录结构 `skills/<slug>/SKILL.md`。与 ecc / superpowers 插件重名的 skill 不再本地复制，由插件运行时加载。

### 分类体系（57 类）

| 分类 | 数量 | 说明 |
|------|------|------|
| code | 18 类 | 代码开发全生命周期 |
| novel | 26 类 | 小说创作与编辑 |
| news | 3 类 | 新闻写作与核查 |
| shared | 6 类 | 跨域通用技能 |
| biz | 2 类 | 商业分析 |
| crypto | 1 类 | 加密相关 |
| science | 1 类 | 科学研究 |

### Skill 层分级

```yaml
_layer.yaml:
  core:        # 核心技能（84 个），默认同步到 IDE 投影层
  peripheral:  # 外围技能（0 个，去重后全部归入 core）
  archived:    # 已归档技能，不同步
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

**35 个 Agent** 覆盖 3 个域。每个 Agent 是一个带 YAML frontmatter 的 Markdown 文件。

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

## 🔧 项目集成指南

### 在你的项目中使用 Harness Foundry

#### 1. 克隆到项目根目录

```bash
cd your-project/
git clone https://github.com/your-org/harness-foundry.git
```

#### 2. 集成配置

```bash
# 复制 CLAUDE 模板（推荐）
cp harness-foundry/docs/CLAUDE-TEMPLATE.md .claude/CLAUDE.md

# 或手动创建 .claude/CLAUDE.md
mkdir -p .claude
```

#### 3. 开始使用

在 Claude Code 中直接对话：

```markdown
# 设计新功能
用户：请用 brainstorming 设计用户认证模块
Claude：[触发 brainstorming，提问确认需求，展示方案...]

# 制定计划
用户：设计已批准，请制定实施计划
Claude：[拆分任务，写步骤...]

# 开发
用户：用 TDD 方式实现登录功能
Claude：[RED → GREEN → REFACTOR...]

# 调试
用户：帮我调试这个空指针
Claude：[根因分析，定位修复...]

# 审查
用户：请审查这段代码
Claude：[两阶段审查，Spec合规 + 代码质量...]
```

### 常用对话模板

| 场景 | 对话 |
|------|------|
| 设计功能 | "请用 brainstorming 设计 X" |
| 制定计划 | "设计已批准，制定实施计划" |
| TDD 开发 | "用 TDD 实现这个功能" |
| 调试 | "帮我调试这个 bug" |
| 审查 | "请审查这段代码" |
| 小改动 | "直接改这个 bug" |
| 扫描安全 | "运行安全扫描" |

### 命令行工具

```bash
cd harness-foundry

# Dashboard GUI（可视化浏览所有 Skills 和 Agents）
npm run dashboard

# 安全扫描
node scripts/security/scan.js

# Eval 测试（验证 Skills 是否工作）
node scripts/eval/run-skill-eval.js --all

# 可视化伴侣（brainstorming 时的 mockup 工具）
node scripts/visual-companion/server.js --open
```

### 跳过/定制

**只使用部分功能？**
```markdown
# 告诉 Claude
我只用 brainstorming 和 requesting-code-review，其他不用
```

**跳过设计门禁？**
```markdown
这是单行配置变更，不需要设计，直接改
```

---

## 核心 Skills 速查

| Skill | 命令 | 何时用 | 功能 |
|-------|------|--------|------|
| `brainstorming` | `/skill brainstorming` | 设计新功能 | 提问、展示方案、分块确认 |
| `writing-plans` | `/skill writing-plans` | 制定计划 | 拆分任务、写步骤 |
| `test-driven-development` | `/skill test-driven-development` | 开发 | RED-GREEN-REFACTOR |
| `systematic-debugging` | `/skill systematic-debugging` | 调试 | 根因分析、系统化调试 |
| `requesting-code-review` | `/skill requesting-code-review` | 审查 | 两阶段审查 |
| `two-stage-review` | `/skill two-stage-review` | 两阶段 | Spec 合规 → 代码质量 |
| `continuous-learning` | `/skill continuous-learning` | 学习 | 从会话提取模式 |
| `auto-compact` | `/skill auto-compact` | 压缩 | 上下文压缩建议 |

### 工作流程

```
完整流程：
想法 → brainstorming → 设计批准 → writing-plans → 实现 → 审查 → 完成

快速流程（小改动）：
想法 → brainstorming → 实现 → 简单审查 → 完成

Debug 流程：
问题 → systematic-debugging → 修复 → 回归测试
```

---

## 关键文件速查

| 需求 | 文件 |
|------|------|
| **快速开始** | [`docs/QUICKSTART.md`](docs/QUICKSTART.md) |
| **用户指南** | [`docs/USER-GUIDE.md`](docs/USER-GUIDE.md) |
| **CLI 参考** | [`docs/CLI-REFERENCE.md`](docs/CLI-REFERENCE.md) |
| **CLAUDE 模板** | [`docs/CLAUDE-TEMPLATE.md`](docs/CLAUDE-TEMPLATE.md) |
| 本项目工作原理 | [`CLAUDE.md`](CLAUDE.md) |
| 意图路由规则 | [`core/intent-routing.md`](core/intent-routing.md) |
| 阶段门禁 | [`core/intent-routing.md` § 阶段门禁](core/intent-routing.md) |
| 设计门禁规则 | [`core/rules/design-gate.md`](core/rules/design-gate.md) |
| 两阶段审查协议 | [`core/review/two-stage-protocol.md`](core/review/two-stage-protocol.md) |
| 连续学习协议 | [`core/memory/continuous-learning/protocol.md`](core/memory/continuous-learning/protocol.md) |
| Token 优化策略 | [`core/optimization/token-strategy.md`](core/optimization/token-strategy.md) |
| Skill 路由表 | [`core/orchestration/skill-preferences.md`](core/orchestration/skill-preferences.md) |
| 调度器工作流 | [`core/orchestration/dispatcher-workflow.md`](core/orchestration/dispatcher-workflow.md) |
| 域编排配置 | [`core/orchestration/domain-config.yaml`](core/orchestration/domain-config.yaml) |
| 全部 Skills | [`skills/INDEX.md`](skills/INDEX.md) |
| 全部 Agents | [`agents/README.md`](agents/README.md) |
| Hook 与 Guardrail | [`hooks/README.md`](hooks/README.md) |
| **Intelligence Layer** | [`docs/intelligence-layer-user-guide.md`](docs/intelligence-layer-user-guide.md) |

---

## 新增功能（2026-07-02）

本次更新新增以下功能，对齐 ECC 和 Superpowers 最佳实践：

| 功能 | 文件 | 说明 |
|------|------|------|
| 连续学习系统 | `skills/continuous-learning/` | 从会话中自动提取模式 |
| 强制设计门禁 | `core/rules/design-gate.md` | `<HARD-GATE>` 阻止未批准实现 |
| 两阶段审查 | `core/review/two-stage-protocol.md` | Spec 合规 + 代码质量分离 |
| Eval 框架 | `core/eval/` | Skill 行为测试 |
| Token 优化 | `core/optimization/` | 模型选择 + 上下文压缩 |
| Dashboard GUI | `scripts/dashboard/` | 可视化组件浏览 |
| 视觉伴侣 | `scripts/visual-companion/` | brainstorming 时的 mockup 工具 |
| AgentShield | `skills/agent-shield/` | 安全审计 |

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
- **codebase-memory** — 本地 Codex skill，提供战术层代码索引