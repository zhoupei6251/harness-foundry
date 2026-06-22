# Trae IDE Adapter

本目录定义 Trae IDE 下的 Harness 适配配置。

## 文件索引

| 文件 | 用途 |
| --- | --- |
| `trae-quick-ref.md` | **开发者快速参考**（一键速查） |
| `skill-binding.md` | Skill 加载路径与自动路由规则 |
| `README.md` | 本文件，概览说明 |
| `.trae/agents/` | Subagent 角色定义 → 投影到项目 `.trae/agents/` |
| `.trae/rules/` | 规则文件 → 投影到项目 `.trae/rules/` |

## 与 Cursor 的差异

| 维度 | Cursor | Trae |
| --- | --- | --- |
| 子 Agent 机制 | `.cursor/agents/` 文件 + Task 工具 | Skill 工具调用 |
| 规则加载 | `.cursor/rules/*.mdc` | `.trae/rules/*.md` |
| 编排框架 | `cursor-orchestration` skill | `harness-orchestration` skill |
| 技能安装 | `.cursor/skills/` | `.trae/skills/` |
| Hooks | `.cursor/hooks/` | Trae 内置钩子 |

## 投影规则

从 `harness-kit/adapters/trae/` 投影到项目根目录：

- `harness-kit/adapters/trae/.trae/agents/` → `.trae/agents/`
- `harness-kit/adapters/trae/.trae/rules/` → `.trae/rules/`

`harness-kit/adapters/trae/orchestration/` **不投影**，保留在 harness-kit 内供 AI 读取。

## Subagent 角色

| 角色 | 对应 Skill | 用途 |
| --- | --- | --- |
| harness-coder | `Task(subagent_type="general_purpose_task")` | 代码类 WU 实现 |
| harness-reviewer | `Skill(name="code-review")` / `Skill(name="TRAE-code-review")` | 代码审查 |
| harness-tester | `Skill(name="test-driven-development")` | 测试用例编写 |
| harness-debugger | `Skill(name="systematic-debugging")` | 缺陷调查 |
| harness-explorer | `Task(subagent_type="search")` | 只读代码探索 |

## 路由映射

见 `.trae/rules/harness-routing.md` 或快速参考 `trae-quick-ref.md`。
