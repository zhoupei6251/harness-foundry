---
name: skill-preferences
description: "子 Agent spawn 路由。新范式：直接 spawn，不调 Skill 工具。"
tags: [Standard]
---

# 子 Agent spawn 路由

> 新范式：直接 spawn subagent，不通过 `wu_skills: auto` 的 skill 解析链路。
> 路由规则见 `core/intent-routing.md` § 写完代码必做。

## 代码域 spawn 规则

| 触发 | spawn 谁 |
|------|---------|
| 写完代码 | `ecc:java-reviewer` |
| 新接口/权限变更 | `ecc:security-reviewer` |
| SQL/DDL 变更 | `ecc:database-reviewer` |
| 精简/优化 | `ecc:code-simplifier` |
| 捕获静默失败 | `ecc:silent-failure-hunter` |
| 大型任务尾盘 | 上面三个并行 |

## Novel 域路由（保留）

| agent_role | wu_type | 建议 skill |
| --- | --- | --- |
| novel-writer | chapter-write | junli-ai-novel, humanizer-zh |
| novel-writer | rewrite | junli-ai-novel, humanizer-zh |
| novel-planner | outline | brainstorming, junli-ai-novel |
| novel-reviewer | review | novel-evaluator |
| humanizer | polish | humanizer-zh |
| editor | cross-chapter-check | memory-manager, junli-ai-novel |

## 参考

- **全局禁止传给子 Agent**：`brainstorming`, `writing-plans`, `git-xywh`
- 旧版 `wu_skills: auto` 完整路由表已移除，见 git history
