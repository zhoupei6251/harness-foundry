# Harness Foundry Code 域综合改进计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 完善 code 域，对齐 ECC 和 Superpowers 的最佳实践

**Architecture:** 
- 连续学习系统：基于会话提取模式，自动沉淀到 skills
- 强制设计门禁：`<HARD-GATE>` 阻止未批准设计就写代码
- 两阶段 Review：Spec 合规 → 代码质量分离检查
- Eval 框架：技能行为测试验证
- Token 优化：模型选择策略 + 上下文压缩
- Dashboard GUI：可视化浏览组件
- 视觉伴侣：brainstorming 时的 mockup 工具
- AgentShield 增强：安全审计能力

**Tech Stack:** Node.js (hooks), Markdown (skills/agents), JSON (config)

---

## Phase 1: P0 核心改进

### Task 1: 创建连续学习系统

**Files:**
- Create: `core/memory/continuous-learning/protocol.md`
- Create: `core/memory/continuous-learning/extractor.md`
- Create: `hooks/continuous-learning/evaluate-session.js`
- Create: `skills/continuous-learning/SKILL.md`
- Modify: `core/memory/state.json` (添加 learning 字段)

**Step 1: 创建连续学习协议文档**

```markdown
# 连续学习协议

## 触发时机
- 会话结束时（Stop hook）
- 用户明确要求学习时

## 学习内容
1. 调试技术（有效的 bug 定位方法）
2. 项目特定模式（架构决策、命名规范）
3. 工具使用技巧（高效的命令组合）
4. 错误处理模式（异常捕获方式）

## 输出位置
- `~/.claude/memory/learned/` - 学习到的技能
- `~/.claude/memory/patterns/` - 通用模式

## 格式
```markdown
---
name: <slug>
description: <一句话描述>
trigger: <何时触发>
confidence: <0-100>
---
<详细说明>
```
```

**Step 2: 创建会话提取器**

```javascript
// scripts/continuous-learning/extractor.js
const fs = require('fs');
const path = require('path');

const LEARNED_DIR = path.join(process.env.HOME, '.claude/memory/learned');
const SESSION_DIR = path.join(process.env.HOME, '.claude/sessions');

function extractPatterns(sessionFile) {
  const content = fs.readFileSync(sessionFile, 'utf-8');
  const patterns = [];
  
  // 提取调试模式
  const debugPattern = /调试|debug|定位|root cause/gi;
  if (debugPattern.test(content)) {
    patterns.push({
      type: 'debugging',
      confidence: 80,
      description: '有效的调试技术'
    });
  }
  
  // 提取项目模式
  const projectPattern = /项目特定|规范|约定/gi;
  if (projectPattern.test(content)) {
    patterns.push({
      type: 'project-pattern',
      confidence: 70,
      description: '项目特定模式'
    });
  }
  
  return patterns;
}

module.exports = { extractPatterns };
```

**Step 3: 创建 Evaluate-Session Hook**

```javascript
// scripts/hooks/evaluate-session.js
#!/usr/bin/env node
const { extractPatterns } = require('../continuous-learning/extractor');
const path = require('path');
const fs = require('fs');

function run(rawInput) {
  const input = JSON.parse(rawInput);
  const sessionFile = input.session_file;
  
  if (!sessionFile || !fs.existsSync(sessionFile)) {
    console.error('[EvaluateSession] No session file found');
    return JSON.stringify({ success: false });
  }
  
  const patterns = extractPatterns(sessionFile);
  
  patterns.forEach(p => {
    const filename = `${p.type}-${Date.now()}.md`;
    const filepath = path.join(process.env.HOME, '.claude/memory/learned', filename);
    
    const content = `---
name: ${p.type}-${Date.now()}
description: "${p.description}"
trigger: "${p.trigger || 'auto-detected'}"
confidence: ${p.confidence}
date: ${new Date().toISOString()}
---

# ${p.type}

${p.content || ''}
`;
    fs.writeFileSync(filepath, content);
  });
  
  return JSON.stringify({ success: true, patterns });
}

if (require.main === module) {
  const input = fs.readFileSync(0, 'utf-8');
  console.log(run(input));
}
```

