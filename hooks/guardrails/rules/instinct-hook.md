---
name: guardrail-instinct-hook
description: "Instinct 提取 Guardrail 规则 — 会话结束时自动触发 instinct 提取并进行质量门禁"
tags: [Security, Guardrail, Learning]
---

# Instinct 提取 Guardrail 规则

## 触发时机

Output Guardrail 的最后一个规则，在 Stop Hook 触发前执行。

## 检查项

### 1. instinct 质量门禁

提取的 instinct 必须满足：
- `description` 非空且长度 ≥ 10 字符
- `type` 是合法值（pattern | trap | lesson | preference）
- `confidence` 在 [0, 1] 范围内
- `source.session_date` 是合法日期
- `body` 至少 50 字符（太短说明信息不足）

### 2. 去重检查

与现有 instinct 计算 Jaccard 相似度（基于 tags 和 description）：
- similarity ≥ 0.85 → 合并（更新 events + 提高 confidence）
- similarity 0.7-0.85 → 记录为 "related" 但不合并
- similarity < 0.7 → 新增

### 3. 频率门禁

同一 `source.trigger` 类型在 24 小时内触发 ≥10 次 → 标记为 "高频模式"，降低置信度 0.1（防止过拟合）

### 4. 域隔离

- 代码模式的 instinct 不进入 novel/news 域
- AI 写作相关 instinct 不进入 code 域
- domain 字段必须与当前会话 domain 一致

## 质量评分

```javascript
function qualityGate(instinct) {
  const checks = {
    description_length: instinct.description.length >= 10,
    valid_type: ['pattern','trap','lesson','preference'].includes(instinct.type),
    valid_confidence: instinct.confidence >= 0 && instinct.confidence <= 1,
    body_length: instinct.body.length >= 50,
    valid_date: !isNaN(Date.parse(instinct.source.session_date)),
    domain_match: instinct.domain === currentSession.domain
  };

  const passCount = Object.values(checks).filter(Boolean).length;
  return {
    passed: passCount === Object.keys(checks).length,
    score: passCount / Object.keys(checks).length,
    failures: Object.entries(checks).filter(([,v]) => !v).map(([k]) => k)
  };
}
```

## 禁止提取的内容

以下内容**不应**提取为 instinct：
- 临时性的一次性配置变更（如 "把端口改成 8080"）
- 纯个人偏好但无通用价值的设置（如 "我喜欢用 Tab 不用 Space"）
- 与 NEVER.md 直接冲突的规则（已被明确禁止）
- 包含敏感信息的内容（API Key、密码、Token）
