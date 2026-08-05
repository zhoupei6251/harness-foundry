---
name: eval-framework
description: Skill Eval 框架 — 行为测试、输出测试、集成测试
version: 1.0.0
status: core
domain: code
tags: [eval, testing, quality]
---

# Skill Eval 框架

> 验证 skill 是否按预期工作，确保行为一致性

## 目的

- **行为验证**：Skill 是否在正确的时机触发
- **输出验证**：Skill 输出是否符合预期格式和质量
- **集成验证**：Skill 在真实工作流中是否正常工作

## 架构

```
tests/eval/
├── skills/                      # Skill 测试用例
│   ├── brainstorming/
│   │   ├── behavior.test.js     # 行为测试
│   │   ├── output.test.js       # 输出测试
│   │   ├── prompt.txt           # 测试输入
│   │   └── expected.md          # 期望输出
│   ├── writing-plans/
│   └── ...
├── integration/                 # 集成测试
│   └── dispatcher.test.js
└── runner.js                   # 测试运行器

core/eval/
├── framework.md                 # 本文档 — 框架说明
└── skill-evaluator.md          # Skill Evaluator 功能说明
```

## 测试类型

### 1. 行为测试 (behavior.test.js)

验证 Skill 的触发和执行行为：

```javascript
// tests/eval/skills/brainstorming/behavior.test.js
module.exports = {
  name: 'brainstorming-behavior',
  skill: 'brainstorming',
  tests: [
    {
      id: 'trigger-before-implementation',
      description: '应在实现前触发 brainstorming',
      assert: (ctx) => ctx.triggeredBefore('implementation'),
    },
    {
      id: 'force-questioning',
      description: '应强制提问而非直接执行',
      assert: (ctx) => ctx.questionsAsked > 0,
    },
    {
      id: 'option-comparison',
      description: '应提供选项对比',
      assert: (ctx) => ctx.optionsProvided === true,
    },
    {
      id: 'stop-after-design-approved',
      description: '设计批准后应停止 brainstorming',
      assert: (ctx) => ctx.stoppedAfterApproval === true,
    },
  ],
};
```

### 2. 输出测试 (output.test.js)

验证 Skill 输出的格式和质量：

```javascript
// tests/eval/skills/brainstorming/output.test.js
module.exports = {
  name: 'brainstorming-output',
  skill: 'brainstorming',
  tests: [
    {
      id: 'design-document-format',
      description: '设计文档格式正确',
      assert: (output) => {
        return output.includes('##') && output.includes('###');
      },
    },
    {
      id: 'tradeoffs-presented',
      description: '包含权衡分析',
      assert: (output) => {
        return /pros?|cons?|trade-?off/i.test(output);
      },
    },
    {
      id: 'sections-200-300-words',
      description: '每个章节 200-300 字',
      assert: (output) => {
        const sections = output.split(/^## /m).slice(1);
        return sections.every(s => s.length < 1500);
      },
    },
  ],
};
```

### 3. 集成测试 (integration/*.test.js)

验证 Skill 在真实工作流中的表现：

```javascript
// tests/eval/integration/dispatcher.test.js
module.exports = {
  name: 'dispatcher-skill-routing',
  tests: [
    {
      id: 'correct-skill-loaded',
      description: '根据 wu_type 正确加载 skill',
      assert: async (ctx) => {
        const result = await ctx.dispatch({
          agent_role: 'coder',
          wu_type: 'feature',
          wu_skills: 'auto',
        });
        return result.loadedSkills.includes('test-driven-development');
      },
    },
  ],
};
```

## 运行方式

### 单个 Skill 测试

```bash
node scripts/eval/run-skill-eval.js --skill brainstorming
```

### 全部测试

```bash
node scripts/eval/run-skill-eval.js --all
```

### 指定测试类型

```bash
node scripts/eval/run-skill-eval.js --skill brainstorming --type behavior
node scripts/eval/run-skill-eval.js --skill brainstorming --type output
node scripts/eval/run-skill-eval.js --skill brainstorming --type integration
```

### JSON 输出

```bash
node scripts/eval/run-skill-eval.js --skill brainstorming --json
```

## 测试覆盖表

| Skill | 行为测试 | 输出测试 | 集成测试 | 状态 |
|-------|---------|---------|---------|------|
| brainstorming | 4 | 3 | 1 | TODO |
| writing-plans | 3 | 2 | 1 | TODO |
| test-driven-development | 2 | 2 | 1 | TODO |
| systematic-debugging | 3 | 2 | 1 | TODO |
| requesting-code-review | 2 | 2 | 1 | TODO |

## 测试用例命名规范

- 文件名：`*.test.js`
- 测试 ID：`kebab-case`，如 `trigger-before-implementation`
- 描述：简洁说明验证内容

## 断言上下文

```javascript
// ctx 对象包含以下属性
{
  // 行为测试
  triggeredBefore: (phase) => boolean,  // phase: 'implementation' | 'design' | 'review'
  questionsAsked: number,
  optionsProvided: boolean,
  stoppedAfterApproval: boolean,

  // 输出测试
  output: string,

  // 集成测试
  dispatch: (params) => Promise<DispatchResult>,
  loadSkill: (slug) => Promise<SkillDefinition>,
}
```

## 添加新 Skill 测试

1. 创建目录：`tests/eval/skills/<skill-name>/`
2. 添加 `behavior.test.js`（必须）
3. 添加 `output.test.js`（可选）
4. 更新 `tests/eval/runner.js` 中的 `skillList`

## 参考

- 参考计划：历史实现计划中的 § Task 4