**Step 4: 创建 continuous-learning Skill**

```markdown
---
name: continuous-learning
description: "从会话中自动提取模式并沉淀为 skills。用于持续改进 agent 行为。"
---

# Continuous Learning

## 何时使用
- 会话结束时自动触发
- 用户说"记住这个"、"学习这个"时

## 学习协议

### 1. 提取触发
会话结束时的 Stop hook 自动提取：
- 有效的调试方法
- 项目特定模式
- 工具使用技巧
- 错误处理方式

### 2. 模式验证
提取后需要验证：
- 是否通用（适用于其他项目）
- 是否准确（描述清晰）
- 是否可操作（触发条件明确）

### 3. 沉淀位置
| 类型 | 位置 |
|------|------|
| 通用技能 | `~/.claude/skills/<slug>/` |
| 项目技能 | `.claude/skills/<slug>/` |
| 项目规则 | `.claude/rules/<slug>.md` |

### 4. 格式
```markdown
---
name: <slug>
description: <一句话描述>
trigger: <何时触发>
confidence: <0-100>
---

# 标题

<详细说明>
```

## 命令
- `/learn-status` - 查看已学习技能
- `/learn-evolve` - 将模式聚合成 skill
- `/learn-prune` - 清理过期学习
```

**Step 5: 修改 state.json 添加 learning 字段**

在 `core/memory/state.json` 中添加：
```json
{
  "learning": {
    "last_extract": "2026-07-02T00:00:00Z",
    "total_patterns": 0,
    "active_patterns": []
  }
}
```

---

### Task 2: 创建强制设计门禁

**Files:**
- Create: `core/rules/design-gate.md`
- Modify: `core/NEVER.md` (添加 HARD-GATE 说明)
- Create: `hooks/pre-implementation/check-gate.js`
- Modify: `skills/brainstorming/SKILL.md`

**Step 1: 创建设计门禁规则**

```markdown
---
name: design-gate
description: "强制设计门禁：任何实现前必须先有批准的设计文档"
applies_to: [code]
---

# 设计门禁规则

## 核心原则

**`<HARD-GATE>` 在设计被用户批准前，禁止：**
- 写任何实现代码
- 创建任何文件（设计文档除外）
- 执行任何构建命令
- 调用实现类 skill

## 门禁检查点

1. **需求澄清阶段** - brainstorming skill 完成
2. **设计方案阶段** - 设计文档已写
3. **用户批准阶段** - 用户明确批准设计
4. **实现计划阶段** - writing-plans skill 生成任务列表

## 违规处理

如果检测到违反门禁：
1. 立即停止当前动作
2. 输出 `[HARD-GATE] 设计未批准，请先完成设计`
3. 列出需要完成的设计步骤

## 例外情况

以下情况可以跳过设计门禁：
- `quick-fix` 意图识别（已定位的小 bug）
- 用户明确说"直接改"
- 单行配置变更
```

**Step 2: 更新 NEVER.md 添加 HARD-GATE 说明**

在 `core/NEVER.md` 中添加：
```markdown
## 设计门禁（HARD-GATE）

**禁止在设计批准前实现：**
- ❌ 写代码
- ❌ 创建文件
- ❌ 运行构建
- ❌ 调用实现 skill

**例外：**
- quick-fix（小改动）
- 用户明确授权
```

**Step 3: 创建门禁检查 Hook**

