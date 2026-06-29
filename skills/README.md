# Skills — 全局 Skill 池

> 三域共用（code / novel / news）。通过 `core/orchestration/domain-config.yaml` 按域加载主次 Skill。

## 目录结构

```
skills/
├── <skill-slug>/    # 扁平化目录，每个 skill 一个目录
├── INDEX.md         # 完整 skill 索引（333 个）
└── README.md        # 本文件
```

所有 skill 已整合到统一池，按功能分类见 [INDEX.md](./INDEX.md)。

## 加载方式

路由到某域后，按 `core/orchestration/domain-config.yaml` 加载：

- **primary_skills**：路由确定后立即加载
- **secondary_skills**：任务需要时按需加载

### 示例配置

```yaml
# core/orchestration/domain-config.yaml
domain: code
primary_skills:
  - architecture-patterns
  - test-driven-development
secondary_skills:
  - code-review
  - refactor-safely
  - simplify
  - technical-writer
  - humanizer-zh
```

## Skill 列表

### Code 域（6 个）

| Skill | 说明 |
|-------|------|
| `architecture-patterns` | 后端架构模式（Clean/Hexagonal/DDD） |
| `code-review` | 代码审查 |
| `refactor-safely` | 安全重构 |
| `security-auditor` | 安全审计 |
| `systematic-debugging` | 系统性调试 |
| `test-driven-development` | TDD 红绿重构循环 |

### Novel 域（14 个）

| Skill | 说明 |
|-------|------|
| `fanqie` | 番茄小说相关 |
| `fanqie-novel-auto-publish` | 番茄小说自动发布 |
| `humanizer-zh` | 中文 AI 文风清洗（轻量） |
| `inkos` | InkOS 小说创作系统 |
| `junli-ai-novel` | 君黎 AI 网文连载助手 |
| `memory-manager` | 小说项目记忆管理 |
| `novel-ai-wash` | AI 文风清洗（深度） |
| `novel-evaluator` | 小说质量评分 |
| `novel-generator` | 爽文小说自动生成 |
| `novel-orchestrator` | 长篇网文协作编排 |
| `novel-to-drama-script` | 小说转短剧剧本 |
| `story-cog` | CellCog 创意写作 |
| `web-novel-publishing-readiness-and-quality-check-skill` | 网文发布质检 |
| `web-tools-guide` | 网页工具使用指南 |

### News 域（4 个）

| Skill | 说明 |
|-------|------|
| `fact-check` | 事实核查 |
| `hot-topic-research` | 热点话题调研 |
| `news-generator` | 新闻自动生成 |
| `news-polish` | 新闻润色 |

### Shared 域（32 个）

| Skill | 说明 |
|-------|------|
| `auto-updater` | 自动更新 |
| `brainstorming` | 头脑风暴 |
| `cursor-orchestration` | Cursor 多子 Agent 编排 |
| `document-review` | 文档审查 |
| `edge-tts` | 文本转语音 |
| `excel-xlsx` | Excel/XLSX 表格处理 |
| `executing-plans` | 执行计划 |
| `find-skills` | 发现并安装 Skill |
| `free-ride` | OpenRouter 免费模型管理 |
| `human-writing` | 人类风格写作 |
| `humanizer` | 去除 AI 写作痕迹（含 CLI 工具） |
| `pdf` | PDF 处理工具包 |
| `planning-with-files` | 基于文件的任务规划 |
| `playwright` | Playwright 浏览器自动化 |
| `project-planner` | 项目规划与 issue 拆解 |
| `prompt-engineering-expert` | Prompt 工程专家 |
| `receiving-code-review` | 接收代码审查反馈 |
| `requesting-code-review` | 发起代码审查 |
| `self-improving` | 自我改进与学习 |
| `skill-vetter` | Skill 安全审查 |
| `summarize` | 内容摘要 |
| `superdesign` | 超级设计工具 |
| `technical-writer` | 技术文档写作 |
| `verification-before-completion` | 完成前验证 |
| `web-reader` | 网页内容读取 |
| `word-docx` | Word 文档处理 |
| `writing-plans` | 撰写执行计划 |

## 添加新 Skill 流程

1. 在 `skills/` 下创建新目录（如 `my-new-skill/`）
2. 创建 `SKILL.md`（必需），包含 skill 名称、描述、使用说明
3. 可选创建 `_meta.json` 用于元数据管理
4. 在 `core/orchestration/domain-config.yaml` 中注册
5. 更新 [INDEX.md](./INDEX.md)
