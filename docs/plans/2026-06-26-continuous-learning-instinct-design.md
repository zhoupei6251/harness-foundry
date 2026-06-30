# 持续学习闭环设计：Instinct 系统

**日期**: 2026-06-26  
**状态**: 计划阶段（pending implementation）  
**来源**: 借鉴 ECC continuous-learning-v2，适配 harness-foundry

---

## 1. 背景与动机

### 1.1 现状问题

harness-foundry 当前的持续学习机制存在以下不足：

1. **静态存储**：`learned-patterns.md`、`learned-traps.md` 等文件是纯 Markdown，无结构化元数据
2. **捕获不可靠**：依赖 Stop Hook 的 prompt 触发，触发率约 50-80%
3. **无置信度**：所有模式平等对待，无法区分高频有效模式 vs 偶发经验
4. **无项目隔离**：所有经验混在一起，跨项目污染
5. **无进化管道**：没有从"经验"到"skill/command"的自动进化机制

### 1.2 设计理念

借鉴 ECC instinct v2 的核心创新：

- **原子化**：将"学习"拆解为独立的 instinct（本能）
- **数据驱动**：YAML frontmatter 结构化存储
- **Hook 捕获**：PreToolUse/PostToolUse 100% 可靠捕获
- **置信度评分**：0.3-0.9 动态评分，自动衰减
- **项目隔离**：项目作用域 + 全局作用域
- **进化管道**：instinct → cluster → skill/command/agent

---

## 2. 核心架构

```
┌─────────────────────────────────────────────────────────┐
│                    会话执行层                              │
│  (Agent 执行任务，触发 PreToolUse/PostToolUse/Stop)      │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│                  捕获层（Hook）                           │
│  hooks/observe.sh                                        │
│  - PreToolUse: 记录工具调用上下文                        │
│  - PostToolUse: 记录执行结果                             │
│  - Stop: 触发 instinct 提取                              │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│                  存储层（instinct 文件）                  │
│  references/instincts/                                   │
│  ├── project/  (项目作用域)                              │
│  │   └── {project-id}/instincts/*.yaml                  │
│  └── global/   (全局作用域)                              │
│      └── instincts/*.yaml                                │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│                  进化层（命令）                           │
│  /evolve         → 聚类 instinct，生成 skill/command     │
│  /prune          → 清理低置信度 instinct                 │
│  /instinct-status → 查看当前 instinct 状态               │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 数据模型

### 3.1 Instinct YAML 格式

```yaml
---
id: prefer-early-return
trigger: "when writing conditional logic"
confidence: 0.7
domain: "code-style"
scope: project  # project | global
source: session  # session | user | evolved
project_id: "harness-foundry"
created: 2026-06-26
last_used: 2026-06-26
usage_count: 3
---

# Prefer Early Return

When writing conditional logic, prefer early returns over nested if-else.

## Example

```javascript
// Bad
function process(data) {
  if (data) {
    if (data.isValid) {
      // ...
    }
  }
}

// Good
function process(data) {
  if (!data || !data.isValid) return;
  // ...
}
```

## Evidence

