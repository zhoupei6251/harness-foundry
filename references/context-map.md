---
name: context-map
description: "harness-foundry 跨模块上下文地图：code/novel/news 三域的核心目录、关键文件、依赖方向。"
tags: [Memory, Standard]
---

# harness-foundry 上下文地图

> 跨模块协作前先看本图，避免在错误的域里改代码。

---

## 三域概览

| 域 | 目录 | 入口 | 编排器 | 主要 Agent 角色 |
|---|------|------|--------|----------------|
| **code** | 项目自身的 `src/` | `ENTRY.md` | `harness-orchestration` | leader / coder / implementer / reviewer / test-engineer / debugger / web-investigator |
| **novel** | 项目根目录 | `core/intent-routing.md` | `novel-orchestrator` | leader / writer / planner / reviewer / humanizer / researcher / editor / memory-keeper |
| **news** | 项目根目录 | 待定 | 待定 | leader / writer / fact-checker / editor |

---

## code 域

### 核心目录

```
harness-foundry/  （放置于项目根目录）
├── .ai-runtime-artifacts/
│   ├── execution-logs/
│   ├── plans/
│   ├── tracking/
│   ├── verifications/
│   └── reviews/
├── src/                        # 项目源码
└── MEMORY.md                   # 项目记忆
```

### 关键文件

| 文件 | 用途 |
|------|------|
| `harness-foundry/core/intent-routing.md` | 代码任务路由入口 |
| `harness-foundry/core/orchestration/dispatcher-workflow.md` | 并行派发流程 |
| `harness-foundry/agents/*.md` | Agent 角色定义 |
| `harness-foundry/adapters/*/bindings.md` | 平台绑定 |

### 依赖方向

```
core/  →  agents/  →  adapters/
core/  →  artifact-templates/
core/  →  skills/
```

---

## novel 域

### 核心目录

```
<小说项目根目录>/
├── README.md
├── 大纲.md
├── 人物设定/
├── 章节目录.md
├── 章节正文/
├── 素材库/
├── .novel-runtime-artifacts/
│   ├── execution-logs/
│   └── tracking/
└── MEMORY.md
```

### 关键文件

| 文件 | 用途 |
|------|------|
| `core/intent-routing.md` | 小说任务路由入口 |
| `core/orchestration/domain-config.yaml` | 域配置 |
| `harness-foundry/skills/` | 小说 skill 集合 |

### 依赖方向

```
novel 域  →  harness-foundry/core/  （复用编排能力）
novel 域  →  harness-foundry/skills/  （小说专用 skill）
novel 域  -/-> harness-foundry/core/orchestration/dispatcher-workflow.md  （小说走 novel-orchestrator）
```

---

## news 域

### 核心目录（待完善）

```
<新闻项目根目录>/
├── README.md
├── .news-runtime-artifacts/
│   ├── execution-logs/
│   └── tracking/
└── MEMORY.md
```

### 关键文件

| 文件 | 用途 |
|------|------|
| `harness-foundry/skills/` | 新闻 skill 集合 |
| `harness-foundry/agents/` | 新闻 Agent 角色 |

---

## 共享层

| 类型 | 位置 | 说明 |
|------|------|------|
| 能力原语 | `core/capabilities/primitives.md` | 三域共用 |
| 能力注册表 | `core/capabilities/registry.md` | 三域共用 |
| 标签索引 | `core/tags-index.md` | 三域共用 |
| 编排配置 | `core/orchestration/config.defaults.yaml` | 默认配置 |
| 域配置 | `core/orchestration/domain-config.yaml` | 分域覆盖 |
| 运行时模板 | `artifact-templates/runtime/` | 三域共用模板 |
| 参考资料 | `references/` | 代码范例、陷阱库 |

---

## 跨域改动最小加载清单

1. 确认目标域（code / novel / news）
2. 读对应域的入口文件（intent-routing）
3. 读域配置 `domain-config.yaml`
4. 读对应 Agent 角色定义
5. 按路由加载 skill
6. 写产物到对应域的 runtime artifacts 目录

---

## 维护说明

- **新增域** → 在"三域概览"加一行，更新依赖方向
- **域间依赖变化** → 更新"依赖方向"图
- **共享层文件变动** → 同时审计三域是否受影响
