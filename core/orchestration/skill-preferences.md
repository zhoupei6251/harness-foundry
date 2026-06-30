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

## 默认路由表（已集成 Intelligence Layer）

| agent_role | wu_type | 建议加载的 skill（按序） | Intelligence |
| --- | --- | --- | --- |
| **leader-code** | plan | understand-project, analyze-architecture | ✅ 战略层 |
| **leader-code** | implement | understand-chat | ✅ 战略层 |
| coder | feature, bugfix, refactor | test-driven-development, requesting-code-review | ✅ 战术层 |
| coder | feature, bugfix, refactor | query-symbol | ✅ 战术层 |
| coder | ui | ui-ux-pro-max, frontend-design, test-driven-development, requesting-code-review | ✅ 战术层 |
| coder | review-fix | receiving-code-review, test-driven-development, requesting-code-review | ✅ 战术层 |
| implementer | docs, config, chore | **无** | ❌ |
| **explorer** | explore, * | understand-chat | ✅ 战略层 |
| explorer | investigate | systematic-debugging | ✅ 战术层 |
| **debugger** | bugfix, * | systematic-debugging, query-symbol | ✅ 战术层 |
| debugger | ui-bug | systematic-debugging, query-symbol | ✅ 战术层 |
| web-investigator | research, * | agent-browser | ❌ |
| **reviewer** | review, * | requesting-code-review, analyze-impact | ✅ 战术层 |
| **code-reviewer** | review, * | requesting-code-review, analyze-impact | ✅ 战术层 |
| test-engineer | test | test-driven-development, analyze-impact | ✅ 战术层 |
| test-engineer | e2e | agent-browser | ❌ |

### Intelligence Layer Skills 自动注入说明

> Intelligence Skills（以 ✅ 标记）**自动注入**，无需手动声明
> - 战略层：understand-project, understand-chat, analyze-architecture
> - 战术层：query-symbol, get-callers, analyze-impact

---

## Intelligence Layer Skills（代码理解层）

> 阶段门禁：plan → implement → verify，Intelligence Skills 在各阶段按需调用

### 战略层 (Understand-Anything)

| agent_role | wu_type | 建议加载的 skill | 调用时机 |
| --- | --- | --- | --- |
| leader-code | plan | understand-project, analyze-architecture | plan 阶段开始时 |
| coder | feature, bugfix, refactor | understand-project | 理解项目时 |
| explorer | explore | understand-project, analyze-architecture | 探查项目时 |

### 战术层 (CodeGraph)

| agent_role | wu_type | 建议加载的 skill | 调用时机 |
| --- | --- | --- | --- |
| coder | feature, bugfix, refactor | index-project, query-symbol | 实现前 |
| coder | feature | get-callers, analyze-impact | 重构前 |
| debugger | bugfix | query-symbol, get-callers | 定位 bug 时 |
| reviewer | review | analyze-impact | review 前 |
| code-reviewer | review | analyze-impact | review 前 |
| test-engineer | test | analyze-impact | 评估测试范围 |

### Intelligence Skills 路由配置

```yaml
# Intelligence Layer Skill 路由
intelligence:
  # 战略层 - 项目理解
  understand-project:
    domains: [code]
    stage: [plan, design]
    agents: [leader-code, coder, explorer]
    trigger: "新项目、不了解项目、需要全局理解"
    priority: 1  # 优先于其他调研手段

  analyze-architecture:
    domains: [code]
    stage: [design, implement]
    agents: [leader-code, coder, explorer]
    trigger: "架构问题、设计原因、技术选型"
    priority: 1

  query-knowledge-graph:
    domains: [code]
    stage: [plan, design, implement, verify]
    agents: [leader-code, coder, explorer, reviewer]
    trigger: "查询项目结构、模块关系"

  # 战术层 - 代码索引
  index-project:
    domains: [code]
    stage: [plan]
    agents: [leader-code, coder]
    trigger: "大型项目 (>100 文件)、需要精准定位"
    auto_invoke: false  # 需要显式调用

  query-symbol:
    domains: [code]
    stage: [implement, verify]
    agents: [coder, debugger, reviewer]
    trigger: "定位符号、查找定义、快速搜索"
    auto_invoke: true  # 可自动调用

  get-callers:
    domains: [code]
    stage: [implement, verify]
    agents: [coder, debugger, reviewer]
    trigger: "分析依赖、评估影响"
    auto_invoke: false

  get-callees:
    domains: [code]
    stage: [implement, verify]
    agents: [coder, debugger]
    trigger: "理解实现细节"
    auto_invoke: false

  analyze-impact:
    domains: [code]
    stage: [implement, verify]
    agents: [coder, reviewer, test-engineer]
    trigger: "重构前、修改核心方法、批量修改"
    auto_invoke: false
```

