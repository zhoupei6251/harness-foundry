# Intelligence Layer 用户指南

> Harness Foundry 智能代码理解能力使用指南

## 概述

Intelligence Layer 为 Harness Foundry 提供智能代码理解能力，由两个层次组成：

| 层次 | 工具 | 回答什么 | 使用时机 |
|------|------|---------|---------|
| **战略层** | Understand-Anything | 项目是什么/为什么这样设计 | 新项目、架构分析 |
| **战术层** | CodeGraph | 符号在哪里/改动会影响谁 | 定位代码、评估影响 |

## 快速开始

### 一键安装

```bash
# Linux/macOS
bash scripts/install-intelligence-deps.sh

# Windows PowerShell
.\scripts\install-intelligence-deps.ps1
```

脚本会自动：
1. 检查 Node.js 版本
2. 安装 CodeGraph
3. 提示 Understand-Anything 安装方法

### 手动安装（可选）

#### CodeGraph（必须）

```bash
npm install -g @colbymchenry/codegraph
```

#### Understand-Anything（可选，需要 MCP 支持的 IDE）

Understand-Anything 是高级项目理解工具，支持自然语言问答和多智能体协同分析。

**安装步骤：**

```bash
# 1. 克隆源码
git clone https://github.com/Understand-Anything/understand-anything.git
cd understand-anything

# 2. 安装依赖
pnpm install

# 3. 构建
pnpm --filter @understand-anything/core build
pnpm --filter @understand-anything/skill build

# 4. 配置 IDE 的 MCP
# 见下方「IDE MCP 配置」章节
```

详细说明见: https://github.com/Understand-Anything/understand-anything

### 初始化项目索引

```bash
cd your-project

# 初始化 CodeGraph
codegraph init

# 建立索引
codegraph index
```

### 开始使用

在 Harness Foundry 中，按需调用 Skills：

```
# 理解项目结构
/understand-project

# 分析架构
/analyze-architecture

# 定位代码
/query-symbol

# 评估影响
/analyze-impact
```

## Skills 详解

### 战略层 Skills

#### /understand-project

理解项目结构和架构，生成知识图谱。

**触发场景**：
- 新项目接手
- 需要了解项目全局
- 询问架构设计

**示例**：
```
用户: 帮我理解这个项目
AI:   [调用 /understand-project]
      ↓
      项目概述：三层架构的电商系统
      技术栈：Spring Boot, MyBatis-Plus, Redis
      核心模块：用户、订单、商品、支付
```

#### /analyze-architecture

深入分析架构，回答架构相关问题。

**触发场景**：
- 询问设计原因
- 技术选型
- 模块职责

**示例**：
```
用户: 为什么要用 Redis 做缓存？
AI:   [调用 /analyze-architecture]
      ↓
      1. 分布式场景需要
         证据: spring.session.store-type: redis
      2. 数据一致性要求
         证据: CacheConfig.java
```

### 战术层 Skills

#### /index-project

为项目建立代码索引。

**触发场景**：
- 大型项目 (>100 文件)
- 需要精准定位
- 快速查找调用关系

**示例**：
```
用户: 帮我索引这个项目
AI:   [调用 /index-project]
      ↓
      已解析 1,234 个文件
      已提取 5,678 个符号
      索引完成 ✓
```

#### /query-symbol

快速定位代码符号。

**触发场景**：
- 查找某个类/函数
- 不知道在哪里
- 查询定义

**示例**：
```
用户: UserService 在哪里？
AI:   [调用 /query-symbol]
      ↓
      找到 1 个结果:
      └─ UserService
         位置: src/service/UserService.java:15
```

#### /get-callers

查找调用指定符号的所有代码。

**触发场景**：
- 评估影响
- 分析依赖
- 回归测试

**示例**：
```
用户: getOrderById 被谁调用了？
AI:   [调用 /get-callers]
      ↓
      ├─ OrderController.getOrder() [line 34]
      ├─ OrderService.findById() [line 67]
      └─ OrderCacheService.get() [line 12]
```

#### /analyze-impact

评估代码变更的完整影响范围。

**触发场景**：
- 重构前
- 修改核心方法
- 批量修改

**示例**：
```
用户: 我想重构 UserService.login，帮我评估影响
AI:   [调用 /analyze-impact]
      ↓
      风险等级: 中等
      影响: 2 个调用方，3 个被调用方
      测试覆盖: 2 个测试文件
```

## 配合工作流

### 新项目接手

```
1. /understand-project     → 获取项目全局理解
2. /analyze-architecture  → 深入了解架构
3. /index-project         → 建立索引
```

### Bug 定位

```
1. /query-symbol          → 定位问题代码
2. /get-callers           → 追踪调用链
3. /analyze-impact        → 评估修复影响
```

### 重构

```
1. /understand-project     → 理解模块结构
2. /analyze-impact        → 评估重构影响
3. /get-callers           → 识别所有调用方
4. /get-callees           → 分析内部依赖
```

### Code Review

```
1. /analyze-impact        → 评估变更范围
2. /query-symbol          → 快速定位代码
```

## 性能指标

| 指标 | 目标 | 实际 |
|------|------|------|
| 项目理解 (10万行) | < 10 分钟 | — |
| 索引建立 (10万行) | < 5 分钟 | — |
| 符号查询 | < 100ms | — |
| Token 节省 | >= 30% | — |

## 常见问题

### Q: 索引很慢怎么办？

A: 对于大型项目，可以先索引核心模块：

```bash
codegraph index --paths src/main/java
```

### Q: 索引占用空间大？

A: 索引存储在 `.codegraph/` 目录，可以添加到 `.gitignore`：

```bash
echo ".codegraph/" >> .gitignore
```

### Q: 如何更新索引？

```bash
# 增量更新
codegraph sync

# 全量重建
codegraph index --force
```

## IDE MCP 配置

### Claude Code

在 `~/.claude/settings.json` 中添加：

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "npx",
      "args": ["-y", "@colbymchenry/codegraph", "serve", "--mcp"]
    }
  }
}
```

### Cursor

在 `.cursor/mcp.json` 中添加：

```json
{
  "mcpServers": {
    "codegraph": {
      "command": "npx",
      "args": ["-y", "@colbymchenry/codegraph", "serve", "--mcp"]
    }
  }
}
```

### 配置说明

- MCP 服务器启动后会自动与 IDE 连接
- CodeGraph 的 MCP 会读取项目中的 `.codegraph/` 目录
- 详见配置模板: `mcp-config/CodeGraph.json`

## 常见问题

### Q: CodeGraph MCP 连接失败？

A: 确保已安装 CodeGraph 并运行：

```bash
# 检查安装
codegraph --version

# 启动 MCP 服务器
codegraph serve --mcp
```

### Q: 索引很慢怎么办？

A: 对于大型项目，可以先索引核心模块：

```bash
codegraph index --paths src/main/java
```

### Q: 索引占用空间大？

A: 索引存储在 `.codegraph/` 目录，可以添加到 `.gitignore`：

```bash
echo ".codegraph/" >> .gitignore
```

### Q: 如何更新索引？

```bash
# 增量更新
codegraph sync

# 全量重建
codegraph index --force
```

## 后续步骤

- 查看完整设计文档: `docs/plans/2026-06-30-intelligence-layer-integration-design.md`
- 查看多智能体设计: `core/intelligence/strategic/multi-agent-design.md`
- 查看 MCP 配置: `mcp-config/`
