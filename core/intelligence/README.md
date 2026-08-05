# Intelligence Layer

> 为 Harness Foundry 提供智能代码理解能力

## 架构

```
Intelligence Layer
├── strategic/    # 战略层 - codebase-memory-mcp
│   └── 项目理解 (index_repository / get_architecture)、架构问答、知识图谱查询
└── tactical/     # 战术层 - codebase-memory / ripgrep / LSP
    └── 索引查询、符号定位、影响分析
```

> 战略层与战术层统一由 codebase-memory-mcp 驱动；ripgrep 与 LSP 作为补充查询手段。

## Skill 列表

| Skill | 层级 | 描述 |
|-------|------|------|
| `/understand-project` | 战略层 | 理解项目结构，建立/查询知识图谱 |
| `/analyze-architecture` | 战略层 | 深入分析架构，回答架构问题 |
| `/index-project` | 战术层 | 为项目建立代码索引 |
| `/query-symbol` | 战术层 | 快速定位代码符号 |
| `/get-callers` | 战术层 | 获取符号的调用方 |
| `/get-callees` | 战术层 | 获取符号的被调用方 |
| `/analyze-impact` | 战术层 | 评估代码变更的影响范围 |

## 配置

- MCP 配置：`mcp-config/codebase-memory.json`（npx codebase-memory-mcp）
- 战略层配置：`core/intelligence/strategic/_config.yaml`
- 战术层配置：`core/intelligence/tactical/_config.yaml`

## 详细设计

参见: `docs/specs/harness-foundry-v2.1-architecture.md`（Intelligence Layer 架构设计）
