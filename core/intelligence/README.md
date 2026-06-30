# Intelligence Layer

> 为 Harness Foundry 提供智能代码理解能力

## 架构

```
Intelligence Layer
├── strategic/    # 战略层 - Understand-Anything
│   └── 项目理解、架构分析、自然语言问答
└── tactical/     # 战术层 - CodeGraph
    └── 索引查询、符号定位、影响分析
```

## Skill 列表

| Skill | 层级 | 描述 |
|-------|------|------|
| `/understand-project` | 战略层 | 理解项目结构，生成知识图谱 |
| `/analyze-architecture` | 战略层 | 深入分析架构，回答架构问题 |
| `/index-project` | 战术层 | 为项目建立代码索引 |
| `/query-symbol` | 战术层 | 快速定位代码符号 |
| `/get-callers` | 战术层 | 获取符号的调用方 |
| `/get-callees` | 战术层 | 获取符号的被调用方 |
| `/analyze-impact` | 战术层 | 评估代码变更的影响范围 |

## 详细设计

参见: `docs/plans/2026-06-30-intelligence-layer-integration-design.md`
