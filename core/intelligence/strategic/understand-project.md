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

使用 Understand-Anything 分析项目结构，生成交互式知识图谱。

## 使用场景

| 场景 | 调用时机 | 价值 |
|------|---------|------|
| 新项目接手 | plan 阶段开始时 | 5 分钟了解项目全貌 |
| 架构评审 | design 阶段 | 提供架构上下文 |
| 大型重构 | implement 前 | 识别影响范围 |
| Bug 定位 | verify 阶段 | 快速定位相关模块 |

## 多智能体协同流程

```
┌─────────────────────────────────────────────────────────────┐
│  Understand-Anything 多智能体分析流程                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. [ProjectScanner] 扫描项目结构                            │
│     └─ 递归扫描目录、识别语言、检测框架                        │
│                                                              │
│  2. [FileAnalyzer] 分析每个文件                               │
│     └─ 解析 AST、提取符号、识别依赖                           │
│     └─ 并行: 多个 FileAnalyzer 实例                          │
│                                                              │
│  3. [ArchitectureAnalyzer] 架构分层                           │
│     └─ 识别架构模式 (MVC/三层/微服务)                         │
│     └─ 识别模块边界和依赖关系                                 │
│                                                              │
│  4. [GraphBuilder] 构建知识图谱                              │
│     └─ 节点: 文件、类、函数、模块                             │
│     └─ 边: 调用、导入、继承、实现                             │
│                                                              │
│  5. [TourBuilder] 生成导览                                   │
│     └─ 项目介绍                                              │
│     └─ 核心流程                                              │
│     └─ 关键文件                                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## MCP 调用协议

### Request

```json
{
  "tool": "understand-project",
  "params": {
    "project_path": "/path/to/project",
    "scope": "full",
    "language": "auto",
    "options": {
      "include_tests": false,
      "include_node_modules": false,
      "max_depth": 10
    }
  }
}
```

### Response

```json
{
  "success": true,
  "data": {
    "overview": {
      "name": "项目名称",
      "description": "一句话描述项目",
      "language": "主要语言",
      "framework": "主要框架",
      "line_count": 12345,
      "file_count": 100
    },
    "architecture": {
      "pattern": "MVC | 三层架构 | 微服务 | ..." ,
      "layers": [
        {
          "name": "表现层",
          "path": "src/controller",
          "responsibility": "处理 HTTP 请求"
        }
      ],
      "modules": [
        {
          "name": "user",
          "path": "src/user",
          "dependencies": ["common"],
          "exports": ["UserService", "UserController"]
        }
      ]
    },
    "technologies": {
      "backend": ["Spring Boot", "MyBatis"],
      "frontend": ["React"],
      "database": ["MySQL", "Redis"],
      "build": ["Maven", "Webpack"]
    },
    "patterns": [
      {
        "name": "工厂模式",
        "locations": ["*.Factory.java"],
        "description": "用于解耦对象创建"
      }
    ],
    "graph": {
      "nodes": [
        {"id": "1", "type": "module", "name": "user"},
        {"id": "2", "type": "class", "name": "UserService"}
      ],
      "edges": [
        {"source": "1", "target": "2", "type": "contains"},
        {"source": "OrderService", "target": "UserService", "type": "calls"}
      ]
    },
    "entry_points": {
      "api": ["src/controller/*.java"],
      "main": ["src/main/java/*Application.java"]
    },
    "tours": {
      "quick_start": "快速上手指南",
      "core_flow": "核心业务流程",
      "key_files": ["关键文件列表"]
    }
  }
}
```

## 使用示例

### 场景 1: 新项目接手

```
用户: 帮我理解这个项目
AI:   正在调用 /understand-project...
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

      表现层 → src/controller/    (REST API)
      业务层 → src/service/      (业务逻辑)
      持久层 → src/mapper/       (数据访问)

      📦 核心模块
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
      构建: Maven

      🎨 设计模式
      ─────────────────────────────────────
      • 工厂模式    UserFactory
      • 策略模式    PaymentStrategy
      • 单例模式    CacheManager

      📁 关键文件
      ─────────────────────────────────────
      • Application.java       入口
      • application.yml        配置
      • pom.xml               依赖

      下一步建议:
      → /analyze-architecture  深入分析架构
      → /index-project        建立代码索引
```

### 场景 2: 快速了解特定模块

```
用户: 订单模块是怎么组织的？
AI:   正在分析订单模块...
      ↓
      📦 订单模块分析
      ─────────────────────────────────────
      路径: src/order/

      组成:
      ├─ OrderController.java    HTTP API
      ├─ OrderService.java       业务逻辑
      ├─ OrderRepository.java    数据访问
      └─ Order.java              实体类

      依赖关系:
      └─ OrderService
         ├─ 调用 UserService (查询买家)
         ├─ 调用 ProductService (验证商品)
         └─ 调用 PaymentService (处理支付)

      关键流程:
      创建订单 → 验证库存 → 锁定库存 → 发起支付 → 完成订单
```

## 与其他 Skill 的配合

```
/understand-project  →  获取全局理解
        ↓
/analyze-architecture  →  深入分析某个方面
        ↓
/index-project  →  建立索引，为精准定位做准备
        ↓
/query-symbol  →  快速定位具体代码
```

## 限制与注意事项

1. **首次分析较慢**: 完整分析可能需要 1-5 分钟
2. **需要增量更新**: 代码变更后建议重新分析
3. **图谱存储**: 知识图谱存储在 `.understand-anything/` 目录
4. **隐私**: 所有分析在本地进行，代码不外传
