---
name: context-map-template
description: "跨模块上下文映射模板。开源版本含占位符，使用前请按项目替换。"
tags: [Memory, Standard, Template]
---

# 项目上下文映射（模板）

> **本文件是 Harness Kit 开源版本提供的模板**。克隆到你自己的项目后：
>
> 1. 把 `${PROJECT_NAME}` 替换成你的项目名（如 `ruoyi-aigc`、`my-app`）
> 2. 把 `${MAIN_PACKAGE}` 替换成你的主包前缀（如 `org.xywh.aigc`、`com.example.app`）
> 3. 删除不需要的章节，按你的实际子包结构增删表格行
> 4. 如果是非 Java/Spring 项目，把"分层"那行改成对应技术栈

> **跨模块协作前先看本图**，避免在错误的模块里改代码。

---

## 占位符说明

| 占位符 | 含义 | 示例值 |
|--------|------|--------|
| `${PROJECT_NAME}` | 项目名（maven/gradle module 名） | `ruoyi-aigc` |
| `${MAIN_PACKAGE}` | 主包前缀（Java package 或源码根目录） | `org.xywh.aigc` |
| `${SERVICE_COUNT}` | 子服务/子模块数量 | 5 |
| `${PRIMARY_LANG}` | 主语言 | `Java 21` |
| `${FRAMEWORK}` | 主框架 | `Spring Boot 3.5.6` |
| `${BUILD_TOOL}` | 构建工具 | `maven` |

---

## 模块子域（按业务职责）

> 按你的实际子包结构填充。下方是 Java/Spring Boot 多模块项目的典型结构。

| 子包 | 业务职责 | 关键 Controller | 关键 Service |
|------|----------|----------------|--------------|
| `<domain-1>/` | `<domain-1 中文说明>` | `<XxxController>` | `<IXxxService>` |
| `<domain-2>/` | `<domain-2 中文说明>` | `<XxxController>` | `<IXxxService>` |
| `<domain-3>/` | `<domain-3 中文说明>` | `<XxxController>` | `<IXxxService>` |
| `config/` | 自动配置 + 第三方 API 拦截 + 线程池 | — | `<XxxAutoConfig>` |
| `common/` | 共享枚举 / 工具 / 异常处理 | — | — |

**填写示例**（仅供参考，**不要保留在你的项目里**）：

```
basic/        — 通用业务（AigcChat / AigcNovel / AigcProject / AigcTask）
bill/         — 计费 / 字典 / 模型价格 / 发票 / 充值
canvas/       — 画布编辑器（DAG 节点/边/撤销/协作）
config/       — 自动配置 + 第三方 API 拦截 + 线程池
drama/        — 业务域（角色/分镜/场景/镜头）
```

## 跨模块依赖方向（强约束）

> 列出你项目的依赖方向。**禁止反向依赖**应明确写出。

```
<domain-A> ──▶ <domain-B>    （<说明：例如 计费扣费 / Token 统计>）
<domain-A> ──▶ <domain-C>    （<说明>）
<domain-C> ──▶ <domain-A>    （<说明>）
```

**禁止反向依赖**（`<domain-B> → <domain-A>` 直接调用）。跨模块走 `Service + DTO` + OpenFeign / ApplicationEvent / message queue。

## 共享层（不要在子包里写）

| 类型 | 位置 | 谁负责 |
|------|------|--------|
| 全局异常处理 | `<框架层 GlobalExceptionHandler>` | 框架层 |
| 公共工具类 | `<framework/common/utils/>` | 框架层 |
| 鉴权注解 | `<框架层 @SaCheckPermission 等>` | 框架层 |

## 跨模块改动时的最小加载清单

1. `Read` 目标子包的 `package-info.java`（拿到模块定位）
2. `Read` 同名 Service 接口 + 实现类（对齐事务边界）
3. `Grep` 上游调用方（看谁在调，决定改动影响面）
4. `Read references/traps.md` § 事务与并发（必看）
5. 若涉及缓存：`Read` 项目内的 `<RedisKeyBuilder>` 复用 Key 规范
6. 若涉及消息推送：`Read` 项目内的 `<MessageRouter>` 路由协议

## 参考范例来源

> 指向你项目内的范例目录。开源版本留空，由项目自己填。

- Controller 范例 → `<填入你的子包，如 canvas/>`
- Service 范例 → `<填入你的子包>`
- 反面教材 → `<填入你的子包>`
- 详见 [references/README.md](references/README.md)

---

## 维护说明

- **新增子包** → 在"模块子域"表加一行，更新"依赖方向"图
- **子包合并/拆分** → 同时更新"模块子域"和"依赖方向"
- **跨模块方向反转** → 必须先评审，禁止私自调整
- **定期审计** → 季度一次 Review `references/README.md` 是否与本图一致