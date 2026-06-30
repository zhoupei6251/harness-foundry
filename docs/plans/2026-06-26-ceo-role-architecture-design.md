# CEO 角色体系设计

> 日期：2026-06-26
> 状态：草稿，待评审
> 参考：gstack 组织角色体系 + OpenAI Agents SDK Handoff 模式

## 一、设计背景

ECC、gstack、OpenAI Agents SDK 均为单域框架，无需跨域协调能力。

Harness Foundry 是三域统一框架（code / novel / news），当用户同时运营多个域时，需要一个全局协调角色。此外，未来可能扩展新域，CEO 需要具备域初始化能力。

## 二、三层架构

```
CEO（跨域协调层）
  ├── 路由到域
  ├── 全局管理所有域的 Worker
  ├── 新域初始化
  ├── 系统健康监控
  ├── 异常最后仲裁
  └── PUA Worker / Leader（数据驱动）
       │
       └── 任务传递：handoff/ceo-task.md
                │
       ┌──────────┼──────────┐
       ▼          ▼          ▼
  Code Leader  Novel Leader  News Leader
       │          │          │
       ▼          ▼          ▼
  Coder      Writer      Writer
  Reviewer   Reviewer    Fact Checker
  Test Eng.  Humanizer   Editor
```

## 三、CEO 职责

### 3.1 路由到域

接收用户需求，翻译成结构化任务，传递给定稿对应的 Domain Leader。

不参与具体实现，只做翻译和分发。

### 3.2 全局管理所有域的 Worker

通过 handoff 文件派发任务，接收完成汇报，整合全局结果。

### 3.3 新域初始化

当用户新增领域时（"我新开了一个 xxx 领域"），CEO 负责：
- 生成新的 `leader-<domain>.md`
- 生成新域的 Worker agent 文件
- 在 `domain-config.yaml` 中注册新域
- 创建新域的 artifacts 目录结构

### 3.4 系统健康监控

- **定时触发**：每周自动跑一次 `/health`
- **用户主动**：用户说"检查系统"时触发
- 发现异常主动汇报，正常不打扰用户

### 3.5 异常最后仲裁

当 Worker 与 Worker、Worker 与 Leader 之间出现分歧且无法自行解决时，CEO 介入裁决。

### 3.6 PUA Worker / Leader（数据驱动）

CEO 记录每个 Worker 的绩效数据：
- WU 完成率
- 返工次数
- 效率指标（后续可扩展）

基于数据对高效 Worker 表扬，对低效 Worker 降级。

## 四、Domain Leader 职责

各域 Leader（code / novel / news）独立运作：

- 接收 CEO 通过 handoff 文件派发的任务
- 负责域内 WU 拆分、派发、整合
- 结果导向汇报（完成时写 handoff 文件 + 更新 state.json）
- 不跨域，不抢 CEO 的决策权

## 五、任务传递流程

### 5.1 CEO → Domain Leader

**触发**：用户输入需求
**载体**：`handoff/ceo-task.md`
**格式**：
```markdown
domain: novel
task: 写一本修仙小说，约 10 章
constraints: 每章 3000-5000 字，结尾留悬念
priority: normal
```

### 5.2 Domain Leader → CEO（成功）

**触发**：任务完成
**载体**：`handoff/<domain>-result.md`
**格式**：
```markdown
# Novel Leader 结果

status: success
wu_completed: 10
review_passed: true
total_word_count: 32000

## Worker 绩效
- Writer: WU=10, success=9, rework=1, 返工率=10%
- Reviewer: WU=10, success=10, rework=0, 返工率=0%
- Humanizer: WU=10, success=10, rework=0, 返工率=0%
```

### 5.3 Domain Leader → CEO（失败）

**触发**：任务无法完成
**格式**：
```markdown
# Novel Leader 结果

status: failed
reason: 审稿 2 次仍不通过
blocked_wu: 第 3 章
recommendation: 需要用户介入决定走向

## Worker 绩效
- Writer: WU=3, success=1, rework=2, 返工率=66%
```

## 六、汇报机制

