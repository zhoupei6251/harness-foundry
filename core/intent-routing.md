---
name: intent-routing
description: "意图路由表。superpowers + ecc 全启，无手动触发。"
tags: [Rules, Runbook]
---

# 意图路由表

> superpowers + ecc 覆盖全部开发阶段，零手动触发。

## 路由

| 用户说 | 动作 |
|--------|------|
| 设计、方案、架构、选型 | Skill(brainstorming) → spawn ecc:code-architect → 写 spec → **暂停等确认** |
| 修bug、空指针、不工作 | Skill(systematic-debugging) → 复现→缩小→假设→验证→修复→回归 |
| 写代码、实现、重构 | 实现 → 自检springboot-checklist → spawn 审查链 |
| 多个独立修改（文件无调用关系） | Skill(dispatching-parallel-agents) 并行派发 |
| OK、开始、做吧 | 拆task → 实现（同上） |
| 审查、review | 并行 spawn: java-reviewer + security-reviewer + database-reviewer + pr-test-analyzer |
| 测试、单测 | Skill(test-driven-development) → 先写测试→验证 |
| mvn compile 报错 | spawn ecc:java-build-resolver |
| commit、merge、push、MR | Skill(git-xywh) |
| 查、搜、调研 | WebSearch → WebFetch |

## 写完代码必做（无论改动大小）

```
自检 traps-archive/code/springboot-checklist.md § 写完自检
  ↓
spawn ecc:java-reviewer
  ↓ （以下按条件自动触发，独立的可并行）
├── 新接口/权限/用户输入 → spawn ecc:security-reviewer
├── SQL/DDL/schema → spawn ecc:database-reviewer
├── 实体/DTO/VO/领域对象变更 → spawn ecc:type-design-analyzer
├── 中型以上 → spawn ecc:silent-failure-hunter
├── task收尾 → 并行 spawn ecc:code-simplifier + ecc:comment-analyzer
└── 大型任务尾盘 → 并行 spawn pr-test-analyzer + ecc:refactor-cleaner
```

## 编译失败

```
spawn ecc:java-build-resolver（专修编译，不改业务逻辑）
```

## 大型任务门禁

1. brainstorm → code-architect → writing-plans → **暂停等确认**
2. 确认 → 拆 task → 逐个实现（每个 task 走写完代码流程）
3. 尾盘 → 并行 spawn java-reviewer + security-reviewer + database-reviewer + pr-test-analyzer + refactor-cleaner
4. 收尾 → code-simplifier + comment-analyzer → Skill(finishing-a-development-branch) → 落盘

## 参考

| 场景 | 看 |
|------|-----|
| 写完自检 | `traps-archive/code/springboot-checklist.md` |
| 更多陷阱 | `traps-archive/code/00-all.md` |
| 禁止事项 | `core/NEVER.md` |