```javascript
// scripts/hooks/check-gate.js
#!/usr/bin/env node

const fs = require('fs');

const DESIGN_APPROVED_FILE = '.claude/.design-approved';
const IMPLEMENTATION_PATTERNS = [
  /Write\(|Edit\(|Bash.*(npm|pnpm|yarn|go| cargo)/,
  /create_file|scaffold/
];

function checkGate(tool, toolInput, conversationHistory) {
  // 检查是否需要门禁
  const isCodeIntent = conversationHistory.some(m => 
    /实现|写代码|功能|feature|implement/.test(m.content)
  );
  
  if (!isCodeIntent) {
    return { pass: true };
  }
  
  // 检查设计是否已批准
  if (fs.existsSync(DESIGN_APPROVED_FILE)) {
    const approved = JSON.parse(fs.readFileSync(DESIGN_APPROVED_FILE, 'utf-8'));
    if (approved.status === 'approved' && approved.timestamp) {
      const hoursSinceApproval = (Date.now() - new Date(approved.timestamp).getTime()) / 3600000;
      if (hoursSinceApproval < 24) {
        return { pass: true };
      }
    }
  }
  
  // 检查是否在 brainstorming 或 writing-plans
  const inDesignPhase = conversationHistory.some(m =>
    /brainstorming|writing-plans|设计|方案/.test(m.content)
  );
  
  if (!inDesignPhase) {
    return { 
      pass: false, 
      message: '[HARD-GATE] 设计未批准。请先使用 brainstorming skill 完成设计并获得用户批准。' 
    };
  }
  
  return { pass: true };
}

module.exports = { checkGate };
```

**Step 4: 更新 brainstorming Skill 添加 HARD-GATE**

修改 `skills/brainstorming/SKILL.md`，在开头添加：

```markdown
<HARD-GATE>
在设计被用户批准前，禁止：
- 写任何代码
- 创建任何文件
- 执行构建命令
- 调用实现类 skill

违反将导致立即停止并输出门禁消息。
</HARD-GATE>
```

---

### Task 3: 创建两阶段 Review 系统

**Files:**
- Create: `core/review/two-stage-protocol.md`
- Create: `skills/two-stage-review/SKILL.md`
- Modify: `agents/reviewer.md` (添加阶段说明)
- Create: `agents/spec-compliance-reviewer.md`
- Modify: `core/orchestration/dispatcher-workflow.md` (更新审查流程)

**Step 1: 创建两阶段审查协议**

```markdown
# 两阶段审查协议

## 概述

审查分为两个独立阶段，确保：
1. **第一阶段：Spec 合规** - 实现是否满足设计
2. **第二阶段：代码质量** - 代码本身是否优秀

## 阶段 1: Spec 合规审查

### 检查项
- [ ] 所有 done criteria 是否满足
- [ ] 是否有遗漏的功能点
- [ ] 实现是否偏离设计意图
- [ ] 边界情况是否处理

### 输出格式
```markdown
## Spec 合规审查

### 结果：PASS | FAIL | PARTIAL

### 缺失项
- <具体缺失>

### 偏离项
- <具体偏离>

### 建议
- <改进建议>
```

## 阶段 2: 代码质量审查

### 检查项
- [ ] 代码风格是否一致
- [ ] 是否有安全漏洞
- [ ] 测试覆盖是否充分
- [ ] 是否有性能问题

### 输出格式
```markdown
## 代码质量审查

### 结果：PASS | FAIL

### 严重问题（阻塞）
- <问题>

### 重要问题（需修复）
- <问题>

### 建议（可选）
- <建议>
```

## 执行顺序

```
实现完成 → Spec 合规审查 → 返修（如需要）→ 代码质量审查 → 完成
```

## 审查角色

| 阶段 | 角色 | 文件 |
|------|------|------|
| Spec 合规 | spec-compliance-reviewer | `agents/spec-compliance-reviewer.md` |
| 代码质量 | reviewer | `agents/reviewer.md` |
```

**Step 2: 创建 spec-compliance-reviewer Agent**

```markdown
---
name: spec-compliance-reviewer
description: "Spec 合规审查：验证实现是否满足设计规范"
---

# Spec Compliance Reviewer

## 角色

审查实现是否严格遵循批准的设计文档。

## 输入

- 设计文档路径
- 实现产物路径
- Done criteria 列表

## 检查流程

### 1. 读取设计文档
读取 `docs/plans/YYYY-MM-DD-<topic>-design.md`

### 2. 对照 Done Criteria
逐项检查：
- [ ] 每一项 done criteria 是否有对应实现
- [ ] 实现方式是否符合设计意图
- [ ] 是否有设计外的功能混入

### 3. 检查边界情况
- 设计中提到的边界是否处理
- 异常流程是否有对应实现

### 4. 输出报告

```markdown
## Spec 合规审查报告

### 审查对象
- 设计文档: <path>
- 实现: <path>
- 时间: <timestamp>