| 事件 | 触发方 | 接收方 | 载体 |
|------|--------|--------|------|
| 任务派发 | CEO | Domain Leader | handoff/ceo-task.md |
| 任务完成 | Domain Leader | CEO | handoff/<domain>-result.md |
| 状态更新 | Domain Leader | CEO | state.json |
| 异常仲裁 | Worker/Leader | CEO | handoff/<domain>-result.md |

## 七、绩效记录

绩效数据内嵌在 handoff 文件中，无需新建独立文件。

CEO 维护一个轻量索引：
```
performance/
  └── worker-stats.json    # 各 Worker 绩效摘要
```

```json
{
  "Writer": { "total_wu": 10, "success_rate": 0.9, "rework_rate": 0.1 },
  "Coder": { "total_wu": 5, "success_rate": 0.8, "rework_rate": 0.2 }
}
```

## 八、CEO Skill 体系

### 8.1 目录结构

```
skills/ceo-orchestration/
  ├── SKILL.md              # CEO 主 Skill（入口）
  ├── intent-router.md       # 意图理解 + 路由子 Skill
  ├── health-monitor.md      # 健康监控子 Skill
  ├── domain-init.md         # 域初始化子 Skill
  └── performance-analyst.md  # 绩效分析子 Skill
```

### 8.2 SKILL.md 主入口

```markdown
---
name: ceo-orchestration
description: "CEO 角色主 Skill — 跨域协调、全局管理、健康监控、绩效分析"
---

# CEO Orchestration

## 激活条件
- 用户首次输入需求（路由决策）
- 用户说 "检查系统健康"
- 用户说 "新开了一个 xxx 领域"
- Domain Leader 汇报失败

## 子 Skill
- intent-router: 意图理解 + 路由到域
- health-monitor: 系统健康监控
- domain-init: 新域初始化
- performance-analyst: 绩效分析 + PUA 策略

## 流程
1. 接收用户需求
2. 调用 intent-router 判断域
3. 生成 handoff/ceo-task.md
4. 等待 Domain Leader 汇报
5. 整合结果 / 处理异常
```

## 九、新域初始化流程

当用户说"新开了一个 xxx 领域"时：

1. CEO 调用 `domain-init` 子 Skill
2. 生成以下文件：
   - `agents/leader-<domain>.md`
   - `agents/<domain>-worker-1.md`
   - `agents/<domain>-worker-2.md`
   - ...
3. 在 `domain-config.yaml` 中注册新域
4. 创建 `rules/<domain>/` 目录
5. 在 `intent-routing.md` 中添加新域路由规则

## 十、与其他角色的关系

```
用户
  │
  ▼
CEO（跨域协调）
  │
  ├──► Code Leader ── Coder / Reviewer / Test Eng.
  ├──► Novel Leader ── Writer / Reviewer / Humanizer
  └──► News Leader ── Writer / Fact Checker / Editor
```

| 角色 | 向谁汇报 | 管理谁 |
|------|---------|--------|
| CEO | 用户 | 三域 Leader + 所有 Worker |
| Code Leader | CEO | Coder / Reviewer / Test Eng. |
| Novel Leader | CEO | Writer / Reviewer / Humanizer |
| News Leader | CEO | Writer / Fact Checker / Editor |

## 十一、禁止事项

- CEO **不直接**执行代码 / 章节 / 新闻
- CEO **不参与**域内 WU 拆分（那是 Domain Leader 的事）
- Domain Leader **不跨域**派发任务
- Worker **不直接向用户**汇报（通过 Leader 中转）

## 十二、与其他已建设施的关系

| 已有设施 | CEO 中的角色 |
|---------|------------|
| `intent-routing.md` | 复用其路由逻辑 |
| `harness-health` | 作为 health-monitor Skill 的子模块 |
| `continuous-learning` | 作为 performance-analyst 的数据来源 |
| `dispatcher-workflow.md` | Domain Leader 复用其 WU 拆分逻辑 |
| `multi-leader-protocol.md` | 当多平台同时工作时的补充协议 |
