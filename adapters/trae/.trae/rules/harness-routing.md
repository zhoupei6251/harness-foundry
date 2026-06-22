# Trae Harness 路由

与 `harness-kit/core/routing.md` 保持一致。差异仅在物理绑定。

## 路由表

| 路由 | Trae Skill/机制 | 产物 |
| --- | --- | --- |
| `design` | `brainstorming` | `specs/` |
| `plan` | `writing-plans` | `plans/` |
| `implement` | `harness-orchestration` + Task | `execution-logs/` |
| `verify` | `verification-before-completion` | `verifications/` |
| `review` | `requesting-code-review` / `code-review` | `reviews/` |
| `research` | `web-tools-guide` + Task | `research/` |
| `小改动，直接处理` | Leader 直做 | `verifications/` |

## 子 Agent（7 角色，与 Cursor 对齐）

| 角色 | Trae 实现 | agent_role |
| --- | --- | --- |
| harness-coder | `Task(general_purpose_task)` | coder |
| harness-implementer | `Task(general_purpose_task)` | implementer |
| harness-test-engineer | `Task(general_purpose_task)` + TDD skill | test-engineer |
| harness-reviewer | `code-review` / `TRAE-code-review` | reviewer |
| harness-debugger | `systematic-debugging` | debugger |
| harness-explorer | `Task(search)` | explorer |
| harness-web-investigator | `Task(search)` + `agent-browser` | web-investigator |

## WU Skill 自动路由

见 `harness-kit/core/orchestration/skill-preferences.md` § 默认路由表。

## 阶段门禁

与 `routing.md` § 阶段门禁 相同。写入 spec/plan 后**暂停**。

## 产物 FM

```yaml
status: draft
approved: false
```

## 沟通语言

中文。