### 结果
- [ ] PASS - 完全符合设计
- [ ] PARTIAL - 部分符合，有遗漏
- [ ] FAIL - 偏离设计

### 详细检查

#### ✅ 符合项
- <列表>

#### ❌ 缺失项
- <描述>

#### ⚠️ 偏离项
- <描述 + 建议>

### 阻塞问题
无 | <问题列表>

### 下一步
通过 | 返回给实现者返修
```
```

**Step 3: 创建两阶段审查 Skill**

```markdown
---
name: two-stage-review
description: "两阶段审查：先验证 Spec 合规，再检查代码质量"
---

# Two-Stage Review

## 何时使用
- 实现完成后
- 代码审查前

## 阶段 1: Spec 合规审查

### 执行者
`spec-compliance-reviewer` agent

### 检查点
1. 读取设计文档
2. 对照 done criteria
3. 检查边界处理
4. 验证无偏离

### 通过条件
- 所有 done criteria 满足
- 无设计偏离
- 边界情况已处理

## 阶段 2: 代码质量审查

### 执行者
`reviewer` agent

### 检查点
1. 代码风格一致性
2. 安全性检查
3. 测试覆盖
4. 性能考虑

### 通过条件
- 无阻塞性问题
- 重要问题已修复

## 流程

```
实现完成
    ↓
阶段 1: Spec 合规审查
    ↓
[失败?] → 返回实现者返修 → 重新审查
    ↓
[通过]
    ↓
阶段 2: 代码质量审查
    ↓
[失败?] → 返回实现者返修 → 重新审查
    ↓
[通过] → 完成
```
```

**Step 4: 更新 dispatcher-workflow.md 审查流程**

在 `core/orchestration/dispatcher-workflow.md` 的 GROUP-2 部分：

```markdown
### GROUP-2：串行审查（两阶段）

| 阶段 | 审查者 | 审查内容 |
| --- | --- | --- |
| **阶段 1** | spec-compliance-reviewer | Spec 合规 + Done criteria |
| **阶段 2** | reviewer | 代码质量 + 安全 + 测试 |

**两阶段审查流程：**
1. 阶段 1 通过 → 进入阶段 2
2. 阶段 1 失败 → 返回 WU 实现者返修（最多 2 次）
3. 阶段 2 失败 → 返回 WU 实现者返修（最多 2 次）
4. 2 次返修仍不通过 → 输出最终审查报告，提示用户介入
```

---

## Phase 2: P1 重要改进

### Task 4: 创建 Eval 框架

**Files:**
- Create: `core/eval/framework.md`
- Create: `core/eval/skill-evaluator.md`
- Create: `tests/eval/skill-behavior.test.js`
- Create: `scripts/eval/run-skill-eval.js`

**Step 1: 创建 Eval 框架文档**

```markdown
# Skill Eval 框架

## 目的

验证 skill 是否按预期工作，确保行为一致性。

## 架构

```
tests/eval/
├── skills/              # 每个 skill 的测试
│   ├── brainstorming/
│   │   ├── prompt.txt   # 测试 prompt
│   │   └── expected.md  # 期望输出模式
│   └── writing-plans/
│       └── ...
└── runner.js            # 测试运行器
```

## 测试类型

### 1. 行为测试
验证 skill 的检查点是否执行

### 2. 输出测试
验证输出格式是否符合规范

### 3. 集成测试
验证 skill 在实际场景中的表现

## 运行方式

```bash
# 运行所有 skill 测试
node tests/eval/run-all.js

# 运行单个 skill 测试
node tests/eval/run-skill-eval.js brainstorming
```
```

**Step 2: 创建 Skill Evaluator**

```markdown
# Skill Evaluator

## 功能

自动评估 skill 行为是否符合规范。

## 使用方式

### 命令行
```bash
node scripts/eval/run-skill-eval.js <skill-name>
```

### 输出
```json
{
  "skill": "brainstorming",
  "tests": [
    {
      "name": "强制提问",
      "result": "PASS",
      "details": "..."
    }
  ],
  "summary": {
    "total": 5,
    "passed": 4,
    "failed": 1
  }
}
```

## 测试覆盖

| Skill | 测试数 | 优先级 |
|-------|--------|--------|
| brainstorming | 5 | P0 |
| writing-plans | 4 | P0 |
| continuous-learning | 3 | P1 |
| two-stage-review | 3 | P1 |
```

