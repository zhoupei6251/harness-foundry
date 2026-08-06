# Intent Routing — Architecture & Limitations

> 为什么自然语言不能自动触发 skills/agents？以及我们做了什么来解决它。

## 三域统一基线设计

### 设计原则

类似 `karpathy-guidelines` 对 code 域的作用（写前思维模式），每个域操作都应该有**"操作前思维基线"**——在开始具体工作之前加载对应领域的核心准则。

### Code 域基线

| 操作 | 基线 Skill | 强制？ | 说明 |
|------|-----------|:--:|------|
| 写代码/重构 | `karpathy-guidelines` | MUST | 9 条准则：先想后写、保持简单、精准修改、目标驱动 |
| 测试 | `test-driven-development` | MUST | 先写测试，再写代码 |
| 审查 | `code-review` | MUST | 安全/性能/正确性/可维护性/测试 5 轴 |
| 调试 | `systematic-debugging` | MUST | 复现→缩小→假设→验证→修复→回归 |
| 设计/架构 | `brainstorming` | MUST | 澄清需求→探索方案→设计输出 |
| 简化/精简 | `simplify` | 写后 | 自查简洁度 |
| 提交 | `git-xywh` | 提交时 | 三主干五类临时分支 |

**完整流水线：**
```
brainstorming → karpathy-guidelines → TDD → 写代码 → simplify → code-review → git-xywh
```

### Novel 域基线

| 操作 | 基线 Skill | 强制？ | 说明 |
|------|-----------|:--:|------|
| 写章节/大纲 | `novel-guidelines` | MUST FIRST | 写作前思维基线 |
| 情节矛盾/角色冲突 | `novel-debug` | 排查时 | 情节系统排查 |
| 章节自查 | `novel-simplify` | 写后审前 | 简洁度自检 |
| 审稿 | `novel-evaluator` | MUST | 7 维评分 |
| 连续性核查 | `novel-guardian` | 审稿时 | 法医式角色/时间线/世界观核查 |
| 伏笔追踪 | `novel-foreshadowing-dag` | 规划/写作中 | 伏笔埋设/触发/回收 DAG |
| 返修 | `novel-safe-revision` | 返修时 | 小步安全返修 |
| 润色 | `humanizer-zh` | MUST | AI 痕迹检测 |
| 发布质检 | `web-novel-publishing-readiness-and-quality-check-skill` | 发布前 | 违禁词/词频/衔接/逻辑质检 |
| 番茄发布 | `fanqie-novel-auto-publish` | 发布时 | 番茄平台自动批量发布 |
| 统稿 | `memory-manager` | 跨章时 | 一致性检查 |

**完整流水线：**
```
novel-guidelines (MUST FIRST)
    → novel-36-beats (大纲)
    → novel-writer (写章节)
    → novel-simplify (自查)
    → novel-evaluator (审稿)
    → novel-guardian (连续性核查)
    → humanizer-zh (润色)
    → web-novel-publishing-readiness-and-quality-check-skill (发布质检)
    → fanqie-novel-auto-publish (番茄发布，可选)
    → memory-manager (记忆)
    （伏笔追踪 novel-foreshadowing-dag 贯穿规划/写作/审稿全程）

Debug/Safe-Revision:
novel-debug → 排查 → novel-safe-revision → 小步返修
```

### News 域基线

| 操作 | 基线 Skill | 强制？ | 说明 |
|------|-----------|:--:|------|
| 写稿 | `news-generator` | MUST | 新闻写作基线 |
| 事实核查 | `fact-check` | MUST | 核查思维 |
| 编辑 | `news-polish` | 审校时 | 审校排版 |
| 调研 | `web-tools-guide` | 调研时 | 资料查找 |

**完整流水线：**
```
hot-topic-research → news-generator → fact-check → news-polish → news-editor
```

---

## 执行链路详解

### 当前实际行为

```
用户输入 "写个登录模块"
│
├── Layer 1: CLAUDE.md 文本指令     ✅ 已实现
│   → Claude 读取 CLAUDE.md
│   → 看到意图路由表
│   → 自行判断："登录模块" → 写代码 → 加载 karpathy-guidelines
│   → 调用 Skill 工具
│   → Skill 加载
│
│   ⚠️ 依赖模型遵守指令的能力
│   ⚠️ 小模型或低 effort 时可能跳过
│
├── Layer 2: Slash Command          ✅ 可用
│   → /brainstorming
│   → /review
│   → 用户显式输入，可靠性最高
│
└── Layer 3: PreMessage Hook        ❌ 平台限制
    → Claude Code hooks 体系有 PreToolUse / PostToolUse / Stop
    → **没有 PreMessage hook** 来拦截用户输入
    → 这是平台限制，不是 Harness Foundry 设计缺陷
```

### 理想的自动路由（需要平台支持）

如果 Claude Code 未来支持 `PreMessage` hook：

```json
{
  "PreMessage": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "node core/intent-routing/resolver.js",
      "description": "自动意图路由 → 解析用户输入 → 加载对应 skill"
    }]
  }]
}
```

```
用户输入 → PreMessage hook 拦截
         → resolver.js 解析关键词
           → "登录" → code 域 → 加载 karpathy-guidelines
           → "小说" → novel 域 → 加载 novel-orchestrator
           → "新闻" → news 域 → 加载 news-generator
         → 上下文注入对应 skill
         → Claude 带着基线准则处理用户请求
```

---

## 已实现的能力清单

| 能力 | 状态 | 实现方式 |
|------|:--:|------|
| 意图路由关键词匹配 | ✅ | CLAUDE.md 指令表 |
| Code 域写前基线 | ✅ | karpathy-guidelines MUST FIRST |
| Novel 域写前基线 | ✅ | novel-orchestrator |
| News 域写前基线 | ✅ | news-generator |
| 意图路由强制调用 | ✅ | CLAUDE.md "MUST invoke" |
| Skill → Write → Simplify → Review 流水线 | ✅ | Code Domain Default Baseline |
| 三域记忆系统 | ✅ | state-schema + domain-config |
| 经验沉淀 | ✅ | 用户触发（"记住这个"）→ instincts/ |
| PreMessage 自动拦截 | ❌ | 等待平台支持 |
| 子 Agent 自动 skill 加载 | ⚠️ | skill-preferences.md 定义，依赖 Leader 实现 |

---

## 已知限制与 Roadmap

| 限制 | 原因 | 解决路径 |
|------|------|---------|
| 自然语言不能自动触发 skill | Claude Code 无 PreMessage hook | 等待平台支持，或迁移到支持 PreMessage 的平台 |
| 子 Agent skill 加载不完整 | Leader 须手动解析 `auto` → slug | 完善 dispatcher 实现 |
| 小模型可能忽略指令 | 上下文过大时指令遵循能力下降 | Token 节流策略 (intent-routing § Token 节流) |
| Novel/News 域 baseline 未像 code 域那样细粒度 | 缺少类似 karpathy-guidelines 的域特定准则 | 未来：novel-guidelines, news-guidelines |

---

## 维护指南

- 新增域操作 → 在意图路由表增加关键词 + 对应 baseline
- 新增 baseline skill → 同步更新本文件 § 三域基线表
- 平台支持 PreMessage 后 → 实现 `core/intent-routing/resolver.js`
- 每次 CLAUDE.md 更新 → 同步 `init-project.sh` 模板
