# Skills Index

> 20 个 Skill 的一览表。所有 skill 统一目录结构（`SKILL.md` + 可选附属文件）。

## 总览

| # | Slug | Layer | 来源 | 适用平台 | 主要用途 |
|---|------|-------|------|---------|---------|
| 1 | `test-driven-development` | wu | harness | All | TDD 流程（先写测试） |
| 2 | `systematic-debugging` | wu | harness | All | 系统化调试流程 |
| 3 | `requesting-code-review` | wu | harness | All | 发起 code review |
| 4 | `receiving-code-review` | wu | harness | All | 接收 review 反馈 |
| 5 | `agent-browser` | wu | harness | All | 浏览器自动化 |
| 6 | `verification-before-completion` | wu | harness | All | 完成前验证 |
| 7 | `ui-ux-pro-max` | wu | harness | All | UI/UX 设计智能 |
| 8 | `frontend-design` | wu | harness | All | 前端页面设计 |
| 9 | `ruoyi-aigc-backend-developer` | project | harness | All | RuoYi 后端规范 |
| 10 | `backend-doc-generator` | project | harness | All | 后端文档生成 |
| 11 | `architecture-patterns` | project | harness | All | 架构模式 |
| 12 | `security-auditor` | project | harness | All | 安全审计 |
| 13 | `refactor-safely` | project | harness | All | 安全重构 |
| 14 | `code-review` | project | harness | All | Code review 流程 |
| 15 | `cursor-orchestration` | cursor_only | harness | Cursor | 子 Agent 编排 |
| 16 | `document-review` | cursor_only | harness | Cursor | 文档审查 |
| 17 | `subagent-driven-development` | — | Superpowers@6.0.3 | All | SDD 核心流程 |
| 18 | `dispatching-parallel-agents` | — | Superpowers@6.0.3 | All | 并行派兵判断 |
| 19 | `using-git-worktrees` | — | Superpowers@6.0.3 | All | Worktree 工作流 |
| 20 | `executing-plans` | — | Superpowers@6.0.3 | All | 跨 session 执行 plan |

## 按触发关键词检索

| 关键词 | 推荐 skill |
|--------|----------|
| TDD、写测试、先测后码 | `test-driven-development` |
| debug、报错、修 bug、crash | `systematic-debugging` |
| review、审查、看代码、CR | `requesting-code-review` / `code-review` |
| 改代码、改反馈、收到意见 | `receiving-code-review` |
| 浏览器、截图、抓网页 | `agent-browser` |
| 完成、收尾、最后检查、提交 | `verification-before-completion` |
| 设计、UI、UX、组件库 | `ui-ux-pro-max` |
| 前端、HTML、CSS、页面 | `frontend-design` |
| 后端、controller、service、RuoYi | `ruoyi-aigc-backend-developer` |
| 写文档、生成文档、Mermaid | `backend-doc-generator` |
| 架构、Clean、Hexagonal、DDD | `architecture-patterns` |
| 安全、漏洞、审计、OWASP | `security-auditor` |
| 重构、改进、清理、tidy | `refactor-safely` |
| 文档审查、spec 审查、plan 审查 | `document-review` |
| 子 agent、派发、orchestration | `cursor-orchestration` |
| SDD、派 implementer、终审 | `subagent-driven-development` |
| 并行、多任务、同时 | `dispatching-parallel-agents` |
| worktree、隔离工作区 | `using-git-worktrees` |
| 跨 session、plan、执行 | `executing-plans` |

## 按平台可用性

| Slug | Trae | Cursor | Claude | Codex |
|------|------|--------|--------|-------|
| harness 自有（14）| ✅ | ✅ | ✅ | ✅ (直读 AGENTS.md) |
| `cursor-orchestration` | ❌ | ✅ | ❌ | ❌ |
| `document-review` | ❌ | ✅ | ❌ | ❌ |
| 第三方 4 个 | ✅ | ✅ | ✅ | ✅ |

## 按 Layer 分组（manifest）

| Layer | 数量 | 说明 |
|-------|------|------|
| `wu` | 8 | 子 Agent WU 级，每个 Task 派发时可选 |
| `project` | 6 | 项目级常用，每次开发都用 |
| `cursor_only` | 2 | 仅 Cursor（其他平台不投影） |
| 第三方 | 4 | 不进 manifest，由 `sync-third-party.sh` 单独管理 |

manifest 真相源：`.agents/skills/_manifest.yaml`

## 更新与扩展

详见 [`README.md` § 重新同步](README.md#重新同步)。

---

**入口：** [`README.md`](../README.md) · [`README.md`](README.md) · [`agents/README.md`](../agents/README.md)