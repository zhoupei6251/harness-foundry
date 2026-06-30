# /health 命令

检查 Harness Foundry 系统健康度。

## 触发

- `/health` — 输出完整健康报告
- `/health --json` — JSON 格式输出
- `/health guardrail` — 仅检查 guardrail 配置
- `/health instinct` — 仅检查 instinct 状态
- `/health skill` — 仅检查 skill 覆盖率

## 工作流

1. 调用 `scripts/harness-health.js`
2. 解析输出，以可读格式展示
3. 如有 `warn` 或 `unhealthy` 项，提供修复建议

## 输出格式

```
=== Harness Foundry Health Report ===
Status: HEALTHY

✅ config_validity: All config files valid
✅ reference_integrity: All core files present
✅ execution_context: Model + Protocol present, 3 providers
✅ guardrail_config: 5 input rules / 5 output rules enabled
⚠️ instinct_quality: 12 instincts, avg confidence 0.52
✅ skill_coverage: 328/328 skills with SKILL.md
⚠️ agent_format_consistency: 5/97 agents with YAML frontmatter

Token Estimates:
  Core rules total lines: 2,041
  Entry overhead lines: 292
```

## 修复建议

系统根据 status 自动生成修复建议：
- `unhealthy` → 建议立即处理，列出具体失败项
- `degraded` → 建议在下次发版前处理
- `healthy` → 无需操作

详见 `core/observability/health-protocol.md`
