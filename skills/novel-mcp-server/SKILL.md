---
name: novel-mcp-server
description: Model Context Protocol 服务器，为写作工具提供 AI 写作能力接口，支持章节写作/审稿评分/记忆管理/大纲查询/伏笔检查
metadata:
  domain: novel
  priority: P1
  tags:
  - MCP
  - protocol
  - server
  - integration
  - external-editor
version: 1.0.0
when_to_use: 外部编辑器需要调用 novel 域能力时
status: peripheral
tags:
- novel
- MCP
- protocol
domain: novel
category: novel.integration
---

# Novel MCP Server — Model Context Protocol 服务器

> 为外部编辑器/IDE 提供 novel 域 AI 能力接口。基于 Model Context Protocol 实现章节写作、审稿评分、记忆管理、大纲查询、伏笔检查等核心功能。

## 激活条件

- 外部编辑器/IDE 通过 MCP 协议连接
- 用户在外部工具中调用 `/novel-start`、`/novel-outline`、`/novel-continue` 等提示
- MCP 客户端请求 `novel://` 资源

## MCP 协议架构

```
外部编辑器 (MCP Client)
        │
        ▼
┌─────────────────────────────────────┐
│       Novel MCP Server              │
│  (Python + FastMCP / Node.js SDK)   │
├─────────────────────────────────────┤
│  tools/     — 7 个核心工具          │
│  resources/ — 3 类资源 URI          │
│  prompts/   — 3 个提示模板          │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│   Novel Orchestrator / 其他 Skill   │
└─────────────────────────────────────┘
```

## 工具定义 (tools)

### write_chapter

写小说章节。

```json
{
  "name": "write_chapter",
  "description": "写小说章节正文",
  "inputSchema": {
    "type": "object",
    "properties": {
      "book_name": {
        "type": "string",
        "description": "书名，用于定位项目目录"
      },
      "chapter_num": {
        "type": "integer",
        "description": "章节序号，如 1, 2, 3..."
      },
      "title": {
        "type": "string",
        "description": "章节标题"
      },
      "context": {
        "type": "string",
        "description": "上下文摘要（上章结局 + 本章目标），用于 writer 续写"
      }
    },
    "required": ["book_name", "chapter_num", "title", "context"]
  }
}
```

**返回：**
- 成功：章节正文文件路径 + 字数统计
- 失败：错误信息 + 重试建议

**调用链：**
```
write_chapter → novel-orchestrator → novel-writer → humanizer-zh → 章节正文/
```

### review_chapter

审稿评分。

```json
{
  "name": "review_chapter",
  "description": "对章节进行 7 维审稿评分",
  "inputSchema": {
    "type": "object",
    "properties": {
      "chapter_path": {
        "type": "string",
        "description": "章节文件路径（绝对路径或相对于项目根目录）"
      },
      "book_name": {
        "type": "string",
        "description": "书名（用于加载 MEMORY.md 中的上下文）"
      }
    },
    "required": ["chapter_path", "book_name"]
  }
}
```

**返回：**
```json
{
  "chapter": "第3章_觉醒",
  "scores": {
    "plot": 8,
    "character": 7,
    "writing": 6,
    "world": 8,
    "hook": 5,
    "emotion": 7,
    "innovation": 6
  },
  "total": 68.5,
  "verdict": "BLOCK",
  "findings": [
    {
      "level": "Important",
      "trap_id": 8,
      "line": 45,
      "quote": "眼中闪过一丝决然",
      "suggestion": "替换为具体肢体语言"
    }
  ],
  "revision_required": 2
}
```

### get_memory

获取书籍记忆文件。

```json
{
  "name": "get_memory",
  "description": "读取书籍的 MEMORY.md 记忆文件",
  "inputSchema": {
    "type": "object",
    "properties": {
      "book_name": {
        "type": "string",
        "description": "书名"
      }
    },
    "required": ["book_name"]
  }
}
```

**返回：** MEMORY.md 完整内容，包含：
- 人物状态快照
- 伏笔列表及状态
- 章节索引
- 写作进度

### update_memory

更新书籍记忆。

```json
{
  "name": "update_memory",
  "description": "更新书籍的 MEMORY.md 记忆文件",
  "inputSchema": {
    "type": "object",
    "properties": {
      "book_name": {
        "type": "string",
        "description": "书名"
      },
      "updates": {
        "type": "object",
        "description": "更新内容，支持部分字段更新",
        "properties": {
          "character_states": "object — 人物状态变更",
          "foreshadowing_status": "object — 伏笔状态更新",
          "chapter_index": "array — 新增章节索引",
          "notes": "string — 额外备注"
        }
      }
    },
    "required": ["book_name", "updates"]
  }
}
```

### list_books

列出所有书籍项目。

```json
{
  "name": "list_books",
  "description": "列出当前工作目录下的所有书籍项目",
  "inputSchema": {
    "type": "object",
    "properties": {}
  }
}
```

**返回：**
```json
{
  "books": [
    {
      "name": "修仙世界",
      "path": "./books/修仙世界",
      "chapters": 42,
      "last_updated": "2026-07-01",
      "status": "in_progress"
    }
  ]
}
```

### get_outline

获取书籍大纲。

```json
{
  "name": "get_outline",
  "description": "读取书籍大纲文件",
  "inputSchema": {
    "type": "object",
    "properties": {
      "book_name": {
        "type": "string",
        "description": "书名"
      }
    },
    "required": ["book_name"]
  }
}
```

**返回：** 大纲.md 完整内容

### check_foreshadowing

检查伏笔状态。

