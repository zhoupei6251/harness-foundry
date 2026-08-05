---
name: understand-project
description: "理解项目结构和架构，生成知识图谱。触发：接手新项目、需要了解项目全局、询问架构设计。"
tags: [Intelligence, Code, Strategic]
triggers:
  - "理解这个项目"
  - "项目架构"
  - "怎么组织的"
  - "用了什么技术"
  - "陌生项目"
layer: strategic
---

# /understand-project

使用 codebase-memory-mcp 分析项目结构，建立/查询知识图谱。

## 使用场景

| 场景 | 调用时机 | 价值 |
|------|---------|------|
| 新项目接手 | plan 阶段开始时 | 5 分钟了解项目全貌 |
| 架构评审 | design 阶段 | 提供架构上下文 |
| 大型重构 | implement 前 | 识别影响范围 |
| Bug 定位 | verify 阶段 | 快速定位相关模块 |

## 工作流程

```
┌─────────────────────────────────────────────────────────────┐
│  codebase-memory-mcp 项目理解流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. [index_status] 检查项目是否已索引                         │
│     └─ 未索引 → index_repository(repo_path, mode)            │
│                                                              │
│  2. [get_architecture] 获取项目全貌                           │
│     └─ aspects: overview / structure / languages / clusters  │
│                                                              │
│  3. [search_graph] 定位具体类/函数/模块                        │
│     └─ query / name_pattern / qn_pattern                     │
│                                                              │
│  4. [get_code_snippet] 读关键实现                             │
│     └─ qualified_name 精确读取                               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## MCP 调用协议

### Request

```json
{
  "tool": "index_repository",
  "params": {
    "repo_path": "/path/to/project",
    "mode": "moderate"
  }
}
```

### Response

```json
{
  "project": "项目名称",
  "nodes_indexed": 1234,
  "edges_indexed": 5678
}
```

### 项目全貌查询

```json
{
  "tool": "get_architecture",
  "params": {
    "project": "<project>",
    "aspects": ["overview", "structure", "languages", "packages", "entry_points", "clusters"]
  }
}
```

## 索引生命周期

索引由 codebase-memory-mcp 管理。不要手动删除或操作其内部索引目录。项目代码变更后，`detect_changes` 可增量更新。

## 使用示例

### 场景 1: 新项目接手

```
用户: 帮我理解这个项目
AI:   调用 codebase-memory: index_status → get_architecture
      ↓
      ✅ 分析完成

      📋 项目概述
      ─────────────────────────────────────
      名称: Spring Boot 电商系统
      语言: Java
      框架: Spring Boot 3.2 + MyBatis-Plus
      规模: 1,234 文件 | 45,678 行代码

      🏗️ 架构模式
      ─────────────────────────────────────
      采用三层架构 + DDD 领域驱动设计
      （来自 get_architecture 的 layers / clusters）

      📦 核心模块（真实聚类）
      ─────────────────────────────────────
      • user      用户模块
      • product   商品模块
      • order     订单模块
      • payment   支付模块

      🛠️ 技术栈
      ─────────────────────────────────────
      后端: Spring Boot, MyBatis-Plus
      缓存: Redis
      数据库: MySQL

      下一步建议:
      → /analyze-architecture  深入分析架构
      → /query-symbol          定位代码
```

### 场景 2: 快速了解特定模块

```
用户: 订单模块是怎么组织的？
AI:   调用 codebase-memory: search_graph(query="订单模块") → get_code_snippet
      ↓
      📦 订单模块分析
      ─────────────────────────────────────
      路径: src/order/

      组成:
      ├─ OrderController.java    HTTP API
      ├─ OrderService.java       业务逻辑
      ├─ OrderRepository.java    数据访问
      └─ Order.java              实体类

      依赖关系（trace_path）:
      └─ OrderService
         ├─ 调用 UserService (查询买家)
         ├─ 调用 ProductService (验证商品)
         └─ 调用 PaymentService (处理支付)
```

## 与其他 Skill 的配合

```
/understand-project  →  get_architecture 获取全局理解
        ↓
/analyze-architecture  →  get_architecture 深入分析某个方面
        ↓
/index-project  →  建立索引，为精准定位做准备
        ↓
/query-symbol  →  快速定位具体代码
```

## 限制与注意事项

1. **首次索引较慢**: 完整索引可能需要 1-5 分钟
2. **需要增量更新**: 代码变更后用 `detect_changes` 更新
3. **图谱存储**: 由 codebase-memory-mcp 管理，位置透明
4. **隐私**: 所有分析在本地进行，代码不外传
