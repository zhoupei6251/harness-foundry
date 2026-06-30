# Harness Foundry — 一页纸规则

> 参考 ECC 的 RULES.md 设计，提供快速入门指南

## 核心原则

1. **三域统一**：代码 / 小说 / 新闻共用一套框架
2. **CEO 三层架构**：用户 → CEO → Domain Leader → Worker（P1-4）
3. **按需加载**：只加载当前场景需要的规则
4. **持续学习**：会话结束自动提取经验
5. **扁平化**：agents/ 和 skills/ 直接平铺，无嵌套

## 快速开始

### 代码开发
```bash
/code          # 进入代码模式
/review        # 代码审查
/test          # TDD 模式
```

**加载规则**：`rules/code/<lang>/` + `rules/common/`

### 小说创作
```bash
/novel         # 进入小说模式
/write         # 写章节
/evaluate      # 审稿评分
```

**加载规则**：`rules/novel/`

### 新闻采编
```bash
/news          # 进入新闻模式
/hot           # 热点追踪
/fact          # 事实核查
```
**三个角色**：Writer（写稿）/ Fact Checker（核查）/ Editor（审校）
**汇报链**：Writer → News Leader → CEO → 用户

**加载规则**：`rules/news/`

## 目录结构

```
harness-foundry/
├── core/              # 核心基础设施（intent-routing, NEVER.md）
├── rules/             # 按技术栈分类的规则库
│   ├── code/          # java/python/go/rust/vue/react/typescript
│   ├── novel/         # 小说创作规则
│   ├── news/          # 新闻采编规则
│   └── common/        # 通用规则
├── contexts/          # 场景化上下文（code/novel/news/review）
├── hooks/             # 自动化机制（PreToolUse/PostToolUse/Stop）
├── commands/          # Slash 命令（/code /novel /news 等）
├── examples/          # 示例配置
├── agents/            # 全局 Agent 池（已扁平化）
├── skills/            # 全局 Skill 池（已扁平化）
├── adapters/          # 多平台适配（trae/cursor/claude/codex/mimocode）
├── scripts/           # 初始化脚本
├── traps-archive/     # 陷阱库（按域分类）
└── references/        # 参考资料（含持续学习内容）
```

## 加载策略

| 场景 | 必读 | 可选 |
|------|------|------|
| 每个新会话 | `core/intent-routing.md` | — |
| 写代码前 | `contexts/code.md` + `rules/code/<tech>/` | `references/traps.md` |
| 写小说前 | `contexts/novel.md` + `rules/novel/` | `references/traps.md` |
| 写新闻前 | `contexts/news.md` + `rules/news/` | `references/traps.md` |
| 审稿/审查前 | `contexts/review.md` | 对应域的 `traps-archive/` |
| 会话结束 | `hooks/continuous-learning.md` | — |

## 致命陷阱（每域 25 条）

- **代码域**：`references/traps.md`（代码部分）
- **小说域**：`references/traps.md`（小说部分）
- **新闻域**：`references/traps.md`（新闻部分）

完整版：`traps-archive/<domain>/00-all.md`

## 持续学习

会话结束时自动提取：
- **模式**：`references/learned-patterns.md`
- **陷阱**：`references/learned-traps.md`
- **经验**：`references/lessons-learned.md`

## 与 ECC 的差异

| 维度 | ECC | Harness Foundry |
|------|-----|-----------------|
| 域 | 单域（代码） | 三域（代码/小说/新闻） |
| 规则分类 | 按语言 | 按域 + 按技术栈 |
| 上下文 | contexts/ | contexts/（相同设计） |
| Hooks | hooks/ | hooks/（相同设计） |
| Commands | commands/ | commands/（相同设计） |
| 持续学习 | 有 | 有（相同设计） |

## 更多信息

- 完整架构说明：[README.md](README.md)
- 标签体系：[core/tags-index.md](core/tags-index.md)
- 意图路由：[core/intent-routing.md](core/intent-routing.md)
- 规则库：[rules/README.md](rules/README.md)
