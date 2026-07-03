---
name: analyze-architecture
description: "深入分析项目架构，回答架构相关问题。触发：询问设计原因、技术选型、模块职责、架构决策。"
version: 1.0.0
when_to_use: 需要深入分析架构时
status: peripheral
tags:
- intelligence
- code
- strategic
domain: code
category: code.intelligence
---

# /analyze-architecture

使用 Understand-Anything 进行架构问答，深入分析设计决策。

## 使用场景

| 场景 | 示例问题 | 分析方式 |
|------|---------|---------|
| 设计评审 | "为什么要用微服务架构？" | 架构模式分析 |
| 技术选型 | "为什么选择 Spring Boot？" | 技术栈分析 |
| 模块分析 | "订单模块的职责是什么？" | 模块职责分析 |
| 依赖分析 | "缓存层是如何设计的？" | 依赖关系分析 |
| 模式识别 | "用了哪些设计模式？" | 模式识别 |
| 流程追踪 | "下单流程是怎样的？" | 数据流分析 |

## 与 /understand-project 的区别

| Skill | 回答什么 | 使用时机 | 分析深度 |
|-------|---------|---------|---------|
| `/understand-project` | 项目整体是什么 | 第一次接触项目 | 广度优先 |
| `/analyze-architecture` | 为什么这样设计 | 有具体问题时 | 深度优先 |

## 使用建议

1. **先了解全局**: 首次使用建议先调用 `/understand-project`
2. **具体问题**: 越具体的问题回答越准确
3. **结合证据**: 回答会包含代码证据，位置精确到文件和行号
4. **多角度分析**: 可以追问"有没有更好的方案"获取更深入分析
