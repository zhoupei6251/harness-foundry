---
name: get-callers
description: "获取调用指定符号的所有代码。触发：想知道谁在调用某个方法、分析依赖、评估影响。"
tags: [Intelligence, Code, Tactical]
triggers:
  - "被谁调用"
  - "调用方"
  - "谁用了"
  - "依赖分析"
  - "调用链"
layer: tactical
---

# /get-callers

使用 CodeGraph 查找调用指定符号的所有代码。

## 使用场景

| 场景 | 示例问题 |
|------|---------|
| 评估影响 | "修改这个方法会影响哪些地方？" |
| 理解依赖 | "哪些地方在调用 UserService？" |
| 回归测试 | "我改了这段代码需要测哪些？" |
| 重构分析 | "这个方法被用的多吗？" |

## 调用方式

```markdown
使用 CodeGraph 的 get-callers 能力：
- symbol: {符号名称}
- depth: 1 (调用深度，默认1层)
```

## 预期输出

```json
{
  "symbol": "UserService.login",
  "callers": [
    {
      "file": "src/controller/AuthController.java",
      "line": 45,
      "method": "login()",
      "context": "调用 login() 进行用户认证"
    },
    {
      "file": "src/controller/AdminController.java",
      "line": 23,
      "method": "adminLogin()",
      "context": "管理员登录"
    }
  ],
  "total": 2
}
```

## 示例对话

```
用户: getOrderById 这个方法被谁调用了？
AI:   调用 /get-callers
      ↓
      调用方分析:
      ├─ OrderController.getOrder() [line 34]
      ├─ OrderService.findById() [line 67]
      ├─ OrderCacheService.get() [line 12]
      └─ OrderController.listOrders() [line 89]

      影响范围: 4 个文件需要关注
```

## 深度调用链

```markdown
# 获取多层调用关系
/get-callers symbol=getOrderById depth=3
```

返回调用深度到 3 层的关系。

## 与 /analyze-impact 的区别

| Skill | 回答什么 |
|-------|---------|
| `/get-callers` | 直接调用方（一层） |
| `/get-callees` | 直接被调用方（一层） |
| `/analyze-impact` | 完整影响范围（多层） |
