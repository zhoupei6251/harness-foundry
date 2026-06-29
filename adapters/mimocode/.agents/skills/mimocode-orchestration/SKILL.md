---
name: mimocode-orchestration
description: MiMo Code 多 actor 并行编排，等价 omx ultrawork。已批准 plan +「开始实现」后并行派发 WU。触发：并行实现、多 task、开始实现、mimocode 编排。
---

# MiMo Code Orchestration

**前置：** 已批准 plan；用户说「开始实现」。未批准不得激活。

**平台：** MiMo Code（Codex → omx；Cursor → cursor-orchestration；Claude → claude-orchestration）。

## 激活后

1. 声明 `「Harness：mimocode-orchestration:dispatcher-workflow」`
2. Read **`harness-foundry/core/orchestration/dispatcher-workflow.md`**（唯一步骤源）
3. Read `tracking/schema.md`、已批准 plan、`project.verification.md`
4. 将委派写代码 WU：**WORKTREE-INIT** → 并行 actor

## SpawnWorker（MiMo Code）

| agent_role | actor |
| --- | --- |
| coder / implementer / test-engineer / debugger / web-investigator | `generalPurpose` + `agents/<role>.md` |
| reviewer | 新 actor + readonly |
| explorer | `explore` 或 readonly actor |

**并行：** 同 GROUP 文件不相交；≤3（硬顶 5）；不传 Leader 全历史。

**Prompt 必含：** WU id、wu_type、agent_role、文件列表、禁止项、done criteria、Skills 路径、worktree_path（沙箱）、返回格式（`wu_status`、`### Skills 使用`）。

**尾盘：** collective-test → actor reviewer → Leader 落盘 code-review → execution-log。

## 禁止

- 未过 plan 门禁实现；Leader 写业务代码（小改动除外）
- 实现与审查同 actor 实例；跳过 DISPATCH-TRACK / 尾盘产物
- 末 WU 返回即声称完成；Leader 自动 push

绑定详情：`harness-foundry/adapters/mimocode/bindings.md`
