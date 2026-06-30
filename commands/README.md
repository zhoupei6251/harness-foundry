# Slash Commands

为常用 skill 提供快捷入口，减少记忆负担。

## 目录结构

```
commands/
├── README.md              # 本文件
├── code.md                # 代码域命令
├── novel.md               # 小说域命令
└── news.md                # 新闻域命令
```

## 使用方式

在对话中输入 `/command` 即可触发对应 skill。

## 代码域命令

| 命令 | 触发 Skill | 说明 |
|------|-----------|------|
| `/code` | harness-orchestration | 进入代码开发模式 |
| `/review` | requesting-code-review | 代码审查 |
| `/debug` | systematic-debugging | 调试模式 |
| `/test` | test-driven-development | TDD 模式 |
| `/plan` | writing-plans | 写实现计划 |
| `/verify` | verification-before-completion | 尾盘验证 |

## 小说域命令

| 命令 | 触发 Skill | 说明 |
|------|-----------|------|
| `/novel` | novel-orchestrator | 进入小说创作模式 |
| `/write` | junli-ai-novel | 写章节 |
| `/outline` | brainstorming | 写大纲 |
| `/evaluate` | novel-evaluator | 审稿评分 |
| `/polish` | humanizer-zh | 润色去 AI 味 |
| `/research` | web-tools-guide | 查资料 |

## 新闻域命令

| 命令 | 触发 Skill | 说明 |
|------|-----------|------|
| `/news` | news-generator | 进入新闻采编模式 |
| `/hot` | hot-topic-research | 热点追踪 |
| `/fact` | fact-check | 事实核查 |
| `/brief` | daily-brief | 生成日报 |

## 通用命令

| 命令 | 触发 Skill | 说明 |
|------|-----------|------|
| `/brainstorm` | brainstorming | 头脑风暴 |
| `/memory` | memory-manager | 记忆管理 |
| `/search` | web-tools-guide | 网络搜索 |

## 自定义命令

可以在项目根目录创建 `.commands/` 目录，添加自定义命令文件。

格式：
```markdown
# 命令名

## 触发
/命令名

## 执行
加载 skill: skill-name
执行: 具体步骤
```
