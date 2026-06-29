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
| `orchestration.leader` | leader | `agents/leader-code.md` | — |

**SpawnWorker 映射：** Leader 按上表 `agent_role` 派发；`wu_type` 决定 skill 路由（`skill-preferences.md` § 默认路由表）。

## 按需增强角色（Cherry-pick，2026-06-22）

从 [ECC](https://github.com/affaan-m/ECC) 精选的专项 agent，**不进入主流程**，仅在 review 阶段由 Leader 显式调用。命名加 `ecc-` 前缀防冲突。

| 角色 | 来源 | 版本 | 触发时机 | agent_role |
| --- | --- | --- | --- | --- |
| `ecc-java-reviewer` | ECC | 2.0.0 | review 阶段对 Java/Spring Boot 代码 | `ecc-java-reviewer` |
| `ecc-security-reviewer` | ECC | 2.0.0 | 写完 user input / auth / API endpoint / sensitive data 代码后 | `ecc-security-reviewer` |
| `ecc-database-reviewer` | ECC | 2.0.0 | 写 SQL / migration / schema / 排查 DB 性能时 | `ecc-database-reviewer` |

**调用方式：** `Task(subagent_type="general-purpose", prompt="按 ecc-java-reviewer 角色审查 [file] ...")`

**与 harness-foundry 7 角色关系：** 互补关系。harness-reviewer 做通用 review；ecc-* 做专项深扫。建议串联：先 harness-reviewer → 再 ecc-*（按需）。

详见：[`docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md)

---

## Meta 层角色（P1-4 新增，2026-06-26）

参考 gstack 的 20+ 组织角色体系，引入 3 个 meta 层角色。这些角色不创建新 agent 文件，通过 prompt 指令叠加给 Leader。小 GROUP（≤2 个 WU）不触发。

| 能力 ID | meta_role | 正文 | 触发条件 |
| --- | --- | --- | --- |
| `meta.architect` | architect | `core/orchestration/meta-roles/architect.md` | GROUP size ≥ 3 OR 跨模块变更 |
| `meta.qa-lead` | qa-lead | `core/orchestration/meta-roles/qa-lead.md` | Review phase start |
| `meta.release` | release-manager | `core/orchestration/meta-roles/release-manager.md` | Batch closeout |

**调用方式**：Leader 在对应阶段加载 meta-role 定义文件，叠加其检查项到自身 prompt。meta 角色之间**有层级关系**：

```
architect（跨 WU 架构一致性）
   ↓
qa-lead（审查质量监督）
   ↓
release-manager（最终质量门禁）
```

**与 domain Leader 的关系**：domain Leader 负责编排水单 domain WU；meta 角色提供跨 domain 和跨 WU 的垂直检查。两者不冲突，meta 角色在 GROUP 整合阶段顺序叠加。
