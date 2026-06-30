---
name: memory-manager
description: 小说项目记忆管理引擎，双轨架构（全局+单书）+ Mem0 增强模式（实体链接/语义检索/时间感知），伏笔状态机，Agent 交接压缩协议
metadata:
  domain: novel
  priority: P0
  tags:
  - memory
  - state
  - persistence
  - long-form
  - mem0
version: 1.2.0
when_to_use: 调用 memory-manager 时
status: peripheral
tags:
- novel
domain: novel
category: novel.memory
---

# Memory Manager — 小说项目记忆管理引擎

> 专为长篇写作优化的持久化记忆系统。借鉴 Morpheus 三层记忆、ainovel-cli 三级摘要压缩，引入 **Mem0 增强模式**（参考 mem0 的实体链接 + 多信号检索 + 时间感知）。
> 双轨记忆 + Mem0 后端，支持伏笔状态机追踪、跨会话恢复、Agent 交接压缩。

## 激活条件

- 会话开始 → 读全局记忆 + 单书记忆，3 句话概括进度
- 写章后 → 更新 chapter_index、人物状态、伏笔状态
- 审稿后 → 更新章节状态（draft → reviewed）
- 润色后 → 更新章节状态（reviewed → polished）
- Agent 交接时 → 输出压缩交接包（writer→reviewer→humanizer→editor）
- 会话结束 → 压缩记忆、更新 in_progress、写回全局索引
- 用户说"接着上次继续" → 触发跨会话恢复

---

## 架构总览

```
┌──────────────────────────────────────────────────────────┐
│                    Memory Manager                         │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────────┐    ┌──────────────────────────┐ │
│  │  File Mode (default) │    │  Mem0 Mode (enhanced)    │ │
│  │  MEMORY.md 双轨文件   │    │  SQLite + Vector Store   │ │
│  │  零依赖，手工维护      │    │  自动提取 + 语义检索      │ │
│  └─────────┬───────────┘    └──────────┬───────────────┘ │
│            │                           │                  │
│            └───────────┬───────────────┘                  │
│                        │                                  │
│              ┌─────────▼──────────┐                      │
│              │ Unified Interface  │                      │
│              │ search / remember  │                      │
│              │ forget / recall    │                      │
│              └────────────────────┘                      │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

**File Mode**：零外部依赖，Markdown 文件读写。适合快速开始、短篇（< 50 章）。本节 § 双轨记忆架构 定义。

**Mem0 Mode**：结构化记忆后端。适合长篇（> 50 章）、复杂人物关系。本节 § Mem0 增强模式 定义。

---

## 双轨记忆架构 (File Mode)

### 全局记忆: `~/.claude/GLOBAL-MEMORY.md`

记录所有书的元信息，不存具体内容：

```markdown
## Novel Projects
| 书名 | 状态 | 当前章节 | 最后更新 | 路径 |
|------|------|---------|---------|------|
| 星辰变 | 连载中 | ch23 | 2026-06-30 | ~/novels/xingchen-bian/ |
| 都市之光 | 暂停 | ch5 | 2026-06-15 | ~/novels/dushi-zhiguang/ |

## 用户写作偏好
- 每章字数: 3000-5000
- 风格偏好: 快节奏、多冲突、修仙文
- 禁忌: 圣母型女主、拖沓感情线
```

### 单书记忆: `MEMORY.md`（每本书根目录）

```markdown
# 《书名》MEMORY.md

## 基础设定
- 世界观: ...
- 修炼体系: ...
- 势力分布: ...

## 人物状态追踪
| 角色 | 状态 | 位置 | 当前目标 | 最新变化 |
|------|------|------|---------|---------|
| 主角 | 元婴期 | 青云山 | 寻找古墓 | ch23 突破元婴 |
| 女主 | 受伤 | 青云山 | 疗伤 | ch22 昏迷 |

## 伏笔追踪
| 伏笔 | 埋设章 | 状态 | 回收章 |
|------|--------|------|--------|
| 古墓中的神秘声音 | ch5 | foreshadowed | - |
| 女主的真实身份 | ch1 | referenced(ch18) | - |
| 藏宝图碎片之一 | ch3 | resolved | ch20 |

## 章节索引
| 章 | 标题 | 字数 | 状态 | 摘要 |
|----|------|------|------|------|
| 1 | 序章 | 3200 | polished | 主角穿越... |
| 2 | 初入青云 | 4100 | polished | 拜师... |
| ... | ... | ... | ... | ... |
| 23 | 古墓开启 | 3800 | draft | 发现古墓入口... |

## 进行中工作
- 当前章节: ch24 初探古墓 (draft)
- 本章目标: 主角进入古墓第一层，遇到第一个陷阱
- 需要埋设的伏笔: 古墓守护者的线索

