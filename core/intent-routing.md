---
name: intent-routing
description: "意图路由表。地图不是牢房，默认启 superpowers + ecc。"
tags: [Rules, Runbook]
---

# 意图路由表

> 地图不是牢房。默认：写代码→code路径，修bug→debug路径，设计→brainstorm路径。

## 路由

| 用户说 | 动作 |
|--------|------|
| 设计、方案、架构、选型 | Skill(brainstorming) → 写 spec → **暂停等确认** |
| 修bug、空指针、不工作 | Skill(systematic-debugging) → 复现→缩小→假设→验证→修复→回归 |
| 写代码、实现、重构 | 实现 → 自检springboot-checklist → spawn reviewer |
| OK、开始、做吧 | 拆task → 实现（同上） |
| 审查、review | 并行 spawn: java-reviewer + security-reviewer + database-reviewer |
| 测试、单测 | 写测试 → 验证 |
| commit、merge、push、MR | `git-xywh` skill |
| 查、搜、调研 | WebSearch → WebFetch |

## 写完代码必做（无论改动大小）

```
自检 traps-archive/code/springboot-checklist.md § 写完自检
  ↓
spawn ecc:java-reviewer
  ↓
改涉及: 新接口/权限/用户输入 → spawn ecc:security-reviewer
改涉及: SQL/DDL/schema → spawn ecc:database-reviewer
中型以上 → spawn ecc:silent-failure-hunter
task收尾 → spawn ecc:code-simplifier
```

## 大型任务门禁

1. brainstorm → 写 plan → **暂停等确认**
2. 确认 → 拆 task → 逐个实现（每个 task 走上面写完代码流程）
3. 尾盘 → 并行 spawn 三合一 reviewer → 整合落盘

## 参考

| 场景 | 看 |
|------|-----|
| 写完自检 | `traps-archive/code/springboot-checklist.md` |
| 更多陷阱 | `traps-archive/code/00-all.md` |
| 禁止事项 | `core/NEVER.md` |
