# Agents — 全局 Agent 池

> 三域共用（code / novel / news）。通过 `core/orchestration/domain-config.yaml` 按域加载主次 Agent。
> 共 **30 个 Agent 文件**（含 3 个 .meta.json 元数据文件）。

## 目录结构

```
agents/
├── README.md                    # 本文件
├── leader-*.md                  # 三域主编（3 个）
├── coder.md                     # 编码者（完整代码实现）
├── implementer.md               # 轻量实现者（文档/配置）
├── reviewer.md                  # 代码审查者（通用）
├── code-reviewer.md             # 代码审查者（专职，含 Handoff 协议）
├── test-engineer.md             # 测试工程师（TDD）
├── debugger.md                  # 调试者（系统化 debug）
├── explorer.md                  # 只读探查者（代码库导航）
├── architect.md                 # 架构师
├── code-simplifier.md           # 代码精简/优化
├── tech-writer.md               # 技术文档撰写
├── web-investigator.md          # 联网搜索取证
├── novel-*.md                   # 小说域专属 agent（5 个）
├── news-*.md                    # 新闻域专属 agent（3 个）
├── ecc-*.md                     # ECC 专属审查 agent（3 个 + 3 .meta.json）
├── humanizer.md                 # AI 文风清洗
├── editor.md                    # 文字校对排版
├── shared-researcher.md         # 通用调研
├── ceo.md                       # CEO 统筹入口
└── memory-keeper.md             # 记忆同步
```

---

## 主编 / Leader（3 个）

| Agent | 触发时机 | 主要能力 |
|-------|---------|---------|
| **leader-code** | 收到任意代码请求 | 意图路由、阶段门禁、派发 subagent、整合结果 |
| **leader-novel** | 收到小说创作请求 | 统筹全流程、阶段门禁、质量把控 |
| **leader-news** | 收到新闻写作请求 | 统筹新闻流程、选题确认、发布审核 |

---

## code 域核心 Agent（12 个）

| Agent | 触发时机 | 主要能力 |
|-------|---------|---------|
| **coder** | 实现功能 / 修 bug / 重构 | 完整代码实现、单测、自测、轻量审查 |
| **implementer** | 文档 / 配置 / 轻量改动 | 单点实现，不写业务代码 |
| **reviewer** | 代码审查（通用） | 五轴审查（功能/可读/架构/安全/性能），尾盘默认 |
| **code-reviewer** | 代码审查（专项） | 技术栈专项审查（React/Node/Java 模式、误报过滤），含 Handoff 协议 |
| **debugger** | 修 bug / 排查问题 | 系统化 debug（重现→最小化→假设→插桩→修复→回归测试） |
| **test-engineer** | 写测试 / TDD | 单元测试、E2E 测试、覆盖率保障 |
| **architect** | 架构设计 / 技术选型 | 架构方案、技术选型、依赖分析 |
| **explorer** | 代码探索 | 代码库导航、依赖分析、影响分析 |
| **code-simplifier** | 精简/优化代码 | 代码可读性提升、去除冗余、扁平化嵌套 |
| **tech-writer** | 写技术文档 | API 文档、用户指南、架构说明 |
| **web-investigator** | 联网搜索取证 | 网页抓取、截图取证、资料整理 |

---

## novel 域（7 个）

| Agent | 触发时机 | 主要能力 |
|-------|---------|---------|
| **novel-writer** | 写章节 / 续写 / 扩写 | 正文创作、情节推进、人物塑造、返修落地 |
| **novel-planner** | 写大纲 / 分卷 / 规划 | 故事大纲、分卷结构、章节规划 |
| **novel-reviewer** | 审稿 / 评分 / 检查 | 小说审稿（情节/人物/文笔/世界观/情感/创新） |
| **humanizer** | 润色 / 去 AI 味 | 中文润色、消除 AI 痕迹 |
| **editor** | 排版 / 校对 | 文字校对、排版优化 |
| **memory-keeper** | 记忆同步 | 维护 MEMORY.md、状态追踪、伏笔管理 |
| **shared-researcher** | 查资料 / 考据 | 历史考据、素材整理 |

---

## news 域（3 个）

| Agent | 触发时机 | 主要能力 |
|-------|---------|---------|
| **news-writer** | 写新闻 / 快讯 / 报道 | 新闻稿撰写、事实准确、语言规范 |
| **fact-checker** | 事实核查 / 查证 | 事实核查、辟谣、来源验证 |
| **news-editor** | 润色 / 审校 | 新闻审校、格式规范、敏感内容审查 |

---

## 通用 Agent（4 个）

| Agent | 触发时机 | 主要能力 |
|-------|---------|---------|
| **explorer** | 只读探查 | 代码库导航、依赖分析 |
| **shared-researcher** | 通用调研需求 | 跨领域调研、资料整理 |
| **web-investigator** | 联网搜索 / 截图 | 网页抓取、截图取证 |
| **ceo** | 复杂任务统筹 | 多域协调、任务拆分、进度跟踪 |

---

## ECC 专属审查 Agent（3 个 + 3 .meta.json）

| Agent | 说明 |
|-------|------|
| **ecc-java-reviewer** | Java 专项审查 |
| **ecc-security-reviewer** | 安全审查 |
| **ecc-database-reviewer** | 数据库审查 |

仅在 review 阶段显式调用，不进入主流程。

---

## Handoff 协议

所有 Agent 文件内置 Handoff 交接协议入口，确保多 Agent 协作时的上下文传递：

```
交接 → 接收方 Agent → 继续执行 → 交接给下一个 Agent
```

详见：[handoff/](handoff/) 目录

---

## 加载方式

路由到某域后，按 `core/orchestration/domain-config.yaml` 加载：

- **primary_agents**：路由确定后立即加载
- **secondary_agents**：任务需要时按需加载

## 真相源

所有 Agent 文件即为真相源，不再从其他目录同步。

## License

MIT
