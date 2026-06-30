---
name: get-callees
description: "获取指定符号调用的所有代码。触发：想知道某个方法内部调用了什么、分析实现细节。"
tags: [Intelligence, Code, Tactical]
triggers:
  - "调用了什么"
  - "被调用方"
  - "内部实现"
  - "调用了哪些"
layer: tactical
---

# /get-callees

使用 CodeGraph 查找指定符号调用的所有代码。

## 使用场景

| 场景 | 示例问题 |
|------|---------|
| 理解实现 | "这个方法里面调用了什么？" |
| 追踪逻辑 | "订单创建的完整流程是什么？" |
| 分析依赖 | "这个服务依赖了哪些组件？" |
| Bug 定位 | "哪个调用抛出了这个异常？" |

## 调用方式

```markdown
使用 CodeGraph 的 get-callees 能力：
- symbol: {符号名称}
- depth: 1 (调用深度，默认1层)
```

## 预期输出

```json
{
  "symbol": "UserService.login",
  "callees": [
    {
      "file": "src/repository/UserRepository.java",
      "line": 15,
      "method": "findByUsername()",
      "context": "查询用户"
    },
    {
      "file": "src/utils/PasswordUtil.java",
      "line": 8,
      "method": "verify()",
      "context": "验证密码"
    },
    {
      "file": "src/cache/CacheService.java",
      "line": 22,
      "method": "set()",
      "context": "缓存登录信息"
    }
  ],
  "total": 3
}
```

## 示例对话

```
用户: login 方法内部是怎么实现的？
AI:   调用 /get-callees
      ↓
      login() 调用链:
      ├─ UserRepository.findByUsername()  [查询用户]
      ├─ PasswordUtil.verify()           [验证密码]
      ├─ CacheService.set()              [缓存登录信息]
      └─ LogService.info()               [记录日志]

      完整流程:
      1. 根据用户名查询数据库
      2. 验证密码哈希
      3. 缓存用户信息
      4. 记录登录日志
```

## 深度调用链

```markdown
# 获取多层调用关系
/get-callees symbol=login depth=3
```

返回调用深度到 3 层的关系，展示完整的调用树。

## 使用建议

- 配合 `/get-callers` 一起使用可获得完整调用图
- 使用 `/analyze-impact` 可一次性获取完整影响范围
