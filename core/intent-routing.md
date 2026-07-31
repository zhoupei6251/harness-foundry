---
name: intent-routing
description: "意图路由表。地图不是牢房，大任务导航，小任务直接处理。"
tags: [Rules, Runbook]
---

# 意图路由表

> 地图不是牢房。大型任务用它导航；小改动声明 Route 后直接处理。

## 路由

| 用户说 | 动作 |
|--------|------|
| 设计、方案、架构、选型 | 写 spec → **暂停等确认** |
| 计划、拆分、WBS、排期 | 写 plan → **暂停等确认** |
| OK、开始、做吧、执行 | 拆 task → 实现 |
| 写代码、实现、重构 | 自检 `springboot-checklist.md` → 实现 → spawn reviewer |
| 修bug、空指针、小问题 | 直接处理 |
| 调试、排查、不工作 | 复现→缩小→假设→验证→修复→回归 |
| 测试、单测、E2E | 写测试→验证 |
| 审查、review | 并行 spawn: java-reviewer + security-reviewer（SQL 变更加 database-reviewer） |
| commit、merge、push、MR | `git-xywh` skill |
| 查、搜、调研 | WebSearch → WebFetch |

## 写完代码必做

1. 自检：`traps-archive/code/springboot-checklist.md` § 写完自检
2. spawn `ecc:java-reviewer`
3. 新接口/权限变更 → 加 spawn `ecc:security-reviewer`
4. SQL/DDL 变更 → 加 spawn `ecc:database-reviewer`
5. 大型任务尾盘 → 并行 spawn 上面三个

## 大型任务阶段门禁

1. spec/plan 写完 → **暂停等确认**
2. 用户确认 → 实现
3. 尾盘 → 并行审查

## 参考

| 场景 | 看 |
|------|-----|
| 写代码前/后 | `traps-archive/code/springboot-checklist.md` |
| 更多陷阱 | `traps-archive/code/00-all.md`（160 条） |
| 禁止事项 | `core/NEVER.md` |
| 多 task 并行 | `core/orchestration/dispatcher-workflow.md` |

## 沟通

- 对用户：中文
- 子 Agent prompt：中文，固定键名保留英文
