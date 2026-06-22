---
name: tags-index
description: "Harness 文件标签体系：Rules/Runbook/Memory/Standard/Never 分类说明与索引。"
tags: [Reference]
---

# 标签体系索引

所有 harness-kit 文件按以下标签分类。

## 标签说明

| 标签 | 含义 | 何时加载 |
|------|------|----------|
| `Rules` | 声明式行为准则 | **始终可用**，不需要触发 |
| `Never` | 绝对禁止清单 | **始终可用**，不需要触发 |
| `Runbook` | 按需加载的过程式手册 | 触发了才 Load |
| `Standard` | 标准/协议/能力定义 | 参考用，不需要背诵 |
| `Memory` | 经验积累/代码范例 | 按需查询 |

## 标签索引

### Rules（行为准则）

| 文件 | 说明 |
|------|------|
| `core/NEVER.md` | 🚫 绝对禁止清单（Never） |
| `core/karpathy-guidelines.md` | 编码准则 R1-R8 + 扩展规则 |
| `adapters/agents/AGENTS.md` | 统一入口（Rules + Runbooks + Memory 汇总） |

### Runbook（操作手册）

| 文件 | 触发词 |
|------|--------|
| `core/intent-routing.md` | 所有任务的入口 |
| `core/orchestration/dispatcher-workflow.md` | 并行派兵实现 |
| `core/orchestration/agents/*.md` | 派兵时按角色加载 |

### Memory（经验积累）

| 文件 | 内容 |
|------|------|
| `references/traps.md` | 25 条精简 + 160 条完整（见 `traps-archive/00-all.md`） |
| `references/README.md` | 代码范例索引 |

### Standard（标准定义）

| 文件 | 内容 |
|------|------|
| `core/capabilities/primitives.md` | 原语语义 |
| `core/capabilities/registry.md` | 能力注册表 |
| `core/orchestration/skill-preferences.md` | Skill 路由 |
| `core/orchestration/roles.md` | 角色定义 |
| `core/multi-leader-protocol.md` | 多平台协作 |

## 加载策略

| 场景 | 必读 | 可选 |
|------|------|------|
| 每个新会话 | `core/intent-routing.md`（入口） | — |
| 写代码前 | `core/karpathy-guidelines.md` | `references/traps.md` |
| 写代码时查范例 | — | `references/README.md` |
| 派兵实现 | `core/orchestration/dispatcher-workflow.md` | 按角色读 `agents/*.md` |
| 写 spec/plan | brainstorming / writing-plans skill | — |
| 尾盘测试 | verification-before-completion skill | — |
| Code Review | requesting-code-review skill | — |
