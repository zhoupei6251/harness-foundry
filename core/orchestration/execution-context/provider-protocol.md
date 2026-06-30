---
name: execution-context-provider-protocol
description: "执行环境 Provider 抽象协议 — 参考 OpenAI Agents SDK 2026 Harness/Compute 分离架构"
tags: [Standard, Protocol]
---

# 执行环境 Provider 协议

## 设计原则

1. **Provider 无关**：core 层只依赖本 Protocol，不引用具体 Provider 实现
2. **最小契约**：每个操作定义明确的输入/输出和错误签名
3. **平台映射**：`adapters/*` 将 Protocol 映射到各平台原生能力
4. **向后兼容**：Provider 不可用时降级为 `local` provider

## 操作定义

### 1. Provision — 创建执行环境

- **前置条件**：domain-config 已加载，WU 列表已确定
- **输入**：`ExecutionContextSpec` { domain, cwd, isolation_level, wu_files[] }
- **输出**：`ExecutionContext` { id, provider, state, bindings, lifecycle }
- **副作用**：
  - worktree provider: `git worktree add` → 新分支
  - local provider: 无（返回当前 cwd）
  - docker provider: `docker run -d` → 容器 ID
- **错误**：
  - `ProvisionTimeoutError` — 创建超时（默认 30s）
  - `ResourceExhaustedError` — 磁盘/内存不足
  - `ProviderUnavailableError` — Provider 不可用 → 降级为 local

### 2. Activate — 激活执行环境

- **前置条件**：state = `provisioning` 且 provision 成功
- **输入**：`ExecutionContext`
- **输出**：void，ctx.state → `active`
- **副作用**：
  - worktree provider: 切换 shell cwd 到 worktree 路径
  - local provider: 无（已在正确 cwd）
  - docker provider: `docker exec` 就绪
- **注意**：Activate 后所有后续操作在 ctx.bindings.cwd 下执行

### 3. Deactivate — 停用执行环境

- **前置条件**：state = `active`
- **输入**：`ExecutionContext`
- **输出**：void，ctx.state → `deactivating`
- **副作用**：
  - worktree provider: 恢复原始 cwd
  - docker provider: 退出容器 shell
- **注意**：Deactivate 后 ctx 不可再用于执行，只能 Destroy 或 HealthCheck

### 4. Destroy — 销毁执行环境

- **前置条件**：state = `deactivating`
- **输入**：`ExecutionContext`
- **输出**：void，ctx.state → `closed`
- **副作用**：
  - worktree provider: `git worktree remove --force` + 分支清理
  - local provider: 无
  - docker provider: `docker rm -f`
- **错误**：
  - `DestroyTimeoutError` — 销毁超时（默认 10s），记录 warning 但标记 closed
- **注意**：Destroy 失败不应阻断主流程，记录 warning 即可

### 5. HealthCheck — 健康检查

- **前置条件**：ctx 已创建（任意非 error 状态）
- **输入**：`ExecutionContext`
- **输出**：`HealthStatus` { healthy: bool, message: string, details: map }
- **用途**：
  - 派发 WU 前快速验证环境可用
  - 长时间任务中定期检查（每 5 分钟）
  - 异常恢复时判断是否需要重新 Provision

## 平台映射速查

| Provider | Claude Code | Cursor | Trae | Codex | MimoCode |
|----------|-------------|--------|------|-------|----------|
| worktree | `git worktree` 脚本 | `git worktree` 脚本 | ❌ 不支持 | degraded (手动) | ❌ 不支持 |
| local | 默认 cwd | 默认 cwd | ✅ | ✅ | ✅ |
| docker | stub | stub | ❌ | ❌ | ❌ |

## 降级策略

```
worktree 不可用 → 降级为 local (isolation_level: partial)
   ↓
local 也不可用 → 报错，要求用户手动设置 cwd

docker 不可用 → 降级为 local (isolation_level: partial)
   ↓
需 full 隔离但无 provider → 警告用户，仍用 local 执行
```

## 与 dispatcher-workflow 的集成点

1. **步骤 0.5（环境初始化）**：读取 domain-config → 选择 provider → Provision → Activate
2. **步骤 2（派发 WU）**：每个 Worker 的 cwd 设为 ctx.bindings.cwd
3. **步骤 5（环境关闭）**：Deactivate → Destroy → 记录 tracking
