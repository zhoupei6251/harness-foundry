# 陷阱归档

按工作域分类。不同域的陷阱不同，写代码时查代码域，写小说时查小说域。

## 按域索引

| 工作域 | 目录 | 总数 | 精简版 |
|--------|------|------|--------|
| **代码** | `traps-archive/code/` | 251 条 | `references/traps.md`（代码域部分） |
| **小说** | `traps-archive/novel/` | 82 条 | `references/traps.md`（小说域部分） |
| **新闻** | `traps-archive/news/` | 69 条 | `references/traps.md`（新闻域部分） |

**总计：402 条陷阱规则**

## 代码域

| 文件 | 内容 | 条数 |
|------|------|------|
| `code/00-all.md` | 完整代码陷阱库（所有章节汇总） | 251 条 |

## 小说域

| 文件 | 内容 | 条数 |
|------|------|------|
| `novel/00-all.md` | 完整小说写作陷阱库 | 82 条 |

### 小说陷阱分类

| 分类 | 说明 |
|------|------|
| AI 痕迹 / 套路化表达 | 消除 AI 写作特征 |
| 人设崩塌 / 声音趋同 | 保持角色一致性 |
| 节奏失控 / 过渡生硬 | 叙事节奏控制 |
| 逻辑漏洞 / 伏笔不回收 | 逻辑自洽性 |
| 章节结构 / 悬念设计 | 章节写作规范 |
| 题材特定 | 各题材特殊要求 |

## 新闻域

| 文件 | 内容 | 条数 |
|------|------|------|
| `news/00-all.md` | 完整新闻采编陷阱库 | 69 条 |

### 新闻陷阱分类

| 分类 | 说明 |
|------|------|
| 事实核查 / 信源 | 信息准确性 |
| 标题 / 夸大 | 标题规范 |
| 时效性 / 更新 | 时效把控 |
| 伦理 / 法律 | 合规性 |
| 写作质量 | 文风规范 |
| 热点追踪 | 热点处理 |

## 使用方式

| 场景 | 查什么 |
|------|--------|
| 写代码前 | `contexts/code.md` + `references/traps.md`（代码域） |
| 写小说前 | `contexts/novel.md` + `references/traps.md`（小说域） |
| 写新闻前 | `contexts/news.md` + `references/traps.md`（新闻域） |
| 审稿/审查前 | `contexts/review.md` + 对应域的 `traps-archive/` |
| 排查代码问题 | `traps-archive/code/00-all.md` |
| Code Review 前复习 | `traps-archive/code/00-all.md` |
| 小说审稿前复习 | `traps-archive/novel/00-all.md` |
| 新闻审稿前复核 | `traps-archive/news/00-all.md` |

## NEVER.md

`core/NEVER.md` 是项目的硬性禁止项清单，包含所有域的通用禁止规则，是 `traps-archive` 的高层抽象。
