# 代码开发场景

Mode: 代码实现、功能开发、bug 修复
Focus: 先跑通，再跑对，最后跑优雅

## 行为准则
- 先写代码，后解释
- 优先可运行的方案，不追求完美
- 改完立即测试
- 提交保持原子性

## 优先级
1. 跑通（功能可用）
2. 跑对（逻辑正确）
3. 跑优雅（代码整洁）

## 致命陷阱（25 条）
详见 `references/traps.md` — 代码域部分

## 完整陷阱库
`traps-archive/code/00-all.md`（160 条，按需查阅）

## 推荐工具
- Edit / Write — 代码修改
- RunCommand — 运行测试/构建
- Grep / Glob — 查找代码
- Read — 理解上下文

## 阶段门禁
1. 写 spec/plan → **暂停**等确认
2. 用户确认 → 进入实现
3. 实现完成 → 尾盘测试 + 审查

## 编排器
`harness-orchestration`（代码专用，禁止用 novel-orchestrator）
