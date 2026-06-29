---
name: novel-orchestrator
description: 小说创作总控调度器，协调 writer→planner→reviewer→humanizer→editor→memory-keeper 全链路
metadata:
  origin: harness-ink
  priority: P0
  tags:
  - orchestration
  - dispatcher
  - workflow
version: 1.0.0
when_to_use: 调用 novel-orchestrator 时
status: peripheral
tags:
- shared
domain: novel
category: novel.creation
---
# 小说编排器

## 激活条件

- 用户要求连续写多章（"写第28到30章"）
- 批量审稿（"审稿第1-5章"）
- 多章并行创作任务

## 核心能力

### 任务拆分
- 将多章写作拆分为独立 WU（Work Unit）
- 识别章节依赖关系（续写依赖必须串行）
- 构建执行图（GROUP-1 到 GROUP-4）

### 并行调度
- GROUP-1：并行 writer 写多章（≤5 并行）
- GROUP-2：串行 reviewer 逐章审稿
- GROUP-3：串行 humanizer 逐章润色
- GROUP-4：串行 editor 跨章统稿
- 尾盘：memory-keeper 同步记忆

### 质量门禁
- 审稿不通过 → 返修给 writer（最多 2 次）
- 2 次返修仍不通过 → 提示用户介入
- 润色后更新章节状态（reviewed → polished）

## 工作流程

1. **读记忆 + 注册平台**
   - 读取 `.harness-novel-runtime/memory/state.json`
   - 检查 `active_wus` 冲突
   - 注册当前平台

2. **构建执行图**
   - 从计划提取 WU
   - 识别依赖关系
   - 分配 agent_role 和 wu_skills

3. **并行派发**
   - GROUP-1：SpawnWorker(writer) 并行写章
   - GROUP-2：SpawnWorker(reviewer) 串行审稿
   - GROUP-3：SpawnWorker(humanizer) 串行润色
   - GROUP-4：SpawnWorker(editor) 串行统稿

4. **记忆写回**
   - SpawnWorker(memory-keeper) 同步记忆
   - 更新 `state.json` 和 `MEMORY.md`

## 禁止事项

- ❌ 章节有续写依赖却并行
- ❌ 未读记忆派发
- ❌ 单 worker 包整个多章
- ❌ 实现与审查同实例
- ❌ Leader 自动 commit

## 产物

- 章节正文文件
- `.harness-novel-runtime/execution-logs/` 执行日志
- `tracking/DISPATCH-TRACK-<date>.md` 追踪文件

## 依赖

- `core/orchestration/dispatcher-workflow.md`：调度工作流
- `agents/*.md`：8 角色定义
- `adapters/<platform>/bindings.md`：平台绑定
