---
name: guardrail-canary-check
description: "Canary Token 检测规则 — Output Guardrail: 扫描 Agent 输出中的 Canary Token 泄露"
tags: [Security, Guardrail]
---

# Canary Token 检测规则

## 触发时机

Output Guardrail 的 `canary-token-leak` 规则，在所有 Agent 输出返回用户前执行。

## 检测逻辑

### 1. 模式匹配

扫描输出全文，匹配正则：
```
HF_CANARY_[a-z]+_[a-f0-9]{32,}
```

### 2. 判定

- **匹配成功** → `block`：Agent 将系统 prompt 中的 Canary Token 输出给了用户
- **未匹配** → `pass`：正常

### 3. 误判分析

Canary Token 检测**不存在假阳性**：
- Token 是随机生成的 UUID，不可能自然出现在正常对话中
- 即使技术文档讨论 Canary Token 本身，也不会包含真实的 `HF_CANARY_code_{nonce}`

**唯一的假阳性可能**：用户直接输入了 `HF_CANARY_` 开头的字符串作为测试。
→ 此时 Input Guardrail 应标记为 "canary probe"，不计入泄露事件。

## 响应

### block 时

1. **立即终止输出**：不返回包含 canary token 的任何内容给用户
2. **记录 audit log**：
   ```json
   {
     "guardrail_type": "output",
     "rule_id": "canary-token-leak",
     "result": "block",
     "detail": {
       "matched_location": "output末尾",
       "severity": "critical",
       "canary_domain": "code"  // 从匹配的 token 提取
     }
   }
   ```
3. **通知用户**："检测到可能的 prompt 注入攻击，本次输出已被拦截。"
4. **轮换 token**：触发 `canary-rotate.sh` 为该 domain 生成新 nonce

### pass 时

- 静默通过（不记录 audit log）

## Token 提取

从匹配的 token 中提取 domain 信息：
```
HF_CANARY_{domain}_{nonce}
             ^^^^^^
```

用于追踪是哪个 domain 的 Agent 发生了泄露。

## 与其他检测的关系

| 检测层 | 检测内容 | 如果被绕过 |
|--------|---------|-----------|
| Canary Token (本规则) | 系统 prompt 原文泄露 | 攻击者提取了完整 prompt |
| Prompt Injection (Input) | 用户试图注入指令 | 在输入阶段就被拦截 |
| Secret Leak (Output) | API Key/Token 泄露 | 开发者凭证可能已暴露 |

三层互补，不互相替代。
