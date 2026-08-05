# Claude Code 适配器

> 平台绑定详见 `bindings.md`；能力对比详见 `capability-matrix.yaml`

## 接入

1. 根目录 `CLAUDE.md` 自动加载（见项目根 `CLAUDE.md`）
2. 统一行为准则来自 `harness-foundry/adapters/agents/AGENTS.md`
3. 多 task 实现：Load `claude-orchestration` → `core/orchestration/dispatcher-workflow.md`

## 桌面版（Claude Code Desktop）支持

2026-08 起桌面版与 CLI **共享同一配置引擎**（旧"桌面版不读 CLI 配置"说法已过时）：

| 会话类型 | `.claude/` 配置加载 | 说明 |
|---------|-------------------|------|
| **本地** | ✅ 全兼容 | CLAUDE.md / skills / agents / hooks / settings.json 全部生效 |
| **SSH** | ✅ 全兼容 | 读远程主机 `~/.claude/skills/` 等 |
| **WSL** | ⚠️ 部分 | **插件不可用**；其余正常 |
| **Cloud**（Anthropic 云） | ⚠️ 受限 | 只读仓库 `.claude/skills/` + 账号 Customize 面板启用的 skills；本机 `~/.claude/settings.json` 的 hooks 不生效 |
| **Cowork** | ⚠️ 受限 | skills/plugins/connectors 全部来自账号 Customize 配置，与 `~/.claude` 无关 |

**桌面版注意**：
- `/config`、`/permissions` 等终端对话框命令不可用 → 改设置须直接编辑 settings 文件或走 GUI（Settings / Customize 面板）
- 每会话自动建 **git worktree**（默认 `<project>/.claude/worktrees/`，位置可配置）——harness hooks 里的路径假设需注意，gitignored 的本地配置用 `.worktreeinclude` 带入
- 插件浏览器（GUI）替代 `/plugin` 命令；scope 可选 user account / project / local-only
- 桌面版无 agent teams（用 dynamic workflows 替代）、无 `--print` / Agent SDK 脚本能力

## 平台差异

| 能力 | 状态 | 说明 |
|------|------|------|
| `interaction.structured-ask` | degraded | 对话式单选，无法使用 AskUserQuestion |
| `hooks.session-lifecycle` | manual | 用户自行配置 `.claude/settings.json` |

parity 全表：`capability-matrix.yaml`；绑定映射：`bindings.md`
