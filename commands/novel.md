# Novel 命令 — 小说创作入口

> 统一入口，根据用户意图自动路由到合适的写作模式。
> **第一句话必须声明 `Route: novel`**

## 命令列表

| 命令 | 说明 | 示例 |
|------|------|------|
| `/novel` | 显示帮助 | `/novel` |
| `/novel quick 第5章` | 快速写作单章 | `/novel quick 第5章` |
| `/novel new` | 新书创作向导 | `/novel new` |
| `/novel new 书名` | 创建新书 | `/novel new 修仙世界` |
| `/novel batch 第N章` | 批量写到第N章 | `/novel batch 第10章` |
| `/novel status` | 查看进度 | `/novel status` |
| `/novel outline` | 查看/编辑大纲 | `/novel outline` |
| `/novel characters` | 查看人物 | `/novel characters` |
| `/novel continue` | 继续上次进度 | `/novel continue` |
| `/novel checkpoint` | 检查点管理 | `/novel checkpoint list` |
| `/novel metrics` | 写作统计 | `/novel metrics` |
| `/novel context` | 上下文一致性检查 | `/novel context` |
| `/write` | 写章节 | `/write` |
| `/outline` | 写大纲 | `/outline` |
| `/evaluate` | 审稿评分 | `/evaluate` |
| `/polish` | 润色去 AI 味 | `/polish` |
| `/research` | 查资料 | `/research` |

---

## 自动检测逻辑

```
用户输入
    ↓
┌─────────────────────────────────────────┐
│  复杂度评估                              │
├─────────────────────────────────────────┤
│  IF 包含"继续"/"接着" → novel-recovery  │
│  IF 包含"新书"/"从头"/"开始" → novel-init │
│  IF 包含"批量"/"到第X章" → novel-batch-write │
│  IF 包含"第X章" → novel-quick-write    │
│  IF 包含"进度"/"统计"/"指标" → novel-dashboard/novel-metrics │
│  IF 包含"大纲"/"人物"/"世界观" → novel-contexts │
│  IF 包含"检查点"/"checkpoint" → novel-checkpoint │
│  ELSE → 交互询问                          │
└─────────────────────────────────────────┘
    ↓
执行对应 Skill
```

---

## 模式 1：快速写作（默认）

```
用户: "写第5章"
         ↓
┌─────────────────────────────────────────┐
│  📖 快速写作模式                          │
│                                         │
│  检测到：写第5章                          │
│  前情提要：第4章已完成                    │
│                                         │
│  ✓ 准备就绪，开始写作？                   │
└─────────────────────────────────────────┘
```

## 模式 2：新书创作

```
用户: "写小说"
         ↓
┌─────────────────────────────────────────┐
│  📖 新书创作向导                          │
│                                         │
│  请描述您的故事：                         │
│  - 题材类型（玄幻/都市/科幻/悬疑...）     │
│  - 核心设定（世界观/金手指/主要冲突）      │
│  - 预计规模（10章/30章/长篇）            │
│                                         │
│  或者直接告诉我您想写什么故事              │
└─────────────────────────────────────────┘
```

## 模式 3：批量写作

```
用户: "写到第10章"
         ↓
┌─────────────────────────────────────────┐
│  📖 批量写作模式                          │
│                                         │
│  当前进度：第3章完成                      │
│  目标：第10章                            │
│                                         │
│  [开始批量写作]  [调整目标]  [查看规划] │
└─────────────────────────────────────────┘
```

---

## Skill 索引

| Skill | 说明 | 命令 |
|-------|------|------|
| `novel-quick-write` | 快速单章写作 | `/novel quick` |
| `novel-init` | 新书创建向导 | `/novel new` |
| `novel-batch-write` | 批量写作 | `/novel batch` |
| `novel-recovery` | 会话恢复 | `/novel continue` |
| `novel-dashboard` | 进度仪表板 | `/novel status` |
| `novel-metrics` | 写作统计 | `/novel metrics` |
| `novel-checkpoint` | 检查点管理 | `/novel checkpoint` |
| `novel-contexts` | 上下文一致性 | `/novel context` |
| `novel-evaluator` | 审稿评分 | `/evaluate` |
| `novel-receiving-review` | 接收审稿反馈 | (自动触发) |
| `humanizer-zh` | 润色去 AI 味 | `/polish` |

---

## 禁止事项

- ❌ 不声明 `Route: novel` 就开始写作
- ❌ 跳过上下文加载直接写
- ❌ 跳过字数检查交付
- ❌ 未过门禁就进入下一阶段
- ❌ 不验证上下文一致性就写

---

## 依赖

- `contexts/novel.md` — 场景上下文
- `rules/novel/` — 规则库
- `traps-archive/novel/00-all.md` — 82 条陷阱
