---
name: multi-leader-protocol
description: "多平台协作协议：多个 AI IDE 同时工作时如何避免文件冲突。"
tags: [Standard]
---

# 多 Leader 协作协议
>
> 当多个平台（Cursor/Trae/Claude Code）同时在同一项目上工作时使用。

## 启动

每个 Leader 新会话启动时：
1. Read `.ai-runtime-artifacts/memory/state.json`
2. 检查 `active_platforms` — 了解其他平台在做什么
3. 检查 `active_wus` — 避免文件冲突

## 注册

在 state.json 的 `active_platforms` 中注册自己：

```json
{
  "platform_id": "claude-canvas",
  "platform_type": "claude",
  "module": "canvas",
  "files": ["ruoyi-modules/ruoyi-aigc/src/main/java/org/xywh/aigc/canvas/**"],
  "started_at": "2026-06-17T10:30:00+08:00"
}
```

## WU 派发前检查

派发 WU 前：
1. 检查 `active_wus`：已有 WU 覆盖的文件**不得再派新 WU**
2. 派发后立即在 `active_wus` 中追加记录
3. WU 完成后更新其 `status` 为 `completed`

## 冲突避免

- **模块级隔离：** 每个平台只在自己的 `module` 范围内派兵
- **公共文件：** `ruoyi-common/` 下的文件由第一个声明的 Leader 负责，其他平台需要改时在 state.json 里留 note
- **冲突检测：** 派发前检查 `active_wus[].files` 是否有交集

## 结束

- 本平台分配的 WU 全部完成后：从 `active_platforms` 中移除自己
- 有未完成的 WU：标记为 `handoff`，在 `context_summary` 中记录上下文
- 更新 `last_updated` 时间戳

## 恢复

新会话启动时，如果 state.json 显示 `active_phase != "idle"` 且有未完成的 WU：
1. 先问用户：继续上次的、还是新任务？
2. 如果继续：读 `approved_plan`、检查 `active_wus` 状态、恢复上下文
