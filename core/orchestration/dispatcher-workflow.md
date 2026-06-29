---
name: dispatcher-workflow
description: "统一调度器工作流：拆任务→并行派兵→整合。支持 code / novel / news 多域。"
tags: [Orchestration, Runbook]
---

# 调度器工作流

> 所有领域共用。根据 `domain-config.yaml` 加载对应 Agent。

## 触发条件

满足以下任一条件时走 dispatcher：
- 连续写 ≥2 章（novel 域）
- 连续实现 ≥2 个功能（code 域）
- 连续产出 ≥2 篇稿件（news 域）
- 用户说"写到第N章为止" / "实现完这几个功能" / "批量处理"

---

## 输入

- 已批准的计划/大纲（code: `.ai-runtime-artifacts/plans/`；novel: `.harness-novel-runtime/plans/`；news: 对应 plans 目录）
- 或用户明确授权连续执行多任务

## 输出

- 各域产出物（代码变更 / 章节正文 / 新闻稿件）
- `.ai-runtime-artifacts/execution-logs/YYYY-MM-DD-<topic>-execution-log.md`
- 可选：`tracking/DISPATCH-TRACK-<date>-<topic>.md`

---

## 步骤 0：读记忆 + 注册平台

**派发前必须：**
1. Read 对应 runtime 的 `memory/state.json` — 了解当前活跃平台和 WU
2. 检查 `active_wus` 文件覆盖是否有冲突
3. 在 `active_platforms` 中注册自己
4. 遵循对应 `multi-leader-protocol.md` 冲突避免规则

## 步骤 0.5：环境初始化

**重要**：本步骤已由 execution-context Provider 协议统一管理。详见 `core/orchestration/execution-context/provider-protocol.md`。

| 域 | Provider | 操作 |
| --- | --- | --- |
| **code** | `worktree` | `Provision(ctx_spec)` → `Activate()` — 创建 git worktree 隔离沙箱 |
| **novel** | `local` | `Provision(ctx_spec)` — 零操作，使用当前工作目录 |
| **news** | `local` | `Provision(ctx_spec)` — 零操作，使用当前工作目录 |

**Provider 选择逻辑**：
1. 读取 `domain-config.yaml` → `execution` 节点
2. 按域选择默认 Provider（code → worktree，novel/news → local）
3. 如果首选 Provider 不可用 → 按降级策略自动切换（如 worktree → local）
4. 降级时在 tracking 中记录 `Provider degraded: <from> → <to>`

**隔离级别**：
- code 域 WU：`isolation_level: full`（worktree 隔离）
- reviewer/explorer 角色：`isolation_level: partial`（只读访问）
- novel/news 域：`isolation_level: none`（主线程直接写）

### 门禁检查
- **code 域**：有委派写代码 WU 时，未完成 worktree Provision **不得**派发
- **非 code 域**：跳过 worktree 检查，local provider 始终可用
- Provider 降级时：Leader 检查降级是否影响安全性，确认后继续

### 与旧版步骤 0.5 的兼容
旧版步骤 0.5（硬编码 worktree 逻辑）：**已废弃**。新版通过 execution-context Provider 协议统一管理，旧 worktree 配置参数（`config.defaults.yaml` 中的 `worktree.*`）仍可从 Provider 读取，但不推荐直接引用。

## 步骤 1：构建执行图

从计划提取 WU（有界 / 可验证 / 文件不相交）：

```markdown
## 执行图

GROUP-1（并行 ≤5，有依赖时串行）:
  WU-01: <描述> | 文件: <path> | 依赖: 无 | wu_type: <type> | agent_role: <role> | wu_skills: <slug|auto>
```

**关键规则：有续写/依赖关系的 WU 必须串行。独立任务可并行。**

## 步骤 2：ParallelBatch / SpawnWorker

### 派发前 Guardrail 检查（P0-2 新增）

派发 WU 前执行 Input Guardrail 检查（参见 `harness-foundry/hooks/guardrails/guardrail-config.json`）：
- 检查用户 prompt 是否包含注入尝试
- 检查 WU 目标文件是否涉及敏感路径
- 检查 WU 参数是否包含命令注入
- 任一规则触发 `block` → 拦截派发，通知用户
- `warn` 模式 → 记录 audit log 但允许继续

**门禁**：`block` 级别的 Input Guardrail 触发时，**不得派发 WU**。

### 派发 Worker

对 GROUP 内无未完成依赖的 WU，**按依赖顺序** SpawnWorker（≤ `max_parallel`，硬顶 5）。

**通用委派 prompt（中文、简练）：**

| 项 | 内容 |
| --- | --- |
| 身份 | `WU-<id>` + `agent_role` / `wu_type` + `agents/<role>.md` |
| 目标/Done | 各 1–3 句 |
| 范围 | 允许文件；禁止项一句 |
| Skills | slug → 路径（禁只写 `auto`） |
| 验证 | 命令或检查项 |
| cwd | code 域沙箱批次：`worktree_path: <abs>` |
| 返回 | `wu_status`、`### Skills 使用` |

