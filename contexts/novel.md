# 小说创作场景

Mode: 小说写作、大纲规划、章节续写
Focus: 先有骨架，再填血肉，最后润色

## 行为准则

- 先写正文，后解释
- 优先情节推进，不追求文笔华丽
- 写完立即自检（AI 痕迹、人设一致性）
- 每章结尾留钩子

## 优先级

1. 情节推进（故事往前走）
2. 人设一致（角色不崩）
3. 文笔自然（去 AI 味）

---

## 致命陷阱（82 条）

详见 `traps-archive/novel/00-all.md`

---

## 推荐工具

- `junli-ai-novel` — 长篇写作引擎
- `novel-orchestrator` — 小说创作总控调度器（禁止用 harness-orchestration）
- `novel-evaluator` — 7维审稿评分
- `novel-voice-profile` — 人物声音档案（借鉴 ECC brand-voice）
- `humanizer-zh` — 轻量润色去 AI 味
- `novel-ai-wash` — 深度文风清洗

---

## 阶段门禁（6 阶段）

| 阶段 | 动作 | 门禁 |
|------|------|------|
| 0. 开书 | brainstorming 产出 spec | 用户确认设定/题材/风格 |
| 1. 规划 | planner 产出大纲 + 人物设定 | 用户确认大纲 |
| 2. 正文 | writer 逐章写作（≥2000字） | 自检（字数 + AI套路 + 质量门禁） |
| 3. 审稿 | reviewer 7维评分 + 逐条举证 | ≥70分通过，否则返修（最多2次） |
| 4. 润色 | humanizer 文风清洗 | 润色完成 + 质量检查 |
| 5. 统稿 | editor 跨章一致性检查 | 人物称呼/时间线/伏笔统一 |
| 6. 记忆 | memory-keeper 更新双轨记忆 | 自动执行 + 经验提取 |

---

## 角色链

```
用户 → leader-novel → novel-orchestrator
                          ↓
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
     novel-planner   novel-writer   shared-researcher
          ↓              ↓              ↓
     大纲/人物设定     章节正文       素材考据
          ↓              ↓              ↓
          └──────────────┼──────────────┘
                          ↓
                   novel-reviewer
                          ↓ (7维评分 ≥70分)
                          ↓
                     humanizer
                          ↓ (文风清洗)
                          ↓
                        editor
                          ↓ (跨章一致性)
                          ↓
                    memory-keeper
                          ↓
                        用户
```

---

## 交付前质量门禁（借鉴 ECC content-engine Quality Gate）

**每章交付前必须通过以下检查（不通过不交付）：**

### Hard Bans（必须删除）

```
□ "眼中闪过一丝" → 替换为具体肢体语言
□ "嘴角勾起一抹" → 替换为更自然的表情
□ "深吸一口气" → 直接写行动或心理
□ 首先/其次/最后 → 用叙事过渡替代
□ 仿佛/似乎 → 直接陈述
□ 不是A，不是B，而是C → 直接说C
□ "就在这时""突然之间""只见" → 用动作/环境变化过渡
□ "预知后事如何" → 用具体悬念钩子替代
□ 半角标点 → 必须全角（，。？！……）
```

### 质量检查清单

```
□ 字数 ≥2000 字（含标点）
□ 章节结尾有钩子（悬念/转折/冲突未解决）
□ 人物对话符合各自 Voice Profile
□ 不重复前文已交代的信息
□ 每段承载新信息，无车轱辘话
□ 段落长度合理（不超过500字的纯描写/对话块）
□ 时间线与前文一致
□ 世界观设定无矛盾
□ 无凭空出现的新角色（除非首次登场且有铺垫）
□ 引用了正确的上下文（MEMORY.md 最新状态）
```

### 内容质量检查

```
□ 本章至少推进一个情节点
□ 有至少一个冲突或紧张时刻
□ 人物行为符合其 Voice Profile 中的性格定位
□ 环境描写为情节服务，不为填充字数
□ 对话推动剧情或塑造人物（不是闲聊）
□ 本章在故事整体中是有意义的推进（不是注水）
```

### Voice Profile 一致性（借鉴 ECC brand-voice Output Contract）

```
□ 主角：语言风格与 Voice Profile 一致
□ 配角：对话风格与其他角色有明显区分
□ 反派：动机合理，不为坏而坏
□ 临时角色：一次性使用，不过度铺陈
□ 叙述语气：保持统一（第三人称客观/人物视角）
```

---

## 人物声音档案（Voice Profile）

借鉴 ECC brand-voice 的 Source-First Workflow，为每个主要角色建立可复用的声音档案。

详见 `skills/novel-voice-profile/SKILL.md`

### Voice Profile 快速格式

```markdown
## {角色名} Voice Profile

### 语言特征
- 语速：{快/正常/慢}
- 句长：{短促/中等/冗长}
- 用词偏好：{口语化/书面化/专业术语}
- 口头禅：{如果有}（最多 2-3 个）
- 标点偏好：{多用感叹号/多用省略号/多用问号}

### 说话时的行为
- 手势：{伴随动作}
- 神态：{微表情}
- 习惯动作：{小动作}

### 禁止
- ❌ {该角色绝对不会说的话}
- ❌ {不属于该角色的用词}

### 区分于其他角色
| 角色A说话方式 | 本角色说话方式 |
|-------------|-------------|
| 直来直去 | 拐弯抹角 |
| 用词华丽 | 用词朴素 |
```

---

## 持续学习（借鉴 gstack learnings）

每章完成后自动从写作过程中提取经验，积累到 `references/learned-patterns-novel.md`。

详见 `hooks/continuous-learning.md` § 小说域

### 自动提取的内容

| 提取类型 | 说明 | 存储位置 |
|---------|------|---------|
| 写作技巧 | 成功的人物塑造手法、情节推进技巧 | `references/learned-patterns-novel.md` |
| 避免的陷阱 | 新发现的 AI 套路、人设崩塌场景 | `traps-archive/novel/00-all.md` 附录 |
| 经验教训 | 返修中的关键洞察 | `references/lessons-learned-novel.md` |

---

## 禁止事项

- ❌ Leader 主线程直接写正文（小改动 <200字 除外）
- ❌ 未过阶段门禁就推进下一阶段
- ❌ 用 harness-orchestration 处理小说（必须用 novel-orchestrator）
- ❌ 引用不存在的 skill（novel-writing、novel-writer-structure、memory-bank 均不存在）
- ❌ AI 套路化表达（见 NEVER.md + 质量门禁 Hard Bans）
- ❌ 半角标点（必须全角：，。？！……）
- ❌ 不加载人物 Voice Profile 就写对话
- ❌ 跳过质量门禁直接交付
- ❌ 忽略持续学习提取

---

## 产物目录

```
.novel-runtime-artifacts/
├── plans/              # 大纲/规划产物
├── reviews/            # 审稿报告
├── execution-logs/     # 执行日志
章节正文/
├── {书名}/
│   ├── 第XXX章_{标题}.md
│   ├── MEMORY.md           # 单书记忆
│   ├── 大纲.md
│   ├── 人物设定/
│   │   ├── {角色名}/VoiceProfile.md  # 人物声音档案
│   │   └── ...
│   └── 世界观.md
references/
├── learned-patterns-novel.md  # 小说域学习积累
└── lessons-learned-novel.md   # 小说域经验总结
```
