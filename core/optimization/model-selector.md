# 模型选择器

> **功能**：基于任务特征自动建议最合适的模型，实现成本效益最大化。

## 自动路由规则

### 决策流程

```
任务输入
    ↓
特征分析 → 文件数量 + 复杂度 + 任务类型
    ↓
路由矩阵匹配
    ↓
模型建议
    ↓
[可选] 手动覆盖
```

### 特征定义

| 维度 | 值 | 说明 |
|-----|---|-----|
| **文件数量** | 1 / 2-5 / 5+ | 涉及的文件数量 |
| **复杂度** | low / medium / high | 任务复杂度直觉判断 |
| **任务类型** | explore / edit / implement / review / debug / security | 任务分类 |

### 路由矩阵

| 文件数 | 复杂度 | 任务类型 | 推荐模型 | 条件 |
|-------|-------|---------|---------|-----|
| 1 | low | explore | Haiku | 纯搜索 |
| 1 | low | edit | Haiku | 单文件修改 |
| 1 | medium | edit | Sonnet | 需要理解上下文 |
| 2-5 | any | explore | Haiku | 快速搜索 |
| 2-5 | low | edit | Sonnet | 多处小改 |
| 2-5 | medium | implement | Sonnet | 标准实现 |
| 2-5 | high | implement | Opus | 复杂逻辑 |
| 5+ | any | explore | Sonnet | 全面搜索 |
| 5+ | any | implement | Opus | 架构级变更 |
| any | any | review | Sonnet | PR/代码审查 |
| any | any | security | Opus | 安全相关 |
| any | high | debug | Opus | 复杂调试 |

### 升级触发器

以下情况自动升级（即使原规则推荐更低模型）：

1. **首次尝试失败** - 连续 2 次输出错误或质量不足
2. **循环检测** - 发现重复尝试相同方法
3. **上下文溢出** - 上下文使用超过 70%
4. **用户明确要求** - 用户说"仔细"、"深入"、"全面"

### 降级触发器

以下情况可降级（需确认任务简单）：

1. **任务简化** - 用户缩小范围
2. **模式识别** - 发现是重复性修改
3. **用户许可** - 用户说"快速处理"

## 手动覆盖

### 命令方式

```bash
/model sonnet   # 降级到 Sonnet
/model opus     # 升级到 Opus
/model haiku    # 降级到 Haiku
/model auto     # 恢复自动选择
```

### 在对话中

用户可以直接说：
- "用 Haiku 处理这个" / "use haiku for this"
- "这个需要 Opus" / "this needs opus"
- "切到 Sonnet" / "switch to sonnet"

## Skill 集成

### auto model-selector

当 `model-selector` skill 被调用时：

1. 分析当前任务描述
2. 评估文件数量和复杂度
3. 匹配路由矩阵
4. 输出建议和理由

### 输出格式

```markdown
## 模型建议

**推荐模型**: Sonnet
**理由**: 多文件实现任务（3个文件），中等复杂度
**成本估算**: ~4x Haiku

**升级条件**（满足任一则升级到 Opus）:
- 首次尝试失败
- 涉及架构决策
- 安全相关代码

**覆盖命令**: `/model <haiku|sonnet|opus|auto>`
```

### 集成到 dispatcher

在 `dispatcher-workflow.md` 的 WU 解析阶段：

```
WU 解析
    ↓
自动添加 model 建议到 prompt
    ↓
子 Agent 可选择接受或覆盖
```

## 实现指南

### 代码示例

```javascript
function selectModel(task) {
  const { fileCount, complexity, type } = analyzeTask(task);
  
  // 路由矩阵
  const rules = [
    { file: 1, complexity: 'low', type: ['explore', 'edit'], model: 'haiku' },
    { file: [2, 5], complexity: 'medium', type: ['implement'], model: 'sonnet' },
    { file: '5+', complexity: 'any', type: ['implement'], model: 'opus' },
    { type: ['security'], model: 'opus' },
    { type: ['review'], model: 'sonnet' },
  ];
  
  for (const rule of rules) {
    if (matches(fileCount, rule.file) && 
        matches(complexity, rule.complexity) &&
        matchesType(type, rule.type)) {
      return rule.model;
    }
  }
  
  return 'sonnet'; // 默认
}
```

### 阈值调优

| 指标 | 初始阈值 | 调优方向 |
|-----|---------|---------|
| 文件数量边界 | 5 | 根据项目平均规模调整 |
| 复杂度判断 | 基于关键词 | 积累案例后优化 |
| 升级延迟 | 2次失败 | 根据质量反馈调整 |

## 相关文档

- `core/optimization/token-strategy.md` - 完整策略文档
- `skills/auto-compact/SKILL.md` - 自动压缩 Skill
- `core/orchestration/skill-preferences.md` - Skill 路由表
