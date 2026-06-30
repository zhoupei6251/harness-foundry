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

| 场景 | 示例问题 | 分析方式 |
|------|---------|---------|
| 设计评审 | "为什么要用微服务架构？" | 架构模式分析 |
| 技术选型 | "为什么选择 Spring Boot？" | 技术栈分析 |
| 模块分析 | "订单模块的职责是什么？" | 模块职责分析 |
| 依赖分析 | "缓存层是如何设计的？" | 依赖关系分析 |
| 模式识别 | "用了哪些设计模式？" | 模式识别 |
| 流程追踪 | "下单流程是怎样的？" | 数据流分析 |

## MCP 调用协议

### Request

```json
{
  "tool": "analyze-architecture",
  "params": {
    "question": "为什么要用 Redis 做缓存？",
    "context": {
      "project_path": "/path/to/project",
      "language": "java",
      "focus_areas": ["缓存", "分布式"]
    }
  }
}
```

### Response

```json
{
  "success": true,
  "data": {
    "answer": "采用 Redis 缓存的原因分析",
    "confidence": 0.95,
    "reasoning": [
      {
        "point": "分布式场景需要",
        "evidence": "项目部署在多实例环境",
        "files": ["config/application.yml"],
        "code_snippet": "spring.session.store-type: redis"
      },
      {
        "point": "数据一致性要求",
        "evidence": "本地缓存无法跨实例同步",
        "files": ["src/config/CacheConfig.java"]
      }
    ],
    "alternatives_considered": [
      {
        "name": "本地缓存 (Caffeine/Guava)",
        "reason_not_used": "仅适用单机部署"
      }
    ],
    "related_patterns": [
      "Cache-Aside Pattern",
      "Read-Through Cache"
    ],
    "related_files": [
      "src/service/CacheService.java",
      "src/config/RedisConfig.java"
    ]
  }
}
```

## 问题类型与回答模板

### 1. 设计原因类

```
问: 为什么要 [设计点]？
答:

## 回答

[直接回答，1-2 句话]

## 理由

1. [原因 1]
   - 证据: [相关代码/配置]
   - 位置: [文件:行号]

2. [原因 2]
   - 证据: [相关代码/配置]
   - 位置: [文件:行号]

## 替代方案

考虑过的替代:
• [替代方案 1] - [未选原因]
• [替代方案 2] - [未选原因]

## 相关文件

• [文件1]
• [文件2]
```

### 2. 技术选型类

```
问: 为什么选择 [技术A] 而不是 [技术B]？
答:

## 技术 [技术A] 的优势

• [优势 1]
• [优势 2]

## 当前项目的选择依据

• [依据 1]: 在 [文件] 中发现 [证据]
• [依据 2]: 在 [配置] 中发现 [证据]

## 与 [技术B] 的对比

| 维度 | [技术A] | [技术B] |
|------|---------|---------|
| [维度1] | [优势] | [劣势] |

## 风险与注意事项

• [潜在风险]: [缓解措施]
```

### 3. 模块职责类

```
问: [模块名] 的职责是什么？
答:

## 模块职责

[核心职责描述]

## 核心功能

| 功能 | 方法 | 说明 |
|------|------|------|
| [功能1] | [方法名] | [说明] |
| [功能2] | [方法名] | [说明] |

## 依赖关系

```
[模块名]
├─ 依赖 ─→ [模块A]: [依赖原因]
│         └→ [模块B]: [依赖原因]
└─ 被依赖 ←─ [模块C]: [使用方式]
          └→ [模块D]: [使用方式]
```

## 关键实现

• [关键类/函数]: [用途]
```

### 4. 流程追踪类

```
问: [业务流程] 是怎样的？
答:

## 流程: [流程名称]

```
用户请求
    ↓
[Controller/入口]
    ↓
[Service/业务逻辑]
    ↓
[Repository/数据访问]
    ↓
数据库/外部服务
```

## 详细步骤

1. [步骤 1]
   - 位置: [文件:行号]
   - 代码: [关键代码片段]

2. [步骤 2]
   - 位置: [文件:行号]
   - 代码: [关键代码片段]

## 涉及的模块

• [模块1]
• [模块2]

## 异常处理

• [异常场景]: [处理方式]
```

## 使用示例

### 示例 1: 技术选型分析

```
用户: 为什么这个项目选择 Spring Boot 而不是 FastAPI？
AI:   正在分析技术选型...
      ↓
      ## 技术选型分析

      ### Spring Boot 的优势

      1. **企业级特性完善**
         • 证据: 发现 @Transactional, @Async 等企业注解
         • 位置: src/service/*.java

      2. **生态系统丰富**
         • 证据: pom.xml 包含 Spring Cloud
         • 位置: pom.xml

      3. **团队熟悉度**
         • 推断: 代码注释风格符合 Java 传统

      ### 项目特征

      • 微服务架构 (发现 spring-cloud-starter)
      • 复杂业务逻辑 (发现多层 Service)
      • 企业级安全 (发现 Spring Security)

      ### 结论

      Spring Boot 更适合:
      ✓ 企业级应用
      ✓ 微服务架构
      ✓ 复杂业务逻辑
```

### 示例 2: 模块依赖分析

```
用户: 订单服务和支付服务是什么关系？
AI:   正在分析依赖关系...
      ↓
      ## 依赖关系分析

      ### 调用关系

      OrderService ──调用──→ PaymentService
                      ↓
                 payment()
                 ├─ 发起支付
                 ├─ 查询状态
                 └─ 退款处理

      ### 具体调用点

      位置: src/order/service/OrderService.java:45
      ```java
      @Resource
      private PaymentService paymentService;

      public void pay(Long orderId) {
          paymentService.createPayment(orderId);
      }
      ```

      ### 接口契约

      PaymentService 提供:
      • createPayment()  创建支付
      • queryPayment()  查询状态
      • refund()        退款

      ### 数据流向

      订单数据 ──同步──→ 支付服务
                 ↓
            支付结果 ──回调──→ 订单服务
```

### 示例 3: 设计模式识别

```
用户: 这个项目用了哪些设计模式？
AI:   正在识别设计模式...
      ↓
      ## 设计模式识别

      ### 识别到的模式

      #### 1. 工厂模式
      • 位置: src/factory/*.java
      • 实例: PaymentFactory
      • 用途: 创建支付渠道实例

      ```java
      public interface PaymentFactory {
          Payment createPayment(String type);
      }
      ```

      #### 2. 策略模式
      • 位置: src/strategy/*.java
      • 实例: DiscountStrategy
      • 用途: 不同折扣计算策略

      #### 3. 模板方法模式
      • 位置: src/template/*.java
      • 实例: OrderProcessTemplate
      • 用途: 定义订单处理流程骨架

      #### 4. 观察者模式
      • 位置: src/observer/*.java
      • 实例: OrderStatusListener
      • 用途: 订单状态变更通知

      ### 模式应用统计

      | 模式 | 使用次数 | 主要用途 |
      |------|---------|---------|
      | 工厂模式 | 3 | 对象创建 |
      | 策略模式 | 5 | 算法切换 |
      | 模板方法 | 2 | 流程复用 |
```

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
