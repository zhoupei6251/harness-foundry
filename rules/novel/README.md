# Novel 域规则库

> 小说创作规则索引。按需加载，不要在每次会话开始时全部读取。

## 目录结构

```
rules/novel/
├── README.md          # 本文件
├── hooks.md           # 创作钩子规则
├── patterns.md        # 叙事模式与技巧
├── security.md        # 安全与合规
├── testing.md         # 审稿测试规范
└── templates/        # 模板文件
    ├── memory-template.md      # MEMORY.md 模板
    ├── outline-template.md      # 大纲模板
    └── character-template.md    # 人物设定模板
```

## 命令入口

| 命令 | Skill | 说明 |
|------|-------|------|
| `/novel` | `novel` command | 统一入口，自动路由 |
| `/novel quick` | `novel-quick-write` | 快速写作单章 |
| `/novel new` | `novel-init` | 新书创建向导 |
| `/novel batch` | `novel-batch-write` | 批量写作 |
| `/novel status` | `novel-dashboard` | 进度仪表板 |
| `/novel continue` | `novel-recovery` | 会话恢复 |

## Skill 路由表

| 用户意图 | Skill | 说明 |
|---------|-------|------|
| "写第X章" | `novel-quick-write` | 快速单章写作 |
| "写到第N章" | `novel-batch-write` | 批量写作 |
| "写小说" | `novel-init` | 新书创建 |
| "继续" | `novel-recovery` | 会话恢复 |
| "进度/状态" | `novel-dashboard` | 进度查看 |
| 复杂任务 | `novel-orchestrator` | 完整编排 |

## 规则分类

### 基础规则

| 规则 | 文件 | 说明 |
|------|------|------|
| 阶段门禁 | `contexts/novel.md` | 6 阶段门禁（开书→规划→正文→审稿→润色→统稿） |
| 致命陷阱 | `traps-archive/novel/00-all.md` | 82 条陷阱（AI痕迹/节奏/逻辑等） |
| NEVER 禁止 | `core/NEVER.md` | 通用禁止项（novel 域部分） |

### 叙事规则

| 规则 | 文件 | 说明 |
|------|------|------|
| 叙事模式 | `patterns.md` | 人物塑造、情节推进、冲突设计 |
| AI 痕迹检测 | `patterns.md` §1 | 套路化表达识别与规避 |
| 节奏控制 | `patterns.md` §2 | 高潮/缓冲/过渡节奏 |
| 钩子设计 | `patterns.md` §3 | 章节结尾悬念技巧 |

### 技术规则

| 规则 | 文件 | 说明 |
|------|------|------|
| 标点规范 | `hooks.md` | 全角标点（，。？！……） |
| 字数要求 | `hooks.md` | 单章 ≥2000 字 |
| 人名规范 | `hooks.md` | 人物名字前后一致 |
| 文件命名 | `hooks.md` | `第{XXX}章_{标题}.md` |

### 审稿规则

| 规则 | 文件 | 说明 |
|------|------|------|
| 7 维评分 | `skills/novel-evaluator/SKILL.md` | 情节/人物/文笔/世界观/钩子/情感/创新 |
| 举证规则 | `skills/novel-evaluator/SKILL.md` | Critical/Important 必须原文行号 |
| 问题定级 | `skills/novel-evaluator/SKILL.md` | Critical/Important/Suggestion/Nit |

## 加载策略

| 场景 | 必读 | 可选 |
|------|------|------|
| 开书/规划 | `contexts/novel.md` + `patterns.md` | `hooks.md` |
| 写正文 | `traps-archive/novel/00-all.md` | `NEVER.md` |
| 审稿 | `novel-evaluator/SKILL.md` | `patterns.md` |
| 润色 | `humanizer/SKILL.md` | `traps-archive/novel/00-all.md` |

## 陷阱分类索引

`traps-archive/novel/00-all.md`（82 条）：

| 分类 | 条数 | 编号 |
|------|------|------|
| AI 痕迹 / 套路化表达 | 15 | #1-15 |
| 人设崩塌 / 声音趋同 | 6 | #16-21 |
| 节奏失控 / 过渡生硬 | 6 | #22-27 |
| 逻辑漏洞 / 伏笔不回收 | 6 | #28-33 |
| 章节结构 / 悬念设计 | 7 | #34-40 |
| 题材特定 | 35 | #41-82 |

## 参考资料

- [novel-orchestrator skill](../skills/novel-orchestrator/SKILL.md) — 完整编排流程
- [novel-evaluator skill](../skills/novel-evaluator/SKILL.md) — 7 维评分系统
- [novel-quick-write skill](../skills/novel-quick-write/SKILL.md) — 快速写作
- [novel-dashboard skill](../skills/novel-dashboard/SKILL.md) — 进度仪表板
- [novel-recovery skill](../skills/novel-recovery/SKILL.md) — 会话恢复
- [novel-init skill](../skills/novel-init/SKILL.md) — 新书创建
- [novel-batch-write skill](../skills/novel-batch-write/SKILL.md) — 批量写作
- [handoff 协议](../handoff/novel-handoff-protocol.md) — 角色交接规范