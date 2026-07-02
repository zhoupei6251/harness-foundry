# Harness Foundry 使用指南

> **目标：** 将 Harness Foundry 作为开发工具集，集成到你的项目中

---

## 目录

1. [快速开始](#快速开始)
2. [目录结构](#目录结构)
3. [核心功能](#核心功能)
4. [Skill 使用](#skill-使用)
5. [Agent 角色](#agent-角色)
6. [工作流程](#工作流程)
7. [配置说明](#配置说明)
8. [常见问题](#常见问题)

---

## 快速开始

### 1. 拉取到项目根目录

```bash
cd your-project/
git clone https://github.com/your-org/harness-foundry.git
```

### 2. 查看可用命令

```bash
cd harness-foundry

# 查看所有 Skills
ls skills/

# 查看所有 Agents
ls agents/

# 查看文档
ls docs/
```

### 3. 在 Claude Code 中使用

在你的项目中启动 Claude Code，然后告诉它：

```
我项目根目录有 harness-foundry，请使用它的 skills 和 agents
```

或者直接使用特定功能：

```
/skill brainstorming    # 设计阶段
/skill writing-plans    # 制定计划
/skill test-driven-development  # TDD 开发
```

---

## 目录结构

```
harness-foundry/
├── core/                    # 核心配置（勿改）
│   ├── orchestration/       # 编排器和调度器
│   ├── domain-config.yaml   # 领域配置
│   ├── intent-routing.md    # 意图路由
│   ├── NEVER.md            # 禁止事项
│   └── rules/             # 设计门禁规则
│
├── skills/                  # 所有 Skills（按需使用）
│   ├── brainstorming/      # 设计阶段
│   ├── writing-plans/      # 制定计划
│   ├── test-driven-development/  # TDD
│   ├── systematic-debugging/     # 调试
│   ├── requesting-code-review/    # 代码审查
│   ├── continuous-learning/       # 连续学习
│   ├── two-stage-review/          # 两阶段审查
│   ├── auto-compact/              # 智能压缩
│   └── agent-shield/              # 安全审计
│
├── agents/                  # Agent 角色定义
│   ├── coder.md           # 代码实现
│   ├── reviewer.md        # 代码审查
│   ├── spec-compliance-reviewer.md  # Spec 审查
│   ├── debugger.md        # 调试
│   └── planner.md         # 规划
│
├── hooks/                  # 自动化钩子
│   ├── pre-implementation/  # 门禁检查
│   ├── continuous-learning/  # 学习提取
│   └── security/            # 安全扫描
│
├── scripts/                # 工具脚本
│   ├── dashboard/          # Dashboard GUI
│   ├── eval/              # Eval 测试
│   ├── security/          # 安全扫描
│   └── visual-companion/   # 可视化工具
│
└── docs/                   # 文档
    └── plans/             # 实施计划模板
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

### 2. 两阶段审查

**作用：** 先检查是否符合设计，再检查代码质量

**阶段 1: Spec 合规**
- 实现是否满足设计？
- 是否有遗漏？
- 边界情况处理？

**阶段 2: 代码质量**
- 代码风格
- 安全漏洞
- 测试覆盖
- 性能问题

### 3. 连续学习

**作用：** 从会话中自动提取有用的模式

**触发时机：**
- 会话结束（Stop hook）
- 你说"记住这个"

**提取内容：**
- 有效的调试方法
- 项目特定模式
- 工具使用技巧
- 错误处理方式

**查看学习成果：**
```bash
cat ~/.claude/memory/learned/*.md
```

### 4. Token 优化

**模型选择建议：**

| 任务 | 模型 | 理由 |
|------|------|------|
| 简单编辑 | sonnet | 性价比高 |
| 探索搜索 | haiku | 快速廉价 |
| 多文件实现 | sonnet | 平衡 |
| 复杂架构 | opus | 深度推理 |
| 安全审查 | opus | 不可遗漏 |

**压缩时机：**
- 研究/探索完成后
- 完成里程碑后
- 方法失败后

### 5. Eval 测试

**作用：** 验证 skill 是否按预期工作

**运行测试：**
```bash
# 单个 skill 测试
node harness-foundry/scripts/eval/run-skill-eval.js --skill brainstorming

# 全部测试
node harness-foundry/scripts/eval/run-skill-eval.js --all
```

### 6. 安全审计

**作用：** 扫描配置中的安全问题

**运行扫描：**
```bash
# 扫描整个项目
node harness-foundry/scripts/security/scan.js

# 扫描 hooks
node harness-foundry/scripts/security/scan.js --path harness-foundry/hooks

# JSON 格式
node harness-foundry/scripts/security/scan.js --format json
```

### 7. Dashboard GUI

**作用：** 可视化浏览所有 skills 和 agents

**启动：**
```bash
cd harness-foundry
npm run dashboard
# 或
python scripts/dashboard/dashboard.py
```

---

## Skill 使用

### 设计阶段：brainstorming

```markdown
# 触发
/skill brainstorming

# 或者对话中
"我想实现 X功能，请先设计"
```

**会做什么：**
1. 提问澄清需求（一次一个问题）
2. 提供 2-3 个方案对比
3. 分块展示设计（每块 200-300 字）
4. 每块等你确认后再继续
5. 生成设计文档
6. 等待你批准

### 计划阶段：writing-plans

```markdown
# 设计批准后触发
/skill writing-plans

# 或者对话中
"设计已批准，请制定实施计划"
```

**会做什么：**
1. 将设计拆分为小任务
2. 每个任务有明确文件和步骤
3. 提供验证命令
4. 2-5 分钟可完成一个任务

### 开发阶段：test-driven-development

```markdown
# 触发
/skill test-driven-development

# 或对话中
"用 TDD 方式实现这个功能"
```

**流程：**
```
RED: 写一个失败的测试
GREEN: 写最小代码让它通过
REFACTOR: 重构改进
```

### 调试阶段：systematic-debugging

```markdown
# 触发
/skill systematic-debugging

# 或对话中
"帮我调试这个空指针问题"
```

**流程：**
```
1. 复现问题
2. 最小化场景
3. 假设根因
4. 验证假设
5. 修复
6. 回归测试
```

### 审查阶段：requesting-code-review

```markdown
# 触发
/skill requesting-code-review

# 或对话中
"请审查这段代码"
```

**两阶段审查：**
1. **Spec 合规** - 是否满足设计？
2. **代码质量** - 风格/安全/测试/性能

### 压缩建议：auto-compact

```markdown
# 触发
/skill auto-compact

# 或对话中
"上下文快满了，建议压缩"
```

---

## Agent 角色

### coder - 代码实现

**职责：**
- 实现功能
- 写单元测试
- 自测验证

**何时使用：**
- 需要实现具体功能时

```markdown
/coder 实现用户登录功能
```

### reviewer - 代码审查

**职责：**
- 通用代码审查
- 风格检查
- 安全检查

**何时使用：**
- 实现完成后
- 提交前

```markdown
/reviewer 审查 auth.ts
```

### spec-compliance-reviewer - Spec 合规审查

**职责：**
- 验证实现是否符合设计
- 检查 done criteria
- 检查边界处理

**何时使用：**
- 两阶段审查的阶段 1

### debugger - 调试专家

**职责：**
- 系统化调试
- 根因分析
- 修复验证

**何时使用：**
- Bug 定位困难时
- 复杂问题调试

```markdown
/debugger 调试支付失败问题
```

### planner - 规划师

**职责：**
- 任务拆分
- 依赖分析
- 优先级排序

**何时使用：**
- 大型功能规划
- 多任务协调

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
1. 快速设计（brainstorming）
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

## 配置说明

### 集成到你的项目

在项目根目录创建 `.claude/CLAUDE.md`：

```markdown
# 我的项目配置

## 项目信息
- 项目名：my-app
- 技术栈：Node.js + React
- 规范：参考 harness-foundry/rules/

## 开发规范

### 使用 TDD
实现功能前先写测试，参考：
harness-foundry/skills/test-driven-development/SKILL.md

### 设计门禁
实现前必须先完成设计并获得批准，参考：
harness-foundry/core/rules/design-gate.md

### 两阶段审查
1. Spec 合规审查
2. 代码质量审查
参考：harness-foundry/core/review/two-stage-protocol.md

## 可用工具

### Skills
- brainstorming: 设计阶段
- writing-plans: 制定计划
- test-driven-development: TDD 开发
- systematic-debugging: 调试
- requesting-code-review: 代码审查

### 命令
node harness-foundry/scripts/security/scan.js  # 安全扫描
node harness-foundry/scripts/eval/run-skill-eval.js --all  # 测试
```

### 环境变量

```bash
# 连续学习开关（默认开启）
export CONTINUOUS_LEARNING=enabled

# 安全扫描严格模式
export SECURITY_SCAN_STRICT=true

# Token 优化
export MAX_THINKING_TOKENS=10000
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50
```

---

## 常见问题

### Q1: 如何在不使用全部功能时只选部分？

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

或启动 Dashboard：
```bash
npm run dashboard
```

### Q4: 如何运行测试？

```bash
# 测试所有 skills
node harness-foundry/scripts/eval/run-skill-eval.js --all

# 测试特定 skill
node harness-foundry/scripts/eval/run-skill-eval.js --skill brainstorming
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

### Q6: 连续学习提取的成果在哪？

```bash
# 查看所有学习
ls ~/.claude/memory/learned/

# 查看统计
cat ~/.claude/memory/learned/learned.json
```

### Q7: 如何自定义规则？

在项目根目录创建 `.claude/rules/`：

```bash
mkdir -p .claude/rules
cp harness-foundry/rules/*.md .claude/rules/
# 然后修改你需要的规则
```

---

## 快捷命令汇总

```bash
# Dashboard
npm run dashboard

# 安全扫描
node harness-foundry/scripts/security/scan.js

# Eval 测试
node harness-foundry/scripts/eval/run-skill-eval.js --all

# 可视化伴侣
node harness-foundry/scripts/visual-companion/server.js --open
```

---

## 版本信息

- **版本：** 1.0.0
- **更新日期：** 2026-07-02
- **新增功能：**
  - 连续学习系统
  - 强制设计门禁
  - 两阶段审查
  - Eval 框架
  - Token 优化策略
  - Dashboard GUI
  - 视觉伴侣
  - AgentShield 安全审计
