# Intelligence Layer Integration Design

> 日期: 2026-06-30
> 状态: 阶段一+二+三已完成

## 实施进度

| 阶段 | 状态 | 提交 |
|------|------|------|
| 阶段一：基础设施 | ✅ 完成 | 9f55a08 |
| 阶段二：CodeGraph 集成 | ✅ 完成 | 065939b |
| 阶段三：Understand-Anything 集成 | ✅ 完成 | — |
| 阶段四：生产就绪 | ⏳ 待开始 | — |

## 目标

为 Harness Foundry 集成 Understand-Anything 和 CodeGraph，构建智能代码理解分层架构。

---

## 1. 整体架构

```
┌─────────────────────────────────────────────────────────┐
│              Harness Foundry (编排层)                     │
│  intent-routing → 阶段门禁 → 并行派发 → 验证            │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │  战略层    │   │  战术层    │   │  执行层    │
    │Understand │   │ CodeGraph  │   │  Worker   │
    │ Anything  │   │           │   │           │
    │           │   │           │   │ coder     │
    │ 项目理解   │   │ 索引查询   │   │ debugger  │
    │ 架构分析   │   │ 影响分析   │   │ reviewer  │
    │ 自然语言QA │   │ 快速定位   │   │ test-eng  │
    └───────────┘   └───────────┘   └───────────┘
```

**核心设计原则**：
- 战略层回答"项目是什么/为什么这样设计"
- 战术层回答"符号在哪里/改动会影响谁"
- 执行层执行具体任务，调用上两层获取上下文

---

## 2. 目录结构

```
harness-foundry/
│
├── core/
│   └── intelligence/                    ★ 新增：智能工具层
│       │
│       ├── README.md                   集成说明文档
│       │
│       ├── strategic/                   ★ 战略层：Understand-Anything
│       │   ├── _config.yaml            配置（MCP 连接、模型等）
│       │   ├── understand-project.md   /understand-project 技能定义
│       │   ├── analyze-architecture.md /analyze-architecture 技能定义
│       │   └── prompts/                战略层专用 prompt 模板
│       │       ├── project-intro.md    项目介绍生成
│       │       └── architecture-qa.md  架构问答模板
│       │
│       └── tactical/                   ★ 战术层：CodeGraph
│           ├── _config.yaml            配置（MCP 连接、索引路径等）
│           ├── index-project.md        /index-project 技能定义
│           ├── query-symbol.md         /query-symbol 技能定义
│           ├── get-callers.md          /get-callers 技能定义
│           ├── get-callees.md         /get-callees 技能定义
│           ├── analyze-impact.md       /analyze-impact 技能定义
│           └── scripts/                本地索引初始化脚本
│               ├── install.sh         CodeGraph 安装脚本
│               └── init-index.sh       项目索引初始化
│
├── mcp-config/                         ★ 新增：MCP 配置
│   ├── Understand-Anything.json       MCP 服务器配置
│   └── CodeGraph.json                 MCP 服务器配置
│
├── skills/                            (现有 330+ skills)
│   └── INDEX.md                       更新索引
│
└── scripts/                           
    ├── bootstrap.sh                   ★ 更新：同步 intelligence 层
    └── sync-skills.sh                 ★ 更新：包含 intelligence skills
```

---

## 3. 数据流与调用协议

### 3.1 调用流程

```
用户: "帮我理解这个 Spring Boot 项目"
       │
       ▼
编排层 → 识别为 code 域 → plan 阶段
       │
       ▼
战略层 (Understand-Anything)
  MCP: /understand-project
  Response: { graph, summary, patterns, technologies }
       │
       ▼
战术层 (CodeGraph)
  MCP: /query-symbol (UserService)
  Response: { file, callers, callees }
       │
       ▼
执行层 (Worker)
  整合结果 → 派发给 coder
```

### 3.2 MCP 调用协议

**Understand-Anything Tools:**

| 工具 | 描述 | 参数 |
|------|------|------|
| `understand-project` | 理解项目结构，生成知识图谱 | `project_path`, `scope`, `language` |
| `analyze-architecture` | 分析项目架构，回答架构问题 | `question`, `context` |
| `query-knowledge-graph` | 查询已生成的知识图谱 | `query`, `filters` |

**CodeGraph Tools:**