## 阻塞项
- 无

## 最后更新
2026-06-30 14:30
```

---

## Mem0 增强模式 (mem0-enhanced)

> 借鉴 mem0 核心能力：ADD-only 累加记忆、实体链接、多信号检索、时间感知、Memory Decay。适合长篇（> 50 章）或复杂人物关系网。

### 何时启用

- 长篇连载即将超过 50 章
- 人物数量 > 20 且关系复杂
- 伏笔数量 > 15 且存在交叉依赖
- 用户要求启用（"启用 Mem0 模式"）
- 编辑反馈手工维护 MEMORY.md 开始遗漏信息

### 能力详解

#### A. 实体链接 (Entity Linking)

每章写完后自动从正文提取实体并跨章链接：

```
第 23 章输入: "主角来到古墓入口，掌心雷光闪烁..."
  → 提取 EntityNode: 主角、古墓、雷光
  → 链接已有实体: 主角 (ch1→ch23, 修为: 元婴期)、古墓 (ch5, 关联伏笔: 神秘声音)
  → 创建新关系: (主角, enters, 古墓), [ch23]
  → 更新人物状态: 主角.location = "古墓入口" (旧 location "青云山主殿" invalidated)
```

**使用方式**：写章后 `memory-keeper` 调用 `add_episode(chapter_text)` 自动执行提取和链接。无需 writer 手动更新人物状态表。

#### B. 多信号检索 (Multi-Signal Retrieval)

三路并行打分融合，替代 File Mode 的纯关键词 Ctrl+F：

```
搜索: "主角在哪座山修炼"
  → Semantic:  余弦相似度 → 匹配 "青云山" (0.89)
  → BM25:      关键词匹配 → 匹配 "修炼" + "山" → 命中 ch2 "青云山拜师"
  → Entity:    实体匹配 → 主角.locations 中最近 valid 的是 "青云山主殿"
  → RRF 融合:  青云山 (rank 1), 玄天峰 (rank 2), 灵兽森林 (rank 3)
```

**使用方式**：writer 写章前调用 `search("当前剧情相关上下文")`，获取最相关的历史章节摘要、人物状态、活跃伏笔。

#### C. 时间感知 (Temporal Awareness)

按时间线排序检索结果，区分"现在"和"过‎去"：

```
查询: "主角的修为变化"
  → ch1:  凡人            (valid_at: ch1_start, invalid_at: ch5_end)
  → ch5:  筑基期           (valid_at: ch5_end, invalid_at: ch12_mid)
  → ch12: 金丹期           (valid_at: ch12_mid, invalid_at: ch23_end)
  → ch23: 元婴期 (current) (valid_at: ch23_end, invalid_at: null)
```

**使用方式**：editor 统稿时调用 `search_timeline("主角")` 获取完整变化时间线，自动检测矛盾（如两个时间窗口重叠的修为状态）。

#### D. Memory Decay (记忆衰减)

自动降权陈旧信息，保持检索精度：

| 最后引用距当前章节 | 衰减系数 | 效果 |
|-------------------|---------|------|
| 0-3 章 | 1.0 | 热记忆，优先返回 |
| 4-10 章 | 0.7 | 温记忆，正常返回 |
| 11-30 章 | 0.4 | 冷记忆，降低排序 |
| >30 章且未回收 | **⚠️ 标记** | 伏笔遗忘风险，推送给 editor |

**与伏笔状态机联动**：`planted` + `>30 章未更新` → 自动标记 `⚠️ 可能遗忘`，推送到 editor 统稿检查清单。

### Mem0 Mode 的伏笔状态机增强

原有 5 状态保持不变，新增自动检测：

| 检测 | File Mode | Mem0 Mode |
|------|----------|-----------|
| >30 章未更新的伏笔 | editor 手动扫描 | Memory Decay 自动推送 |
| 伏笔间依赖关系 | 手工记录 | Entity 链接自动发现 "伏笔 A 的回收依赖于伏笔 B 的埋设" |
| 回收冲突检测 | ❌ | ✅ "伏笔 C 在 ch25 已回收，但 ch30 又暗示 C 未解决" |
| Semantic 伏笔搜索 | ❌ | "搜所有和'身份秘密'类似的伏笔" → 语义匹配 |

---

## Agent 交接压缩协议 (Handoff Protocol)

> 借鉴 mattpocock `/handoff`：用紧凑格式压缩上下文，实现 writer→reviewer→humanizer→editor 无痛切换。

### 协议格式

每次 Agent 完成工作后，输出下列交接包：

```markdown
## HANDOFF: writer → reviewer

### 产物
- 第X章正文: `章节正文/第XXX章_xxx.md` (3800字)

