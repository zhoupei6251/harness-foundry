# Codex 适配器

> 平台：**Codex Desktop**（OpenAI）——CLI / IDE 扩展 / **ChatGPT 桌面版**共享同一配置栈

## 状态：✅ 可用

配置栈（CLI / IDE / ChatGPT 桌面版共享）：

| 配置面 | 路径 | 加载 |
|--------|------|------|
| 覆盖层 | `AGENTS.codex-overlay.md` | 在项目 `AGENTS.md` 中引用本文件路径加载 |
| 路由 | `routing.codex.md` | 阶段门禁 + 工具绑定（Codex 版） |
| 绑定 | `bindings.yaml` | 逻辑原语 → Codex 工具映射 |
| 能力矩阵 | `capability-matrix.yaml` | 平台能力对齐 |
| Skill 映射 | `skill-mapping.json` | harness skills → Codex skills |
| **投影源** | `.codex/` | 由 `bootstrap.sh --target codex` 投影到项目 `.codex/` |

## 加载方式

在主项目 `AGENTS.md`（或 `.codex/AGENTS.md`）中引用覆盖层：

```markdown
<!-- 项目根 AGENTS.md -->
详见 harness-foundry/adapters/codex/AGENTS.codex-overlay.md
```

注意 AGENTS.md 链总预算 32 KiB（`project_doc_max_bytes`）——覆盖层只做地图，重内容封装为 skill。

## 投影

```bash
# 投影 .codex/ 配置 + skills 到项目
bash scripts/bootstrap.sh --target codex

# 仅同步 skills（Codex 原生 .agents/skills/ 开放标准，与 Claude 共用真相源）
bash scripts/sync-skills.sh --target codex
```

## 桌面版（ChatGPT 桌面版 / IDE 扩展）

Codex Desktop、CLI、IDE 扩展共享同一配置栈（2026-08 起）：

- 项目 `.codex/` 目录为 Codex 原生配置面（`AGENTS.md` / `agents/` / `skills/`）
- **Skills 原生发现**：`.agents/skills/<slug>/SKILL.md`（与 Claude Code 相同的 Anthropic Agent Skills 开放标准），显式 `$skill-name` 调用或 description 隐式触发
- **Agents**：`.codex/agents/<role>.toml`（官方格式）
- **并行派发**：`spawn_agent`（v2：`task_name`+`message`+`fork_turns`），官方默认 max_threads=6、max_depth=1

## 平台差异

| 能力 | 状态 | 说明 |
|------|------|------|
| `spawn_agent` | ✅ | 官方 API，默认 max_threads=6、max_depth=1（harness 默认 ≤5 Worker 兼容） |
| `.codex/agents/` | ✅ | TOML 格式（官方） |
| `.agents/skills/` | ✅ | 原生 skill 发现（开放标准） |
| Hooks | ⚠️ | Codex 无 Claude 式 hooks；纪律由 AGENTS.md + 阶段门禁保障 |

parity 全表：`capability-matrix.yaml`；绑定映射：`bindings.yaml`；路由：`routing.codex.md`；Skill 映射：`skill-mapping.json`
