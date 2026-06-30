---
name: execution-context-lifecycle
description: "执行环境生命周期管理 — 状态机 + 超时策略 + 异常恢复"
tags: [Standard, Runbook]
---

# Execution Context 生命周期管理

## 状态机

```
                    ┌──────────┐
                    │  pending  │
                    └─────┬────┘
                          │ provision()
                          ▼
                    ┌──────────────┐
              ┌─────│ provisioning │─────┐
              │     └──────────────┘     │
              │ provision 失败           │ 超时
              ▼                          ▼
        ┌───────┐                  ┌───────┐
        │ error │                  │ error │
        └───────┘                  └───────┘
              │
              │ provision 成功
              ▼
        ┌──────────┐
        │  active  │◄──────────── activate()
        └─────┬────┘
              │
              │ deactivate()
              ▼
        ┌──────────────┐
        │ deactivating │
        └──────┬───────┘
               │
               │ destroy()
               ▼
        ┌──────────┐
        │  closed  │
        └──────────┘
```

## 状态转换规则

| 当前状态 | 允许操作 | 目标状态 |
|---------|---------|---------|
| `pending` | `provision()` | `provisioning` |
| `provisioning` | 成功 → `activate()` | `active` |
| `provisioning` | 失败/超时 | `error` |
| `active` | `deactivate()` | `deactivating` |
| `active` | `health()` 定期检查 | `active` (不变) |
| `deactivating` | `destroy()` | `closed` |
| `error` | `retry()` 重新 provision | `provisioning` |
| `closed` | 无（终态） | — |

## 超时策略

| 阶段 | 默认超时 | 可配置 | 超时后动作 |
|------|---------|--------|-----------|
| Provision | 30s | ✅ | 重试 1 次 → 降级为 local |
| Activate | 5s | ❌ | 报错 |
| HealthCheck | 3s | ❌ | 返回 unhealthy |
| Deactivate | 10s | ❌ | 强制继续（记录 warning） |
| Destroy | 10s | ✅ | 强制标记 closed（记录 warning） |
| 总生命周期 | 60min | ✅ | 自动 Deactivate → Destroy |

## 异常恢复

### 场景 1：Provision 超时
```
1. 记录 warning: "worktree provision timeout (30s)"
2. 重试 1 次（仅 worktree provider）
3. 仍超时 → 降级为 local provider
4. tracking 记录: "Provider degraded: worktree → local"
```

### 场景 2：执行中 ctx 不可用
```
1. HealthCheck 返回 unhealthy
2. 如果 WU 未完成 → 标记 WU status = blocked
3. Leader 决定：重新 Provision → 重新派发 WU
4. 旧 ctx → force Destroy
```

### 场景 3：Destroy 失败
```
1. 记录 warning: "worktree destroy failed"
2. 保留 worktree 目录（不强制删除）
3. tracking 记录路径，下次会话由 Leader 手动清理
4. ctx 仍标记为 closed（逻辑上已关闭）
```

### 场景 4：生命周期过期
```
1. ctx.active 状态超 max_lifetime_seconds
2. 如果 WU 仍在执行 → 发 warning 通知 Leader
3. Leader 决定：延长生命周期 / 中断 WU / 等待完成
4. 默认行为：等待当前 WU 完成后立即 Destroy
```

## 监控指标

每个 ctx 在生命周期内应记录：
- `provision_duration_ms` — 创建耗时
- `active_duration_ms` — 活跃时长
- `wu_count` — 在该 ctx 中执行的 WU 数量
- `health_check_count` — 健康检查次数
- `health_failure_count` — 健康检查失败次数
- `destroy_duration_ms` — 销毁耗时

## 与 multi-leader-protocol 的协调

多个 Leader 同时创建 ctx 时：
1. 每个 Leader 在 state.json 的 `active_platforms` 中注册自己的 ctx
2. worktree 路径命名包含 platform_id，避免冲突
3. ctx 文件集不相交检查 — 与 WU 文件集冲突检测共用逻辑
