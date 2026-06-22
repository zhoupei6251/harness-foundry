---
name: code-reference
description: "Harness 代码参考系统：按 Controller/Service/Mapper/Entity/Redis/WebSocket 分类的最佳范例索引。"
tags: [Memory]
---

# Harness 代码参考系统

> 不是规则手册，是**范例索引**。规则能防错，范例才能教会怎么写得好。
> 每个参考文件都经过质量审计（2026-06-17），未被审计的文件可能质量不达标。

---

## 用法

1. AI 被要求写一个 XxxController → 查下表 → 读参考文件 → 对照反面教材 → 再写
2. 对齐的是**节奏感**：方法长度、私有方法拆分粒度、注释密度、异常处理方式、日志位置
3. 不是照抄代码，是匹配风格

## 仓库路径

所有 `canvas/` 范例（参考与反面教材除外）位于：

```
ruoyi-modules/ruoyi-aigc/src/main/java/org/xywh/aigc/canvas/
├── controller/   ← Controller 范例
├── service/impl/ ← Service 实现范例
├── mapper/       ← Mapper 范例（含 .xml）
├── domain/       ← Entity / VO / BO 范例
├── redis/        ← RedisService / KeyBuilder 范例
├── notifier/     ← WebSocket 推送范例
└── enums/        ← 错误码枚举范例
```

其他模块的反面教材：

| 反面教材 | 路径 |
|---------|------|
| `AigcChatController.java`、`AigcNovelController.java` 等 | `ruoyi-modules/ruoyi-aigc/src/main/java/org/xywh/aigc/basic/controller/` |
| `AigcNovelServiceImpl.java`、`AigcDramaServiceImpl.java` | `ruoyi-modules/ruoyi-aigc/src/main/java/org/xywh/aigc/{basic,drama}/service/impl/` |
| `GlobalExceptionHandler.java`（框架层） | `ruoyi-common/ruoyi-common-web/src/main/java/org/xywh/common/web/handler/` |

`Grep "XxxController.java"` 可快速定位；找不到时用 Glob。

---

## 路由表

### Controller

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| 标准 CRUD | `CanvasProjectController.java` — 每个方法 <10 行，CRUD➕分页全 | ★★★★★ |
| 复杂业务（批量/锁/权限） | `CanvasNodeController.java` — 分组校验➕@Log➕@RepeatSubmit 全 | ★★★★★ |
| 异步任务（提交→状态→取消） | `CanvasGenerateController.java` — 异步生命周期标准模式 | ★★★★★ |
| 接口文档化（按角色分组） | `BfRechargeOrderController.java` — Javadoc 含页面映射和状态流转，按 tenant/platform 分组 | ★★★★☆ |

**反面教材 — 不要学：**

| 文件 | 问题 |
|------|------|
| `AigcDramaController.java` | Controller 层写业务逻辑（`startRewrite` 中 null 判断 + `R.fail()`），方法过长 >10 行 |
| `AigcChatController.java`（遗留） | 手写 try-catch 兜底异常，破坏全局异常处理器 |

### Service

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| 重业务（事务+锁+Redis+广播） | `CanvasNodeServiceImpl.java` — 34 个私有方法，分布式锁+CASE WHEN+Lua+WebSocket 全覆盖 | ★★★★★ |
| DAG/图/关系校验 | `CanvasEdgeServiceImpl.java` — BFS 环检测+防重复并发+前后端双检 | ★★★★★ |
| 查询+缓存一致性 | `CanvasProjectServiceImpl.java` — TransactionSynchronization 后置缓存+EXISTS 权限过滤 | ★★★★★ |

**反面教材 — 不要学：**

| 文件 | 问题 |
|------|------|
| `AigcNovelServiceImpl.java` | **所有写方法缺少 @Transactional**、`validEntityBeforeSave` 空方法+TODO、无错误码枚举 |
| `AigcDramaServiceImpl.java` | `deleteWithValidByIds` 硬编码手动级联删除 6 张表 40+ 行、异常未归一化 |

### Mapper

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| 标准 Mapper + CASE WHEN | `CanvasNodeMapper.java` + `.xml` — BaseMapperPlus 双泛型+CASE WHEN 批量+递归 CTE | ★★★★★ |
| 原子计数/EXISTS | `CanvasProjectMapper.java` — GREATEST(0, IFNULL(...)) 防负数 | ★★★★★ |
| 软删除+恢复 | `CanvasEdgeMapper.java` — del_flag 软删除+restoreDeleted | ★★★★★ |

### Entity / VO / BO

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| 实体（租户+JSON+枚举） | `CanvasNode.java` — TenantEntity+autoResultMap+JacksonTypeHandler | ★★★★★ |
| VO（AutoMapper+展示增强） | `CanvasNodeVo.java` — String 替代枚举+非 DB 展示字段 | ★★★★★ |
| BO（分组校验+批量接收） | `CanvasNodeBo.java` — 内部校验组+reverseConvertGenerate=false | ★★★★★ |

### Redis

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| RedisService | `CanvasRedisService.java` — Lua 原子+RBatch Pipeline+SETNX 限流 | ★★★★★ |
| KeyBuilder | `CanvasRedisKeyBuilder.java` — tenantId 前缀强制+Duration TTL+scan pattern | ★★★★★ |

### WebSocket

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| 消息路由器 | `CanvasWebSocketMessageRouter.java` — WebSocketMessageRouter 接口+switch 分发 | ★★★★★ |
| 推送/广播 | `CanvasPushNotifier.java` — 单用户+广播+排除发送者+离线队列 | ★★★★★ |

### 异常处理

| 场景 | 参考文件 | 评级 |
|------|---------|------|
| 全局异常处理器 | `GlobalExceptionHandler.java` — 14 种异常+SSE 特殊处理 | ★★★★★ |
| 错误码枚举 | `CanvasErrorCode.java` — 34 个错误码+{} 占位符+throwException | ★★★★★ |

---

## 看参考文件时关注什么

| 维度 | 关注点 |
|------|--------|
| **骨架** | 类注解、继承、注入方式、方法签名 |
| **节奏** | 方法长度、拆分粒度、私有方法个数 |
| **注释** | 哪些方法写 Javadoc、中文密度 |
| **异常** | 抛什么、哪里 catch、哪里不 catch |
| **日志** | 入口打不打、出口打不打、什么级别 |
| **数据流** | 参数→BO→Entity→VO，转换在哪里发生 |

---

## 持续更新

- **发现更好的范例** → 替换表中条目，附"比旧参考好在哪"
- **发现变差的文件** → 移到 "退役" 区
- **发现新的反面教材** → 补充到对应章节

最后审计日期：2026-06-17