**Step 3: 创建测试运行器**

```javascript
// scripts/eval/run-skill-eval.js
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const SKILLS_DIR = path.join(__dirname, '../../skills');
const TESTS_DIR = path.join(__dirname, '../../tests/eval/skills');

function loadSkill(skillName) {
  const skillPath = path.join(SKILLS_DIR, skillName, 'SKILL.md');
  if (!fs.existsSync(skillPath)) {
    throw new Error(`Skill not found: ${skillName}`);
  }
  return fs.readFileSync(skillPath, 'utf-8');
}

function runTests(skillName) {
  const testsDir = path.join(TESTS_DIR, skillName);
  
  if (!fs.existsSync(testsDir)) {
    return { 
      skill: skillName, 
      tests: [],
      summary: { total: 0, passed: 0, failed: 0 },
      status: 'NO_TESTS'
    };
  }
  
  const testFiles = fs.readdirSync(testsDir).filter(f => f.endsWith('.test.js'));
  const results = testFiles.map(f => {
    const test = require(path.join(testsDir, f));
    return test.run();
  });
  
  return {
    skill: skillName,
    tests: results,
    summary: {
      total: results.length,
      passed: results.filter(r => r.result === 'PASS').length,
      failed: results.filter(r => r.result === 'FAIL').length
    }
  };
}

if (require.main === module) {
  const skillName = process.argv[2];
  if (!skillName) {
    console.error('Usage: node run-skill-eval.js <skill-name>');
    process.exit(1);
  }
  
  const result = runTests(skillName);
  console.log(JSON.stringify(result, null, 2));
}
```

---

### Task 5: 创建 Token 优化策略

**Files:**
- Create: `core/optimization/token-strategy.md`
- Create: `core/optimization/model-selector.md`
- Create: `skills/auto-compact/SKILL.md`
- Modify: `core/memory/state.json` (添加 optimization 字段)

**Step 1: 创建 Token 优化策略文档**

```markdown
# Token 优化策略

## 模型选择策略

### 默认选择

| 任务类型 | 模型 | 理由 |
|---------|------|------|
| 简单编辑 | sonnet | 性价比最高 |
| 探索搜索 | haiku | 快速廉价 |
| 多文件实现 | sonnet | 平衡质量和成本 |
| 复杂架构 | opus | 深度推理 |
| 安全审查 | opus | 不可遗漏漏洞 |
| PR 审查 | sonnet | 理解上下文 |

### 升级到 Opus 的条件

- 首次尝试失败
- 任务跨越 5+ 文件
- 架构决策
- 安全关键代码

## 上下文压缩策略

### 压缩时机

1. **主动压缩**：研究/探索完成后，实现前
2. **里程碑压缩**：完成里程碑后，下一个开始前
3. **失败后压缩**：方法失败后，尝试新方法前

### 不要压缩的时机

- 实现中途（会丢失变量名、文件路径、状态）
- 调试过程中
- 复杂重构进行中

## 会话管理

### `/clear` 时机
- 任务切换
- 无关话题

### `/compact` 时机
- 逻辑断点
- 阶段完成

### `/cost` 查看
- 长时间会话
- 大型任务

## 配置文件

```json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50"
  }
}
```

### 设置说明

| 设置 | 默认 | 推荐 | 影响 |
|-----|------|------|------|
| model | opus | sonnet | ~60% 成本降低 |
| MAX_THINKING_TOKENS | 31,999 | 10,000 | ~70% 思考成本降低 |
| CLAUDE_AUTOCOMPACT_PCT_OVERRIDE | 95 | 50 | 更早压缩，质量更好 |
```

**Step 2: 创建模型选择器**

```markdown
# 模型选择器

## 自动路由规则

### 根据任务特征选择

```
特征分析 → 模型路由

特征:
- 文件数量: 1 | 2-5 | 5+
- 复杂度: low | medium | high
- 类型: explore | edit | implement | review | debug

