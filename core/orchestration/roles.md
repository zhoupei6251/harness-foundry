---
name: roles
description: "Harness 编排角色索引：coder/implementer/reviewer/test-engineer 等角色的语义定义。"
tags: [Standard]
---

# Harness 编排角色索引

逻辑角色定义在 `agents/`；物理绑定见各平台 `adapters/*/bindings.md`。

| 能力 ID | agent_role | 正文 | 典型 wu_type |
| --- | --- | --- | --- |
| `roles.coder` | coder | `agents/coder.md` | feature, bugfix, refactor, ui, review-fix |
| `roles.implementer` | implementer | `agents/implementer.md` | docs, chore, config |
| `roles.reviewer` | reviewer | `agents/reviewer.md` | review |
| `roles.test-engineer` | test-engineer | `agents/test-engineer.md` | test, e2e |
| `roles.explorer` | explorer | —（只读探查，无独立正文） | explore |
| `roles.debugger` | debugger | `agents/debugger.md` | bugfix, investigate, ui-bug |
| `roles.web-investigator` | web-investigator | `agents/web-investigator.md` | research |
| `orchestration.leader` | leader | `agents/leader.md` | — |

**SpawnWorker 映射：** Leader 按上表 `agent_role` 派发；`wu_type` 决定 skill 路由（`skill-preferences.md` § 默认路由表）。

## 按需增强角色（Cherry-pick，2026-06-22）

从 [ECC](file:///d:/work/xinyue/aigc_platfrom_back/ECC) 精选的专项 agent，**不进入主流程**，仅在 review 阶段由 Leader 显式调用。命名加 `ecc-` 前缀防冲突。

| 角色 | 来源 | 版本 | 触发时机 | agent_role |
| --- | --- | --- | --- | --- |
| `ecc-java-reviewer` | ECC | 2.0.0 | review 阶段对 Java/Spring Boot 代码 | `ecc-java-reviewer` |
| `ecc-security-reviewer` | ECC | 2.0.0 | 写完 user input / auth / API endpoint / sensitive data 代码后 | `ecc-security-reviewer` |
| `ecc-database-reviewer` | ECC | 2.0.0 | 写 SQL / migration / schema / 排查 DB 性能时 | `ecc-database-reviewer` |

**调用方式：** `Task(subagent_type="general-purpose", prompt="按 ecc-java-reviewer 角色审查 [file] ...")`

**与 harness-kit 7 角色关系：** 互补关系。harness-reviewer 做通用 review；ecc-* 做专项深扫。建议串联：先 harness-reviewer → 再 ecc-*（按需）。

详见：[`harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](file:///d:/work/xinyue/aigc_platfrom_back/harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md)
