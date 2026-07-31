---
name: never清单
description: "绝对禁止事项清单。写代码/审查时自检。"
tags: [Rules, Never]
---

# NEVER 清单

## 代码

- **shell 写文本文件** — 用 Write/Edit 工具
- **未读就写** — 先 Read 相关文件再动笔
- **静默失败** — 空 catch、返回 null 不抛异常
- **Controller 写业务** — 只做参数校验 + 路由
- **循环 SQL** — for 里发 SQL → 批量
- **空 catch** — 必须处理或转译上抛
- **泄露敏感信息** — 密码/Token/身份证不打日志
- **AOP 自调用** — `this.xxx()` 不走代理，事务/@Cache/@Async 全失效
- **JSON 库混用** — 优先级：系统工具 → FastJson2 → Hutool → Jackson
- **事务内缓存更新** — 用 `afterCommit` 回调
- **多实例用本地锁** — `synchronized` 只锁单 JVM
- **分布式锁非原子** — 用 Redisson，不手写 setnx+expire
- **SQL 注入** — `${xxx}` 拼接用户输入 → 用 `#{}`
- **水平越权** — 改 id 查他人数据 → 租户 + 归属校验
- **参数篡改** — 后端相信前端价格 → 后端计算
- **`SELECT *`** — 明确列名
- **深分页** — `LIMIT 1000000,10` → 游标分页
- **大/热 Key** — 分片 + 本地缓存
- **一次调用的抽象** — Factory/Strategy/Builder 只调一次 → 删
- **"为以后扩展"** — YAGNI
- **三层以上嵌套** — 重构
- **自动 push** — 永远不

## 路由

- **不声明 Route** — 首句必须有
- **置信度 < 0.7 还不反问**
- **多域同时匹配不确认**

## 参考

- `traps-archive/code/springboot-checklist.md` — 写完自检清单
- `traps-archive/code/00-all.md` — 160 条详细陷阱
