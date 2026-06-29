---
name: skill-preferences
description: "Skill 使用偏好说明：子 Agent wu_skills: auto 如何解析，按角色/任务类型路由。"
tags: [Standard]
---

# Skill 使用偏好说明（WU 级，按需加载）

> **范围：** 本文档仅 **子 Agent / WU**（`wu_skills: auto`）。**Leader 阶段 skill**（`brainstorming`、`writing-plans`、`verification-before-completion`、`「git-xywh」`）见 `harness-foundry/core/intent-routing.md` § 阶段指定 skill 必用 — **必 Load**，不适用下文「按需」。

本文档是 Harness **子 Agent 应加载哪些 skill** 的**唯一维护入口**（文档维护，**不是** skill 文件）。

- 项目内置**能力副本**在 `.cursor/skills/`（TDD、verification 等），由 Cursor 发现；升级用 `bash harness-foundry/scripts/sync-cursor-skills.sh`。
- **编排步骤**见 `core/orchestration/dispatcher-workflow.md`。

---

## `wu_skills: auto` 怎么解析

Leader 或子 Agent 看到 **`auto`** 时：

1. 从 prompt 读取 **`agent_role`**、**`wu_type`**（及可选 `overrides` / `exclude`）
2. 查下文 **§ 默认路由表**：同一 `agent_role` 下优先匹配**最具体**的 `wu_type` 行（如 `ui-bug` 优于 `*`）；无精确匹配时用含 `*` 的行
3. 得到 skill slug 列表（顺序即加载顺序）
4. 应用 `overrides` 追加、`exclude` 删除
5. 剔除 **§ 全局禁止**
6. 对列表中每一项 **按需** invoke / Read skill（路径见 § 加载顺序，不存在则 `skipped`，不硬套）

**Leader 派发：** 将解析出的 **slug + 路径** 抄入 prompt（**禁**只写 `auto`）。子 Agent 须返回 `### Skills 使用`。

---

## 默认路由表

| agent_role | wu_type | 建议加载的 skill（按序） |
| --- | --- | --- |
| coder | feature, bugfix, refactor | test-driven-development, requesting-code-review |
| coder | ui | ui-ux-pro-max, frontend-design, test-driven-development, requesting-code-review |
| coder | review-fix | receiving-code-review, test-driven-development, requesting-code-review |
| implementer | docs, config, chore | **无** |
| explorer | explore, * | **无** |
| explorer | investigate | systematic-debugging |
| debugger | bugfix, * | systematic-debugging |
| debugger | ui-bug | systematic-debugging |
| web-investigator | research, * | agent-browser |
| reviewer | review, * | requesting-code-review |
| test-engineer | test | test-driven-development |
| test-engineer | e2e | agent-browser |

---

## 全局禁止（不得传给子 Agent）

`brainstorming`, `writing-plans`, `cursor-orchestration`, 「claude-orchestration」, `using-superpowers`, 「git-xywh」, `dispatching-parallel-agents`, `subagent-driven-development`

---

## 内置能力副本

| slug | 用途 | Cursor 路径 | Trae 路径 | Claude Code 路径 |
| --- | --- | --- | --- | --- |
| test-driven-development | 先测后实现 | `.cursor/skills/` | `.trae/skills/` | `harness-foundry/skills/` |
| systematic-debugging | 根因调查 | `.cursor/skills/` | `.trae/skills/` | `harness-foundry/skills/` |
| requesting-code-review | 独立审查 | `.cursor/skills/` | `.trae/skills/` | `harness-foundry/skills/` |
| receiving-code-review | 按审查意见改代码 | `.cursor/skills/` | `.trae/skills/` | `harness-foundry/skills/` |
| ui-ux-pro-max | UI/UX 设计系统 | `~/.trae/skills/` | `~/.trae/skills/` | `harness-foundry/skills/` |
| frontend-design | UI 实现审美 | 全局复制 | `~/.trae/skills/` | `harness-foundry/skills/` |

副本来源登记：`adapters/cursor/.cursor/skills/_vendor-sources.yaml`。

### 仅 Leader / 不在子 Agent 列表

