# Understand-Anything Multi-Agent Collaboration Design

> 多智能体协同工作流程设计

## 概述

Understand-Anything 使用多个专业智能体协同分析项目，每个智能体负责特定任务。

## 智能体架构

```
┌─────────────────────────────────────────────────────────────┐
│                  Understand-Anything                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐                                           │
│  │ Orchestrator │ ←── 总指挥协调                             │
│  └──────┬──────┘                                           │
│         │                                                   │
│  ┌──────┴──────┬──────────┬──────────┐                    │
│  ↓             ↓          ↓          ↓                      │
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐              │
│ │Project │ │ File   │ │Architecture│ │ Graph │          │
│ │Scanner │ │Analyzer│ │ Analyzer │ │Builder │          │
│ └────────┘ └────────┘ └────────┘ └────────┘              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 智能体职责

### 1. ProjectScanner

**职责**: 扫描项目结构

```
任务:
1. 递归扫描项目目录
2. 识别项目语言
3. 检测框架类型
4. 识别构建工具
5. 统计代码规模

输出:
- 项目结构树
- 语言分布
- 框架列表
- 文件统计
```

### 2. FileAnalyzer (并行)

**职责**: 分析每个文件

```
任务:
1. 解析 AST (抽象语法树)
2. 提取符号 (类、函数、变量)
3. 识别导入依赖
4. 分析代码复杂度
5. 识别注释和文档

输出:
- 文件符号表
- 依赖列表
- 复杂度指标
- 文档摘要
```

### 3. ArchitectureAnalyzer

**职责**: 架构分析

```
任务:
1. 识别架构模式
2. 分析模块边界
3. 识别依赖关系
4. 提取设计模式
5. 生成架构图

输出:
- 架构模式
- 模块依赖图
- 设计模式列表
- 架构建议
```

### 4. GraphBuilder

**职责**: 构建知识图谱

```
任务:
1. 合并 FileAnalyzer 结果
2. 构建调用图
3. 识别关系类型
4. 存储图谱数据
5. 生成导览

输出:
- 知识图谱 (nodes + edges)
- 调用链
- 导览数据
```

## 协同流程

```
┌─────────────────────────────────────────────────────────────┐
│                     协同流程                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Orchestrator 接收任务                                     │
│     └─ "理解 /path/to/project"                               │
│                                                              │
│  2. ProjectScanner 执行 (顺序)                                │
│     └─ 扫描目录结构                                           │
│     └─ 输出: 项目结构                                         │
│                                                              │
│  3. FileAnalyzer 执行 (并行，多实例)                          │
│     ├─ 实例1: 分析 src/controller/*.java                      │
│     ├─ 实例2: 分析 src/service/*.java                        │
│     └─ 实例3: 分析 src/repository/*.java                     │
│                                                              │
│  4. ArchitectureAnalyzer 执行 (顺序)                         │
│     └─ 基于扫描+分析结果进行架构分析                          │
│     └─ 输出: 架构报告                                        │
│                                                              │
│  5. GraphBuilder 执行 (顺序)                                  │
│     └─ 合并所有结果                                           │
│     └─ 构建知识图谱                                           │
│     └─ 生成导览                                               │
│                                                              │
│  6. Orchestrator 返回最终结果                                 │
│     └─ 项目概述                                               │
│     └─ 架构分析                                               │
│     └─ 知识图谱                                               │
│     └─ 导览                                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 并行策略

### FileAnalyzer 并行化

```python
# 并行分析策略
PARALLELISM = {
    "small_project": 2,    # < 100 文件
    "medium_project": 4,   # 100-500 文件
    "large_project": 8,   # > 500 文件
}

# 并行执行
analyzers = [FileAnalyzer() for _ in range(PARALLELISM[current_size])]
results = parallel_execute(analyzers, file_groups)
```

### 任务调度

```
优先级队列:
1. 核心文件 (入口、配置) - 高优先级
2. 业务逻辑文件 (.java/.ts) - 中优先级
3. 测试文件 - 低优先级
4. 文档/配置文件 - 低优先级
```

## 数据共享

### 中间结果存储

```
.understand-anything/
├── intermediate/           # 中间产物
│   ├── scanner/           # 扫描结果
│   │   └── structure.json
│   ├── analyzer/          # 分析结果
│   │   ├── file-001.json
│   │   ├── file-002.json
│   │   └── ...
│   ├── architecture/      # 架构分析
│   │   └── report.json
│   └── graph/            # 图谱构建
│       └── knowledge-graph.json
├── cache/                # 缓存
└── tours/               # 导览
    └── *.md
```

### 结果合并

```python
# GraphBuilder 合并逻辑
def merge_results(scanner_result, analyzer_results, architecture_result):
    # 1. 合并文件节点
    nodes = []
    for result in analyzer_results:
        nodes.extend(result.symbols)

    # 2. 合并边
    edges = []
    for result in analyzer_results:
        edges.extend(result.dependencies)

    # 3. 添加架构信息
    for module in architecture_result.modules:
        add_module_node(nodes, module)
        add_module_edges(edges, module)

    # 4. 构建图谱
    return build_graph(nodes, edges)
```

## 错误处理

### 容错策略

```
1. 单文件分析失败
   └─ 记录错误，继续分析其他文件
   └─ 最终报告包含失败列表

2. 架构分析失败
   └─ 回退到基础模式识别
   └─ 标记分析不完整

3. 内存不足
   └─ 减少并行度
   └─ 分批处理
```

### 恢复机制

```
失败恢复:
1. 检查点保存 - 每个阶段完成后保存状态
2. 增量恢复 - 从检查点恢复
3. 重试策略 - 失败任务最多重试 3 次
```

## 性能优化

### 缓存策略

```
缓存级别:
1. 项目级缓存 - 项目结构不常变化
2. 文件级缓存 - 基于文件 hash
3. 增量更新 - 只重新分析变更文件
```

### 资源限制

```
资源限制:
- 内存: 最大 2GB
- CPU: 使用系统可用核心的 50%
- 超时: 单文件分析 30s
- 总超时: 项目分析 10min
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
     │         └─ Understand-Anything 多智能体协同
     │
     └─ Execute 阶段
          └─ Worker 使用图谱结果
               └─ /query-symbol (CodeGraph)
```

### 数据流

```
Harness Worker
     │
     ├─ 请求理解项目
     │
     ├─ Understand-Anything 返回
     │    ├─ 项目概述
     │    ├─ 架构分析
     │    └─ 知识图谱
     │
     └─ Worker 使用结果
          ├─ 理解代码结构
          ├─ 定位模块
          └─ 分析依赖
```

## 配置选项

```yaml
# Understand-Anything 配置
understand_anything:
  # 并行度
  parallelism:
    auto: true      # 自动根据项目大小调整
    max_workers: 8  # 最大并行数

  # 缓存
  cache:
    enabled: true
    ttl: 3600       # 缓存有效期 (秒)

  # 分析范围
  scope:
    include_tests: false
    include_docs: true
    max_depth: 10

  # 资源限制
  resources:
    max_memory_mb: 2048
    timeout_per_file: 30
    timeout_total: 600
```

## 未来扩展

### 计划功能

1. **流式输出**: 支持边分析边输出
2. **交互式导览**: 支持在图谱中导航
3. **差异分析**: 对比不同版本的架构变化
4. **自定义规则**: 支持用户定义分析规则
