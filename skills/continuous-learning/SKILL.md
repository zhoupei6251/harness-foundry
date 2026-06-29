---
name: continuous-learning
version: 2.0.0
description: 持续学习系统 — Session → instinct → cluster → Skill 进化闭环。P1-3 升级：confidence
  scoring 增强 + 时间衰减 + evolve 闭环。
description_zh: 持续学习系统 — 从会话中提取 instinct 并进化为 skill。参考 ECC v2 Continuous Learning
  v2 设计。
category: meta
triggers:
- 学习
- instinct
- 进化
- evolve
- 持续学习
- prune
when_to_use: 调用 continuous-learning 时
status: peripheral
tags:
- shared
domain: shared
---
# 持续学习系统

从会话中自动提取模式、陷阱、经验，通过置信度评分（含时间衰减）和进化机制，将高频有效模式转化为 skill/command/agent。

> **P1-3 升级**：confidence scoring 算法增强、时间衰减模型、evolve 闭环对接 instinct YAML 格式。

## 核心概念

### Instinct（本能）

原子学习单元，记录从会话中提取的模式或经验。

```yaml
id: "instinct-{domain}-{yyyyMMdd}-{nonce}"
domain: code | novel | news | shared
type: pattern | trap | lesson | preference
confidence: 0.0-1.0
description: "一句话描述"
source:
  session_date: "YYYY-MM-DD"
  trigger: "用户纠正" | "重复模式" | "有效方案" | "用户偏好"
events:
  - type: successful_application | user_affirmation | user_rejection | led_to_error
    date: "YYYY-MM-DD"
    note: "简要说明"
tags: ["tag1", "tag2"]
evolved_to: null | "skill-slug"
body: |
  <详细内容>
```

### 置信度评分（P1-3 升级）

```
初始: 0.5
+0.1 每次成功应用 (successful_application)
+0.2 用户明确肯定 (user_affirmation)
-0.1 用户否定 (user_rejection)
-0.15 导致错误 (led_to_error)
-0.05 每 30 天未使用（时间衰减）

范围: [0, 1]

阈值:
< 0.3: 自动删除（/prune，每周自动执行）
0.3-0.6: 保持观察
0.6-0.8: 可用于建议
> 0.8: 可进化为 skill/command
```

### 进化管道

```
Session → PostToolUse observe.sh 记录 → Stop Hook 提取 instinct
    → 写入 references/instincts/
    → 积累 → 某 domain ≥5 个 && avg_confidence ≥0.7
    → /evolve 聚类分析 → 生成候选 Skill/Agent
    → 用户确认 → 写入 skills/ 或 agents/
    → 原始 instinct 标记 evolved_to
```

**聚类算法**：Jaccard 相似度（基于 tags）
```
similarity = |tags(A) ∩ tags(B)| / |tags(A) ∪ tags(B)|
similarity ≥ 0.7 → 同一 cluster
cluster size ≥ 3 → 触发进化提案
```

**进化目标映射**：
- `code-style` / `architecture` / `testing` → skill
- `workflow` / `debugging` → command
- `review` → agent

## 使用方法

### 1. 提取 instinct

会话结束时（Stop Hook），自动检查是否有值得学习的模式：

```
检查本次会话是否有值得学习的模式（用户纠正、重复出现的问题、有效的解决方案）。
如果有，提取为 instinct 并保存到 references/instincts/project/<project-id>/instincts/
```

### 2. 管理 instinct

```bash
# 列出所有 instinct
node scripts/instinct-cli.js list

# 更新置信度（事件驱动）
node scripts/instinct-cli.js event prefer-early-return successful_application "brief note"
node scripts/instinct-cli.js event prefer-early-return user_rejection "caused issue"

# 统计
node scripts/instinct-cli.js stats

# 修剪低置信度 instinct
node scripts/instinct-cli.js prune --threshold=0.3

# 进化为 skill/command
node scripts/instinct-cli.js evolve --domain=code --min-count=5 --min-confidence=0.7
```

### 3. 命令

- `/evolve` - 分析 instinct，聚类，生成进化提案
- `/prune` - 清理低置信度 instinct（threshold 默认 0.3）
- `/instinct-status` - 查看当前 instinct 统计分布
- `/instinct-import` - 导入外部 instinct 文件
- `/instinct-export` - 导出 instinct 文件

## 存储位置

```
references/instincts/
├── README.md                  # instinct 目录说明和 YAML 格式规范
├── project/                   # 项目级 instinct
│   └── <project-id>/
│       ├── instincts/         # instinct YAML 文件
│       ├── sessions/          # session summary
│       └── clusters/          # 聚类中间产物
└── global/                    # 全局 instinct（跨项目）
    └── instincts/             # instinct YAML 文件
```

## 示例 Instinct

```yaml
id: "instinct-code-20260626-a1b2"
domain: code
type: trap
confidence: 0.85
description: "避免在循环中查询数据库导致 N+1 问题"
source:
  session_date: "2026-06-26"
  trigger: "重复模式"
events:
  - type: user_affirmation
    date: "2026-06-26"
    note: "用户确认这是常见性能问题"
tags: ["performance", "sql", "java"]
evolved_to: "sql-performance-patterns"
body: |
  ## 触发场景
  在循环中查询关联数据

  ## 错误示例
  for (User user : users) {
      Order order = orderRepository.findByUserId(user.getId()); // N+1
  }

  ## 正确做法
  使用 JOIN 或批量查询：
  List<Order> orders = orderRepository.findByUserIdIn(userIds);
```

## 质量控制

- **去重**：Jaccard 相似度 ≥0.85 时合并 events（非重复存储）
- **验证**：确保提取的内容准确有用
- **分类**：按 domain（code/novel/news/shared）+ tags 双维度分类
- **精简**：去除冗余信息
- **频率门禁**：同 trigger 类型 24h 内 ≥10 次 → 降低 0.1（防过拟合）
- **域隔离**：code 域 instinct 不进入 novel/news 域

## 成功指标

- 每周提取 ≥ 3 个 instinct
- 30 天内有 instinct 进化为 skill/command
- 重复错误率下降 50%
- 用户纠正次数下降 30%