| slug | 位置 |
| --- | --- |
| cursor-orchestration | `.agents/skills/` |
| brainstorming, writing-plans, git-xywh | 用户全局 |

---

## 按 Harness 角色（速查）

| 角色 | Subagent | 典型 wu_type | auto 默认 |
| --- | --- | --- | --- |
| Coder | harness-coder | feature / bugfix / refactor | TDD + requesting-code-review |
| Coder | harness-coder | ui | ui-ux-pro-max + frontend-design + TDD + requesting-code-review |
| Coder | harness-coder | review-fix | receiving-code-review + TDD + requesting-code-review |
| 轻量执行 | harness-implementer | docs / chore / config | 无 |
| 探查者 | harness-explorer | explore | 无 |
| 调试者 | harness-debugger | bugfix | systematic-debugging |
| 审查者 | harness-reviewer | review | requesting-code-review |
| 测试工程师 | harness-test-engineer | test | TDD |
| 测试工程师 | harness-test-engineer | e2e | agent-browser |
| 网探 | harness-web-investigator | research | agent-browser |

---

## 测试工程师 E2E

`wu_type: e2e` 且 `auto` 时：**必须先 Read** skill 文件（路径见 § 加载顺序，再按 skill 执行）。

执行优先级：Playwright → `agent-browser`（`infsh`）→ 项目 CLI。返回 `e2e_via: playwright | agent-browser | cli | n/a`。

---

## 按任务类型（用户话术）

| 任务 | Subagent | auto 查表 |
| --- | --- | --- |
| 并行写业务代码 | harness-coder | coder + wu_type |
| 审查 BLOCK 后按意见改代码 | harness-coder | coder + **review-fix** |
| 文档 / 配置 / chore | harness-implementer | implementer + docs/chore/config |
| 只读摸底 | harness-explorer | explorer |
| 调查 bug | harness-debugger | debugger |
| 实现后审查 | harness-reviewer | reviewer |
| 补测试 / 集成测试 | harness-test-engineer | test-engineer + test |
| E2E 验收 | harness-test-engineer | test-engineer + e2e |
| 信息调研 / 网页搜索 | harness-web-investigator | web-investigator + research |
| 只跑一条命令 | Task shell | 无 |
| 提交 / MR | Leader | git-xywh（禁止子 Agent） |

---

## 派发字段

| 字段 | 含义 |
| --- | --- |
| wu_type | feature \| bugfix \| ui \| chore \| refactor \| **review-fix** \| docs \| config \| test \| e2e \| explore \| review \| investigate \| ui-bug \| **research** |
| wu_skills | 逗号分隔 slug，或 **`auto`**（查本文档 § 默认路由表） |
| agent_role | coder \| implementer \| explorer \| debugger \| reviewer \| test-engineer \| **web-investigator** |

---

## 加载顺序（路径）

### Cursor / 通用
1. `.cursor/skills/<slug>/SKILL.md`
2. `~/.cursor/skills/<slug>/SKILL.md`
3. `~/.agents/skills/<slug>/SKILL.md`

### Claude Code
1. `.claude/skills/<slug>/SKILL.md`（项目级）
2. `~/.claude/skills/<slug>/SKILL.md`（用户全局）

### Trae IDE
1. `.trae/skills/<slug>/SKILL.md`（项目级）
2. `~/.trae/skills/<slug>/SKILL.md`（用户全局）

> Trae 的 Skill 工具调用会自动发现 `.trae/skills/` 目录下的 skill，无需手动指定路径。

### MiMo Code
1. `harness-foundry/adapters/mimocode/.agents/skills/<slug>/SKILL.md`（项目级）
2. `.cursor/skills/<slug>/SKILL.md`（共享 Cursor 副本）
3. `~/.agents/skills/<slug>/SKILL.md`（用户全局）

---

## 维护

- 改路由：**只改本文档** § 默认路由表；plan 执行图见 `artifact-templates/dispatch.harness-overlay.md`。
- 升级能力副本：`bash harness-foundry/scripts/sync-cursor-skills.sh`。
- 项目专有 skill：放在 `.cursor/skills/<name>/`，在 plan 的 `wu_skills` 手写或 `overrides` 追加。
