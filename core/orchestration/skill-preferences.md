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
| 实现前（任何代码任务） | 注入 `ponytail:ponytail`（懒惰阶梯：YAGNI → 复用 → 标准库 → 平台原生 → 已装依赖 → 一行 → 最小实现） |
| 写完代码 | `ecc:java-reviewer` |
| 新接口/权限变更 | `ecc:security-reviewer` |
| SQL/DDL 变更 | `ecc:database-reviewer` |
| 实体/DTO/VO 变更 | `ecc:type-design-analyzer` |
| 精简/优化 | `ponytail:ponytail-review`（diff 删除清单）→ 按需 `ecc:code-simplifier` |
| 捕获静默失败 | `ecc:silent-failure-hunter` |
| 编译失败 | `ecc:java-build-resolver` |
| task 收尾 | `ecc:code-simplifier` + `ecc:comment-analyzer` 并行 |
| 大型任务尾盘 | `ecc:java-reviewer` + `ecc:security-reviewer` + `ecc:database-reviewer` + `ecc:pr-test-analyzer` + `ecc:refactor-cleaner` 并行 |

> ponytail 强度：默认 full，可用 `/ponytail lite|full|ultra|off` 切换。其「对理解从不懒惰」与 harness R1（先读后写）一致；被显式要求的内容（校验、防数据丢失、安全）不削减。

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

## Intelligence Layer 路由

由 codebase-memory-mcp 驱动（`core/intelligence/`），战略层 + 战术层统一：

| 任务 | 动作 |
|------|------|
| 理解项目/新项目接手 | `/understand-project`（index_repository + get_architecture） |
| 架构分析/设计评审 | `/analyze-architecture`（get_architecture） |
| 查询知识图谱 | `/query-knowledge-graph`（search_graph / query_graph） |
| 建立代码索引 | `/index-project`（index_repository，>100 文件） |
| 定位代码符号 | `/query-symbol`（search_graph + get_code_snippet） |
| 查调用方 | `/get-callers`（trace_path inbound） |
| 查被调用方 | `/get-callees`（trace_path outbound） |
| 评估变更影响 | `/analyze-impact`（detect_changes） |
| 文本/字符串搜索 | `ripgrep-search`（rg，图结构无法覆盖时） |
| 编译器级定义/引用 | `lsp-query`（textDocument/*） |
| 三层协同编排 | `code-insight-stack`（默认入口） |
