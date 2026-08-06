# WorkBuddy Agents 投影

> 由 `bootstrap.sh --target workbuddy` 投影到项目 `.codebuddy/agents/`。
> 真相源在 `harness-foundry/agents/*.md`（frontmatter 与 Claude Code 同构）。

## 角色

WorkBuddy（= CodeBuddy）frontmatter 与 Claude Code 几乎一一对应：
`name/description/model/effort/maxTurns/tools/disallowedTools/skills/memory/background/isolation`。

harness 角色定义（`harness-foundry/agents/`）：

| 域 | Leader | 主要 Worker |
|----|--------|-------------|
| code | leader-code | coder, debugger, reviewer, test-engineer, explorer |
| novel | leader-novel | novel-writer, novel-planner, novel-reviewer, humanizer |
| news | leader-news | news-writer, fact-checker, news-editor |

## 用法

- 使用 `.codebuddy/agents/<role>.md`（agentic 模式，主代理按 description 自动委派，独立上下文）
- Team Mode 用 `task` / `team_create` / `send_message`（harness 默认 ≤5 Worker）
- 直接引用 `harness-foundry/agents/*.md` 亦可（AGENTS.md 兼容路径）

## 强制声明

每任务首句：`「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`
（见 `harness-foundry/core/intent-routing.md` 路由表）
