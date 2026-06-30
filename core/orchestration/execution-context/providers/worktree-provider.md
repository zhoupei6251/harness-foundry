---
name: worktree-provider
description: "Git worktree 执行环境 Provider — 为 code 域提供编译/测试隔离沙箱"
tags: [Standard, Provider]
---

# Worktree Provider

## 概述

基于 `git worktree` 的隔离执行环境。每个 worktree 是一个独立的 git 分支 + 独立文件系统，Agent 在 worktree 内的操作不会影响主工作区。WU 完成后 Leader 可选择 merge 结果回主分支，或丢弃 worktree。

**参考**：OpenAI Agents SDK Sandbox 概念 + ECC 的 Git Worktree Isolation Design

## 适用场景

- code 域 WU 执行（编译、测试、代码修改）
- 需要文件系统隔离但不想引入 Docker 的场景
- 多 Agent 并行修改不同文件集时避免冲突

## 不适用场景

- novel 域（主 checkout 直接写章节文件，不需要 worktree 开销）
- news 域（同上）
- 只需只读访问的 reviewer/explorer 角色

## Provision 实现

### 前置检查
1. 确认 git 仓库状态干净（无未暂存变更冲突）
2. 确认 `.harness-worktrees/` 目录存在（不存在则创建）
3. 确认 base branch 存在（默认 `origin/main`）

### 创建流程
```bash
# 1. 确定 base ref
BASE_REF=$(git rev-parse origin/main)

# 2. 创建 worktree
WORKTREE_PATH=".harness-worktrees/wt-${DOMAIN}-$(date +%Y%m%d%H%M%S)-${RANDOM}"
BRANCH_NAME="harness/${DOMAIN}-$(date +%Y%m%d%H%M%S)-${RANDOM}"

git worktree add -b "${BRANCH_NAME}" "${WORKTREE_PATH}" "${BASE_REF}"

# 3. 返回 ExecutionContext
echo "{
  \"id\": \"worktree-${DOMAIN}-$(date +%s)\",
  \"provider\": \"worktree\",
  \"bindings\": {
    \"cwd\": \"${WORKTREE_PATH}\",
    \"branch\": \"${BRANCH_NAME}\"
  }
}"
```

### 错误处理
| 错误 | 原因 | 处理 |
|------|------|------|
| `git worktree add` 失败 | 磁盘空间不足 / 分支名冲突 | 重试 1 次，仍失败降级为 local |
| worktree 路径已存在 | 上次未清理 | 强制删除旧路径后重试 |
| base ref 不存在 | 仓库无 main 分支 | 尝试 `origin/master`，仍失败用 HEAD |

## Activate 实现

```bash
# 切换当前 shell 的 cwd 到 worktree
cd "${WORKTREE_PATH}"

# 验证 worktree 可操作
git status  # 确认在正确的分支上
```

## Destroy 实现

### 清理流程
```bash
# 1. 强制删除 worktree 目录
git worktree remove --force "${WORKTREE_PATH}"

# 2. 删除对应分支（如果存在）
git branch -D "${BRANCH_NAME}" 2>/dev/null || true

# 3. 清理空的 worktrees 目录
rmdir .harness-worktrees 2>/dev/null || true
```

### 安全注意事项
- `--force` 会丢弃未提交的变更 — 只在 WU 已完成或明确放弃时调用
- 如果 worktree 内有需要保留的结果，Leader 应先在 `Destroy` 前 cherry-pick/merge

## HealthCheck 实现

```bash
# 1. 检查 worktree 路径是否存在
test -d "${WORKTREE_PATH}" || echo "UNHEALTHY: worktree path missing"

# 2. 检查 worktree 是否在 git worktree list 中
git worktree list | grep -q "${WORKTREE_PATH}" || echo "UNHEALTHY: not in worktree list"

# 3. 检查磁盘空间（至少 100MB 剩余）
df -m "${WORKTREE_PATH}" | awk 'NR==2 { if ($4 < 100) print "WARN: low disk space" }'
```

## 平台兼容性

| 平台 | 状态 | 备注 |
|------|------|------|
| Claude Code | ✅ supported | 原生 git CLI 可用 |
| Cursor | ✅ supported | 原生 git CLI 可用 |
| Trae | ❌ unsupported | 不支持 worktree 语义，降级为 local |
| Codex | ⚠️ degraded | 需手动 `git worktree add`，degraded 记录写入 tracking |
| MimoCode | ❌ unsupported | 不支持，降级为 local |

## 配置参数（从 config.defaults.yaml 读取）

```yaml
execution:
  worktree:
    base_ref: origin/main        # worktree 基线分支
    path_prefix: .harness-worktrees  # worktree 存储目录
    auto_cleanup: true           # Destroy 时自动清理
    max_lifetime_minutes: 60     # 最大生命周期
    disk_space_min_mb: 100       # 最小磁盘空间要求
```
