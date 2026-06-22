---
artifact: spec
title: "三层 Harness 集成：harness-kit（主） + Superpowers 补缺（辅） + ECC 专项 agent（按需）"
date: 2026-06-22
status: approved
platform: harness-kit
route: superpowers:brainstorming
approved: true
related:
  - harness-kit/core/intent-routing.md
  - harness-kit/adapters/trae/skill-binding.md
  - harness-kit/adapters/cursor/skill-binding.md
  - .trae/rules/harness-entry.md
  - superpowers/skills/
  - ECC/agents/
---

# 三层 Harness 集成设计

## 1. 背景与问题

心悦 AIGC 项目（`aigc_platfrom_back`）当前使用 harness-kit 作为 AI 编码工作流框架。用户在工作目录里同时存在两个外部开源项目：

- `d:\work\xinyue\aigc_platfrom_back\superpowers`（obra/superpowers，v6.0.3）
- `d:\work\xinyue\aigc_platfrom_back\ECC`（Everything Claude Code，v2.0.0）

**诉求：** 是否能把 Superpowers + ECC 的能力叠加到 harness-kit 上，得到"最强的 AI 编码工作流"。

**调研发现：**

| 事实 | 影响 |
|------|------|
| harness-kit 已从 Superpowers 同步了 80% 核心 skill（test-driven-development / systematic-debugging / brainstorming / requesting-code-review / verification-before-completion 等） | 直接装 Superpowers 整个插件会**重复加载同名 skill** |
| harness-kit 已定义 7 个专属 agent + 完整意图路由 | ECC 的命令式工作流（`/plan` `/tdd` `/code-review`）会**抢意图路由** |
| Superpowers 缺少 4 个 skill：`subagent-driven-development` / `dispatching-parallel-agents` / `using-git-worktrees` / `executing-plans` | 这些是 SDD（Subagent-Driven Development）核心流程，harness-kit 当前未集成 |
| ECC 含 67 个 agent，其中 java-reviewer / security-reviewer / database-reviewer 与心悦 AIGC 项目强相关 | 这些是**专项能力**，按需调用不会冲突 |

**结论：** 不能"装整个插件"，必须**Cherry-pick（精选）**。具体策略是三层叠加：

## 2. 决策摘要（已确认）

| 项 | 选择 |
|----|------|
| 集成方式 | **C — Cherry-pick**：从上游精选需要的 skill/agent，不装整个插件 |
| L1 主 | harness-kit 保持原状，已包含 Superpowers 80% 核心 |
| L2 辅 | 从 Superpowers 复制 4 个缺失 skill 到 `.trae/skills/` |
| L3 按需 | 从 ECC 复制 3 个专项 agent 到 `.trae/agents/` |
| Meta-skill | **不引入** `using-superpowers`（会重写 Agent 基础行为，破坏意图路由） |
| 防冲突 | `_meta.json` 标注来源 + `sync-skills.sh` 跳过规则 |

## 3. 目标与非目标

### 3.1 目标

1. **零冲突**：所有新增 skill/agent 不与 harness-kit 现有命名/路径冲突。
2. **可回滚**：每个 cherry-pick 操作可独立撤销（不修改任何已有文件）。
3. **可升级**：上游 Superpowers / ECC 升级后，能识别本地副本并提示升级。
4. **可控性**：新引入的 skill/agent 必须经过 `sync-skills.sh` 投影机制，避免 IDE 直接扫描到非预期路径。
5. **不破坏意图路由**：harness-kit 的 `intent-routing.md` 优先级保持最高。

### 3.2 非目标

- 装 Superpowers / ECC 整个插件
- 修改 harness-kit 现有 skill 内容
- 替换 harness-kit 的 7 个核心 agent
- 引入 `using-superpowers` meta-skill
- 支持 Codex / Copilot CLI 等其他平台

## 4. 架构

### 4.1 三层叠加模型

