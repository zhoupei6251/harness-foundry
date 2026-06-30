# Hooks & Guardrails 自动化机制

> **P0-2 双层 Guardrail 架构**：参考 OpenAI Agents SDK 双层防护和 gstack 6 层 prompt injection 防御体系。

## 架构总览

```
用户输入
   │
   ▼
┌─────────────────────────────────────────────┐
│  Input Guardrail（并行执行）                    │
│  - prompt-injection-canary                   │
│  - sqli-pattern                             │
│  - command-injection                         │
│  - prompt-override                          │
│  - path-traversal                           │
│  fail_strategy: any                         │
└─────────────────────────────────────────────┘
   │ [通过]
   ▼
┌─────────────────────────────────────────────┐
│  Agent 执行                                   │
│  (PreToolUse hooks — 兼容保留)                │
└─────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────┐
│  Output Guardrail（顺序执行、阻塞）              │
│  - secret-leak-output                       │
│  - canary-token-leak                         │
│  - never-violation                          │
│  - ai-writing-markers (novel/news)          │
│  - syntax-check (code)                      │
│  fail_strategy: block                       │
└─────────────────────────────────────────────┘
   │ [通过]
   ▼
返回用户
```

## 目录结构

```
hooks/
├── README.md                          # 本文件
├── hooks.json                          # Hook 配置（向后兼容旧 prompt hook）
├── continuous-learning.md              # 持续学习机制
├── observe.sh / observe.ps1            # 会话观察脚本
├── memory-persistence/                 # 记忆持久化
│   └── README.md
└── guardrails/                         # Guardrail 体系
    ├── guardrail-config.json           # Guardrail 配置中心
    ├── audit-log-schema.json           # 审计日志结构定义
    └── rules/                          # Guardrail 规则库
        ├── prompt-injection.md         # Prompt 注入检测规则
        ├── sensitive-data.md           # 敏感数据检测规则
        ├── canary-check.md             # Canary Token 检测规则
        └── instinct-hook.md            # Instinct 提取规则
```

## Guardrail 类型

| 类型 | 触发时机 | 执行模式 | 失败策略 |
|------|----------|---------|---------|
| **Input Guardrail** | 用户输入到达 Agent 前 | 并行 | any-fail → block |
| **Output Guardrail** | Agent 输出返回用户前 | 顺序 | any-block → block |

## Hook 类型（向后兼容）

| 类型 | 触发时机 | 用途 | 状态 |
|------|----------|------|------|
| PreToolUse | 工具执行前 | 验证、提醒 | 降级为"建议"级别 |
| PostToolUse | 工具执行后 | 分析、通知 | 降级为"建议"级别 |
| Stop | 响应结束后 | 状态保存、instinct 提取 | 继续使用 |

## 新旧关系

- **Guardrail**（新）：Input + Output 双层，在 prompt/response 层面工作
- **Hook**（旧）：PreToolUse + PostToolUse + Stop，在工具调用层面工作
- **过渡策略**：Guardrail 先执行（可 block），旧 Hook 降级为"建议"级别（只能 warn）

## 审计

所有 Guardrail 的 block/warn 事件写入 `.ai-runtime-artifacts/guardrail-audit.jsonl`，保留 90 天。

## 退出码约定

| 退出码 | 含义 | 适用 |
|--------|------|------|
| 0 | 通过 | Input + Output |
| 1 | 警告，允许继续 | Input(warn模式) |
| 2 | 阻止，拒绝执行 | Input(block模式) + Output |

## 紧急绕过

如果 Guardrail 误拦正常操作，使用 `--skip-guardrail` 标志临时关闭所有 guardrail 检查。

**注意**：`--skip-guardrail` 的使用会被记录到 audit log。