路由:
- explore + any → haiku
- edit + 1-file + low → haiku
- edit + 2-5-files + medium → sonnet
- implement + 5+ + high → opus
- review + any → sonnet
- debug + high → opus
- security + any → opus
```

### 手动覆盖

```bash
/model sonnet  # 降级
/model opus    # 升级
```

## Skill 集成

`model-selector` skill 在任务开始时自动调用，分析任务特征并建议模型。
```

---

## Phase 3: P2 可选改进

### Task 6: 创建 Dashboard GUI

**Files:**
- Create: `scripts/dashboard/dashboard.py`
- Create: `scripts/dashboard/styles.css`
- Modify: `package.json` (添加 dashboard 命令)

**Step 1: 创建 Dashboard Python 脚本**

```python
#!/usr/bin/env python3
"""Harness Foundry Dashboard - 可视化浏览组件"""

import tkinter as tk
from tkinter import ttk
import json
import os
from pathlib import Path

class HarnessDashboard:
    def __init__(self, root):
        self.root = root
        self.root.title("Harness Foundry Dashboard")
        self.root.geometry("1000x700")
        
        self.setup_styles()
        self.create_widgets()
        self.load_data()
    
    def setup_styles(self):
        self.style = ttk.Style()
        self.style.theme_use('clam')
        self.style.configure('Title.TLabel', font=('Arial', 16, 'bold'))
        self.style.configure('Header.TLabel', font=('Arial', 12, 'bold'))
        
    def create_widgets(self):
        # 顶部标题
        title = ttk.Label(self.root, text="Harness Foundry", style='Title.TLabel')
        title.pack(pady=20)
        
        # 标签页
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Skills 标签
        skills_frame = ttk.Frame(notebook)
        notebook.add(skills_frame, text='Skills')
        self.create_skills_tab(skills_frame)
        
        # Agents 标签
        agents_frame = ttk.Frame(notebook)
        notebook.add(agents_frame, text='Agents')
        self.create_agents_tab(agents_frame)
        
        # 统计标签
        stats_frame = ttk.Frame(notebook)
        notebook.add(stats_frame, text='Statistics')
        self.create_stats_tab(stats_frame)
    
    def create_skills_tab(self, parent):
        # 搜索框
        search_frame = ttk.Frame(parent)
        search_frame.pack(fill='x', padx=10, pady=5)
        
        ttk.Label(search_frame, text="Search:").pack(side='left')
        self.skill_search = ttk.Entry(search_frame, width=30)
        self.skill_search.pack(side='left', padx=5)
        self.skill_search.bind('<KeyRelease>', self.filter_skills)
        
        # Skills 列表
        list_frame = ttk.Frame(parent)
        list_frame.pack(fill='both', expand=True, padx=10, pady=5)
        
        self.skills_tree = ttk.Treeview(list_frame, columns=('name', 'category', 'status'), show='headings')
        self.skills_tree.heading('name', text='Name')
        self.skills_tree.heading('category', text='Category')
        self.skills_tree.heading('status', text='Status')
        self.skills_tree.column('name', width=200)
        self.skills_tree.column('category', width=150)
        self.skills_tree.column('status', width=100)
        self.skills_tree.pack(side='left', fill='both', expand=True)
        
        scrollbar = ttk.Scrollbar(list_frame, orient='vertical', command=self.skills_tree.yview)
        scrollbar.pack(side='right', fill='y')
        self.skills_tree.configure(yscrollcommand=scrollbar.set)
    
    def create_agents_tab(self, parent):
        # Agents 列表
        list_frame = ttk.Frame(parent)
        list_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.agents_tree = ttk.Treeview(list_frame, columns=('name', 'domain', 'description'), show='headings')
        self.agents_tree.heading('name', text='Name')
        self.agents_tree.heading('domain', text='Domain')
        self.agents_tree.heading('description', text='Description')
        self.agents_tree.pack(fill='both', expand=True)
    
    def create_stats_tab(self, parent):
        # 统计信息
        stats_frame = ttk.Frame(parent)
        stats_frame.pack(fill='both', expand=True, padx=20, pady=20)
        
        self.stats_labels = {}
        stats = [
            ('Total Skills', 'total_skills'),
            ('Total Agents', 'total_agents'),
            ('Active Sessions', 'active_sessions'),
            ('Memory Patterns', 'memory_patterns')
        ]
        
        for i, (label, key) in enumerate(stats):
            row = i // 2
            col = i % 2
            frame = ttk.LabelFrame(stats_frame, text=label, padding=10)
            frame.grid(row=row, column=col, padx=10, pady=10, sticky='nsew')
            
            value_label = ttk.Label(frame, text="0", font=('Arial', 24, 'bold'))
            value_label.pack()
            self.stats_labels[key] = value_label
    
    def load_data(self):
        # 加载 skills
        skills_dir = Path('skills')
        if skills_dir.exists():
            skills = [d.name for d in skills_dir.iterdir() if d.is_dir()]
            for skill in skills:
                self.skills_tree.insert('', 'end', values=(skill, 'general', 'active'))
            self.stats_labels['total_skills'].config(text=str(len(skills)))
        
        # 加载 agents
        agents_dir = Path('agents')
        if agents_dir.exists():
            agents = list(agents_dir.glob('*.md'))
            for agent in agents:
                name = agent.stem
                domain = 'code' if name.startswith(('coder', 'reviewer', 'debugger')) else 'shared'
                self.agents_tree.insert('', 'end', values=(name, domain, ''))
            self.stats_labels['total_agents'].config(text=str(len(agents)))
    
    def filter_skills(self, event):
        # 过滤 skills
        pass

if __name__ == '__main__':
    root = tk.Tk()
    app = HarnessDashboard(root)
    root.mainloop()
```

