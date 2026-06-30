---
name: local-provider
description: "本地执行环境 Provider — 零开销，直接在当前工作目录执行"
tags: [Standard, Provider]
---

# Local Provider

## 概述

最简单的 Provider，无任何隔离开销。Agent 直接在项目当前工作目录下执行。适用于不需要文件系统隔离的场景。

**参考**：OpenAI Agents SDK — `Sandbox: none` 模式

## 适用场景

- novel 域：章节写作、大纲规划、审稿评分的所有角色
- news 域：稿件写作、事实核查、热点追踪的所有角色
- code 域的只读角色：reviewer、explorer、web-investigator（isolation_level: partial）
- 小改动（无需隔离的 bug fix、配置修改）

## 不适用场景

- code 域的编译/测试（需 worktree provider 隔离）
- 不可信代码执行（需 docker provider 隔离）
- 多 Agent 同时修改同一文件集（需 worktree provider 避免冲突）

## Provision 实现

```bash
# Local provider 的 Provision 是零操作
# 直接返回当前 cwd 作为 bindings
echo "{
  \"id\": \"local-${DOMAIN}-$(date +%s)\",
  \"provider\": \"local\",
  \"bindings\": {
    \"cwd\": \"$(pwd)\"
  }
}"
```

## Activate 实现

无需操作 — 当前 shell 已在正确的 cwd。

## Deactivate 实现

无需操作 — 没有需要恢复的上下文。

## Destroy 实现

无需操作 — 没有需要清理的资源。

## HealthCheck 实现

```bash
# 仅检查当前目录是否可读写
test -r "$(pwd)" && test -w "$(pwd)" || echo "UNHEALTHY: current directory not readable/writable"
```

## 平台兼容性

| 平台 | 状态 | 备注 |
|------|------|------|
| 全部 | ✅ supported | 无任何平台依赖 |

## 安全注意事项

由于 local provider 没有任何隔离：
- Agent 的 `Write/Edit` 操作直接影响主工作区文件
- Leader 在派发前应确认 WU 文件集无冲突
- 建议与 Guardrail output 层配合，阻止危险操作写入主分支
- 多 Agent 并行时需通过 `multi-leader-protocol.md` 协调文件访问
