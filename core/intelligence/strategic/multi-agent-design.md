# 多智能体协同工作流程设计

> 多智能体协同工作流程设计 —— 基于 codebase-memory-mcp 图谱 + 分层 agent 查询

## 概述

使用 cbm 分层 agent（cbm-scout → cbm-verify → cbm-auditor）配合 codebase-memory-mcp 知识图谱，完成从快速发现到深度审计的代码理解。

## 智能体架构

```
┌─────────────────────────────────────────────────────────────┐
│                  Intelligence Layer                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐   ┌───────────┐   ┌───────────┐           │
│  │ cbm-scout   │   │ cbm-verify│   │cbm-auditor│           │
│  │ (Tier 1)    │ → │ (Tier 2)  │ → │ (Tier 3)  │           │
│  └──────┬──────┘   └─────┬─────┘   └─────┬─────┘           │
│         │                │               │                   │
│  ┌──────┴────────────────┴───────────────┴──────┐          │
│  │        codebase-memory-mcp 知识图谱            │          │
│  └───────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## 智能体职责

### 1. cbm-scout（Tier 1 快速发现）

**职责**: 快速初步搜索

```
任务:
1. 按名称/模式搜索符号 (search_graph name_pattern)
2. 检查函数/路由存在性
3. 快速调用链速写 (trace_path)
4. 架构速览 (get_architecture)

输出:
- 初步线索 (3-4 个窄查询)
- 精确验证交给 cbm-verify
```

### 2. cbm-verify（Tier 2 证据核实）

**职责**: 定向取证

```
任务:
1. 确认谁调用 X (trace_path inbound)
2. X 调用了什么 (trace_path outbound)
3. 影响范围/爆炸半径 (trace_path + Read)
4. 死代码确认 (query_graph)
5. 跨服务路径 (trace_path cross_service)

输出:
- 图证据 + 源码精确范围双重确认
```

### 3. cbm-auditor（Tier 3 结构审计）

**职责**: 有界范围的结构审计

```
任务:
1. 死代码审计
2. 高扇出/高扇入分析
3. 重构候选
4. 架构热点
5. 依赖评审

输出:
- 审计报告（限定当前索引范围）
```

## 协同流程

```
┌─────────────────────────────────────────────────────────────┐
│                     协同流程                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. 接收任务: "理解 /path/to/project"                        │
│                                                              │
│  2. index_status → 未索引则 index_repository                  │
│                                                              │
│  3. cbm-scout 执行 (并行)                                    │
│     ├─ 搜索符号/模块                                          │
│     └─ 速写调用链                                             │
│                                                              │
│  4. cbm-verify 执行 (并行)                                   │
│     ├─ 核实调用关系                                            │
│     └─ 确认影响范围                                            │
│                                                              │
│  5. cbm-auditor 执行 (按需)                                  │
│     └─ 结构审计 / 死代码 / 重构候选                            │
│                                                              │
│  6. 汇总最终结果                                              │
│     └─ 项目概述 + 架构分析 + 影响评估                          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 与 Harness Foundry 集成

### 集成点

```
Harness Foundry
     │
     ├─ Intent Routing (识别需要理解项目)
     │
     ├─ Plan 阶段
     │    └─ 调用 /understand-project
     │         └─ codebase-memory-mcp 建立/查询图谱
     │
     └─ Execute 阶段
          └─ Worker 使用图谱结果
               └─ /query-symbol (search_graph)
```

### 数据流

```
Harness Worker
     │
     ├─ 请求理解项目
     │
     ├─ codebase-memory-mcp 返回
     │    ├─ 项目概述 (get_architecture)
     │    ├─ 架构分析 (clusters / layers)
     │    └─ 知识图谱 (search_graph)
     │
     └─ Worker 使用结果
          ├─ 理解代码结构
          ├─ 定位模块
          └─ 分析依赖
```

## 错误处理

### 容错策略

```
1. 项目未索引
   └─ index_repository 建立索引后再查询

2. 图谱查询无结果
   └─ 降级到 ripgrep-search 文本搜索
   └─ 标记分析不完整

3. 索引过期
   └─ detect_changes 增量更新
```

## 性能优化

### 缓存策略

```
缓存级别:
1. 图谱持久化 - 索引生命周期由 codebase-memory-mcp 管理
2. 增量更新 - detect_changes 只重新索引变更文件
3. 查询优先级 - 窄查询优先，避免全图扫描
```

### 查询层职责划分

```
- search_graph     → 符号定位 (cbm-scout)
- trace_path      → 调用链 (cbm-verify)
- query_graph     → 复杂 Cypher (cbm-auditor)
- detect_changes  → 变更影响 (cbm-verify)
```

## 未来扩展

### 计划功能

1. **流式输出**: 支持边分析边输出
2. **交互式导览**: 支持在图谱中导航
3. **差异分析**: 对比不同版本的架构变化
4. **自定义规则**: 支持用户定义分析规则
