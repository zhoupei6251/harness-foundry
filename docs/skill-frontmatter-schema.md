---
name: skill-frontmatter-schema
description: "Skill SKILL.md 文件的 frontmatter 字段规范。"
tags: [Standard, Skill]
---

# Skill Frontmatter Schema

> 所有 Skill 的 `SKILL.md` 必须以符合本规范的 YAML frontmatter 开头。

## 必填字段（6 项）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `name` | string | 正则 `^[a-z0-9][a-z0-9-]*[a-z0-9]$` | slug，全局唯一，必须与目录名一致 |
| `description` | string | 1-200 字符 | 一句话描述「做什么 + 何时用」 |
| `version` | semver | `^[0-9]+\.[0-9]+\.[0-9]+$` | 语义化版本，初始 `1.0.0` |
| `when_to_use` | string | 1-300 字符 | 触发词或使用场景 |
| `status` | enum | 见下表 | 当前状态 |
| `tags` | string[] | ≥1 个 | 分类标签 |

### status 取值

| 值 | 含义 | 同步到 IDE |
|----|------|----------|
| `stable` | 核心层 Skill，可被路由 | ✅ |
| `peripheral` | 外围层，可被加载但不主动路由 | ✅ |
| `archived` | 归档层，仅保留供查阅 | ❌ |
| `experimental` | 实验层，可能随时调整 | ✅（标记 warning） |

## 选填字段（4 项）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `domain` | enum | code \| novel \| news \| shared \| biz \| crypto \| science | 所属域 |
| `category` | enum | language \| workflow \| tool \| review \| pattern \| framework | 能力分类 |
| `routing_role` | string | 匹配 `agents/<role>.md` 文件名 | 路由到哪个 Agent 角色 |
| `references` | string[] | 相对路径 | 关联文档/Skill 路径 |

## 完整示例

```yaml
---
name: code-review
description: "系统性代码审查方法论，覆盖安全、性能、可维护性、正确性、测试五个维度。"
version: 1.0.0
when_to_use: "用户说『审查』/『code review』/『看看这个 PR』时调用"
status: stable
tags: [review, quality, code]
domain: code
category: review
routing_role: code-reviewer
references:
  - ../rules/code/common/patterns.md
---
```