---
name: skill-evaluator
description: Skill Evaluator — 自动化 skill 质量评估工具
version: 1.0.0
status: core
domain: code
tags: [eval, testing, quality]
---

# Skill Evaluator

> 自动化验证 skill 定义和行为的工具

## 功能

- **Skill 定义验证**：检查 SKILL.md 格式是否符合规范
- **元数据检查**：验证 required fields、version、tags
- **行为断言**：执行 behavior.test.js 并报告结果
- **输出断言**：执行 output.test.js 并验证输出
- **集成验证**：在模拟工作流中测试 skill

## 使用方式

### CLI

```bash
# 评估单个 skill
node scripts/eval/run-skill-eval.js --skill brainstorming

# 评估全部 skills
node scripts/eval/run-skill-eval.js --all

# 仅验证定义
node scripts/eval/run-skill-eval.js --skill brainstorming --check-definition

# 输出 JSON
node scripts/eval/run-skill-eval.js --skill brainstorming --json
```

### API

```javascript
const { SkillEvaluator } = require('./scripts/eval/skill-evaluator.js');

// 创建评估器
const evaluator = new SkillEvaluator({
  basePath: 'D:/work/zhoupei/harness-foundry',
  verbose: true,
});

// 评估单个 skill
const result = await evaluator.evaluate('brainstorming');

// 评估多个 skills
const results = await evaluator.evaluateAll(['brainstorming', 'writing-plans']);

// 检查定义
const definitionCheck = await evaluator.checkDefinition('brainstorming');
```

## 输出格式

### 标准输出

```
=== Skill Evaluator ===
Skill: brainstorming
  [PASS] trigger-before-implementation
  [PASS] force-questioning
  [PASS] option-comparison
  [PASS] stop-after-design-approved
  [PASS] design-document-format
  [PASS] tradeoffs-presented

Summary: 6/6 tests passed
Status: PASS
```

### JSON 输出

```json
{
  "skill": "brainstorming",
  "timestamp": "2026-07-02T10:30:00.000Z",
  "tests": [
    {
      "id": "trigger-before-implementation",
      "type": "behavior",
      "status": "PASS",
      "description": "应在实现前触发 brainstorming"
    }
  ],
  "summary": {
    "total": 6,
    "passed": 6,
    "failed": 0,
    "passRate": 1.0
  },
  "status": "PASS"
}
```

## 测试覆盖表

| Skill | 行为测试 | 输出测试 | 定义检查 | 状态 |
|-------|---------|---------|---------|------|
| brainstorming | 4 | 3 | YES | DONE |
| writing-plans | 3 | 2 | YES | TODO |
| test-driven-development | 2 | 2 | YES | TODO |
| systematic-debugging | 3 | 2 | YES | TODO |
| requesting-code-review | 2 | 2 | YES | TODO |
| receiving-code-review | 2 | 2 | YES | TODO |
| novel-orchestrator | 3 | 2 | YES | TODO |

## 定义检查项

1. **必需字段**：
   - `name`: string
   - `description`: string
   - `version`: semver
   - `status`: core | peripheral | experimental

2. **可选字段**：
   - `tags`: string[]
   - `domain`: code | novel | news | shared
   - `category`: string

3. **格式检查**：
   - frontmatter 格式正确
   - 标题层级清晰
   - 代码块有语言标识

## 断言 API

```javascript
// 行为断言
assert.triggeredBefore(phase)
assert.questionsAsked(count)
assert.optionsProvided()
assert.stoppedAfterApproval()

// 输出断言
assert.matchesPattern(pattern)
assert.contains(keyword)
assert.maxLength(maxChars)
assert.hasSection(heading)

// 集成断言
assert.skillLoaded(slug)
assert.routeCorrect(params)
```

## 扩展测试用例

参见 `core/eval/framework.md` § 添加新 Skill 测试

## 限制

- 不执行真实的 LLM 调用（使用模拟输出）
- 不验证 skill 的实际效果（需人工审查）
- 不测试 skill 之间的交互（单独测试）

## 未来增强

- [ ] 支持真实 LLM 调用测试
- [ ] 支持 skill 交互测试
- [ ] 支持性能基准测试
- [ ] 支持 diff 测试（检测 skill 更新变化）
