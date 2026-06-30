# L3 评估：LLM 裁判验证（可选增强）

> 参考 gstack 的 L3 LLM 裁判层。当前为文档阶段，待 harness-foundry 成熟后激活。

## 概述

L1 静态测试（免费/<2s）和 L2 集成测试（本地）覆盖了 95% 的问题。
L3 是可选增强层，仅在以下场景使用：
- 发版前的质量审计
- 新增核心 skill/agent 的文档评审
- PR review 时的自动质量评分

## 评估维度

| 维度 | 裁判模型 | 评分标准 | 成本 |
|------|---------|---------|------|
| 文档清晰度 | Sonnet | 0-100 分，基于可操作性、例子质量、结构完整性 | ~$0.05 |
| 规则完整性 | Opus | 检查是否覆盖边界情况、是否有歧义、与 NEVER.md 一致性 | ~$0.15 |
| Skill 触发精度 | Opus | 给定 10 个测试 prompt，检查 skill 是否被正确触发 | ~$0.10 |

## 触发方式

```bash
# 评估单个 skill
EVALS=1 bash tests/L3-eval/eval-skill.sh <skill-slug>

# 评估所有变更的 skill（PR 时）
EVALS=1 bash tests/L3-eval/eval-diff.sh

# 全量评估（发版前，~$100/次）
EVALS=1 bash tests/L3-eval/eval-all.sh
```

## 注意事项

- L3 评估**不阻塞** CI，只在 `EVALS=1` 时手动触发
- 评分结果写入 `.ai-runtime-artifacts/eval-reports/`
- 由于依赖 LLM API 调用，L3 不适合频繁运行
- 建议频率：发版前 1 次 + 月度审计