- 2026-06-25: 用户纠正了 3 次嵌套 if-else
- 2026-06-26: 在 code-review 中建议 early return
```

### 3.2 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | kebab-case 标识符，全局唯一 |
| `trigger` | string | 触发场景描述 |
| `confidence` | float | 0.0-1.0，动态评分 |
| `domain` | string | 领域分类：code-style / architecture / testing / security / workflow / debugging / review |
| `scope` | string | project（项目隔离）或 global（全局共享） |
| `source` | string | session（会话提取）/ user（用户明确）/ evolved（进化而来） |
| `project_id` | string | 项目标识（scope=project 时必填） |
| `created` | date | 创建日期 |
| `last_used` | date | 最后使用日期 |
| `usage_count` | int | 使用次数 |

---

## 4. 捕获流程

### 4.1 Hook 触发

在 `hooks/hooks.json` 中增加 observe hook：

```json
{
  "code": {
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/observe.sh pre \"$TOOL_NAME\"",
            "timeout": 5000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/observe.sh post \"$TOOL_NAME\"",
            "timeout": 5000
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "检查本次会话是否有值得学习的模式。如果有，提取为 instinct 并保存到 references/instincts/project/{project-id}/instincts/"
          },
          {
            "type": "command",
            "command": "bash hooks/observe.sh stop",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

### 4.2 提取规则

写入 `hooks/continuous-learning.md`：

**触发条件**：
- 用户明确纠正（"不对"、"应该"、"别这样"）
- 同一模式出现 3+ 次
- 用户明确说"记住这个"

**提取内容**：
- `id`: kebab-case 标识符
- `trigger`: 触发场景描述
- `confidence`: 初始 0.5，根据证据调整
- `domain`: code-style | architecture | testing | security | workflow | debugging | review
- `scope`: project（默认）或 global

**质量控制**：
- 去重：检查是否已存在相似 instinct
- 具体性：避免过于宽泛的 instinct
- 可验证性：必须有具体证据

---

## 5. 置信度评分

### 5.1 评分规则

```
初始: 0.5
+0.1 每次成功应用
+0.2 用户明确肯定
-0.1 用户否定
-0.05 30 天未使用（衰减）

阈值:
< 0.3: 自动删除（/prune）
0.3-0.6: 保持观察
0.6-0.8: 可用于建议
> 0.8: 可进化为 skill/command
```

### 5.2 评分时机

- **PreToolUse**: 检查是否有相关 instinct，记录匹配
- **PostToolUse**: 根据执行结果调整置信度
- **Stop**: 根据用户反馈调整置信度

---

## 6. 进化管道

### 6.1 /evolve 命令流程

1. 扫描所有 instinct（按 domain 分组）
2. 聚类相似 instinct（基于 trigger 和 domain）
3. 对每个 cluster：
   - 如果 cluster 包含 5+ instinct 且平均 confidence > 0.7
   - 生成 skill/command/agent 提案
4. 用户确认后：
   - 创建 `skills/{name}/SKILL.md` 或 `commands/{name}.md`
   - 将原始 instinct 标记为 `source: evolved`
   - 更新 instinct 的 confidence 为 0.9

### 6.2 进化目标映射

| domain | 进化目标 |
|--------|---------|
| code-style | skill |
| architecture | skill |
| testing | skill |
| workflow | command |
| debugging | command |
| review | agent |

---

## 7. 实施计划（未实施）

### 7.1 计划文件结构（⚠️ 以下文件均未创建）

```
harness-foundry/
├── hooks/
│   ├── hooks.json                          # 更新：增加 observe hook
│   ├── continuous-learning.md              # 更新：instinct 提取规则
│   └── observe.sh                          # 新增：instinct 捕获脚本
├── commands/
│   ├── evolve.md                           # 更新：完整进化流程
│   ├── prune.md                            # 新增：清理低置信度 instinct
│   ├── instinct-status.md                  # 新增：查看 instinct 状态
│   ├── instinct-import.md                  # 新增：导入 instinct
│   └── instinct-export.md                  # 新增：导出 instinct
├── scripts/
│   └── instinct-cli.js                     # 新增：instinct 生命周期管理
├── references/
│   ├── instincts/
│   │   ├── project/                        # 项目作用域 instinct
│   │   │   └── {project-id}/
│   │   │       └── instincts/
│   │   │           └── {id}.yaml
│   │   └── global/                         # 全局作用域 instinct
│   │       └── instincts/
│   │           └── {id}.yaml
│   ├── learned-patterns.md                 # 保留（向后兼容）
│   ├── learned-traps.md                    # 保留
│   └── lessons-learned.md                  # 保留
└── skills/
    └── continuous-learning/
        └── SKILL.md                        # 新增：持续学习技能文档
```

### 7.2 实施步骤

1. **Phase 1: 基础设施**（1-2 天）
   - 创建 instinct 目录结构
   - 实现 observe.sh 捕获脚本
   - 更新 hooks.json

2. **Phase 2: CLI 工具**（2-3 天）
   - 实现 instinct-cli.js 核心命令
   - 实现 list / create / score / prune / evolve

3. **Phase 3: 命令集成**（1-2 天）
   - 更新 evolve.md
   - 创建 prune.md / instinct-status.md / instinct-import.md / instinct-export.md

4. **Phase 4: 文档与路由**（1 天）
   - 创建 skills/continuous-learning/SKILL.md
   - 更新 core/intent-routing.md
   - 更新 AGENTS.md

---

## 8. 向后兼容

保留现有 `learned-patterns.md`、`learned-traps.md`、`lessons-learned.md` 文件，新 instinct 系统独立运行。未来可考虑迁移脚本将旧文件转换为 instinct 格式。

---

## 9. 成功指标

- instinct 捕获率 > 90%（通过 Hook 实现）
- 置信度评分准确反映模式有效性
- /evolve 能自动生成 skill/command 提案
- 项目隔离有效，无跨项目污染

---

## 10. 风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| Hook 性能影响 | 设置 timeout=5000ms，observe.sh 仅记录元数据 |
| instinct 质量参差 | /prune 自动清理低置信度 instinct |
| 项目标识冲突 | 使用 git rev-parse 获取项目根目录 |
| 进化提案质量 | 用户确认后才创建 skill/command |

---

## 11. 参考资料

- ECC continuous-learning-v2: `d:\work\zhoupei\aigc-verse\ECC\skills\continuous-learning-v2\`
- ECC instinct-cli.py: `d:\work\zhoupei\aigc-verse\ECC\skills\continuous-learning-v2\scripts\instinct-cli.py`
- ECC observe.sh: `d:\work\zhoupei\aigc-verse\ECC\skills\continuous-learning-v2\hooks\observe.sh`
