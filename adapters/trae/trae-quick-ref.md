# Trae IDE Harness 开发者快速参考

> 本文件面向在 Trae IDE 中使用 Harness Kit 的开发者，提供一站式速查。

## 一句话启动

在对话中输入：**`Harness：<路由>`**

| 你想做 | 输入 |
|--------|------|
| 设计方案/架构 | `Harness：design` |
| 写任务计划 | `Harness：plan` |
| 写代码/实现功能 | `Harness：implement` |
| 验证/调试 Bug | `Harness：verify` |
| 代码审查 | `Harness：review` |
| 小修小改 | `Harness：小改动，直接处理` |
| 初始化 Harness | `Harness：bootstrap` |
| 查看帮助 | `Harness：help` |

## 开发流程速览

```
design → plan → implement → verify → review
  ↓        ↓        ↓         ↓        ↓
 spec    plan    代码实现    测试通过   审查通过
```

- 每个阶段产物写入 `.ai-runtime-artifacts/` 对应目录
- spec / plan 阶段完成后需用户确认才进入下一阶段
- 小改动可跳过 design/plan 直接实现

## 子 Agent 委派

在实现阶段，主 Agent 会自动委派子 Agent 并行工作：

| 子 Agent | 用途 | Trae 实现方式 |
|----------|------|---------------|
| harness-coder | 写代码 | `Task(subagent_type="general_purpose_task")` |
| harness-reviewer | 代码审查 | `Skill(name="code-review")` |
| harness-test-engineer | 测试/E2E | `Skill(name="test-driven-development")` / `agent-browser` |
| harness-implementer | 文档/配置 | `Task(general_purpose_task)` |
| harness-web-investigator | 调研取证 | `Task(search)` + `web-tools-guide` |
| harness-debugger | 调试 Bug | `Skill(name="systematic-debugging")` |
| harness-explorer | 探索代码 | `Task(subagent_type="search")` |

## Skill 路由（自动匹配）

主 Agent 会根据任务类型自动加载对应 Skill：

| 任务类型 | 自动加载的 Skill |
|----------|------------------|
| 写新功能 / 修 Bug | `test-driven-development` → `requesting-code-review` |
| UI 实现 | `ui-ux-pro-max` → `frontend-design` → `test-driven-development` → `requesting-code-review` |
| 按审查意见修改 | `receiving-code-review` → `test-driven-development` → `requesting-code-review` |
| 调查 Bug | `systematic-debugging` |
| 编写测试 | `test-driven-development` |
| 代码审查 | `requesting-code-review` |

## Trae 工具映射

| 做什么 | 使用工具 |
|--------|----------|
| 语义搜索代码 | `SearchCodebase` |
| 按文件名查找 | `Glob` |
| 按内容搜索 | `Grep` |
| 读取文件 | `Read` |
| 编辑文件 | `Edit` / `Write` |
| 执行命令 | `RunCommand` |
| 诊断错误 | `GetDiagnostics` |
| 任务追踪 | `TodoWrite` |
| 调用 Skill | `Skill` |
| 委派子任务 | `Task` |

## Skill 发现路径

Trae 会自动扫描以下目录的 Skill：

| 优先级 | 路径 | 说明 |
|--------|------|------|
| 1 | `.trae/skills/` | 项目级 Skill |
| 2 | `~/.trae/skills/` | 用户全局 Skill |

> 项目已有 60+ Skill，覆盖后端开发、文档生成、小说创作等场景。

## 项目专属 Skill

| Skill | 用途 |
|-------|------|
| `ruoyi-aigc-backend-developer` | RuoYi-Vue-Plus AIGC 平台后端开发指导 |
| `backend-doc-generator` | 生成后端技术文档（含 Mermaid 图） |
| `architecture-patterns` | 架构模式参考（Clean/Hexagonal/DDD） |
| `harness-orchestration` | Harness 编排器（路由解析 + 阶段管理） |

## 开发规范提醒

- **中文输出**：所有注释、文档、回复使用简体中文
- **TDD 流程**：写完业务代码后 → 自动生成测试 → 代码审查
- **记忆管理**：跨会话自动加载 `MEMORY.md`，保持上下文连贯
- **产物规范**：所有 plan/spec/decision 写入 `.ai-runtime-artifacts/`

## 目录结构

```
项目根目录/
├── .trae/
│   ├── rules/          # 规则文件（harness-entry.md, harness-routing.md）
│   ├── agents/         # 7 角色（与 Cursor 对齐）
│   ├── skills/         # 投影 Skill（~14，bootstrap 生成）
│   └── mcp/            # MCP 配置
├── .agents/
│   └── skills/         # 通用 Skill 目录（与 .trae/skills/ 内容一致）
├── .ai-runtime-artifacts/  # Harness 产物目录
│   ├── specs/          # 设计文档
│   ├── plans/          # 任务计划
│   ├── decisions/      # 决策记录
│   └── verifications/  # 验证记录
└── harness-kit/        # Harness Kit 核心
    ├── adapters/trae/  # Trae 适配配置
    ├── core/orchestration/  # 编排核心
    └── artifact-templates/  # 产物模板
```

## 常见问题

**Q: 如何跳过 plan 直接写代码？**
A: 使用 `Harness：小改动，直接处理`

**Q: 子 Agent 执行失败怎么办？**
A: 查看返回的 `blocker` 字段，根据阻塞原因调整任务描述或解决依赖

**Q: 如何查看当前 Harness 状态？**
A: 输入 `Harness：help` 查看可用路由和当前阶段

**Q: 能否并行执行多个任务？**
A: 可以，`Harness：implement` 会自动将 plan 拆分为并行 WU（最多 3 个并行，硬顶 5 个）
