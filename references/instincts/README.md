# Instinct 目录

> **P1-3 渐进式技能进化**：Session 结束时提取的 instinct 自动存入此目录。积累到一定数量（同 domain ≥5 个，avg_confidence ≥0.7）后触发 `/evolve` 生成 Skill 提案。

## 目录结构

```
references/instincts/
├── README.md              # 本文件
├── project/               # 项目级 instinct（当前项目）
│   └── <project-id>/
│       ├── instincts/     # instinct YAML 文件
│       ├── sessions/      # session summary
│       └── clusters/      # 聚类中间产物
└── global/                # 全局 instinct（跨项目）
    └── instincts/         # instinct YAML 文件
```

## instinct YAML 格式

```yaml
id: "instinct-{domain}-{yyyyMMdd}-{nonce}"
domain: code | novel | news | shared
type: pattern | trap | lesson | preference
confidence: 0.0-1.0
description: "一句话描述"
source:
  session_date: "YYYY-MM-DD"
  trigger: "用户纠正" | "重复模式" | "有效方案" | "用户偏好"
events:
  - type: successful_application | user_affirmation | user_rejection | led_to_error
    date: "YYYY-MM-DD"
    note: "简要说明"
tags: ["tag1", "tag2"]
evolved_to: null | "skill-slug"
body: |
  <详细内容：对 pattern 类型是解决方案，对 trap 类型是根因+修复，对 lesson 是洞察>
```

## 生命周期

```
Session Stop Hook → 提取 instinct → 写入 project/ 或 global/
   → instinct-cli stats 查看分布
   → domain 内 ≥5 个且 avg_confidence ≥0.7
   → /evolve 生成候选 Skill
   → 用户确认 → 生成 SKILL.md → instinct 标记 evolved_to
   → 每 30 天 prune（confidence < 0.3 自动删除）
```

## 置信度计算

参见 `scripts/instinct-cli.js` 中的 `calculateScore()` 函数。

核心公式：
```
confidence = base_confidence
  + (successful_application × 0.1)
  + (user_affirmation × 0.2)
  - (user_rejection × 0.1)
  - (led_to_error × 0.15)
  - (time_decay: 30天未用 -0.05，每额外30天再 -0.05)
```
范围：[0, 1]
