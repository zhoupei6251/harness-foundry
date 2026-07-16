# Harness Foundry v2.1 - 架构 (Code 域三层洞察栈)

> 版本: v2.1. 在 v2.0 (TypeScript/Node.js 运行时) 方向上回退到以 Skill/规则/Markdown 为主的轻量运行时, 并将 code 域的战术查询能力升级为 codebase-memory + ripgrep + LSP 三层栈.

## 1. 目标
Harness Foundry 的真实目标: 让 AI 在其他项目里更稳定地产出可用结果.

## 2. 核心原则
- 知识与运行时分离
- 三层栈 (图/文本/语义)
- Harness 不替 AI 写代码
- 失败显式化
- 可重入轻状态

## 3. 三层栈
- code-insight-stack: 统一入口
- codebase-memory: 知识图谱
- ripgrep-search: 文本搜索
- lsp-query: 语言服务

## 4. 决策表
| 需求 | 首选 | 备用 |
|---|---|---|
| 谁调用 X (语义) | lsp-query references | codebase-memory trace_path inbound |
| 内部调了什么 | codebase-memory trace_path outbound | lsp-query hover |
| 字符串/注释/路径 | ripgrep-search | - |
| 类型/签名 | lsp-query hover | codebase-memory get_code_snippet |
| 编译错误 | lsp-query diagnostic | simplify / tdd |
| 跨文件结构 | codebase-memory search_graph | lsp-query workspace/symbol |
| 影响面 | codebase-memory detect_changes | lsp-query references 交叉 |
| TODO/FIXME | ripgrep-search | - |
| 重命名 | lsp-query executeCommand | - |
| 陌生项目全局 | codebase-memory get_architecture | ripgrep-search 列目录 |

## 5. 降级
- LSP 不可用 -> 退到 codebase-memory + ripgrep-search
- codebase-memory 索引未建立 -> 退到 ripgrep-search + lsp-query, 任务结束前补 index_repository
- ripgrep 不可用 -> 用 grep -Rn 兜底, 标注 low_confidence

## 6. 路由 (skill-preferences 自动注入)
- coder | feature, bugfix, refactor | test-driven-development, requesting-code-review
- coder | feature, bugfix, refactor | query-symbol
- coder | feature, bugfix, refactor | ripgrep-search, lsp-query
- coder | ui                          | ripgrep-search, lsp-query
- reviewer | review, *                | requesting-code-review, analyze-impact
- reviewer | review, *                | ripgrep-search, lsp-query
- test-engineer | test                | test-driven-development, analyze-impact
- test-engineer | test                | ripgrep-search, lsp-query
- leader-code | refactor              | code-insight-stack, understand-chat

## 7. Agent 工作流 (Code 域)
### 7.1 leader-code
- 入口: Route: code
- 阶段链: brainstorming -> writing-plans -> 实现/派发 WU -> 测试+审查 -> execution-log 关闭
- 阶段门禁: spec/plan 未经用户确认前, 不进入实现阶段
- 战术层自动注入: 在派发 prompt 中加 codebase-memory + ripgrep + LSP 提示

### 7.2 coder
- 1. /code-insight-stack 选最便宜工具组合
- 2. /lsp-query references 或 /get-callers 看调用方
- 3. /analyze-impact 评估影响
- 4. /lsp-query diagnostic 验证编译

### 7.3 debugger
- 定位: ripgrep-search 错误信息 -> /query-symbol 类名 -> /lsp-query definition
- 分析: /lsp-query references + /get-callers (兜底图)
- 根因: /get-callees + /lsp-query hover (看类型)

### 7.4 code-reviewer
- Review 前: /analyze-impact + /ripgrep-search 复核关键字
- Review 中: /lsp-query references 看语义引用, 必要时 /query-symbol
- Review 后: /ripgrep-search 校验字符串一致性, 必要时 /get-callers

### 7.5 explorer
- 探查工具: codebase-memory + ripgrep-search + lsp-query + code-insight-stack

## 8. 跨 IDE 投影
| IDE | 投影目录 | 命令 |
|---|---|---|
| Trae | .trae/skills/ / .trae/agents/ | bash scripts/sync-skills.sh --target trae |
| Claude Code | .claude/skills/ / .claude/agents/ | bash scripts/sync-skills.sh --target claude |
| Cursor | .cursor/skills/ / .cursor/agents/ | 走 Codex/Claude 投影间接共享 |

## 9. 端到端验证
- bash scripts/install-intelligence-deps.sh
- bash tests/validate-intelligence-layer.sh
- bash tests/L2-integration/validate-routing.sh
- bash tests/L3-intelligence/test-agent-integration.sh
- bash tests/L3-intelligence/test-mcp-config.sh
- gh actions run

## 10. 已知限制
- lsp-query 不强依赖某个 language server 进程; 具体可用性由宿主 IDE 决定.
- _layer.yaml 中 historical 残留 (如 frontend-design 出现两次) 暂未清理, 不影响运行.
- bash scripts/verify.sh 的 5/6 步需要 python3, Windows 环境下 python3 缺失会标 partial fail, 与本次改动无关.

## 11. 版本
- v2.0.0-beta.1 (已废弃, v2 完整 TypeScript 运行时, 迁移未完成) -> 退回 v1 基础
- v2.1.0 (当前) -> 加 ripgrep + LSP + code-insight-stack, 保留 v1 知识层