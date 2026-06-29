---
artifact: dispatch-track
date: YYYY-MM-DD
topic: <topic>
platform: claude
---

# DISPATCH-TRACK — <topic>

> Append-only。禁止改删历史行。
> 格式规范：`harness-foundry/core/orchestration/tracking/schema.md`

---

## 元信息

- **批次**: <topic>
- **日期**: YYYY-MM-DD
- **平台**: claude
- **worktree**: <path 或 n/a>

---

## 追踪记录

<!-- 追加记录，勿改历史 -->

```
[YYYY-MM-DD HH:MM] DISPATCH-GROUP-1 | Leader | Status: started
Detail: 开始 GROUP-1 派发
Sub-agents: 0
Context: ~XX%
Output: none
Error: none
Next: 派发 WU-01, WU-02
```

---

## WU 状态

| WU | agent_role | Status | head_sha | 备注 |
|----|-----------|--------|---------|------|
| WU-01 | coder | pending | — | |
| WU-02 | coder | pending | — | |

---

## 尾盘状态

- collective-test: pending
- code-review: pending
- execution-log: in-progress