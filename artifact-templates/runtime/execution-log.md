---
artifact: execution-log
topic: <topic>
platform: claude
date: YYYY-MM-DD
status: in-progress
---

# Execution Log — <topic>

> 执行摘要。完成编排后 `status: completed`。
> 对应 `harness-foundry/core/orchestration/dispatcher-workflow.md`。

---

## 任务概述

- **topic**: <topic>
- **platform**: claude
- **date**: YYYY-MM-DD
- **routing**: <route>

---

## 执行图摘要

| GROUP | WU | agent_role | wu_type | Status |
|-------|----|-----------|---------|--------|
| 1 | WU-01 | coder | feature | done |
| 1 | WU-02 | coder | feature | done |
| 2 | WU-03 | implementer | chore | done |

---

## 尾盘

### A 集体测试

- 状态: **PASS** | FAIL
- 产物: `.ai-runtime-artifacts/verifications/YYYY-MM-DD-<topic>-collective-test.md`
- 命令: `mvn compile -q && mvn test -q`

### B 集体审查

- 状态: **APPROVE** | BLOCK | SKIPPED
- 产物: `.ai-runtime-artifacts/reviews/YYYY-MM-DD-<topic>-code-review.md`

---

## 变更文件

```
<file1> — <说明>
<file2> — <说明>
```

---

## 追踪文件

- `DISPATCH-TRACK-YYYY-MM-DD-<topic>.md`

---

## 完成状态

**status**: in-progress | **completed**

---

## Next

- completed → 通知用户、提示 git 操作
- BLOCK → 修复后重新审查