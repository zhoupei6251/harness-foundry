# Trae 角色 Agent 定义

本目录定义 Trae 平台下各角色的行为约束，供 `SpawnWorker` 时作为 system prompt 注入。

## 角色列表

| 角色 | 文件 | 真相源 |
|------|------|--------|
| coder | `harness-coder.md` | `harness-foundry/agents/coder.md` |
| implementer | `harness-implementer.md` | `harness-foundry/agents/implementer.md` |
| reviewer | `harness-reviewer.md` | `harness-foundry/agents/reviewer.md` |
| test-engineer | `harness-test-engineer.md` | `harness-foundry/agents/test-engineer.md` |
| explorer | `harness-explorer.md` | `harness-foundry/agents/explorer.md` |
| debugger | `harness-debugger.md` | `harness-foundry/agents/debugger.md` |
| web-investigator | `harness-web-investigator.md` | `harness-foundry/agents/web-investigator.md` |

## 说明

Trae 平台不在此目录维护角色定义副本，而是直接引用 `harness-foundry/agents/` 下的真相源。

`SpawnWorker` 时读取对应 `agents/<role>.md` 注入 system prompt 即可。
