# 持续学习 Hooks

> 会话结束时自动提取模式、陷阱和经验，持续优化知识库。
> 支持三域：code / novel / news。
> 设计借鉴 gstack learnings 注入理念和 ECC continuous-learning 演化机制。

## 触发时机

**Stop Hook**：每次响应结束后触发

---

## 三域提取

### Code 域

#### 1. 代码模式（Code Patterns）
- 新发现的最佳实践
- 重复出现的代码结构
- 性能优化技巧
- 架构设计决策

#### 2. 陷阱（Traps）
- 新发现的 bug 模式
- 常见错误
- 反模式
- 安全漏洞

#### 3. 经验（Lessons）
- 调试经验
- 重构经验
- 测试经验
- 协作经验

---

### Novel 域（借鉴 gstack learnings 注入理念）

#### 1. 写作技巧（Writing Techniques）

```markdown
提取条件：
IF 本章达到以下标准之一：
  - 审稿评分 ≥8.0 且某维度 ≥9.0
  - 钩子设计特别巧妙
  - 人物对话特别出彩
  - 读者反馈积极
THEN:
  - 提取成功手法
  - 记录使用场景
  - 保存到 references/learned-patterns-novel.md
```

**提取格式**：

```markdown
## [技巧名称] — 发现于第{XXX}章

### 场景
{什么时候使用}

### 技巧
{具体手法：3-5 句话描述}

### 示例
{从该章引用成功范例，标注行号}

### 适用条件
{在什么情况下有效}

### 发现日期
{YYYY-MM-DD}
```

#### 2. 避免的陷阱（New Traps）

```markdown
提取条件：
IF 本章出现以下情况：
  - 审稿返修 ≥1 次
  - 审稿发现新的 AI 套路模式
  - 审稿发现新的人设崩塌模式
THEN:
  - 提取为新的陷阱条目
  - 追加到 traps-archive/novel/00-all.md 附录
```

**提取格式**：

```markdown
## #{编号} — {陷阱名称}

### 症状
{表现形式：改前是什么样}

### 原因
{根本原因}

### 解决
{改正方法：改后是什么样}

### 预防
{写前检查项}

### 发现日期
{YYYY-MM-DD} | 第{XXX}章
```

#### 3. 经验教训（Lessons Learned）

```markdown
提取条件：
IF 本章经历以下过程之一：
  - 返修 ≥2 次
  - Leader 介入决策
  - 用户直接纠正
  - 发现大纲/设定层面的问题
THEN:
  - 提取关键洞察
  - 记录决策过程
  - 保存到 references/lessons-learned-novel.md
```

**提取格式**：

```markdown
## [标题] — 发现于第{XXX}章

### 背景
{当时发生了什么}

### 问题
{遇到了什么问题}

### 决策
{如何解决的}

### 关键洞察
{最重要的教训：1-2 句话}

### 后续改进
{为���避免再次发生，做了什么改变}

### 发现日期
{YYYY-MM-DD}
```

---

### News 域

同 Novel 域格式，存入对应文件：
- `references/learned-patterns-news.md`
- `references/lessons-learned-news.md`

---

## 存储位置

```
references/
├── learned-patterns.md         # Code 域学习到的模式
├── learned-traps.md            # Code 域学习到的陷阱
├── lessons-learned.md          # Code 域经验总结
├── learned-patterns-novel.md   # Novel 域写作技巧
└── lessons-learned-novel.md    # Novel 域经验总结
```

---

## 自动加载机制

### Code 域

| 场景 | 加载内容 |
|------|---------|
| 写新代码 | `learned-patterns.md` |
| 调试时 | `learned-traps.md` |
| Code Review | `lessons-learned.md` |

### Novel 域

| 场景 | 加载内容 |
|------|---------|
| 写章节前 | `learned-patterns-novel.md`（最近 5 条技巧） |
| 审稿前 | `traps-archive/novel/00-all.md`（含附录新增陷阱） |
| 返修时 | `lessons-learned-novel.md`（相关经验） |

### 加载策略

```markdown
会话开始时：

1. 读取 `MEMORY.md` → 了解当前进度
2. 读取 `learned-patterns-novel.md` 最近 5 条 → 提示可用技巧
3. 如果上章有返修记录 → 读取对应 `lessons-learned-novel.md`

目的：不增加大量上下文开销，精准提供相关经验
```

---

## 质量检查（借鉴 ECC evolved 去重逻辑）

### 去重规则

```markdown
保存新内容前检查：

1. 相似度检查
   - 标题相似度 > 80% → 跳过（不添加新条目）
   - 内容相似度 > 60% → 合并（更新已有条目）

2. 时效性检查
   - 距离发现日期 > 6 个月 → 降级到 references/archive/
   - 同一技巧被引用 ≥5 次 → 升级到核心规则

3. 可信度检查
   - 仅出现一次的异常 → 标记为 "待验证"
   - 反复触发 ≥2 次 → 标记为 "已验证"
   - 审稿评分 ≥8.0 关联的技巧 → 标记为 "高效"
```

---

## 经验演化（借鉴 ECC /evolve 机制）

### 自动演化

```markdown
每 30 天或积累 ≥10 条新经验时：

1. 扫描 references/learned-patterns-novel.md
2. 识别重复出现的模式（≥3 次）
3. 提取为核心规则 → 添加到 contexts/novel.md
4. 标记旧条目为 "已演化 — 见核心规则"
```

### 手动演化

```markdown
用户触发 /evolve novel 时：

1. 显示当前积累的经验统计
2. 识别可演化的模式
3. 建议升级到：
   - 核心规则（contexts/novel.md）
   - 新的 Skill
   - 新的 Agent
```

---

## 禁止事项

- ❌ 提取不完整的内容（缺少"发现日期"等关键字段）
- ❌ 存储重复内容（必须先去重）
- ❌ 不验证就保存（提取的内容应该是本会话确实发生的）
- ❌ 保存敏感信息到学习文件
- ❌ 过期内容不归档（>6 个月）

---

## 提取触发词

| 触发词 | 域 | 说明 |
|--------|-----|------|
| "学到了" | novel | 用户明确指出学到了东西 |
| "下次不要" | novel | 用户明确指出要避免什么 |
| "这里写得好" | novel | 审稿或用户表扬 |
| "这个技巧" | novel | 用户分享技巧 |
| 审稿高分 | novel | 评分 ≥8.0 自动提取 |
| 返修多次 | novel | 返修 ≥2 次自动提取 |
