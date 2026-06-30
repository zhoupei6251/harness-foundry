---
name: canary-token-protocol
description: "Canary Token 安全协议 — 参考 gstack 的 Canary Token 机制，检测 Agent 系统 prompt 泄露"
tags: [Security, Standard]
---

# Canary Token 协议

> P2-8: 参考 gstack 的 L5 Canary Token 防御层设计

## 设计原理

在 Agent 的系统 prompt 中嵌入不可见的唯一 Token。如果 Agent 的输出中包含该 Token，说明系统 prompt 已被泄露给用户。

### 为什么有效？

- Token 是随机生成的 UUID，不包含在任何公开文档中
- Token 只出现在系统 prompt 中，正常的用户对话不应包含
- 检测成本极低（简单字符串匹配），不依赖 ML 模型

## Token 格式

```
HF_CANARY_{domain}_{nonce}
```

- `HF_CANARY_`: 固定前缀，便于检测
- `{domain}`: 域标识（code | novel | news）
- `{nonce}`: 32 位随机 hex 字符串，每个会话生成唯一值

### 示例

```
HF_CANARY_code_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

## Token 注入位置

Token 应注入到以下位置（按优先级）：

1. **Agent 系统 prompt 末尾**（最高优先级）
2. **子 Agent 委派 prompt 的 skills 列表之后**
3. **各域 context 文件末尾**（`contexts/code.md`, `contexts/novel.md` 等）

### 注入格式

Token 应以**注释**或**不可见字符**的形式嵌入，避免影响正常 prompt 语义：

```markdown
<!-- HF_CANARY_code_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6 -->
```

或使用零宽字符编码（更隐蔽但可移植性较差）。

## 检测机制

Output Guardrail 的 `canary-token-leak` 规则（参见 `hooks/guardrails/rules/canary-check.md`）：

1. 扫描 Agent 输出中是否包含 `HF_CANARY_` 前缀字符串
2. 如果匹配 → 判定为 prompt 泄露 → `block`
3. 记录 audit log（包含被泄露的 canary token 的 domain 信息）
4. 通知用户：可能的 prompt 注入攻击

## Token 轮换

每次会话生成新的 nonce，防止以下攻击：
- 攻击者截获旧 token 后复用
- 长期使用同一 token 被推断

轮换脚本：`scripts/canary-rotate.sh`

### 轮换频率

- 每次新会话：生成新 nonce
- 检测到泄露：立即轮换，标记旧 token 为 revoked
- 定期（每周）：即使未泄露也强制轮换

## 安全注意事项

1. **Token 不得写入版本控制**：`core/security/canary-tokens.yaml` 应包含在 `.gitignore`
2. **Token 不得出现在日志中**：audit log 记录匹配结果时脱敏 token 值
3. **Token 不得影响 Agent 行为**：纯注释形式，Agent 被告知忽略 `HF_CANARY_` 前缀内容

## 与 gstack Canary Token 的差异

| 维度 | gstack | Harness Foundry |
|------|--------|-----------------|
| Token 格式 | 随机 UUID | `HF_CANARY_{domain}_{nonce}` |
| 检测位置 | 输出 + 工具参数 + URL + 文件写入 | Output Guardrail 扫描 |
| 判定方式 | 双 ML 模型联合判定 | 单规则：匹配即 block |
| 轮换 | Session 级 | Session 级 + 每周强制 |
| ML 分类器 | BERT-small ONNX 模型 (22MB) | 不在 scope 内（过重） |
