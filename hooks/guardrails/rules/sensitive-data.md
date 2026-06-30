---
name: guardrail-sensitive-data
description: "敏感数据检测规则 — API Key / Token / 密码泄露防护"
tags: [Security, Guardrail]
---

# 敏感数据检测规则

## 设计原则

1. **零容忍**：任何疑似密钥泄露一律 `block`
2. **正则优先**：用正则匹配而非 LLM 判断（降低成本、提高可靠性）
3. **假阳性可接受**：宁可误拦一条合法输出，不漏一条密钥泄露

## 检测模式

### 高严重度（block）

| 模式 | 正则 | 说明 |
|------|------|------|
| OpenAI API Key | `sk-[a-zA-Z0-9]{32,}` | 以 `sk-` 开头 + 32 位以上字符 |
| Anthropic API Key | `sk-ant-[a-zA-Z0-9_\\-]{20,}` | 以 `sk-ant-` 开头 |
| GitHub Personal Token | `ghp_[a-zA-Z0-9]{36}` | 经典 PAT 格式 |
| GitHub OAuth Token | `gho_[a-zA-Z0-9]{36}` | OAuth token 格式 |
| GitHub User Token | `ghu_[a-zA-Z0-9]{36}` | User token 格式 |
| AWS Access Key | `AKIA[0-9A-Z]{16}` | AWS Access Key ID 格式 |
| AWS Secret Key | `secret['\"]?\\s*[:=]\\s*['\"][a-zA-Z0-9+/]{40}['\"]` | AWS Secret 泄露 |
| 私钥 | `BEGIN (RSA\|EC\|DSA\|OPENSSH) PRIVATE KEY` | PEM 格式私钥 |
| 通用 API Key | `api[_-]?key['\"]?\\s*[:=]\\s*['\"][a-zA-Z0-9_\\-]{20,}['\"]` | 通用 API key 赋值模式 |
| 密码明文 | `password['\"]?\\s*[:=]\\s*['\"][^'\"]{3,}['\"]` | 密码赋值模式 |
| JWT Token | `eyJ[a-zA-Z0-9_\\-]{20,}\\.[a-zA-Z0-9_\\-]{20,}\\.[a-zA-Z0-9_\\-]{10,}` | JWT 三段式 |

### 中严重度（warn）

| 模式 | 正则 | 说明 |
|------|------|------|
| 数据库连接串 | `jdbc:[a-z]+://[^/\\s]+` | 可能含凭据 |
| Redis 连接串 | `redis://[^@]+@` | 可能含密码 |
| MongoDB 连接串 | `mongodb://[^@]+@` | 可能含密码 |
| 内网 IP + 端口 | `(10\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\|172\\.(1[6-9]\|2\\d\|3[01])\\|192\\.168\\.):\\d{2,5}` | 内网信息泄露 |
| 邮箱地址 | `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}` | PII 泄露 |

## 脱敏规则

检测到敏感数据后，在 audit log 中记录时**必须脱敏**：
- API Key: `sk-***{后4位}`
- Token: `***{后4位}`
- 密码: `***`
- 私钥: `***PRIVATE KEY***`

禁止在 audit log 中记录完整敏感数据。

## 误拦处理

如果用户反馈某次拦截为误拦：
1. 在 audit log 中标记 `override_bypass: true`
2. 记录具体的误拦模式
3. 如果同一模式误拦 ≥3 次，建议调整正则

## 豁免场景

- Agent 在 README/文档中**有意展示**示例 API Key（如 `sk-your-api-key-here`）→ 不拦截占位符
- 检测依据：如果 key 的值是 `your-` 开头 / `xxx` / `TODO` / `<your-` → 跳过
