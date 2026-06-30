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

| 场景 | 调用时机 |
|------|---------|
| 新项目接手 | plan 阶段开始时 |
| 架构评审 | design 阶段 |
| 大型重构 | implement 前 |
| Bug 定位 | verify 阶段 |

## 调用方式

```markdown
使用 Understand-Anything 的 understand-project 能力：
- project_path: {当前项目路径}
- scope: full (完整项目) 或 module (仅模块)
- language: auto (自动检测) 或指定语言
```

## 预期输出

```json
{
  "summary": "三层架构的电商系统",
  "layers": ["Controller", "Service", "Repository"],
  "patterns": ["工厂模式", "策略模式"],
  "technologies": ["Spring Boot", "MyBatis", "Redis"],
  "graph": {
    "nodes": [...],
    "edges": [...]
  }
}
```

## 示例对话

```
用户: 帮我理解这个项目
AI:   调用 /understand-project
      ↓
      项目概述：这是一个采用 MVC 三层架构的电商系统
      技术栈：Spring Boot 3.2, MyBatis-Plus, Redis, MySQL
      核心模块：用户模块、订单模块、商品模块、支付模块
      设计模式：工厂模式(创建对象)、策略模式(支付方式)
      ...
```

## 后续步骤

理解完成后，可以继续使用：
- `/analyze-architecture` - 深入分析某个模块
- `/index-project` - 建立代码索引进行精准定位
