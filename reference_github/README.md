# AI Coding & Agent 生态索引

> 本目录汇集了 AI 编程助手、Agent 框架、知识图谱等相关的开源项目。
> `reference_github/` 已被 `.gitignore` 排除（仅本 README 例外），新电脑请按下方链接逐一 clone。

---

## 快速批量 Clone

```bash
mkdir -p reference_github && cd reference_github

# AI Agent 框架
git clone https://github.com/langchain-ai/langgraph.git langgraph
git clone https://github.com/run-llama/llama_index.git llama_index
git clone https://github.com/All-Hands-AI/OpenHands.git OpenHands
git clone https://github.com/garrytan/gstack.git gstack

# AI 编程助手 & Harness
git clone https://github.com/anthropics/claude-code.git claude-code
git clone https://github.com/affaan-m/ECC.git ECC
git clone https://github.com/obra/superpowers.git superpowers
git clone https://github.com/wshobson/agents.git agents
git clone https://github.com/anthropics/skills.git anthropics
git clone https://github.com/forrestchang/andrej-karpathy-skills.git andrej-karpathy-skills

# 知识图谱 & 记忆系统
# codebase-memory 由 Codex skill 提供，无需单独 clone
git clone https://github.com/Egonex-AI/Understand-Anything.git Understand-Anything
git clone https://github.com/topoteretes/cognee.git cognee
git clone https://github.com/getzep/graphiti.git graphiti
git clone https://github.com/mem0ai/mem0.git mem0

# 技能 & 插件 & 设计
git clone https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git ui-ux-pro-max-skill
git clone https://github.com/open-webui/open-webui.git open-webui

# Awesome 列表
git clone https://github.com/anthropics/awesome-claude-code.git awesome-claude-code
git clone https://github.com/Shubhamsaboo/awesome-llm-apps.git awesome-llm-apps
git clone https://github.com/punkpeye/awesome-mcp-servers.git awesome-mcp-servers

# 学习资源 & 参考
git clone https://github.com/Snailclimb/JavaGuide.git JavaGuide
git clone https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools.git system-prompts-and-models-of-ai-tools
```

---

## 完整索引

### AI Agent 框架

| 目录 | 描述 | GitHub |
|------|------|--------|
| `langgraph` | 构建有状态 AI Agent 的底层编排框架，支持持久化执行和人机协作 | https://github.com/langchain-ai/langgraph |
| `llama_index` | 构建 Agentic 应用的开源框架，提供数据连接器、索引和检索接口 | https://github.com/run-llama/llama_index |
| `OpenHands` | 开源 AI Agent，用于自动化软件开发和任务执行 | https://github.com/All-Hands-AI/OpenHands |
| `gstack` | 面向编程 Agent 的软件开发方法论，包含 23 个专家角色和 8 个命令行工具 | https://github.com/garrytan/gstack |

### AI 编程助手 & Harness

| 目录 | 描述 | GitHub |
|------|------|--------|
| `claude-code` | 终端中的 Agentic 编程工具，理解代码库，帮助快速编码 | https://github.com/anthropics/claude-code |
| `ECC` | Claude Code 的操作员系统，提供技能、本能、记忆优化和跨 Harness 的 Agent 工作流 | https://github.com/affaan-m/ECC |
| `superpowers` | 面向编程 Agent 的完整软件开发方法论，包含 TDD、脑暴、子 Agent 驱动开发等可组合技能 | https://github.com/obra/superpowers |
| `agents` | Agentic 插件市场，提供 88 个插件、194 个 Agent、158 个技能和 106 个命令 | https://github.com/wshobson/agents |
| `anthropics` | Anthropic 官方 Claude Code 技能仓库 | https://github.com/anthropics/skills |
| `andrej-karpathy-skills` | 改进 Claude Code 行为的单一 CLAUDE.md，包含四大原则：编码前思考、简洁优先、精确变更、目标驱动 | https://github.com/forrestchang/andrej-karpathy-skills |
| `mattpocock` | Matt Pocock 的 AI 编程助手技能集 | *待确认来源* |

### 知识图谱 & 记忆系统

| 目录 | 描述 | GitHub |
|------|------|--------|
| `codebase-memory` | 通过知识图谱工具提供代码结构查询、调用链追踪和影响分析 | 本地 Codex skill |
| `Understand-Anything` | 将代码库、知识库或文档转换为 AI 编程助手的交互式知识图谱 | https://github.com/Egonex-AI/Understand-Anything |
| `cognee` | 开源 AI 记忆平台，支持任意格式数据摄入和自托管知识图谱构建 | https://github.com/topoteretes/cognee |
| `graphiti` | 为 AI Agent 构建时序上下文图谱，支持双时态事实追踪和混合检索 | https://github.com/getzep/graphiti |
| `mem0` | 个性化 AI 的记忆层，保留用户偏好、适应个体需求、持续学习 | https://github.com/mem0ai/mem0 |

### 技能 & 插件 & 前端

| 目录 | 描述 | GitHub |
|------|------|--------|
| `ui-ux-pro-max-skill` | AI 设计智能技能，67 种 UI 风格、161 个配色方案、57 种字体搭配和设计系统生成 | https://github.com/nextlevelbuilder/ui-ux-pro-max-skill |
| `open-webui` | 开源 Web UI，为 LLMs 提供类似 ChatGPT 的界面 | https://github.com/open-webui/open-webui |

### Awesome 列表

| 目录 | 描述 | GitHub |
|------|------|--------|
| `awesome-claude-code` | Anthropic 官方整理的 Claude Code 最佳资源合集 | https://github.com/anthropics/awesome-claude-code |
| `awesome-llm-apps` | 100+ AI Agent 和 RAG 应用，含分步教程，涵盖 Agent、MCP、语音 AI 等 | https://github.com/Shubhamsaboo/awesome-llm-apps |
| `awesome-mcp-servers` | Model Context Protocol 服务器精选列表 | https://github.com/punkpeye/awesome-mcp-servers |

### 学习资源 & 参考

| 目录 | 描述 | GitHub |
|------|------|--------|
| `JavaGuide` | 全面的 Java 学习资源，涵盖 Java、Spring Boot、数据库、分布式系统和面试准备 | https://github.com/Snailclimb/JavaGuide |
| `system-prompts-and-models-of-ai-tools` | 收集各种 AI 工具的系统提示词和模型信息 | https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools |

---

## 快速导航

- 🔧 想提升编程效率？→ Claude Code + Superpowers + ECC
- 🧠 想构建 Agent 记忆？→ Mem0 + Graphiti + cognee
- 📊 想理解代码库？→ codebase-memory + Understand-Anything
- 🎨 想做 UI 设计？→ UI UX Pro Max
- 📚 想学习 Java？→ JavaGuide
- 🔄 防 AI 偷懒？→ Ralph Loop (`skills/ralph/`)

---

## 注意事项

- 上述 clone 命令会创建与当前相同的目录名，注意在 `reference_github/` 内执行
- 部分仓库较大，建议浅克隆：`git clone --depth 1 <url> <dir>`
- 本 README 是 `reference_github/` 下**唯一允许提交的文件**（其余均在 `.gitignore` 中排除）
