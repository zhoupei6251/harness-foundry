<!-- harness-foundry Codex overlay — 加载本文件即可获得 foundry 规则引擎 -->

# Harness Foundry — Codex Desktop 适配层

> 版本：V1.0 | 日期：2026-07-29 | 平台：Codex Desktop

## 加载方式

在主项目 `AGENTS.md` 或 `.codex/rules/` 中引用本文件路径，Codex 会在会话启动时加载。

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

## Codex Desktop 原生工具绑定

| 原语 | Codex Desktop 绑定 |
|------|--------------------|
| SpawnWorker | `multi_agent_v1.spawn_agent` + `harness-foundry/agents/<role>.md` |
| ParallelBatch | 并行 `spawn_agent`（建议 ≤4），`wait_agent` 汇总 |
| ProgressTrack | `update_plan`（`in_progress` / `completed`） |
| KnowledgeGraph | codebase-memory MCP：`search_graph` / `trace_path` / `get_code_snippet` / `index_status` |
| Verify | `mvn compile` / `git diff` 等 shell 验证 + `superpowers:verification-before-completion` |
| MCP 配置 | 项目 `.mcp.json` + `~/.codex/config.toml` `[mcp_servers.codebase_memory]` |

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