---

### Task 7: 创建视觉伴侣工具

**Files:**
- Create: `scripts/visual-companion/server.js`
- Create: `scripts/visual-companion/static/`
- Create: `skills/brainstorming/visual-companion.md`

**Step 1: 创建 Visual Companion Server**

```javascript
// scripts/visual-companion/server.js
#!/usr/bin/env node

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 3847;
const STATIC_DIR = path.join(__dirname, 'static');

const mimeTypes = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg'
};

function serveStatic(req, res) {
  let filePath = path.join(STATIC_DIR, req.url === '/' ? 'index.html' : req.url);
  
  if (!fs.existsSync(filePath)) {
    res.writeHead(404);
    res.end('Not found');
    return;
  }
  
  const ext = path.extname(filePath);
  const contentType = mimeTypes[ext] || 'text/plain';
  
  res.writeHead(200, { 'Content-Type': contentType });
  fs.createReadStream(filePath).pipe(res);
}

function handlePost(req, res) {
  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    const data = JSON.parse(body);
    
    // 处理不同类型的请求
    if (data.type === 'mockup') {
      // 生成 mockup 响应
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        success: true, 
        mockup: generateMockup(data) 
      }));
    } else if (data.type === 'diagram') {
      // 生成图表
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        success: true, 
        diagram: generateDiagram(data) 
      }));
    }
  });
}

function generateMockup(data) {
  return {
    type: 'html',
    content: `<div class="mockup">${data.description}</div>`
  };
}

function generateDiagram(data) {
  return {
    type: 'mermaid',
    content: data.structure
  };
}

const server = http.createServer((req, res) => {
  if (req.method === 'GET') {
    serveStatic(req, res);
  } else if (req.method === 'POST') {
    handlePost(req, res);
  }
});

server.listen(PORT, () => {
  console.log(`Visual Companion running at http://localhost:${PORT}`);
  // 自动打开浏览器
  spawn('open', [`http://localhost:${PORT}`]);
});
```

**Step 2: 创建 Visual Companion Skill 文档**

```markdown
# Visual Companion Guide

## 功能

在 brainstorming 过程中提供可视化辅助。

## 何时使用

当问题用图形表达更清晰时：
- UI 布局对比
- 架构图
- 数据流图
- 组件关系图

## 不适合

- 概念性问题
- 需求澄清
- 选项对比（文本更清晰）

## 使用方式

1. brainstorming 过程中判断是否需要可视化
2. 如果需要，在独立消息中询问：
   > "这个部分可能用图形展示更清楚，需要我打开可视化工具吗？"
