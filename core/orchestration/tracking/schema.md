---
name: tracking-schema
description: "执行追踪数据格式，code / novel / news 域共用。"
tags: [Orchestration, Schema]
---

# 追踪数据 Schema

状态保存在仓库文件中，**不**依赖上下文窗口。

## 文件层级

| 文件 | 用途 | 写入者 |
| --- | --- | --- |
| `DISPATCH-TRACK-<YYYY-MM-DD>-<topic>.md` | 并行 WU 逐步追踪 | Leader |
| `CHECKLIST-<topic>-WU-<id>.md` | 单 WU done criteria | Leader 创建 |
| `../HANDOFF.md` | 上下文重置检查点（覆盖写） | Leader |
| `../PROGRESS.md` | 周期级紧凑摘要（可选） | Leader |

---

## 执行日志格式

每条追踪**追加**到文件末尾，**禁止**改删历史行：

```text
[YYYY-MM-DD HH:MM] <PHASE>-<STEP> | <AGENT> | Status: <started|completed|blocked|recovering>
Detail: <事实一句>
Sub-agents: <活跃 Task 数>
Context: ~<XX>%
Output: <产物路径或 none>
Error: <错误或 none>
Next: <下一步>
```

| 字段 | 说明 |
| --- | --- |
| PHASE-STEP | 如 `DISPATCH-GROUP-1`、`WU-02-implement` |
| AGENT | `Leader` / `Writer` / `Reviewer` / `Humanizer` / `Editor` / `Implementer` / `Debugger` |
| Status | started → completed；blocked 需人工或 Leader 决策 |

## DISPATCH 专用字段

并行编排时在 Detail 后可选追加：

```text
GROUP: <N> | WU: <id> | ITER: <n> | STEP: <step_name>
Domain: code|novel|news
Tests: <测试通过或字数统计>
Queue-remaining: WU-03, WU-04
Reviewer: separate-task | pending
Title(zh): <wu_title_zh>
Worktree: <path or n/a> | Branch: <name or n/a>
```

---

## YAML 执行记录格式（用于阶段门禁 & 状态导出）

```yaml
timestamp: 2026-06-24T10:30:00Z
domain: novel
intent: novel:write
route: code|novel|news
agents:
  - name: writer
    status: success|failed|retried
    output: path/to/output.md
skills:
  - name: junli-ai-novel
    status: loaded|skipped
stage_gates:
  - name: planning
    confirmed: true
  - name: implementation
    confirmed: true
```

## 内存状态格式

```json
{
  "domain": "novel",
  "current_book": "我的小说",
  "last_chapter": 3,
  "last_updated": "2026-06-24",
  "pending_tasks": ["第4章", "审稿第1-3章"]
}
```

---

## 中断恢复协议

1. 打开当前 `DISPATCH-TRACK-*.md`
2. 找最后一条 `Status: completed` 的 WU/步骤
3. 对无 `completed` 的 WU，从其最后 `started` 步骤继续
4. 若存在 `HANDOFF.md` 且比 track 新 → 先读 HANDOFF 再恢复
5. **不要**重跑已有确认的 WU

### Leader 恢复话术

```text
从 DISPATCH-TRACK-<file> 恢复：最后完成 WU-<id>。
继续 GROUP-<n> 中 WU-<id> 的 <step>。
```

---

## 与 execution-log 关系

- **tracking/**：过程逐步日志（可很长，append-only）
- **execution-log**：任务收尾摘要（front matter + 变更列表 + 验证状态）

完成编排后，execution-log 的 `source` 应引用对应 `DISPATCH-TRACK-*.md`。