```json
{
  "name": "check_foreshadowing",
  "description": "检查伏笔埋设与回收状态",
  "inputSchema": {
    "type": "object",
    "properties": {
      "book_name": {
        "type": "string",
        "description": "书名"
      },
      "chapter_num": {
        "type": "integer",
        "description": "当前章节号（可选，用于检查截至该章节的伏笔状态）"
      }
    },
    "required": ["book_name"]
  }
}
```

**返回：**
```json
{
  "book_name": "修仙世界",
  "foreshadows": [
    {
      "id": "fs-001",
      "setup_chapter": 3,
      "setup_text": "主角在山洞发现神秘玉简",
      "status": "unresolved",
      "expect_payoff_chapter": 15,
      "days_remaining": 12
    },
    {
      "id": "fs-002",
      "setup_chapter": 7,
      "setup_text": "配角提及宗门秘闻",
      "status": "resolved",
      "payoff_chapter": 12
    }
  ],
  "summary": {
    "total": 5,
    "resolved": 2,
    "unresolved": 3,
    "overdue": 1
  }
}
```

## 资源定义 (resources)

### novel://books/

书籍列表资源。

```
novel://books/          → 列出所有书籍（JSON 列表）
novel://books/{name}    → 书籍概览（JSON）
novel://books/{name}/memory  → MEMORY.md 内容
novel://books/{name}/outline → 大纲.md 内容
novel://books/{name}/chapters/{n} → 章节 n 内容
```

**URI 模板：**
```
novel://books/
novel://books/{book_name}/memory
novel://books/{book_name}/outline
novel://books/{book_name}/chapters/{chapter_num}
```

**MIME 类型：**
- `novel://books/` → `application/json`
- `novel://books/*/memory` → `text/markdown`
- `novel://books/*/chapters/*` → `text/markdown`

## 提示模板 (prompts)

### /novel-start

开书向导提示。

```
# 新书创建向导

你正在引导用户创建一本新书。请依次询问：

1. **题材选择**：修仙/都市/玄幻/科幻/历史/悬疑/言情/其他
2. **核心设定**：简要描述世界观核心（1-3 句话）
3. **主角定位**：主角身份、性格、目标
4. **风格偏好**：轻松/严肃/黑暗/热血/治愈
5. **篇幅预期**：短篇(<20章)/中篇(20-50章)/长篇(>50章)

收集完毕后，调用 brainstorming skill 生成完整设定文档。
```

### /novel-outline

大纲生成提示。

```
# 大纲生成向导

基于已确认的书籍设定，生成完整大纲：

## 输出要求

1. **卷结构**：按篇幅分卷，每卷 10-15 章
2. **核心冲突**：每卷一个核心冲突
3. **章节安排**：每章 1 句话摘要
4. **伏笔规划**：埋设 5-8 个伏笔，标注预期回收章节
5. **高潮设计**：标注关键高潮点

## 调用链

novel-outline → novel-planner → 大纲.md
```

### /novel-continue

续写当前章节提示。

```
# 续写当前章节

基于 MEMORY.md 中的上下文，续写当前章节：

## 输入
- book_name: 当前书籍名
- chapter_num: 当前章节号
- context: 上章结局摘要 + 本章进度摘要

## 输出
- 继续本章正文（≥1000 字）
- 保持人物声音一致
- 推进情节发展
- 结尾留钩子

## 调用链

novel-continue → novel-writer → 章节正文/
```

## 技术实现

### 目录结构

```
skills/novel-mcp-server/
├── SKILL.md              # 本文档
├── server/
│   ├── __init__.py
│   ├── main.py           # MCP 服务器入口
│   ├── tools.py          # 工具实现
│   ├── resources.py      # 资源定义
│   └── prompts.py        # 提示模板
├── requirements.txt
└── README.md
```

### 依赖

```
# requirements.txt
fastmcp>=0.1.0          # FastMCP 框架
pydantic>=2.0           # 数据验证
pathlib>=1.0            # 路径处理
```

### 启动方式

```bash
# 方式 1：直接运行
python -m novel_mcp_server

# 方式 2：通过 MCP Inspector 测试
npx @modelcontextprotocol/inspector python server/main.py

# 方式 3：配置到 Claude Code / Cursor
# 在 IDE 的 MCP 配置中添加：
{
  "mcpServers": {
    "novel": {
      "command": "python",
      "args": ["/path/to/novel-mcp-server/server/main.py"]
    }
  }
}
```

## 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `WORKSPACE_ROOT` | `./novels` | 书籍根目录 |
| `MEMORY_FILE` | `MEMORY.md` | 记忆文件名 |
| `OUTLINE_FILE` | `大纲.md` | 大纲文件名 |
| `CHAPTER_DIR` | `章节正文` | 章节目录 |
| `MAX_CHAPTERS_PARALLEL` | 3 | 最大并行写章节数 |

## 错误处理

| 错误码 | 含义 | 处理 |
|--------|------|------|
| `BOOK_NOT_FOUND` | 书籍不存在 | 返回书籍列表，提示创建 |
| `CHAPTER_NOT_FOUND` | 章节不存在 | 返回可用章节列表 |
| `MEMORY_CORRUPTED` | 记忆文件损坏 | 尝试重建，警告可能丢失状态 |
| `OUTLINE_MISSING` | 大纲缺失 | 提示先生成大纲 |

## 安全约束

- 只读写 `WORKSPACE_ROOT` 下的文件
- 不执行任意命令
- 不读取项目目录外的文件
- MCP 请求有超时限制（默认 60s）

## 依赖

- `skills/novel-orchestrator/SKILL.md` — 核心编排器
- `skills/novel-evaluator/SKILL.md` — 审稿评分
- `skills/novel-foreshadowing-dag/SKILL.md` — 伏笔管理
- `agents/novel-writer.md` — 写作 Agent
- `agents/novel-reviewer.md` — 审稿 Agent
- `traps-archive/novel/00-all.md` — 小说域陷阱