### 本章关键变动 (≤ 3 条，每条约 30 字)
- 主角突破元婴，古墓入口开启
- 新伏笔埋设: 古墓守护者线索
- 女主伤势恶化 (伏笔 #2 铺垫)

### 新增伏笔
| 伏笔 | 位置 | 预回收章 |
|------|------|---------|
| 古墓守护者线索 | 第X章 第412行 | ch28-30 |

### 回收伏笔
- 藏宝图碎片之一 (ch3 planted → ch20 resolved)

### 人物状态变更
- 主角: 金丹→元婴期 (ch23)，位置 青云山→古墓入口
- 女主: 状态 轻伤→重伤

### 给下游的上下文 (≤ 100 token)
主角刚突破元婴但境界不稳，进入古墓后前3个陷阱靠修为压制，第4个需要智慧。本章埋的"古墓守护者"伏笔是为ch28的高潮做铺垫。
```

### 各交接节点的上下文配额

| 交接 | 发送方 | 接收方 | 上下文配额 | 核心内容 |
|------|--------|--------|----------|---------|
| writer → reviewer | writer | reviewer | ≤ 150 token | 本章关键变动 + 新增/回收伏笔 + 人物变化 |
| reviewer → humanizer | reviewer | humanizer | ≤ 80 token | 评分结论 + AI 陷阱命中清单 |
| humanizer → editor | humanizer | editor | ≤ 100 token | 清洗统计 + 人物声音变化 + 残留 AI 风险 |
| editor → memory-keeper | editor | memory-keeper | ≤ 200 token | 跨章矛盾 + 伏笔状态变更 + 时间线修正 |

### 交接格式规范

- **≤ 3 条关键变动**：精不要多，每条 ≤ 30 字
- **人物状态用 diff 格式**："xxx: old → new (触发章)"
- **伏笔用标准状态值**：`planted / referenced / foreshadowed / resolved / abandoned`
- **给下游的上下文**：不重复标题和总结，直接写"你需要知道的事"

---

## 伏笔状态机

```
planted → referenced → foreshadowed → resolved
                                    ↘ abandoned (标记放弃原因)
```

| 状态 | 含义 | 触发条件 |
|------|------|---------|
| **planted** | 已埋设 | 章节中首次引入 |
| **referenced** | 被提及 | 后续章节中再次提及（但未深入） |
| **foreshadowed** | 正在铺垫 | 有意识地强化伏笔，为回收做准备 |
| **resolved** | 已回收 | 伏笔在某个章节完全揭晓 |
| **abandoned** | 已放弃 | 标记放弃该伏笔（附原因） |

**自动检查**：
- File Mode：editor 在统稿阶段扫描所有 `planted` / `foreshadowed` 状态超过 30 章未更新的伏笔 → `⚠️ 可能遗忘`
- Mem0 Mode：Memory Decay 自动推送 + editor 核实

## 跨会话恢复协议

用户说"接着上次继续"时：

1. **读全局记忆** → 找到当前活跃的书
2. **读单书 MEMORY.md** (File Mode) 或 `search("current_state")` (Mem0 Mode) → 拿到 current_chapter、最后摘要、人物状态、伏笔
3. **压缩上下文** → 把关键信息压缩到 ≤500 token：
   ```
   上章摘要 (200 token) + 当前章节目标 (100 token) +
   出场人物状态 (100 token) + 活跃伏笔 (100 token)
   ```
4. **喂给 writer** → writer 直接从上一章结尾续写

## 压缩策略

长篇写作中记忆会不断膨胀，需要定期压缩：

- **触发条件**：写完第 5/10/15/20…章（每 5 章）
- **保留规则**：
  - 最近 3 章：保留全文
  - 3-10 章前：保留 200 字摘要 + 关键人物变化 + 伏笔变化
  - 10 章以上前：保留 100 字摘要 + 伏笔状态
- **压缩产物**：更新 `MEMORY.md`（章节索引中旧章扩展为完整摘要）
- **注意**：压缩不删除原文 — 只精简 MEMORY.md 中的摘要
- **Mem0 Mode 补充**：压缩同时触发 `memory.decay_update()`，将 >10 章前的记忆衰减系数降低，但向量索引保留（语义搜索仍能找到）

## 禁止

- ❌ 跳过记忆读取直接写
- ❌ 压缩时删除原文
- ❌ 伏笔只埋不收（abandoned 除外）
- ❌ 人物状态前后矛盾不记录
- ❌ Agent 交接时传递 >200 token 的原始上下文（用 Handoff 协议压缩）

## 依赖

- `core/intent-routing.md` — 意图路由
- `agents/memory-keeper.md` — 记忆管理员角色
- `agents/editor.md` — 统稿编辑角色（伏笔状态扫描 + 矛盾检测）
- **Mem0 Mode** (可选): `pip install mem0` + SQLite + Vector Store