```
┌─────────────────────────────────────────────────────────────┐
│ L1 主层（harness-kit，不动）                                 │
│ ─────────────────────────────────────────────────────────  │
│  • 7 角色 agent（coder/reviewer/test-engineer/...）         │
│  • 意图路由（design/plan/implement/verify/review）          │
│  • 阶段门禁 + Token 节流                                    │
│  • 80% Superpowers 核心 skill（已同步）                     │
│  • 后端规范 ruoyi-aigc-backend-developer                   │
└─────────────────────────────────────────────────────────────┘
                          ↓ 补充
┌─────────────────────────────────────────────────────────────┐
│ L2 辅层（Superpowers 缺失补缺）                             │
│ ─────────────────────────────────────────────────────────  │
│  • subagent-driven-development（SDD 核心）                 │
│  • dispatching-parallel-agents（并行派兵）                  │
│  • using-git-worktrees（Worktree 工作流）                  │
│  • executing-plans（执行 plan）                            │
└─────────────────────────────────────────────────────────────┘
                          ↓ 按需
┌─────────────────────────────────────────────────────────────┐
│ L3 按需层（ECC 专项 agent）                                 │
│ ─────────────────────────────────────────────────────────  │
│  • ecc-java-reviewer（Java/Spring Boot 评审）               │
│  • ecc-security-reviewer（安全漏洞扫描）                    │
│  • ecc-database-reviewer（数据库/SQL 评审）                │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 命名空间

| 来源 | 目录 | 命名规则 |
|------|------|---------|
| harness-kit 原生 | `.trae/skills/<slug>/` | 直接使用 slug |
| Superpowers 补缺 | `.trae/skills/<slug>/` | slug 与上游同名（已比对无冲突） |
| ECC 专项 agent | `.trae/agents/ecc-<slug>.md` | 加 `ecc-` 前缀防冲突 |

### 4.3 来源追踪

每个第三方 skill/agent 必须包含 `_meta.json` 或 `.meta.json`：

```json
{
  "source": "superpowers",
  "source_version": "6.0.3",
  "source_path": "skills/subagent-driven-development",
  "imported_at": "2026-06-22",
  "cherry_picked": true,
  "integration_layer": "L2-auxiliary"
}
```

### 4.4 真相源 + 投影架构

```
harness-kit/third-party/        ← 真相源（git tracked）
├── superpowers/skills/<slug>/
└── ecc/agents/ecc-<name>.md

        ↓ sync-third-party.sh

.trae/                            ← IDE 读取路径（git ignored 或按需）
├── skills/<slug>/SKILL.md
└── agents/ecc-<name>.md
```

**原则：**
- `harness-kit/third-party/` 是 source of truth
- `.trae/` 是 IDE 运行时副本，由 `sync-third-party.sh` 投影生成
- 原 `ECC/` 和 `superpowers/` 目录已**删除**（不属于项目级别）
- 升级流程：临时 `git clone --depth 1` 上游 → diff → 写入 `third-party/` → 跑 `sync-third-party.sh`

## 5. 防冲突与防回归机制

### 5.1 sync-skills.sh 跳过规则

修改 `harness-kit/scripts/sync-skills.sh`，新增：

```bash
# 跳过第三方来源 skill（保留本地副本不被覆盖）
SKIP_FROM_SYNC=("subagent-driven-development" "dispatching-parallel-agents" "using-git-worktrees" "executing-plans")
```

### 5.2 agent 注册

修改 `harness-kit/core/orchestration/agents/registry.md`，新增：

```yaml
- role: ecc-java-reviewer
  source: ECC@2.0.0
  on_demand: true
  trigger: review 阶段显式调用
```

## 6. 风险评估

| 风险 | 等级 | 缓解措施 |
|------|------|---------|
| skill 命名冲突 | 低 | 已逐个比对，4 个 slug 在 harness-kit 中不存在 |
| agent 命名冲突 | 低 | 加 `ecc-` 前缀 |
| 升级被覆盖 | 中 | `_meta.json` 来源追踪 + sync-skills.sh 跳过规则 |
| Meta-skill 失控 | 已规避 | 不引入 `using-superpowers` |
| 路径权限 | 低 | 只读不写 Superpowers / ECC 原目录 |

## 7. 验收标准

- [ ] `.trae/skills/subagent-driven-development/SKILL.md` 存在且 frontmatter 正确
- [ ] `.trae/skills/dispatching-parallel-agents/SKILL.md` 存在
- [ ] `.trae/skills/using-git-worktrees/SKILL.md` 存在
- [ ] `.trae/skills/executing-plans/SKILL.md` 存在
- [ ] 4 个 `_meta.json` 标记 `source: superpowers`
- [ ] `.trae/agents/ecc-java-reviewer.md` 存在
- [ ] `.trae/agents/ecc-security-reviewer.md` 存在
- [ ] `.trae/agents/ecc-database-reviewer.md` 存在
- [ ] `harness-kit/adapters/trae/skill-binding.md` 新增"第三方来源"章节
- [ ] `harness-kit/core/orchestration/agents/registry.md` 新增 ECC agent 注册
- [ ] `harness-kit/scripts/sync-skills.sh` 新增 SKIP_FROM_SYNC 列表
- [ ] 不修改任何 harness-kit 已有文件
- [ ] 不修改 Superpowers / ECC 原目录