| 工具 | 描述 | 参数 |
|------|------|------|
| `index-project` | 为项目建立索引 | `project_path`, `languages` |
| `search-nodes` | 搜索符号/节点 | `query`, `node_types` |
| `get-callers` | 获取调用方 | `symbol`, `depth` |
| `get-callees` | 获取被调用方 | `symbol`, `depth` |
| `get-impact-radius` | 评估变更影响范围 | `file`, `symbol` |

### 3.3 数据存储

```
# CodeGraph 索引（项目本地）
/path/to/project/.codegraph/
├── graph.db           # SQLite 索引数据库
├── symbols.json       # 符号映射
└── watch-list.json    # 监视文件列表

# Understand-Anything 图谱（项目本地）
/path/to/project/.understand-anything/
├── knowledge-graph.json
└── intermediate/       # 智能体中间产物
```

---

## 4. Skill 定义与路由配置

### 4.1 新增 Skill 列表

| Skill | 层级 | 触发场景 |
|-------|------|---------|
| `/understand-project` | 战略层 | 新项目接手、架构评审 |
| `/analyze-architecture` | 战略层 | 设计原因、技术选型 |
| `/index-project` | 战术层 | 大型项目、需要精准定位 |
| `/query-symbol` | 战术层 | 查找符号、定位代码 |
| `/get-callers` | 战术层 | 分析依赖、评估影响 |
| `/get-callees` | 战术层 | 分析依赖、评估影响 |
| `/analyze-impact` | 战术层 | 重构或修改前 |

### 4.2 路由配置

```yaml
# core/orchestration/skill-preferences.md

intelligence:
  strategic:
    understand-project:
      domains: [code]
      stage: [plan, design]
      priority: 1
      
    analyze-architecture:
      domains: [code]
      stage: [design, implement]
      priority: 1
      
  tactical:
    index-project:
      domains: [code]
      stage: [plan]
      trigger: "大型项目 (>100 文件)"
      
    query-symbol:
      domains: [code]
      stage: [implement, verify]
      
    analyze-impact:
      domains: [code]
      stage: [implement, verify]
      trigger: "重构或修改前"
```

---

## 5. 实施计划

### 阶段一：基础设施 (1-2 周)

| Milestone | 任务 |
|-----------|------|
| 1.1 | 创建 `core/intelligence/` 目录结构 |
| 1.2 | 配置 MCP (`mcp-config/`) |
| 1.3 | 编写 Skill 框架文件 |

### 阶段二：CodeGraph 集成 (1 周)

| Milestone | 任务 |
|-----------|------|
| 2.1 | 实现索引 Skill (`/index-project`, `/query-symbol`) |
| 2.2 | 实现分析 Skill (`/get-callers`, `/analyze-impact`) |
| 2.3 | 集成测试与 Token 消耗对比 |

### 阶段三：Understand-Anything 集成 (2-3 周)

| Milestone | 任务 |
|-----------|------|
| 3.1 | 实现项目理解 (`/understand-project`) |
| 3.2 | 实现架构分析 (`/analyze-architecture`) |
| 3.3 | 多智能体协同测试 |

### 阶段四：生产就绪 (1 周)

| Milestone | 任务 |
|-----------|------|
| 4.1 | 编写文档 |
| 4.2 | 完整测试 |
| 4.3 | 发布 |

---

## 6. 技术依赖

| 工具 | 版本要求 | 安装方式 |
|------|---------|---------|
| CodeGraph | Node.js >= 20 | `npm install -g @colbymchenry/codegraph` |
| Understand-Anything | Node.js >= 22, pnpm | `pnpm install` (monorepo) |
| Claude Code/Cursor/Trae | MCP 支持 | 现有功能 |

---

## 7. 验收标准

| 指标 | 目标 |
|------|------|
| 新项目索引时间 | < 5 分钟 (10万行代码) |
| 符号查询响应时间 | < 100ms |
| Token 消耗减少 | >= 30% |
| 项目理解覆盖率 | >= 90% |
| 架构问答准确率 | >= 80% |
| 现有功能兼容性 | 100% |
| MCP 连接成功率 | >= 99% |

---

## 8. 风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| MCP 连接不稳定 | fallback 方案、超时重试 |
| 大项目索引慢 | 后台增量索引、分模块索引 |
| 多 MCP 服务器冲突 | 独立端口、启动顺序控制 |
| 外部依赖更新破坏兼容 | 锁定版本、集成测试覆盖 |
