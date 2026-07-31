# Spring Boot 编码自检清单

> 内联 karpathy-guidelines + springboot-patterns 精华。写完代码自检。

## 行为准则（9 条，P0 优先级）

1. **先想后写** — 不确定就问。不默默假设。
2. **保持简单** — 最少代码解决问题。200 行能压到 50 行就重写。
3. **精准修改** — 只碰要改的，不"顺带优化"旁边的代码。
4. **目标驱动** — 先定成功标准，再写代码。修 bug 先复现→修复→验证。
5. **先读后写** — 没读过的文件不要改。先 Read 再动笔。
6. **工具优先** — Write/Edit/Read/Grep/Glob，禁止 shell 写文本文件。
7. **不静默失败** — 空 catch/吞异常/返回 null 不抛异常 = 必须打回。
8. **冲突显式化** — 方案和实际对不上，说出来。不悄悄自己改方案。
9. **写完自查** — 能再删 20% 吗？有触发词（Factory/Strategy/Builder）吗？

## 过度设计检测

| 触发词 | 自问 |
|--------|------|
| Factory、Strategy、Builder、Abstract | 有 2 个以上调用方吗？ |
| 多层接口+实现 | 被调用 2 次以上吗？ |
| "为以后扩展" | 真的有扩展需求吗？ |

**全是"否"→直接写。**

## Spring Boot 规则

### Controller
- 只做参数校验 + 路由 + 返回包装，不写业务
- `@Validated` 分组校验，不用 if-else 堆参数检查

### Service
- `@Transactional` 在 public 方法上，自调用不走代理
- `@Async` 线程无事务，不混用
- 异常用 `ServiceException`（`ruoyi-common-core`）

### Mapper / SQL
- `SELECT *` → 明确列名
- 循环里不发 SQL → 批量
- `${xxx}` 只用于非用户输入的场景（ORDER BY 等），用户输入用 `#{}`
- 深分页 → 游标分页或缩小时间窗口

### 并发 / 锁
- 分布式锁用 Redisson `tryLock`，不手写 `setnx + expire`
- 事务内不更新缓存 → `TransactionSynchronization.afterCommit`
- 多实例禁止本地 `synchronized`

### 安全
- 所有查询带租户 ID + 归属校验（防水平越权）
- 后端不信任前端传来的价格/金额
- 文件上传校验 Magic Number + UUID 重命名

### JSON
- 优先级：系统工具类 → FastJson2 → Hutool → Jackson

### 日志
- 密码/Token/身份证/手机号不打日志
- catch 里 error 必须带异常对象：`log.error("msg", e)`

## 写完自检（20 秒）

- [ ] 有空 catch 吗？→ 处理或转译
- [ ] 有 `SELECT *` 吗？→ 明确列名
- [ ] 有循环 SQL 吗？→ 批量
- [ ] 有不必要的 Factory/Strategy 吗？→ 删
- [ ] 有敏感信息进日志吗？→ 脱敏
- [ ] 有水平越权吗？→ 租户+归属
- [ ] 能再删 20% 吗？→ 试
