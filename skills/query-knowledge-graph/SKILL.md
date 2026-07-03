---
name: query-knowledge-graph
description: "查询已生成的知识图谱，获取结构化信息。触发：需要查询项目结构、模块关系、依赖关系。"
version: 1.0.0
when_to_use: 查询项目图谱时
status: peripheral
tags:
- intelligence
- code
- strategic
domain: code
category: code.intelligence
---

# /query-knowledge-graph

查询 Understand-Anything 生成的交互式知识图谱。

## 使用场景

| 场景 | 示例查询 |
|------|---------|
| 模块导航 | "用户模块在哪里？" |
| 依赖追踪 | "哪些模块依赖了订单服务？" |
| 关系查询 | "Controller 和 Service 的关系是什么？" |

## 调用方式

```markdown
使用 Understand-Anything 的 query-knowledge-graph 能力：
- query: {查询语句}
- filters: {过滤条件}
```