Leader 解析 `auto` → 抄 slug+路径入 prompt；无 `### Skills 使用` **不整合**。

**禁传 worker：** `brainstorming`、`planning-with-files` / `writing-plans`、平台编排 skill、`memory-manager` / `memory-bank`（除非 wu_type 明确需要）。

## 步骤 3：整合与尾盘

单 WU 返回：验证字段 → Leader 更新 plan/tracking。**不写批次完成态。**

### GROUP-2：串行审查

| 域 | 审查者 | 审查内容 |
| --- | --- | --- |
| **code** | reviewer（新实例） | 代码审查 + 测试验证 |
| **novel** | reviewer + `novel-evaluator` | 章节质量审查 + 6维评分 |
| **news** | fact-checker | 事实核查 + 合规审查 |

审查不通过 → 返修给对应 writer/coder（最多 2 次）。
2 次返修仍不通过 → 输出最终审查报告，提示用户介入。

### 尾盘 Output Guardrail 检查（P0-2 新增）

整合阶段执行 Output Guardrail（参见 `harness-foundry/hooks/guardrails/guardrail-config.json`）：
- 检查 Worker 输出是否包含密钥/Token 泄露
- 检查 Worker 输出是否有 Canary Token（Prompt 泄露检测）
- 检查是否违反 NEVER.md 规则
- 检查 AI 写作痕迹（novel/news 域）
- 检查代码语法（code 域）
- 任一规则触发 `block` → 阻止纳入最终产物，记录 audit log
- 触发 `warn` → 允许纳入但标记 review 建议

**门禁**：`block` 级别的 Output Guardrail 触发时，该 WU 产物**不得纳入结果集**，需返修。

### GROUP-3：串行整合

| 域 | 整合者 | 整合内容 |
| --- | --- | --- |
| **code** | collective test + 审查 | 集体测试验证 + 代码审查产物 |
| **novel** | editor | 跨章一致性（人物称呼、时间线、伏笔、文风） |
| **news** | news-editor | 审校排版 + 统一风格 |

### 各域 Worker 角色索引

#### code 域
- **coder**: 实现功能 + 单测 + 轻量审查
- **implementer**: 文档/配置/杂项
- **test-engineer**: 测试/E2E 资产
- **code-reviewer**: 独立代码审查（尾盘）
- **reviewer**: 通用代码审查
- **web-investigator**: 调研取证
- **debugger**: 调试修复
- **explorer**: 只读探查

#### novel 域
- **writer**: 写章节正文（核心写手）
- **planner**: 大纲/分卷规划、结构拆解
- **reviewer**: 章节质量审查、6维评分
- **humanizer**: AI文风清洗、去套路化
- **shared-researcher**: 素材考据、世界观调研
- **editor**: 跨章一致性检查、统稿
- **memory-keeper**: 记忆同步、状态追踪

#### news 域
- **news-writer**: 写新闻稿
- **fact-checker**: 事实核查
- **news-editor**: 审校排版
- **shared-researcher**: 背景调研

## 步骤 4：追踪

1. 创建 `DISPATCH-TRACK-<date>-<topic>.md`
2. 每 WU append（参见 `tracking/schema.md`）
3. 上下文重置写 HANDOFF

## 步骤 5：环境关闭 + 记忆写回

| 域 | 操作 |
| --- | --- |
| **code** | `git worktree remove` → tracking 记 `WORKTREE-CLOSE` → `Destroy(ctx)` |
| **novel** | 跳过 worktree 关闭 → `Destroy(ctx)` (local no-op) |
| **news** | 跳过 worktree 关闭 → `Destroy(ctx)` (local no-op) |

更新对应 `memory/state.json`：
- 更新 `active_wus` 状态
- 更新 `active_phase`（如全部完成则设为 `idle`）
- 更新 `last_updated` 时间戳
- code 域额外：从 `active_platforms` 注销本平台
- novel 域额外：更新单书 `MEMORY.md`（chapter_index、人物状态、伏笔状态）
- **新增**：记录 execution-context 生命周期指标（provision/active/destroy 时长）到 tracking

---

## Superpowers 衔接

| 阶段 | code 域 | novel 域 | news 域 |
| --- | --- | --- | --- |
| 开书/设计 | `brainstorming` | `brainstorming` | — |
| 规划 | `writing-plans` | `junli-ai-novel` | — |
| 实现 | 平台编排 skill + Task | 平台编排 skill + Task | 平台编排 skill + Task |
| 尾盘测试 | `verification-before-completion` | `novel-evaluator` | `fact-checker` |
| 尾盘审查 | `requesting-code-review` | `novel-evaluator` | `news-editor` |
| 润色 | — | `humanizer-zh` / `novel-ai-wash` | — |
| 统稿 | — | `junli-ai-novel` | `news-editor` |
| 记忆 | — | `memory-manager` | — |

## 反模式

- 未读记忆/计划就派发；单 worker 包整个 epic/多章
- 实现与审查同实例；跳过 execution-log / 尾盘产物
- 有依赖关系却并行执行
- code 域：有委派无 WORKTREE-INIT；无委派仍 INIT
- Leader 自动 push / commit
