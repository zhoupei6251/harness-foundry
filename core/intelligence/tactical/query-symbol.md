---
name: query-symbol
description: "快速定位代码符号（类/函数/变量）。触发：需要找某个符号、不知道在哪里、查询定义。"
tags: [Intelligence, Code, Tactical]
triggers:
  - "查找"
  - "在哪里"
  - "定义"
  - "符号"
  - "定位"
  - "搜索"
layer: tactical
---

# /query-symbol

使用 CodeGraph 快速定位代码符号（类、函数、方法、变量等）。

## 使用场景

| 场景 | 示例 |
|------|------|
| 找类定义 | "UserService 在哪里？" |
| 找函数实现 | "login 方法在哪里？" |
| 找变量声明 | "MAX_RETRY 是什么？" |
| 找接口实现 | "实现了哪些接口？" |

## 调用方式

```markdown
使用 CodeGraph 的 search-nodes 能力：
- query: {符号名称}
- node_types: ["class", "function", "method", "variable"] (可选)
```

## 预期输出

```json
{
  "results": [
    {
      "name": "UserService",
      "type": "class",
      "file": "src/service/UserService.java",
      "line": 15,
      "signature": "public class UserService implements IUserService"
    },
    {
      "name": "UserService",
      "type": "class",
      "file": "test/service/UserServiceTest.java",
      "line": 10
    }
  ]
}
```

## 示例对话

```
用户: 帮我找一下 OrderController
AI:   调用 /query-symbol
      ↓
      找到 1 个结果:
      └─ OrderController
         类型: class (REST Controller)
         位置: src/main/java/com/example/controller/OrderController.java:1
         方法: createOrder(), getOrder(), cancelOrder()
```

## 支持的符号类型

| 类型 | 说明 |
|------|------|
| `file` | 文件 |
| `module` | 模块 |
| `class` | 类 |
| `interface` | 接口 |
| `function` | 函数 |
| `method` | 方法 |
| `property` | 属性 |
| `variable` | 变量 |
| `constant` | 常量 |
| `enum` | 枚举 |

## 搜索优化

- 支持模糊搜索
- 自动过滤测试文件（除非指定）
- 结果按相关性排序
