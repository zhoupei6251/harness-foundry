---
name: memory-manager
description: 长期记忆管理，双轨记忆架构（全局记忆+单书记忆），跨会话恢复协议
metadata:
  origin: harness-ink
  priority: P0
  tags:
  - memory
  - state
  - persistence
version: 1.0.0
when_to_use: 调用 memory-manager 时
status: peripheral
tags:
- shared
domain: code
category: code.architecture
---
# 长期记忆管理

## 激活条件

- 会话开始（"接着写"、"上次写到哪"）
- 会话结束（"今天就到这"、"保存进度"）
- 写章后更新记忆
- 审稿/润色后更新状态

## 核心能力

### 双轨记忆架构

#### 全局记忆：`~/.claude/GLOBAL-MEMORY.md`
- 用户写作偏好
- 各书进度索引
- 跨书共享信息

#### 单书记忆：`MEMORY.md`（每本书根目录）
- 本书基础设定
- 人物状态追踪
- 伏笔追踪
- 章节索引+一句话摘要
- 进行中工作
- 阻塞项
- 最后更新时间

### 跨会话恢复协议

用户说"接着写"时：
1. 读全局记忆 → 找到当前书
2. 读单书 MEMORY.md → 拿到 current_chapter、最后摘要、人物状态、伏笔
3. 把关键信息压缩到 500 token 内，喂给 writer
4. writer 直接从上一章结尾续写

### 记忆同步

- 写章后：更新 chapter_index、人物状态、伏笔状态
- 审稿后：更新章节状态（draft → reviewed）
- 润色后：更新章节状态（reviewed → polished）
- 会话结束：压缩记忆、更新 in_progress、写回全局索引

## 工作流程

1. **会话开始**
   - 读全局记忆
   - 读单书 MEMORY.md
   - 3 句话概括进度

2. **会话过程中**
   - 写章后更新记忆
   - 审稿/润色后更新状态
   - 增量更新（不整文件重写）

3. **会话结束**
   - 审计本次成果
   - 压缩已完成条目
   - 更新元数据
   - 写回 MEMORY.md

## 禁止事项

- ❌ 跳过记忆读取直接工作
- ❌ 不更新记忆直接交付
- ❌ 整文件无意义重写
- ❌ 在记忆文件中写入敏感信息

## 产物

- 更新后的 `MEMORY.md`
- 更新后的 `~/.claude/GLOBAL-MEMORY.md`

## 依赖

- `agents/memory-keeper.md`：记忆管理员角色定义
