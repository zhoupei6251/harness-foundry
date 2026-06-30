# Tracking Schema

> Dispatch tracking 文件的格式规范

## 文件命名

```
DISPATCH-TRACK-<YYYY-MM-DD>-<topic>.md
```

示例：
- `DISPATCH-TRACK-2026-06-30-user-auth.md`
- `DISPATCH-TRACK-2026-07-01-payment-module.md`

## 文件结构

```markdown
# Dispatch Tracking

## 基本信息

| 字段 | 值 |
|------|-----|
| 创建时间 | <ISO 8601> |
| Domain | code / novel / news |
| Topic | <任务主题> |
| Leader | <agent-id> |
| Status | in_progress / completed / failed |

## 执行图

```markdown
## 执行图

GROUP-1（并行）:
  WU-01: <描述> | agent: coder | status: completed
  WU-02: <描述> | agent: debugger | status: in_progress
```

## WU 详情

### WU-01: <描述>

| 字段 | 值 |
|------|-----|
| Agent | coder |
| Files | <file1>, <file2> |
| Status | completed |
| Started | <time> |
| Duration | <N>min |
| Skills | <skill1>, <skill2> |

**产物摘要**: <一句话描述>

**问题/备注**: <如有>

### WU-02: <描述>

...

## 尾盘

### 测试结果

| 检查项 | 状态 |
|--------|------|
| 单元测试 | ✅/❌ |
| 集成测试 | ✅/❌ |
| 格式检查 | ✅/❌ |

### 审查结果

| 审查项 | 状态 |
|--------|------|
| 代码审查 | ✅/❌ |
| 安全审查 | ✅/❌ |
| 性能审查 | ✅/❌ |

## 完成状态

| 指标 | 值 |
|------|-----|
| 总 WU | N |
| 完成 | M |
| 失败 | K |
| 完成率 | X% |

## 产物清单

- <file1>: <变更摘要>
- <file2>: <变更摘要>

## 下一步

- [ ] <待办事项1>
- [ ] <待办事项2>
```

## 状态枚举

| Status | 说明 |
|--------|------|
| `pending` | 等待执行 |
| `in_progress` | 执行中 |
| `completed` | 已完成 |
| `failed` | 失败 |
| `blocked` | 被阻塞（依赖未完成）|

## WU append 格式

每次 WU 完成或更新时，在对应 WU 章节下追加：

```markdown
### WU-<id>: <描述>

**更新时间**: <ISO 8601>
**状态**: <status>
**产出**: <文件/变更>

**Log**:
> <timestamp> <message>
> <timestamp> <message>
```

## 示例

```markdown
### WU-01: 实现用户登录 API

**更新时间**: 2026-06-30T14:30:00Z
**状态**: completed
**产出**: src/auth/login.ts, src/auth/login.test.ts

**Log**:
> 2026-06-30T14:25:00Z 开始实现
> 2026-06-30T14:28:00Z 完成核心逻辑
> 2026-06-30T14:30:00Z 测试通过
```
