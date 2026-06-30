---
name: analyze-impact
description: "评估代码变更的影响范围。触发：重构前、修改核心方法、批量修改前。"
tags: [Intelligence, Code, Tactical]
triggers:
  - "影响范围"
  - "改了这个会影响到"
  - "重构"
  - "变更影响"
  - "评估影响"
layer: tactical
---

# /analyze-impact

使用 CodeGraph 评估代码变更的完整影响范围。

## 使用场景

| 场景 | 使用价值 |
|------|---------|
| 重构前 | 知道改哪里会影响到哪些模块 |
| 修改核心方法 | 评估风险，制定测试计划 |
| 批量修改 | 避免遗漏关键的依赖方 |
| Code Review | 快速了解变更的影响范围 |

## 调用方式

```markdown
使用 CodeGraph 的 get-impact-radius 能力：
- file: {文件路径}
- symbol: {符号名称} (可选)
```

## 预期输出

```json
{
  "target": {
    "file": "src/service/UserService.java",
    "symbol": "login",
    "line": 25
  },
  "impact": {
    "callers": [
      {
        "file": "src/controller/AuthController.java",
        "count": 1
      }
    ],
    "callees": [
      {
        "file": "src/repository/UserRepository.java",
        "count": 2
      }
    ]
  },
  "risk": {
    "level": "medium",
    "reason": "涉及 1 个调用方，需要回归测试"
  },
  "affected_modules": ["auth", "user"],
  "test_files": [
    "test/service/UserServiceTest.java",
    "test/controller/AuthControllerTest.java"
  ]
}
```

## 示例对话

```
用户: 我想重构 UserService.login 这个方法，帮我评估下影响
AI:   调用 /analyze-impact
      ↓
      影响评估报告:
      ═══════════════════════════════

      目标: UserService.login() [line 25]

      影响范围:
      ├─ 上游影响 (调用方): 2 个
      │  ├─ AuthController.login() [line 34]
      │  └─ AdminController.adminLogin() [line 23]
      │
      ├─ 下游影响 (被调用): 3 个
      │  ├─ UserRepository.findByUsername()
      │  ├─ PasswordUtil.verify()
      │  └─ CacheService.set()
      │
      └─ 测试覆盖: 2 个测试文件

      风险等级: 中等

      建议:
      1. 修改前运行相关单元测试
      2. 通知相关模块负责人
      3. 制定回归测试计划
```

## 风险等级说明

| 等级 | 说明 |
|------|------|
| `low` | 无调用方或被广泛测试覆盖 |
| `medium` | 有少量调用方，需要回归测试 |
| `high` | 被多个模块调用，影响范围广 |
| `critical` | 核心基础设施，影响整个系统 |

## 与其他 Skill 的配合

```
1. /query-symbol     → 定位要修改的代码
2. /get-callers      → 快速查看直接调用方
3. /get-callees      → 快速查看被调用方
4. /analyze-impact   → 综合评估完整影响
```
