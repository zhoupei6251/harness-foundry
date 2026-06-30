---
name: health-protocol
description: "Harness Foundry 健康检查协议 — 定义系统健康度的指标、阈值和响应"
tags: [Standard, Observability]
---

# Health-check 可观测性协议

> P2-7: 参考 gstack 的 3×50K 环形缓冲区 + ECC v2 的 Rust control plane 设计理念

## 健康状态定义

| 状态 | 含义 | 触发条件 |
|------|------|---------|
| `healthy` | 所有检查通过 | 所有 check status = pass |
| `degraded` | 部分子系统有警告 | ≥1 warn, 0 fail |
| `unhealthy` | 关键子系统失败 | ≥1 fail |

## 检查项

### 1. config_validity — 配置合法性
- **pass**: 所有配置文件存在且格式正确（JSON parse 成功，YAML 结构有效）
- **fail**: 配置文件缺失或格式错误

### 2. reference_integrity — 引用完整性
- **pass**: 所有 core/ 文件存在
- **warn**: 部分非关键文件缺失

### 3. execution_context — 执行环境 (P0-1)
- **pass**: model.yaml + provider-protocol.md 均存在
- **fail**: 文件缺失

### 4. guardrail_config — Guardrail 配置 (P0-2)
- **pass**: guardrail-config.json 存在且至少 1 条 input + 1 条 output 规则启用
- **warn**: 配置存在但规则数为 0

### 5. instinct_quality — Instinct 质量 (P1-3)
- **pass**: 有 instinct 且 avg_confidence ≥ 0.7
- **warn**: 有 instinct 但 avg_confidence < 0.7 或 total = 0
- **info**: 尚未记录任何 instinct（新项目）

### 6. skill_coverage — Skill 覆盖率
- **pass**: 所有 skill 目录有 SKILL.md
- **warn**: 部分 skill 目录缺失 SKILL.md

### 7. agent_format_consistency — Agent 格式一致性
- **pass**: YAML frontmatter 覆盖率 > 50%
- **warn**: YAML frontmatter 覆盖率 ≤ 50%

## 指标 schema

参见 `core/observability/metrics-schema.json`

## 定期检查

建议频率：
- **每次会话启动**: config_validity + reference_integrity
- **每周**: 完整健康检查
- **发版前**: 完整健康检查 + instinct 质量审计
