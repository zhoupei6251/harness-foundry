---
name: tags-index
description: "Harness 文件标签体系：Rules/Runbook/Memory/Standard/Never 分类说明与索引。"
tags: [Reference]
---

# 标签体系索引

所有 harness-foundry 文件按以下标签分类。

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
| `rules/` | 按技术栈分类的规则库（code/novel/news/common） |
| `adapters/agents/AGENTS.md` | 统一入口（Rules + Runbooks + Memory 汇总） |

### Runbook（操作手册）

| 文件 | 触发词 |
|------|--------|
| `core/intent-routing.md` | 所有任务的入口 |
| `core/orchestration/dispatcher-workflow.md` | 并行派兵实现 |
| `agents/*.md` | 派兵时按角色加载 |

### Memory（经验积累）

| 文件 | 内容 |
|------|------|
| `references/traps.md` | 按域分类致命版（每域 25 条） |
| `traps-archive/code/00-all.md` | 代码域完整版（160 条） |
| `traps-archive/novel/00-all.md` | 小说域完整版（47 条） |
| `traps-archive/news/00-all.md` | 新闻域完整版（34 条） |
| `references/README.md` | 代码范例索引 |
| `references/learned-patterns.md` | 持续学习：自动提取的模式 |
| `references/learned-traps.md` | 持续学习：自动提取的陷阱 |
| `references/lessons-learned.md` | 持续学习：经验总结 |

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
| 每个新会话 | `core/intent-routing.md`（入口） | `RULES.md`（一页纸摘要） |
| 写代码前 | `contexts/code.md` + `rules/code/<tech>/` + `rules/common/` | `references/traps.md` |
| 写小说前 | `contexts/novel.md` + `rules/novel/` | `references/traps.md` |
| 写新闻前 | `contexts/news.md` + `rules/news/` | `references/traps.md` |
| 审稿/审查前 | `contexts/review.md` | 对应域的 `traps-archive/` |
| 写代码时查范例 | — | `references/README.md` |
| 派兵实现 | `core/orchestration/dispatcher-workflow.md` | 按角色读 `agents/*.md` |
| 写 spec/plan | brainstorming / writing-plans skill | — |
| 尾盘测试 | verification-before-completion skill | — |
| Code Review | requesting-code-review skill | — |
| 会话结束 | `hooks/continuous-learning.md` | — |
| 自我进化 | `commands/evolve.md` | — |
| 配置验证 | `tests/README.md` | — |

## 场景上下文（contexts/）

参考 ECC 分层策略，按场景提供核心规则 + 致命陷阱引用。

| 文件 | 场景 | 内容 |
|------|------|------|
| `contexts/code.md` | 代码开发 | 行为准则 + 25 条致命陷阱 + 阶段门禁 |
| `contexts/novel.md` | 小说创作 | 行为准则 + 25 条致命陷阱 + 阶段门禁 |
| `contexts/news.md` | 新闻采编 | 行为准则 + 25 条致命陷阱 + 阶段门禁 |
| `contexts/review.md` | 审稿/审查 | 审查清单 + 输出格式 + 推荐工具 |

## 自动化机制（hooks/）

| 文件 | 用途 |
|------|------|
| `hooks/hooks.json` | 钩子配置文件 |
| `hooks/continuous-learning.md` | 持续学习机制 |
| `hooks/` | 项目钩子配置（prompt 类型） |

## 命令快捷入口（commands/）

| 文件 | 用途 |
|------|------|
| `commands/code.md` | 代码域命令 |
| `commands/novel.md` | 小说域命令 |
| `commands/news.md` | 新闻域命令 |
| `commands/evolve.md` | 自我进化命令 |

## 配置验证（tests/）

| 文件 | 用途 |
|------|------|
| `tests/validate-config.sh` | 验证配置完整性 |
| `tests/validate-references.sh` | 验证文件引用完整性 |
| `tests/run-all-tests.sh` | 运行所有测试 |
| `tests/README.md` | 测试套件说明 |

## 示例配置（examples/）

| 文件 | 用途 |
|------|------|
| `examples/CLAUDE.md` | Claude Code 项目配置模板 |
| `examples/cursor-rules.md` | Cursor 项目规则模板 |
| `examples/trae-rules.md` | Trae 项目规则模板 |
| `examples/code-project/` | 代码项目示例 |
| `examples/novel-project/` | 小说项目示例 |
| `examples/news-project/` | 新闻项目示例 |
