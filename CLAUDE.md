# Harness Foundry — CLAUDE.md

> AI 编码工作流框架。**独立项目**：可放入任何项目目录，帮助该项目更好地使用 AI——统一驱动 **Claude Code / Trae / Codex / WorkBuddy**。

## 地图不是牢房

大型任务用它导航；小改动声明 Route 后直接处理。

## 书架（写完代码查阅，不预加载）

| 文件 | 内容 |
|------|------|
| `traps-archive/code/springboot-checklist.md` | Java/Spring Boot 编码自检清单（内联 karpathy + springboot-patterns） |
| `traps-archive/novel/novel-checklist.md` | Novel 创作自检清单（8 AI红线 + 5维自评 + 流水线） |
| `scripts/novel/novel_graph.py` | 剧情知识图谱校验（因果链熔断，配 `kb/graph.yaml`） |
| `traps-archive/news/news-checklist.md` | News 采编自检清单（倒金字塔 + 9项检查 + 6红线） |
| `traps-archive/code/00-all.md` | 251 条代码陷阱 |
| `core/NEVER.md` | 硬性禁止事项 |
| `core/intent-routing.md` | 意图路由 + 写完代码必做 spawn 规则 |

## 目录

```
core/                          # 路由 + 禁止清单 + 编排配置
├── intent-routing.md          # 路由表 + spawn 规则
├── NEVER.md                   # 禁止事项
├── orchestration/             # domain-config.yaml + skill-preferences + dispatcher
└── karpathy-guidelines.md     # 行为准则原文

traps-archive/code/            # 代码域陷阱库
├── springboot-checklist.md    # ★ 写完自检（整合 karpathy + springboot）
└── 00-all.md                  # 251 条详细陷阱

adapters/                      # 平台适配：claude/, trae/, codex/, workbuddy/
hooks/                         # PreToolUse/PostToolUse/Stop
```

## 使用方式（Claude Code）

```
「Route：code」「小改动，直接处理」
```

写完代码 → 自检 `springboot-checklist.md` → spawn `ecc:java-reviewer`.

## 命令

```bash
bash scripts/bootstrap.sh --target all     # 同步（trae|claude|workbuddy|all）
bash scripts/verify.sh                      # CI 验证
```