### Intelligence Skills 使用建议

```
阶段: plan
  ├─ /understand-project     → 获取项目全局理解
  └─ /index-project          → 建立代码索引

阶段: implement
  ├─ /query-symbol          → 定位要修改的代码
  ├─ /get-callers            → 查看调用方
  └─ /analyze-impact         → 评估影响范围

阶段: verify
  ├─ /query-symbol          → 验证修改位置
  └─ /analyze-impact         → 确认变更范围
```

---

## 全局禁止（不得传给子 Agent）

`brainstorming`, `writing-plans`, `cursor-orchestration`, 「claude-orchestration」, 「using-superpowers」, 「git-xywh」, `dispatching-parallel-agents`, `subagent-driven-development`

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

## Novel 域路由表

> Novel 域没有 Intelligence Layer，Skill 均为显式声明。

| agent_role | wu_type | 建议加载的 skill |
| --- | --- | --- |
| **leader-novel** | plan | brainstorming, writing-plans |
| **leader-novel** | implement | novel-orchestrator |
| novel-writer | chapter-write, chapter-continue | junli-ai-novel, humanizer-zh |
| novel-writer | rewrite | junli-ai-novel, humanizer-zh |
| novel-planner | outline, volume-plan | brainstorming, junli-ai-novel |
| novel-reviewer | review | novel-evaluator |
| humanizer | polish | humanizer-zh |
| humanizer | deep-clean | novel-ai-wash |
| editor | cross-chapter-check | memory-manager, junli-ai-novel |
| memory-keeper | sync, resume | memory-manager |
| shared-researcher | research | web-tools-guide |

### Novel 域角色速查

| 角色 | Agent 文件 | 典型 wu_type | auto 默认 |
| --- | --- | --- | --- |
| 写手 | `novel-writer.md` | chapter-write / chapter-continue | junli-ai-novel + humanizer-zh |
| 规划师 | `novel-planner.md` | outline / volume-plan | brainstorming + junli-ai-novel |
| 审稿人 | `novel-reviewer.md` | review | novel-evaluator |
| 润色师 | `humanizer.md` | polish / deep-clean | humanizer-zh / novel-ai-wash |
| 统稿编辑 | `editor.md` | cross-chapter-check | memory-manager + junli-ai-novel |
| 记忆管理 | `memory-keeper.md` | sync / resume | memory-manager |
| 调研员 | `shared-researcher.md` | research | web-tools-guide |

### Novel 域 wu_type 枚举

| wu_type | 含义 | 触发场景 |
| --- | --- | --- |
| chapter-write | 写新章 | 续写下一章 |
| chapter-continue | 承接续写 | 承接上一章结尾续写 |
| rewrite | 返修重写 | 根据 reviewer 意见修改 |
| outline | 大纲规划 | 产出整体大纲 |
| volume-plan | 分卷规划 | 产出某一卷的详细规划 |
| review | 审稿评分 | 7 维评分 + 逐条原文举证 |
| polish | 轻量润色 | 单章 humanizer-zh 润色 |
| deep-clean | 深度清洗 | 批量 novel-ai-wash 深度清洗 |
| cross-chapter-check | 跨章统稿 | editor 一致性检查 |
| sync | 记忆同步 | 更新双轨记忆 |
| resume | 会话恢复 | 从上次中断处恢复 |

## 派发字段 (novel 域)

| 字段 | 含义 |
| --- | --- |
| wu_type | chapter-write \| chapter-continue \| rewrite \| outline \| volume-plan \| review \| polish \| deep-clean \| cross-chapter-check \| sync \| resume \| research |
| wu_skills | 逗号分隔 slug，或 **`auto`**（查本文档 § Novel 域路由表） |
| agent_role | novel-writer \| novel-planner \| novel-reviewer \| humanizer \| editor \| memory-keeper \| shared-researcher |

---

| 角色 | Subagent | 典型 wu_type | auto 默认 |
| --- | --- | --- | --- |
| Coder | harness-coder | feature / bugfix / refactor | TDD + requesting-code-review |
| Coder | harness-coder | ui | ui-ux-pro-max + frontend-design + TDD + requesting-code-review |
| Coder | harness-coder | review-fix | receiving-code-review + TDD + requesting-code-review |
| 轻量执行 | harness-implementer | docs / chore / config | 无 |
| 探查者 | harness-explorer | explore | 无 |
| 调试者 | harness-debugger | bugfix | systematic-debugging |
| 审查者 (通用) | harness-reviewer | review | requesting-code-review |
| 审查者 (代码专项) | harness-reviewer | review | requesting-code-review + analyze-impact |
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

> **Novel 域：** wu_type / agent_role 枚举见上文 § Novel 域路由表；Leader 按 novel 域路由表解析 `auto`。

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
