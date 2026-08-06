# L3 评估：LLM 裁判验证（可选增强）

> **2026-08-06 修正**：原文档声称存在 `eval-skill.sh` / `eval-diff.sh` / `eval-all.sh`，实际这些脚本从未创建（L3-eval 目录仅本文档）。已降级为诚实说明。Skill 行为测试的真实入口是 `scripts/eval/run-skill-eval.js`（已接入 verify.sh [8/9]）。

## 概述

L1 静态测试（免费/<2s）、L2 集成测试（本地）、skill eval 行为测试（`run-skill-eval.js`）覆盖了绝大部分问题。
本层是可选的 **LLM 裁判**增强——用 LLM 对 skill 文档质量做主观评分，**尚未实现**。

## 现状（2026-08-06 盘点）

| 项 | 状态 |
|----|------|
| `scripts/eval/run-skill-eval.js` | ✅ 存在，已接入 verify.sh [8/9]；84 skill 中 1 个（brainstorming）有 11 项行为测试 |
| `scripts/eval/skill-evaluator.js` | ✅ 存在（编程接口） |
| `tests/eval/skills/brainstorming/` | ✅ 测试骨架（prompt.txt / expected.md / 2 个 .test.js） |
| `tests/eval/runner.js` | ❌ 不存在（framework.md 声称存在） |
| `eval-skill.sh` / `eval-diff.sh` / `eval-all.sh` | ❌ 不存在（本文档旧版声称存在） |

## 未来实现计划（若需 LLM 裁判层）

1. 编写 `eval-skill.sh <slug>`：调 `run-skill-eval.js` + LLM 评分 prompt
2. 编写 `eval-diff.sh`：git diff 变更的 skill 列表 → 逐个评估
3. 编写 `eval-all.sh`：全量（发版前，~$100/次）
4. 评分结果写入 `.ai-runtime-artifacts/eval-reports/`

## 注意事项

- 本层**不阻塞** CI，只在 `EVALS=1` 时手动触发
- 建议频率：发版前 1 次 + 月度审计

## 替代方案（今天就能用）

需要客观行为验证时，用已接入 CI 的静态替代品：

```bash
# Skill 行为测试（有测试的 skill 必须全过）
node scripts/eval/run-skill-eval.js --all

# 路由触发测试（意图 → 路由表命中 + skill 存在性）
bash tests/L2-integration/validate-route-triggers.sh
```
