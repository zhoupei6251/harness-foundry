<!-- harness-foundry Codex overlay — 加载本文件即可获得 foundry 规则引擎 -->

# Harness Foundry — Codex Desktop 适配层

> 版本：V1.1 | 日期：2026-08-05 | 平台：Codex Desktop（CLI / IDE 扩展 / ChatGPT 桌面版共享同一配置栈）

## 加载方式

在主项目 `AGENTS.md`（或 `.codex/AGENTS.md`）中引用本文件路径，Codex 会在会话启动时加载。
注意 AGENTS.md 链总预算 32 KiB（`project_doc_max_bytes`）——本文件只做地图，重内容建议封装为 skill（见下）。

## 按需加载的规则文件

| 场景 | 加载文件 | 路径 |
|------|----------|------|
| **所有会话**（强制基线） | NEVER 清单 | `../../core/NEVER.md` |
| **编码 / 代码审查** | Java 规范 | `../../rules/code/java/patterns.md` |
| **编码 / 代码审查** | Java 安全 | `../../rules/code/java/security.md` |
| **编码 / 代码审查** | Java 测试 | `../../rules/code/java/testing.md` |
| **安全审计** | 安全 Canary | `../../core/security/canary-token-protocol.md` |
| **两阶段审查** | 审查协议 | `../../core/review/two-stage-protocol.md` |

## 阶段门禁（Codex 版）

> 阶段门禁由 `routing.codex.md` 承载。以下为摘要：

| 阶段 | 动作 | 门禁 |
|------|------|------|
| 设计 / Spec | `superpowers:brainstorming` skill | 写产物后暂停，等用户确认 |
| 计划 | `superpowers:writing-plans` skill | 写产物后暂停，等用户确认 |
| 编码 | 直接执行 | 自主性指令满足后自动进行 |
| 验证 | `superpowers:verification-before-completion` | 编译通过 + 检查清单 |
| 审查 | `requesting-code-review` | 尾盘产物 |

## Codex 原生工具绑定

| 原语 | Codex 绑定 |
|------|-----------|
| SpawnWorker | `spawn_agent`（v2：`task_name`+`message`+`fork_turns`；`multi_agent_v1.` 前缀已过时）+ `.codex/agents/<role>.toml`（官方）或 `agents/<role>.md`（prompt 型，未获官方确认） |
| ParallelBatch | 并行 `spawn_agent`（官方默认 max_threads=6、max_depth=1 → 单层扇出 ≤6），`wait_agent` 汇总 |
| ProgressTrack | `update_plan`（`in_progress` / `completed`） |
| KnowledgeGraph | codebase-memory MCP：`search_graph` / `trace_path` / `get_code_snippet` / `index_status` |
| Verify | `mvn compile` / `git diff` 等 shell 验证 + `superpowers:verification-before-completion` |
| Skills | 原生发现：`.agents/skills/<slug>/SKILL.md`（项目 / 仓库根 / 用户级 `~/.agents/skills`），显式 `$skill-name`，description 隐式触发；harness skills 可 symlink 进 `.agents/skills/` |
| Hooks | `~/.codex/hooks.json` / `.codex/hooks.json`（command 型）：SessionStart / PreToolUse / PostToolUse / UserPromptSubmit / Stop 等 |
| MCP 配置 | **`.codex/config.toml` `[mcp_servers.<name>]`**（Codex **不读 `.mcp.json`**）|

## 与 harness-kit 的关系

harness-foundry **补充** harness-kit：

- `harness-kit` → 项目级配置（skill 路由、profile、git 规范）
- `harness-foundry` → 跨项目通用规则（Java 规范、NEVER 清单、安全审计）

两者**不互相替代**，共同加载。冲突时 `harness-kit` 优先（项目级 > 通用级）。

## 绝对禁止（来自 core/NEVER.md）

- Controller 写业务逻辑
- 循环 SQL（N+1 查询）
- 空 catch 块
- 泄露敏感信息（密码/密钥/Token 进日志）
- Shell 写 Java 文件（用 apply_patch 工具）
- 事务边界错误（this.xxx() 不走代理）

违反任意一条 → 代码审查打回。
