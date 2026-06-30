---
name: analyze-architecture
description: "深入分析项目架构，回答架构相关问题。触发：询问设计原因、技术选型、模块职责、架构决策。"
tags: [Intelligence, Code, Strategic]
triggers:
  - "为什么这样设计"
  - "模块职责"
  - "技术选型"
  - "架构分析"
  - "这个设计好不好"
  - "为什么要用 XX"
layer: strategic
---

# /analyze-architecture

使用 Understand-Anything 进行架构问答，深入分析设计决策。

## 使用场景

| 场景 | 示例问题 |
|------|---------|
| 设计评审 | "为什么要用微服务架构？" |
| 技术选型 | "为什么选择 Spring Boot 而不是 FastAPI？" |
| 模块分析 | "订单模块的职责是什么？" |
| 依赖分析 | "缓存层是如何设计的？" |

## 调用方式

```markdown
使用 Understand-Anything 的 analyze-architecture 能力：
- question: {用户的自然语言问题}
- context: {当前理解的项目上下文}
```

## 预期输出

```json
{
  "answer": "采用微服务架构的原因有以下几点...",
  "reasoning": [
    "业务边界清晰，可以独立部署",
    "团队自治，不同团队负责不同服务",
    "技术栈可以按需选择"
  ],
  "evidence": {
    "files": ["src/api-gateway/", "src/user-service/"],
    "patterns": ["API Gateway Pattern", "Service Discovery"]
  }
}
```

## 示例对话

```
用户: 为什么要用 Redis 做缓存，不用本地缓存？
AI:   调用 /analyze-architecture
      ↓
      回答：
      1. 分布式场景需要 - 项目部署在多实例
      2. 数据一致性 - 本地缓存会有同步问题
      3. 内存利用率 - Redis 集中管理，节省内存

      证据：
      - 发现 Application.java 中注入了 RedisTemplate
      - 发现使用了 @Cacheable 注解
      - 配置文件中有 redis.host 配置
```

## 与 /understand-project 的区别

| Skill | 回答什么 | 使用时机 |
|-------|---------|---------|
| `/understand-project` | 项目整体是什么 | 第一次接触项目 |
| `/analyze-architecture` | 为什么这样设计 | 有具体问题时 |
