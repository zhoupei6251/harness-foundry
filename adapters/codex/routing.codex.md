<!-- harness-foundry routing for Codex Desktop -->

# Codex Desktop — 路由与门禁（harness-foundry 版）

> 本文件是 harness-foundry 核心路由的 Codex 适配。
> 真相源：`harness-foundry/core/intent-routing.md`
> 项目兜底：`harness-kit/core/routing.md`（冲突时优先）

## 意图路由

| 用户意图 | Codex 执行路径 |
|----------|---------------|
| 需求澄清 / 方案设计 | 加载 `superpowers:brainstorming` skill → 写 `specs/` 产物 → 暂停等确认 |
| 实施计划 | 加载 `superpowers:writing-plans` skill → 写 `plans/` 产物 → 暂停等确认 |
| 编码 / 实现 | 直接执行（满足自主性条件时）或 先加载 `rules/code/java/patterns.md` |
| 多任务并行实现 | `multi_agent_v1.spawn_agent` 拆 WU（建议 ≤4 并行）→ `update_plan` 跟踪 → 主 agent 整合验证 |
| 代码审查 | 加载 `requesting-code-review` skill → 对照 NEVER 清单 + Java 安全 |
| 验证 | 加载 `superpowers:verification-before-completion` → 编译 + 检查清单 |
| 架构决策 | 写 `decisions/` 产物 → 暂停等确认 |
| Git 协作 | 加载 `git-xywh` skill + `project.git.md` |
| 安全审计 | 加载 `rules/code/java/security.md` → 扫描结果 |

## Codex 特有的门禁替代

| Claude Hook | Codex 替代 |
|-------------|------------|
| `PreToolUse` → 设计门禁 | skill 内置 `request_user_input` 暂停 |
| `PostToolUse` → 自动审查 | 尾盘手动调用 `requesting-code-review` |
| `Stop` → 阶段暂停 | 写产物后直接在回复中请求确认 |
| 进度跟踪 | `update_plan` 维护 `in_progress` / `completed` |

## 自主性条件（同 harness-kit）

满足**全部三条件**才能自主继续：
1. 用户已说「开始实现 / 直接做 / 并行执行」
2. 不是「写方案 / 写计划」阶段
3. 无组合指令里的「然后执行」

不满足 → 每个阶段产物写完后暂停等用户确认。