3. 用户同意后，启动 visual-companion server
4. 在工具中创建相应的可视化
5. 将链接分享给用户

## 工具功能

### Mockup 创建
- 拖拽式 UI 组件
- 实时预览
- 导出为 HTML

### 图表生成
- Mermaid 语法支持
- 流程图
- 时序图
- 架构图
```

---

### Task 8: AgentShield 增强

**Files:**
- Create: `skills/agent-shield/SKILL.md`
- Create: `scripts/security/scan.js`
- Create: `hooks/security/pre-prompt-guard.js`
- Modify: `hooks/guardrails/guardrail-config.json` (添加规则)

**Step 1: 创建 AgentShield Skill**

```markdown
---
name: agent-shield
description: "安全审计：扫描配置漏洞、注入风险、MCP 安全问题"
---

# AgentShield

## 功能

对 Harness Foundry 配置进行安全审计。

## 扫描范围

### 1. Secret 检测
检测硬编码的密钥、token、密码：
- API keys (sk-, ghp_, AKIA...)
- 私钥文件
- 密码模式

### 2. 权限审计
检查工具权限配置：
- 文件系统访问
- 网络访问
- Shell 执行权限

### 3. Hook 注入分析
检查 hooks 是否安全：
- 命令注入风险
- 路径遍历风险
- 恶意脚本

### 4. MCP 安全
评估 MCP 服务器风险：
- 数据外泄风险
- 权限过度
- 可信度评估

## 使用方式

### 命令行
```bash
node scripts/security/scan.js
```

### Skill
```bash
/agent-shield scan
```

## 输出格式

```markdown
## AgentShield 安全报告

### 扫描时间
<timestamp>

### 总体评分
A | B | C | D | F

### 发现问题

#### 严重（必须修复）
- <问题>

#### 重要（建议修复）
- <问题>

#### 警告（可选）
- <问题>

### 建议
- <改进建议>
```
```

**Step 2: 创建安全扫描脚本**

```javascript
// scripts/security/scan.js
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const SCAN_PATTERNS = {
  secrets: [
    /sk-[a-zA-Z0-9]{48}/,
    /ghp_[a-zA-Z0-9]{36}/,
    /AKIA[0-9A-Z]{16}/,
    /[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}:[a-zA-Z0-9]+/
  ],
  injection: [
    /\$([^\\s]+)/,
    /\$\{.*\}/,
    /\`.*\$\{.*\}.*\`/
  ],
  pathTraversal: [
    /\.\.\//,
    /\.\.\\/
  ]
};

function scanFile(filepath) {
  const content = fs.readFileSync(filepath, 'utf-8');
  const issues = [];
  
  // 检查 secrets
  SCAN_PATTERNS.secrets.forEach(pattern => {
    const matches = content.match(pattern);
    if (matches) {
      issues.push({
        type: 'SECRET',
        severity: 'CRITICAL',
        pattern: pattern.toString(),
        matches: matches.length
      });
    }
  });
  
  // 检查注入风险
  SCAN_PATTERNS.injection.forEach(pattern => {
    const matches = content.match(pattern);
    if (matches) {
      issues.push({
        type: 'INJECTION',
        severity: 'HIGH',
        pattern: pattern.toString(),
        matches: matches.length
      });
    }
  });
  
  return issues;
}

function runScan() {
  const scanPaths = [
    'settings.json',
    'hooks/hooks.json',
    'agents/*.md',
    'skills/**/*.md'
  ];
  
  const results = {
    timestamp: new Date().toISOString(),
    files: 0,
    issues: []
  };
  
  // 扫描文件
  // ... (简化实现)
  
  console.log(JSON.stringify(results, null, 2));
}

if (require.main === module) {
  runScan();
}

module.exports = { scanFile, runScan };
```

---

## 总结

| Phase | Tasks | Priority | Effort |
|-------|-------|----------|--------|
| P0 | 3 | 必须 | 高 |
| P1 | 2 | 应该 | 中 |
| P2 | 3 | 可以 | 低-中 |

**总任务数**: 8
**预计时间**: 2-3 周（逐步实现）
