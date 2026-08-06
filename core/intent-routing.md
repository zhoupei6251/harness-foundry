---
name: intent-routing
description: "意图路由表。superpowers + ecc 全启，无手动触发。"
tags: [Rules, Runbook]
---

# 意图路由表

> superpowers + ecc 覆盖全部开发阶段，零手动触发。

## 代码域路由

| 用户说 | 动作 |
|--------|------|
| 设计、方案、架构、选型 | Skill(superpowers:brainstorming) → spawn ecc:code-architect → 写 spec → **暂停等确认** |
| 修bug、空指针、不工作 | Skill(superpowers:systematic-debugging) → 复现→缩小→假设→验证→修复→回归 |
| 写代码、实现、重构 | 实现 → 自检springboot-checklist → spawn 审查链 |
| 多个独立修改（文件无调用关系） | Skill(superpowers:dispatching-parallel-agents) 并行派发 |
| OK、开始、做吧 | 拆task → 实现（同上） |
| 审查、review | 并行 spawn: ecc:java-reviewer + ecc:security-reviewer + ecc:database-reviewer + ecc:pr-test-analyzer |
| 测试、单测 | Skill(superpowers:test-driven-development) → 先写测试→验证 |
| mvn compile 报错 | spawn ecc:java-build-resolver |
| commit、merge、push、MR | Skill(git-xywh) |
| 查、搜、调研 | WebSearch → WebFetch |

## Novel 域路由

> 入口：任何 novel 指令先走 `novel-protocol`（渐进式披露路由 + 因果链一致性，省 76% token），按需装配。
> **完整路由表见 `skills/novel-protocol/SKILL.md` § 指令路由表（唯一权威源）**，此处仅列高频意图。

| 用户说 | 动作 |
|--------|------|
| **任何 novel 指令（首步）** | Skill(novel-protocol)：路由 → 装配 → 知识库绑定 → 因果链校验 → 交付 |
| 写章节、继续写、下一章 | novel-protocol → 读 MEMORY.md → 自检 `traps-archive/novel/novel-checklist.md` → 写 → 5维自检 |
| 审稿、评分、评测 | 跑 novel-evaluator（7维评分+原文举证）→ 报告 |
| 大纲、世界观、设定 | Skill(superpowers:brainstorming) → 产出大纲 |
| 润色、去AI味 | 跑 humanizer-zh |
| 写前查设定 | 读 MEMORY.md → 参考已有伏笔/人物 |

## News 域路由

| 用户说 | 动作 |
|--------|------|
| 写稿件、写新闻 | 自检 `traps-archive/news/news-checklist.md` → 写 → 交付前自检 |
| 事实核查、核实 | 跑 fact-check |
| 追热点、选题 | WebSearch → 素材整理 |
| 审校、编辑 | 倒金字塔复查 + 6 红线自检 |

## 写完代码必做（无论改动大小）

```
自检 traps-archive/code/springboot-checklist.md § 写完自检
  ↓
spawn ecc:java-reviewer（prompt 必带：按 rules/code/java/patterns.md「编码标准基准」逐条核对
  Alibaba Java Coding Guidelines + Google Java Style + Clean Code 的禁止/必须清单，违反即打回重构）
  ↓ （以下按条件自动触发，独立的可并行）
├── 新接口/权限/用户输入 → spawn ecc:security-reviewer
├── SQL/DDL/schema → spawn ecc:database-reviewer
├── 实体/DTO/VO/领域对象变更 → spawn ecc:type-design-analyzer
├── 中型以上 → spawn ecc:silent-failure-hunter
├── task收尾 → 并行 spawn ecc:code-simplifier + ecc:comment-analyzer
└── 大型任务尾盘 → 并行 spawn ecc:pr-test-analyzer + ecc:refactor-cleaner
```

## 编译失败

```
spawn ecc:java-build-resolver（专修编译，不改业务逻辑）
```

## 大型任务门禁

1. brainstorm → ecc:code-architect → writing-plans → **暂停等确认**
2. 确认 → 拆 task → 逐个实现（每个 task 走写完代码流程）
3. 尾盘 → 并行 spawn ecc:java-reviewer + ecc:security-reviewer + ecc:database-reviewer + ecc:pr-test-analyzer + ecc:refactor-cleaner
4. 收尾 → ecc:code-simplifier + ecc:comment-analyzer → Skill(superpowers:finishing-a-development-branch) → 落盘

## 参考

| 场景 | 看 |
|------|-----|
| 写完自检 | `traps-archive/code/springboot-checklist.md` |
| Novel 写前/写后 | `traps-archive/novel/novel-checklist.md` |
| News 写前/写后 | `traps-archive/news/news-checklist.md` |
| 更多陷阱 | `traps-archive/code/00-all.md` |
| 禁止事项 | `core/NEVER.md` |
