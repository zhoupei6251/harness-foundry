---
name: skill-preferences
description: "子 Agent spawn 路由。代码域直接 spawn ecc，novel/news 域走 checklist + 审查。"
tags: [Standard]
---

# 子 Agent spawn 路由

> 代码域：直接 spawn subagent。Novel/News 域：自检 checklist → 审查 skill。

## 代码域 spawn 规则

| 触发 | spawn 谁 |
|------|---------|
| 写完代码 | `ecc:java-reviewer` |
| 新接口/权限变更 | `ecc:security-reviewer` |
| SQL/DDL 变更 | `ecc:database-reviewer` |
| 实体/DTO/VO 变更 | `ecc:type-design-analyzer` |
| 精简/优化 | `ecc:code-simplifier` |
| 捕获静默失败 | `ecc:silent-failure-hunter` |
| 编译失败 | `ecc:java-build-resolver` |
| task 收尾 | code-simplifier + comment-analyzer 并行 |
| 大型任务尾盘 | java-reviewer + security-reviewer + database-reviewer + pr-test-analyzer + refactor-cleaner 并行 |

## Novel 域路由

| 任务 | 动作 |
|------|------|
| 写章节 | 自检 `traps-archive/novel/novel-checklist.md` → 写 → 自检 5 维 |
| 审稿 | 跑 `novel-evaluator`（7 维评分 + 原文举证） |
| 润色 | 跑 `humanizer-zh` |
| 大纲规划 | Skill(superpowers:brainstorming) → 产出大纲 |

## News 域路由

| 任务 | 动作 |
|------|------|
| 写稿件 | 自检 `traps-archive/news/news-checklist.md` → 写 → 交付前自检 |
| 事实核查 | 跑 `fact-check` |
| 追热点 | WebSearch → 素材整理 |

## 参考

- 全局禁止传给子 Agent：`brainstorming`, `writing-plans`, `git-xywh`
