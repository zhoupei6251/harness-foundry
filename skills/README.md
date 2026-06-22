# Skills — 项目用到的 Skill 集合

> 20 个 Skill，覆盖开发全流程。每个 Skill 是一个独立目录，
> 入口文件是 `SKILL.md`（含 frontmatter + 使用说明）。

## 目录结构

```
skills/
├── README.md                    # 本文件
├── INDEX.md                     # 表格索引
├── harness/                     # 16 个 harness 自有 skill
│   ├── test-driven-development/
│   ├── systematic-debugging/
│   ├── requesting-code-review/
│   ├── receiving-code-review/
│   ├── agent-browser/
│   ├── verification-before-completion/
│   ├── ui-ux-pro-max/
│   ├── frontend-design/
│   ├── ruoyi-aigc-backend-developer/
│   ├── backend-doc-generator/
│   ├── architecture-patterns/
│   ├── security-auditor/
│   ├── refactor-safely/
│   ├── code-review/
│   ├── cursor-orchestration/
│   └── document-review/
└── third-party/                 # 4 个第三方 skill
    └── superpowers/
        ├── subagent-driven-development/
        ├── dispatching-parallel-agents/
        ├── using-git-worktrees/
        └── executing-plans/
```

## Skill 清单

### harness 自有（16 个）

#### wu 层 — 子 Agent WU 级（8 个）

| Slug | 用途 | 触发关键词 |
|------|------|-----------|
| `test-driven-development` | TDD 流程，先写测试再写实现 | TDD、写测试、先测后码 |
| `systematic-debugging` | 系统化调试流程（重现→最小化→假设→插桩→修复）| debug、报错、修 bug |
| `requesting-code-review` | 发起 code review | review、审查、看代码 |
| `receiving-code-review` | 接收 review 反馈并改进 | 收到反馈、改代码 |
| `agent-browser` | 浏览器自动化（Playwright/agent-browser）| 浏览器、截图、抓取 |
| `verification-before-completion` | 完成前的最终验证 | 完成、收尾、最后检查 |
| `ui-ux-pro-max` | UI/UX 设计智能（design tokens、组件库）| 设计、UI、UX |
| `frontend-design` | 前端页面设计 | 前端、HTML、CSS |

#### project 层 — 项目常用（6 个）

| Slug | 用途 | 触发关键词 |
|------|------|-----------|
| `ruoyi-aigc-backend-developer` | RuoYi 5.5.0 + Spring Boot 3.5.6 后端规范 | 后端、controller、service |
| `backend-doc-generator` | 后端文档生成（含 Mermaid 流程图）| 写文档、生成文档 |
| `architecture-patterns` | 架构模式（Clean / Hexagonal / DDD）| 架构、设计模式 |
| `security-auditor` | 安全审计（OWASP Top 10）| 安全、漏洞、审计 |
| `refactor-safely` | 安全重构（带回归测试）| 重构、改进、清理 |
| `code-review` | Code review 流程 | review、看代码 |

#### cursor_only 层 — Cursor 专属（2 个）

| Slug | 用途 | 触发关键词 |
|------|------|-----------|
| `cursor-orchestration` | Cursor 子 Agent 编排 | 子 agent、派发 |
| `document-review` | 文档审查（spec/plan/design）| 审查文档、看 spec |

### 第三方 cherry-pick（4 个）

| Slug | 来源 | 版本 | 用途 |
|------|------|------|------|
| `subagent-driven-development` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | SDD 核心流程：每个 Task 派发新 implementer + 任务级审查 + 终局大审查 |
| `dispatching-parallel-agents` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | 并行派发独立任务（2+ 独立任务时）|
| `using-git-worktrees` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | Worktree 隔离工作流（优先平台原生，git 作为 fallback）|
| `executing-plans` | [Superpowers](https://github.com/obra/superpowers) | 6.0.3 | 跨 session 执行 plan（fallback，已有 subagent 时优先 SDD）|

## Skill 目录结构

每个 skill 目录遵循统一结构：

```
<skill-slug>/
├── SKILL.md           # 主文档（YAML frontmatter + Markdown 内容）
├── _meta.json         # 元数据（来源、版本、tags）
├── references/        # 参考资料（可选）
├── scripts/           # 辅助脚本（可选）
└── data/              # 数据文件（可选，如 ui-ux-pro-max 的 csv）
```

`SKILL.md` 的 frontmatter：

```yaml
---
name: <slug>
description: <触发场景，AI 自动用此触发>
---
```

## 使用方式

### 在 IDE 中使用

- **Cursor / Claude Code**：在对话中提到 skill 用途关键词，AI 自动加载
- **Trae**：通过 skill 面板手动加载，或对话触发

### 程序化加载

```typescript
// Cursor / Claude Code / Trae 都支持
import skill from 'harness-kit/skills/<slug>/SKILL.md'
```

## 重新同步

真相源不在本目录。如果需要更新 skill，从真相源重新复制：

```bash
# harness 自有 skill（来自 .agents/skills/）
cp -a .agents/skills/<slug> harness-kit/skills/harness/

# 第三方 skill（来自 harness-kit/third-party/）
cp -a harness-kit/third-party/superpowers/skills/<slug> \
      harness-kit/skills/third-party/superpowers/

# 第三方 ECC agent（来自 harness-kit/third-party/）
cp -a harness-kit/third-party/ecc/agents/<name>.md \
      harness-kit/skills/third-party/ecc/agents/

# 自动化批量同步
bash harness-kit/scripts/sync-third-party.sh
```

## 添加新 Skill

1. 在 `harness/<slug>/` 下创建目录
2. 写 `SKILL.md`（含 frontmatter）
3. 写 `_meta.json`（含 `source`、`source_version`）
4. 更新 [`INDEX.md`](INDEX.md)
5. 在 `.agents/skills/_manifest.yaml` 加入对应 layer

## License

MIT

---

**入口：** [`README.md`](../README.md) · [`INDEX.md`](INDEX.md) · [`agents/README.md`](../agents/README.md)