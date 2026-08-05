# WorkBuddy Adapter（腾讯 — = CodeBuddy 双品牌）

本目录定义 **WorkBuddy**（腾讯 AI 原生桌面智能体工作台，国内品牌；国际品牌 CodeBuddy）下的 Harness 适配配置。
**WorkBuddy 与 CodeBuddy 是同一产品的双品牌**（esphome.cloud 官方手册确认），配置面统一为 `.codebuddy/`（项目）+ `~/.codebuddy/`（用户）。

## 为什么适配成本最低

官方明确兼容 Claude Code 生态（codebuddy.ai/docs/zh/cli/plugins-reference）：

| 兼容点 | 说明 |
|--------|------|
| **SKILL.md 开放标准** | Anthropic Agent Skills 格式，`.agents/skills/` 项目级路径与 Claude 一致 |
| **`.claude-plugin/` 直接识别** | 无需改名即可运行；`${CLAUDE_PLUGIN_ROOT}` 等环境变量有兼容别名 |
| **AGENTS.md 自动加载** | 项目根有 `AGENTS.md` 而无 `CODEBUDDY.md` 时全文加载 |
| **Agents frontmatter 同构** | `name/description/model/effort/maxTurns/tools/disallowedTools/isolation` 与 `.claude/agents/` 几乎一一对应 |
| **Hooks 同构** | `SessionStart/PreToolUse/PostToolUse/UserPromptSubmit/Stop/PreCompact`，另扩展 `prompt`/`agent` 型 handler |

## 文件索引

| 文件 | 用途 |
| --- | --- |
| `capability-matrix.yaml` | 能力对齐矩阵（与 claude/trae/codex 同构） |
| `bindings.yaml` | 逻辑原语 → WorkBuddy 绑定（路径/工具/限制） |
| `skill-mapping.json` | harness skills → WorkBuddy 本地/市场技能映射 |

## 投影规则（建议）

从 harness-foundry 投影到项目：

- `skills/*` → `.agents/skills/`（项目，与 Claude 共用同一真相源投影）
- `agents/*` → `.codebuddy/agents/`
- `core/routing.md` 等规则 → `CODEBUDDY.md`（或保留 `AGENTS.md` 走兼容路径）
- rules → `.codebuddy/rules/*.md`
- hooks → `.codebuddy/hooks/hooks.json`
- 身份/记忆：`.workbuddy/`（IDENTITY.md、USER.md、SOUL.md、MEMORY.md）

## 扩展机制速查（2026-08 官方文档）

| 机制 | 路径 | 格式 |
| --- | --- | --- |
| Skills | `.agents/skills/` → `skills/`（工作区）→ `~/.workbuddy/skills/` | SKILL.md（name/description 必填） |
| Agents | `.codebuddy/agents/`（项目）/ `~/.codebuddy/agents/`（用户） | Markdown + YAML frontmatter；agentic/manual 两模式 |
| Team Mode | 主控 Orchestrator + Worker | 工具：`task` / `team_create` / `send_message` |
| Rules | `.codebuddy/rules/*.md`（递归） | RULE.mdc；frontmatter：alwaysApply/paths/enabled |
| Hooks | `hooks/hooks.json` 或插件内 | command/http/prompt/agent 四型 |
| MCP | `~/.codebuddy/mcp.json` / 项目 `.mcp.json` | 标准 mcpServers 对象（stdio + HTTP + OAuth） |
| Plugins | `.codebuddy-plugin/`、`.workbuddy-plugin/`、**`.claude-plugin/`** | 可捆绑 Skills+Agents+Hooks+MCP+LSP |
| Commands | `.codebuddy/commands/*.md` | 斜杠命令 |
| CLI | `codebuddy`（npm `@tencent-ai/codebuddy-code`） | `-p` 单次模式、`/init`、`/plan`、`/resume` |

## 已知边界

- 产品迭代快（2026-03 上线 → v5.0+），配置面可能有 breaking change
- 生态闭源；MCP schema 部分靠社区逆向
- Team Mode 并行硬上限官方未公布（沿用 harness ≤5 默认）
- 社区参考实现：[zhuang-HE/workbuddy-harness](https://github.com/zhuang-HE/workbuddy-harness)（hooks 引擎/Guardian 危险模式 42 种）、[edisonzerolam/team-orchestration-skill](https://github.com/edisonzerolam/team-orchestration-skill)（28 专家团/188 子 agent 逆向移植）

## 官方文档

- [.codebuddy 目录结构](https://www.codebuddy.ai/docs/zh/cli/codebuddy-dir) | [插件参考](https://www.codebuddy.ai/docs/zh/cli/plugins-reference) | [Subagents](http://www.codebuddy.ai/docs/zh/ide/Features/Subagents) | [Hooks](https://www.codebuddy.cn/docs/ide/Features/Hooks) | [Rules](https://www.codebuddy.ai/docs/zh/ide/User-guide/Rules) | [MCP](https://www.workbuddy.ai/docs/workbuddy/From-Beginner-to-Expert-Guide/Function-Description/MCP-Guide)
