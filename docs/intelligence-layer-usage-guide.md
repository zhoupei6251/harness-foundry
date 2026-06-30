# Intelligence Layer 使用指南

> 如何让 Harness Foundry 的所有组件（Leader、Worker、Skills）使用知识图谱

---

## 概述

### 知识图谱的价值

```
传统方式:          Intelligence Layer 方式:
用户问 → Agent     用户问 → Leader 编排
   ↓                 ↓
Agent 搜索代码      Leader 调用 /understand
   ↓                 ↓
理解上下文          获取项目全局理解
   ↓                 ↓
回答问题 (慢)       精准定位 (快)
   
效果: Token ↓57%, 工具调用 ↓71%, 理解时间 ↓5分钟
```

### 已集成的组件

| 组件 | 状态 | 说明 |
|------|------|------|
| **leader-code** | ✅ 已增强 | plan 阶段自动调用 understand-project |
| **explorer** | ✅ 已增强 | Intelligence 主力使用者 |
| **skill-preferences** | ✅ 已增强 | 路由表已包含 Intelligence Skills |
| **其他 Agents** | ⏳ 待增强 | 可手动注入 |
| **其他 Skills** | ⏳ 待增强 | 可手动调用 |

---

## 快速开始

### 1. 生成知识图谱（首次）

```bash
# 在项目根目录运行
/understand --language zh
```

输出位置: `.understand-anything/knowledge-graph.json`

### 2. 交互式问答

```bash
/understand-chat 项目的整体架构是什么？
/understand-chat agents 和 skills 是什么关系？
```

### 3. 可视化仪表板

```bash
/understand-dashboard
```

---

## 角色使用指南

### Leader-code

Leader 在以下阶段自动使用 Intelligence：

```
┌─────────────────────────────────────────────────────────────┐
│ Leader-code Intelligence 集成                                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  plan 阶段:                                                  │
│    1. /understand-project    → 项目全局理解                │
│    2. /index-project          → 建立代码索引 (>100文件)      │
│                                                              │
│  implement 阶段:                                             │
│    3. /query-symbol           → 定位要修改的代码             │
│    4. /get-callers           → 查看调用方                    │
│                                                              │
│  verify 阶段:                                                │
│    5. /analyze-impact         → 评估变更影响                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Explorer（Intelligence 主力）

Explorer 是 Intelligence 的主要使用者：

```bash
# 典型探查流程
1. /understand-chat <问题>  # 基于图谱回答
2. codegraph_explore <符号>   # 精准定位
3. /get-callers <函数>        # 调用分析
```

### Coder

Coder 在派发时自动获得 Intelligence 支持：

```markdown
## Intelligence 支持

可使用：
- /query-symbol <符号>   # 快速定位代码
- /get-callers <符号>    # 查看调用方
- /analyze-impact <符号>  # 评估影响
```

### Reviewer

Reviewer 在审查前使用：

```bash
/analyze-impact <修改的文件>
  # → 评估影响范围
  # → 确定需要审查的相关文件
```

---

## Skill 调用参考

### 战略层 (Understand-Anything)

| Skill | 触发 | 用法 |
|-------|------|------|
| `/understand-project` | plan 阶段 | 生成/更新项目知识图谱 |
| `/understand-chat` | 任何阶段 | 基于图谱的交互式问答 |
| `/understand-dashboard` | 任何阶段 | 打开可视化仪表板 |
| `/understand-diff` | PR/代码变更 | 分析变更的影响 |
| `/analyze-architecture` | design 阶段 | 深度架构分析 |

### 战术层 (CodeGraph)

| Skill | 触发 | 用法 |
|-------|------|------|
| `/index-project` | plan 阶段 | 建立代码索引 |
| `/query-symbol` | implement 阶段 | 快速定位符号 |
| `/get-callers` | implement 阶段 | 分析调用方 |
| `/get-callees` | implement 阶段 | 分析被调用方 |
| `/analyze-impact` | verify 阶段 | 评估变更影响 |

---

## 自动化配置

### skill-preferences.md 路由增强

```yaml
# 已自动注入 Intelligence Skills
leader-code:
  plan: understand-project, analyze-architecture
  implement: understand-chat

coder:
  feature, bugfix, refactor:
    - test-driven-development
    - query-symbol  # ← Intelligence 自动注入

explorer:
  explore: understand-chat  # ← Intelligence

reviewer:
  review: analyze-impact  # ← Intelligence
```

### Agent prompt 增强

在派发 prompt 中自动包含：

```markdown
## Intelligence 支持

本项目已建立知识图谱 (`.understand-anything/knowledge-graph.json`)
可使用：
- /understand-chat <问题>   # 基于图谱回答
- /query-symbol <符号>      # 定位代码
- codegraph_explore <符号>   # 索引查询
```

---

## 常见场景

### 场景 1: 新项目接手

```
用户: 帮我理解这个项目
      ↓
Leader-code:
  1. /understand-project --language zh
  2. /understand-chat 项目的整体架构是什么？
  3. 派发给 Worker
```

### 场景 2: 修 Bug

```
用户: 修复 intent-routing 相关的 bug
      ↓
Leader-code:
  1. codegraph_explore "intent-routing"
  2. 派发给 debugger
      ↓
Debugger:
  1. /query-symbol intent-routing
  2. /get-callers routing
  3. 定位并修复
```

### 场景 3: 大型重构

```
用户: 重构 hooks 系统
      ↓
Leader-code:
  1. /understand-chat hooks 系统的结构
  2. /analyze-impact hooks/
  3. /get-callers <核心函数>
  4. 评估影响范围后派发
```

### 场景 4: Code Review

```
用户: 帮我审查这个 PR
      ↓
Reviewer:
  1. /understand-diff
  2. /analyze-impact <修改的文件>
  3. 针对影响范围进行审查
```

---

## 故障排除

### 知识图谱不存在

```bash
# 检查
ls .understand-anything/knowledge-graph.json

# 如果不存在，生成
/understand --language zh
```

### 图谱过期

```bash
# 强制重建
/understand --full --language zh
```

### CodeGraph 索引不存在

```bash
# 检查
ls .codegraph/

# 如果不存在，建立
codegraph init
codegraph index
```

### Skills 不可用

```bash
# 检查 skills 是否同步
bash scripts/sync-skills.sh --dry-run

# 如果需要，同步
bash scripts/sync-skills.sh --target claude
```

---

## 文件位置

```
.understand-anything/           # Understand-Anything 数据
├── knowledge-graph.json         # 知识图谱
├── meta.json                    # 元数据
├── config.json                  # 配置
└── intermediate/                # 中间产物

.codegraph/                     # CodeGraph 数据
├── codegraph.db                 # SQLite 索引
└── ...                          # 其他索引文件

core/intelligence/               # Intelligence Layer 配置
├── strategic/                    # 战略层 Skills
│   └── understand-project.md
└── tactical/                    # 战术层 Skills
    └── index-project.md
```

---

## 下一步

1. ✅ 已完成：知识图谱生成
2. ✅ 已完成：leader-code 增强
3. ✅ 已完成：explorer 增强
4. ✅ 已完成：skill-preferences 增强
5. ⏳ 可选：增强其他 Agents（coder, reviewer 等）
6. ⏳ 可选：同步到其他 IDE（Trae, Cursor）

---

## 参考

- [Intelligence Layer 用户指南](intelligence-layer-user-guide.md)
- [Intelligence Layer 故障排除](intelligence-layer-troubleshooting.md)
- [Understand-Anything 项目](https://github.com/Egonex-AI/Understand-Anything)
- [CodeGraph 项目](https://github.com/AfkarSiddiq/CodeGraph)
