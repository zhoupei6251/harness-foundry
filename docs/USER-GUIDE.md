# Harness Foundry 使用指南

> **目标：** 将 Harness Foundry 作为独立开发工具集，集成到任何项目中——帮助该项目更好地使用 AI

---

## 目录

1. [快速开始](#快速开始)
2. [目录结构](#目录结构)
3. [核心功能](#核心功能)
4. [工作流程](#工作流程)
5. [Skill 与 Agent](#skill-与-agent)
6. [Intelligence Layer（智能代码理解）](#intelligence-layer智能代码理解)
7. [多平台适配](#多平台适配)
8. [配置说明](#配置说明)
9. [常见问题](#常见问题)

---

## 快速开始

### 1. 拉取到项目根目录

```bash
cd your-project/
git clone https://github.com/your-org/harness-foundry.git
```

或者作为子模块：

```bash
git submodule add https://github.com/your-org/harness-foundry.git harness-foundry
```

### 2. 注入宿主项目配置（2 个文件 + 指向）

```bash
# 复制 CLAUDE 模板到宿主项目的 .claude/CLAUDE.md
cp harness-foundry/docs/CLAUDE-TEMPLATE.md .claude/CLAUDE.md

# （可选）生成 AGENTS.md 统一入口
# 见 harness-foundry/adapters/agents/
```

### 3. 安装依赖插件（一次性）

harness-foundry 是编排层，依赖两个生态插件（**不在仓库内**，运行时从插件加载）：

```bash
# 方法论插件（superpowers：设计/计划/TDD/调试）
claude plugin marketplace add claude-plugins-official https://github.com/anthropics/claude-plugins-official
claude plugin install superpowers@claude-plugins-official

# 专家 Agent 池（ecc：80+ 审查/构建/设计 agent）
claude plugin marketplace add ecc https://github.com/affaan-m/ECC
claude plugin install ecc@ecc
```

> **缺插件不报错**：Claude 会忽略不存在的 skill/agent 引用，静默降级——换机器后务必先装插件。

### 4. 开始使用

在 Claude Code 中启动，然后告诉它：

```
我项目根目录有 harness-foundry，请使用它的 skills 和 agents
```

---

## 目录结构

```
harness-foundry/
├── AGENTS.md               # 统一入口：行为准则 R1-R8 + 禁止清单 + 操作手册
├── CLAUDE.md               # Claude Code 上下文文件
├── core/                   # 平台无关真相源（勿改）
│   ├── intent-routing.md   # 意图路由表（每个会话第一个读）
│   ├── NEVER.md            # 硬性禁止项（402 条陷阱规则）
│   ├── principles.md       # 10 条核心原则
│   ├── orchestration/      # 调度 / 角色 / Skill 路由
│   ├── review/             # 两阶段审查协议
│   ├── rules/              # 设计门禁规则
│   ├── memory/             # 记忆管理协议
│   └── intelligence/       # Intelligence Layer 配置
│
├── adapters/               # 平台物理绑定（薄壳）
│   ├── claude/             # Claude Code 适配器
│   ├── trae/               # Trae IDE 适配器
│   ├── codex/              # Codex 适配器
│   ├── workbuddy/          # WorkBuddy 适配器
│   └── agents/             # AGENTS.md 统一行为准则
│
├── skills/                 # ★ 84 个 Skills（扁平结构，与 ecc/superpowers 去重）
│   ├── INDEX.md            # 完整 Skill 索引（自动生成）
│   └── <slug>/SKILL.md     # 每个 Skill 独占一个目录
│
├── agents/                 # ★ 34 个 Agent（扁平结构）
│   ├── leader-*.md         # 域主编（code / novel / news / product）
│   ├── coder.md            # 编码者
│   ├── reviewer.md         # 代码审查者
│   └── ...
│
├── hooks/                  # Guardrail 静态配置（不挂载 hooks）
├── scripts/                # 工具脚本（bootstrap / sync / verify / dashboard 等）
├── tests/                  # L1 静态 / L2 集成 / L3 智能测试
├── commands/               # 快捷命令
├── contexts/               # 域专属上下文（code / novel / news / review）
├── rules/                  # 技术栈专属编码规则
├── references/             # 上下文地图、Instinct、学习模式
├── traps-archive/          # 历史陷阱存档（402 条规则）
├── handoff/                # Agent 交接协议
├── memory/                 # 记忆存储
├── docs/                   # 文档（QUICKSTART / USER-GUIDE / CLI-REFERENCE 等）
└── LICENSE
```

---

## 核心功能

### 1. 强制设计门禁（HARD-GATE）

**作用：** 确保在设计被批准前，不会开始写代码

**流程：**
```
想法 → brainstorming（设计） → 用户批准 → writing-plans（计划） → 实现
```

**使用方式：**
```markdown
# 告诉 Claude：

"我想添加用户认证功能，请用 brainstorming skill"

# Claude 会：
1. 提问澄清需求
2. 提出设计方案
3. 分块展示设计
4. 等待你批准
5. 批准后才开始实现
```

> 规则见 `core/rules/design-gate.md`。小改动可以说"这是单行配置变更，不需要设计，直接改"跳过。

### 2. 两阶段审查

**作用：** 先检查是否符合设计，再检查代码质量

**阶段 1: Spec 合规**（`spec-compliance-reviewer`）
- 实现是否满足设计？
- 是否有遗漏？
- 边界情况处理？

**阶段 2: 代码质量**（`reviewer` / `ecc:java-reviewer` 等专项）
- 代码风格
- 安全漏洞
- 测试覆盖
- 性能问题

> 协议见 `core/review/two-stage-protocol.md`。写完代码必做 `spawn ecc:java-reviewer`（见 `core/intent-routing.md`）。

### 3. 连续学习

**作用：** 从会话中自动提取有用的模式（Stop hook 触发）

**提取内容：**
- 有效的调试方法
- 项目特定模式
- 工具使用技巧
- 错误处理方式

**配置：** `core/memory/continuous-learning/protocol.md`（用户触发，非自动）

### 4. 记忆管理

| 层级 | 路径 | 说明 |
|------|------|------|
| **全局记忆** | `~/.claude/GLOBAL-MEMORY.md` | 跨项目共享 |
| **项目记忆** | `MEMORY.md`（项目根目录）| 项目专用 |
| **会话记忆** | `memory/` | 运行时临时存储 |

### 5. Guardrail 双层防护

**作用：** 输入输出双向安全过滤

| 层级 | 类型 | 规则 |
|------|------|------|
| **Input**（并行，任一失败即阻断）| prompt injection | SQL 注入 | 命令注入 | prompt 覆盖 | 路径穿越 |
| **Output**（顺序，阻塞式）| 敏感信息泄露 | canary token 泄露 | NEVER 违规 | AI 写作标记 | 语法检查 |

**配置：** `hooks/guardrails/guardrail-config.json`
**审计日志：** `.ai-runtime-artifacts/guardrail-audit.jsonl`

### 6. Intelligence Layer（智能代码理解）

见 [第 6 章](#intelligence-layer智能代码理解)。

---

## 工作流程

### 标准流程（完整）

```
1. 想法
   ↓
2. brainstorming（设计）
   ↓ [用户批准]
3. writing-plans（计划）
   ↓ [计划完成]
4. 实现（coder）
   ↓ [完成后]
5. Spec 审查（spec-compliance-reviewer）
   ↓ [通过]
6. 代码审查（reviewer）
   ↓ [通过]
7. 完成
```

### 快速流程（小改动）

```
1. 声明「Route: 小改动，直接处理」
   ↓
2. 直接实现
   ↓
3. 简单审查
```

### Debug 流程

```
1. systematic-debugging
   ↓ [找到根因]
2. 修复
   ↓
3. 回归测试
```

---

## Skill 与 Agent

### 核心 Skills

| Skill | 来源 | 何时用 | 功能 |
|-------|------|--------|------|
| `superpowers:brainstorming` | 插件 | 设计新功能 | 提问、展示方案、分块确认 |
| `superpowers:writing-plans` | 插件 | 制定计划 | 拆分任务、写步骤 |
| `superpowers:test-driven-development` | 插件 | 开发 | RED-GREEN-REFACTOR |
| `superpowers:systematic-debugging` | 插件 | 调试 | 根因分析、系统化调试 |
| `requesting-code-review` | 仓库 | 审查 | 两阶段审查 |
| `two-stage-review` | 仓库 | 两阶段 | Spec 合规 → 代码质量 |
| `auto-compact` | 仓库 | 压缩 | 上下文压缩建议 |

> 完整索引见 `skills/INDEX.md`（84 个 skill）。

### Agent 角色

| 域 | Leader | 主要 Worker |
|---|--------|-----------|
| **code** | leader-code | coder, debugger, reviewer, test-engineer, explorer |
| **novel** | leader-novel | novel-writer, novel-planner, novel-reviewer, humanizer, memory-keeper |
| **news** | leader-news | news-writer, fact-checker, news-editor |

**专项 Reviewer（ecc 插件 Agent）：** `ecc:java-reviewer`（写完代码必做）、`ecc:security-reviewer`（新接口/权限/用户输入）、`ecc:database-reviewer`（SQL/DDL/schema 变更）。仅在 review 阶段显式调用。

---

## Intelligence Layer（智能代码理解）

Harness Foundry 集成 **codebase-memory-mcp**（知识图谱）+ **ripgrep / LSP** 三层查询栈：

| 层次 | 工具 | 能力 |
|------|------|------|
| **战略层** | codebase-memory-mcp (`index_repository` / `get_architecture`) | 项目理解、架构分析、自然语言问答 |
| **战术层·知识图谱** | codebase-memory (`search_graph` / `trace_path` / `detect_changes`) | 跨文件结构关系、调用图、影响面 |
| **战术层·文本搜索** | ripgrep (`rg`) | 字符串 / 注释 / 路径 / TODO 兜底 |
| **战术层·语言服务** | LSP (`textDocument/definition` / `references` / `hover` / `diagnostic`) | 编译器级定义、引用、类型、诊断 |

**一键安装：**

```bash
# Linux/macOS
bash scripts/install-intelligence-deps.sh

# Windows PowerShell
.\scripts\install-intelligence-deps.ps1
```

**使用：**
- `/understand-project` — 项目理解（建立/查询知识图谱）
- `/analyze-architecture` — 架构分析
- `/query-symbol`、`/get-callers`、`/get-callees`、`/analyze-impact` — 符号定位与影响分析

> 详见 [intelligence-layer-user-guide.md](intelligence-layer-user-guide.md) | [故障排除](intelligence-layer-troubleshooting.md)

---

## 多平台适配

| 平台 | 适配器 | 投影位置 |
|------|--------|---------|
| **Claude Code** | `adapters/claude/` | `.claude/` |
| **Trae** | `adapters/trae/` | `.trae/` |
| **Codex** | `adapters/codex/` | `AGENTS.codex-overlay.md` |
| **WorkBuddy** | `adapters/workbuddy/` | `.codebuddy/` |

**投影：**

```bash
# 同步适配器 + skills 到指定平台
bash scripts/bootstrap.sh --target all          # 所有平台 (trae, claude, workbuddy)
bash scripts/bootstrap.sh --target trae         # 仅 Trae
bash scripts/bootstrap.sh --target claude       # 仅 Claude Code
bash scripts/bootstrap.sh --target workbuddy    # 仅 WorkBuddy

# 同步 skills
bash scripts/sync-skills.sh --target all

# 先预览（安全 — 不写文件）
bash scripts/bootstrap.sh --target all --dry-run
```

---

## 配置说明

### 集成到你的项目

在项目根目录创建 `.claude/CLAUDE.md`（模板见 `docs/CLAUDE-TEMPLATE.md`）：

```markdown
# 我的项目配置

## 项目信息
- 项目名：my-app
- 技术栈：Node.js + React
- 规范：参考 harness-foundry/rules/

## Harness Foundry
本项目使用 harness-foundry 作为开发工具集。

### 设计门禁
实现前必须先完成设计并获得批准。
- 参考：harness-foundry/core/rules/design-gate.md
- 简单改动可以说"直接改，不需要设计"

### 两阶段审查
1. Spec 合规审查（spec-compliance-reviewer）
2. 代码质量审查（reviewer / ecc:java-reviewer）
- 参考：harness-foundry/core/review/two-stage-protocol.md
```

### 命令行工具

```bash
cd harness-foundry

# Dashboard（可视化浏览所有 Skills 和 Agents）
npm run dashboard
# 或 python scripts/dashboard/dashboard.py

# 安全扫描
node scripts/security/scan.js

# Eval 测试（验证 Skills 是否工作）
node scripts/eval/run-skill-eval.js --all

# 完整 CI 验证
bash scripts/verify.sh
```

### 自举开发（开发 harness-foundry 自身时）

```bash
bash scripts/bootstrap-self.sh --target trae,claude  # 同步到两个平台
bash scripts/bootstrap-self.sh --dry-run             # 预览
```

### 模板初始化其他项目

```bash
bash scripts/init-project.sh /path/to/new-project
```

---

## 常见问题

### Q1: 如何只使用部分功能？

```markdown
# 只使用设计和审查
"我只用 brainstorming 和 requesting-code-review，其他不用"

# 只使用 TDD
"只用 test-driven-development skill"
```

### Q2: 如何跳过设计门禁？

```markdown
# 对于简单改动
"这是单行配置变更，不需要设计，直接改"

# 对于紧急修复
"紧急修复，直接改，事后审查"
```

### Q3: 如何查看所有可用 skills？

```bash
ls harness-foundry/skills/
```

或打开 `skills/INDEX.md`。

### Q4: 如何运行测试？

```bash
# 完整 CI 验证
bash harness-foundry/scripts/verify.sh

# L1 静态检查
bash tests/L1-static/validate-agent-format.sh
bash tests/L1-static/validate-skill-meta.sh

# L2 集成检查
bash tests/L2-integration/validate-routing.sh
bash tests/L2-integration/validate-domain-config.sh
```

### Q5: 如何进行安全扫描？

```bash
# 扫描整个项目
node harness-foundry/scripts/security/scan.js

# 只扫 secrets
node harness-foundry/scripts/security/scan.js --type secrets

# 只扫 hooks
node harness-foundry/scripts/security/scan.js --type hooks
```

### Q6: 如何自定义规则？

在项目根目录创建 `.claude/rules/`：

```bash
mkdir -p .claude/rules
cp harness-foundry/rules/*.md .claude/rules/
# 然后修改你需要的规则
```

### Q7: 经验沉淀的成果在哪？

- Instinct 提取：`references/instincts/`
- 陷阱库：`references/traps.md` / `traps-archive/`

---

## 版本信息

- **版本：** 1.0.0
- **更新日期：** 2026-08-05
- **架构：** v2.1（见 [docs/specs/harness-foundry-v2.1-architecture.md](specs/harness-foundry-v2.1-architecture.md)）
- **核心能力：**
  - 意图路由 + 阶段门禁（三域：code / novel / news）
  - 两阶段审查（Spec 合规 → 代码质量）
  - 并行派发（dispatcher，≤5 Worker）
  - Intelligence Layer（codebase-memory-mcp 知识图谱 + ripgrep/LSP）
  - Guardrail 双层防护 + Canary Token
  - 连续学习 + 记忆管理
  - 多平台适配（Claude Code / Trae / Codex / WorkBuddy）
