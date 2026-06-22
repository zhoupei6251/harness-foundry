---
artifact: handoff
date: YYYY-MM-DD
topic: <topic>
context_version: <n>
---

# HANDOFF — <topic>

> 上下文重置检查点。覆盖写。Leader 在派发前创建，恢复时读。
> 规范：`harness-kit/core/orchestration/tracking/schema.md` § 中断恢复协议。

---

## 当前状态

- **批次**: <topic>
- **日期**: YYYY-MM-DD
- **执行图**: `.ai-runtime-artifacts/plans/<date>-<topic>-dispatch.md`
- **追踪文件**: `.ai-runtime-artifacts/execution-logs/tracking/DISPATCH-TRACK-<date>-<topic>.md`
- **已完成 WU**: WU-01, WU-02
- **进行中 WU**: WU-03
- **待处理 WU**: WU-04

---

## Git 沙箱

- **worktree_path**: <abs-path>
- **branch**: harness/wt-<stem>
- **base_ref**: <SHA>

---

## 恢复指令

从 DISPATCH-TRACK 文件恢复：找到最后 `Status: completed` 的 WU。
对无 `completed` 的 WU，从其最后 `started` 步骤继续。

```
[恢复话术]
从 DISPATCH-TRACK-<file> 恢复：最后完成 WU-<id>。
继续 GROUP-<n> 中 WU-<id> 的 <step>。
```

---

## 关键上下文（精简）

- plan 批准时间: YYYY-MM-DD
- 关键依赖: WU-01 → WU-03（WU-03 依赖 WU-01 完成）
- 验证命令: `mvn compile -q`

---

## 降级记录

- `capability orchestration.continuous-loop: manual（HANDOFF 人工衔接）`
- `capability interaction.structured-ask: degraded（无 AskQuestion 工具）`