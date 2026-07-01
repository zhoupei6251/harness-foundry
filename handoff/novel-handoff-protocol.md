# Novel 域 Handoff 协议

> 定义 novel-writer → novel-reviewer → humanizer → editor 之间的交接规范。
> 替代旧的"结果汇报模板"，提供完整的上下文传递机制。

## 交接原则

1. **上下文不丢失**：每次交接必须包含足够的上下文供下一角色继续工作
2. **状态可见**：交接时必须明确当前状态（success / blocked / rework）
3. **最小冗余**：只传递必要信息，避免重复已在前序环节确认的内容

---

## 交接类型

### H1: Writer → Reviewer（章节提交审稿）

```markdown
## HANDOFF: writer → reviewer

### 基本信息
- chapter: 第{XXX}章
- title: "{章节标题}"
- file: 章节正文/第{XXX}章_{标题}.md
- word_count: {数字}（包含符号）

### 状态
- status: ready-for-review
- rework_count: {0|1|2}

### 上下文摘要
- 上一章结尾: {一句话描述上章结局}
- 本章目标: {本章要完成的情节目标}
- 人物状态变化: {本章涉及的人物状态变更}
- 伏笔状态: {埋设/回收的伏笔列表}

### 自检结果
- 字数检查: PASS/FAIL（{数字}字）
- AI套路检查: PASS/FAIL（{检测到的问题数量}处）
- 人设一致性: PASS/FAIL

### 交接给 reviewer
请执行 7 维评分（情节/人物/文笔/世界观/钩子/情感/创新），逐条原文举证。
```

---

### H2: Reviewer → Humanizer（审稿通过，进入润色）

```markdown
## HANDOFF: reviewer → humanizer

### 基本信息
- chapter: 第{XXX}章
- title: "{章节标题}"
- file: 章节正文/第{XXX}章_{标题}.md

### 审稿结论
- status: APPROVED
- total_score: {X.X}（满分10）
- passing_level: EXCELLENT（≥80）/ GOOD（70-79）

### 评分明细
| 维度 | 分数 | 摘要 |
|------|------|------|
| 情节 | X | {简评} |
| 人物 | X | {简评} |
| 文笔 | X | {简评} |
| 世界观 | X | {简评} |
| 钩子 | X | {简评} |
| 情感 | X | {简评} |
| 创新 | X | {简评} |

### 润色要求
- 保留内容: {无需修改的部分}
- 需改善: {minor suggestions 列表}
- 人物对话: {需要保持的风格说明}
- 禁用词: {本章禁用的高频AI表达}

### 交接给 humanizer
请执行文风清洗，消除 AI 套路，保持人物声音差异化。
```

---

### H3: Reviewer → Writer（审稿不通过，需要返修）

```markdown
## HANDOFF: reviewer → writer

### 基本信息
- chapter: 第{XXX}章
- title: "{章节标题}"
- file: 章节正文/第{XXX}章_{标题}.md

### 审稿结论
- status: BLOCKED
- total_score: {X.X}（满分10）
- passing_level: BLOCK（60-69）/ SERIOUS（<60）
- rework_count: {1|2}
- last_rework: {true|false}（第2次返修仍不通过则通知用户介入）

### 评分明细
| 维度 | 分数 | 问题摘要 |
|------|------|----------|
| 情节 | X | {问题} |
| 人物 | X | {问题} |
| ... | X | {问题} |

### Critical Issues（必须修复）
1. [行XX-XX] {问题描述}
   - 原文: "{引用}"
   - 修改建议: "{具体修改方向}"

### Important Issues（建议修复）
1. [行XX] {问题描述}
   - 原文: "{引用}"
   - 修改建议: "{具体修改方向}"

### 交接给 writer
请根据以上问题进行返修，完成后重新提交审稿。
```

---

### H4: Humanizer → Editor（润色完成，进入统稿）

```markdown
## HANDOFF: humanizer → editor

### 基本信息
- chapter: 第{XXX}章
- title: "{章节标题}"
- source_file: 章节正文/第{XXX}章_{标题}.md
- polished_file: 章节正文/第{XXX}章_{标题}_润色.md

### 润色摘要
- 原文字数: {数字}
- 润色后字数: {数字}
- 修改字数: {数字}（增减）
- 修改段落: {数量}

### 润色处理
- AI套路消除: {处理了哪些问题}
- 句式重构: {主要改动}
- 人物声音: {是否做了差异化处理}

### 跨章一致性检查项
- 人物称呼: {与前几章是否一致}
- 地名/专有名词: {是否统一}
- 时间线: {是否连续}
- 伏笔状态: {是否有遗漏}

### 交接给 editor
请执行跨章一致性检查，确保本章与已完成章节在人物/时间/伏笔上保持一致。
```

---

### H5: Editor → Memory-keeper（统稿完成，更新记忆）

```markdown
## HANDOFF: editor → memory-keeper

### 基本信息
- chapter: 第{XXX}章
- title: "{章节标题}"
- final_file: 章节正文/第{XXX}章_{标题}_定稿.md

### 统稿结论
- status: APPROVED
- consistency_check: PASS

### 需要更新的记忆
- 人物状态: {更新内容}
- 伏笔状态: {新增/已回收的伏笔}
- 章节索引: 第{XXX}章完成

### 交接给 memory-keeper
请更新 MEMORY.md 和 GLOBAL-MEMORY.md，记录本章完成状态和状态变更。
```

---

## 状态机

```
writer 完成初稿
    ↓
reviewer 审稿
    ↓ [APPROVE]
humanizer 润色
    ↓
editor 统稿
    ↓
memory-keeper 更新记忆
    ↓
用户确认

    ↓ [BLOCK]
reviewer → writer 返修（最多2次）
    ↓ [第3次仍BLOCK]
通知用户介入决策
```

---

## 文件命名约定

| 阶段 | 命名格式 |
|------|----------|
| 写作 | `第{XXX}章_{标题}.md` |
| 审稿中 | `第{XXX}章_{标题}_审稿中.md` |
| 润色 | `第{XXX}章_{标题}_润色.md` |
| 统稿 | `第{XXX}章_{标题}_定稿.md` |
| 审稿报告 | `.novel-runtime-artifacts/reviews/第{XXX}章_审稿报告.md` |

---

## 禁止事项

- ❌ 跳过交接直接派发下一角色
- ❌ 交接时遗漏人物状态/伏笔信息
- ❌ 交接状态与实际产物不符
- ❌ 修改交接过的文件而不重新交接