# 测试套件

> **P2-6 升级**：参考 gstack 的 3 层测试体系 —— "Catch 95% of issues for free"

## 测试分层

| 层级 | 内容 | 成本 | 速度 | 运行方式 |
|------|------|------|------|---------|
| **L1 静态验证** | Config schema / Agent 格式 / Skill meta / NEVER / novel-graph / novel 红线 / novel 引擎 / news 清单 / code 禁令 | 免费 | <2s | `bash tests/run-all-tests.sh` |
| **L2 集成测试** | Routing / Domain config / 路由触发 | 免费 | ~5s | `bash tests/run-all-tests.sh` |
| **L3-intelligence** | Skill 路由 / Agent 集成 / MCP 配置（静态） | 免费 | ~5s | `bash tests/run-all-tests.sh` |
| **Skill 行为测试** | eval runner（`run-skill-eval.js`，84 skill 中 3 个有测试：brainstorming / code-review / novel-protocol） | 免费 | ~5s | `node scripts/eval/run-skill-eval.js --all` |
| **L3 LLM 裁判** | 文档质量主观评分 | ~$0.30 | ~30s | 未实现（见 `L3-eval/eval-with-llm-judge.md`） |

## 测试脚本

### L1 静态验证

| 脚本 | 用途 |
|------|------|
| `L1-static/validate-config-schema.sh` | 验证所有 JSON/YAML 配置文件的结构合法性 |
| `L1-static/validate-agent-format.sh` | 检查 Agent 文件格式一致性（YAML frontmatter vs 纯 Markdown） |
| `L1-static/validate-skill-meta.sh` | 检查所有 SKILL.md 的基本元数据字段 |
| `L1-static/validate-never.sh` | 检查 NEVER.md 规则可与 guardrail 的覆盖情况 |
| `L1-static/validate-novel-graph.sh` | novel-graph 因果链熔断（正向 + 负向） |
| `L1-static/validate-novel-redlines.sh` | novel AI 痕迹红线回归（A/B 实验语料） |
| `L1-static/validate-novel-continuity.sh` | novel continuity 连续性引擎（伏笔回收 / 时间线 / 角色矛盾） |
| `L1-static/validate-novel-scorer.sh` | novel mechanical scorer 机械评分器（AI 高频词 / 字数 / 报告结构） |
| `L1-static/validate-novel-foreshadowing.sh` | novel foreshadowing DAG 伏笔图（逾期 / 闲置 / 循环 / 孤立 / 状态流转） |
| `L1-static/validate-novel-memory-health.sh` | novel memory health 记忆健康（健康分 / 角色解析 / 问题清单） |
| `L1-static/validate-novel-memory-injector.sh` | novel memory injector 记忆注入（提取 / 结构 / token 上限） |
| `L1-static/validate-novel-checkpoint.sh` | novel checkpoint 检查点（持久化 / 验证 / 容错） |
| `L1-static/validate-novel-export.sh` | novel export 多格式导出（JSON / JSONL / CSV / HTML / EPUB） |
| `L1-static/validate-novel-metrics.sh` | novel metrics 写作指标（属性计算 / 仪表板 / 周报） |
| `L1-static/validate-news-checklist.sh` | news 自检清单（夸大词 / AI 套路 / 单一信源） |
| `L1-static/validate-code-checklist.sh` | code 自检清单（空 catch / SELECT * / N+1 / 硬编码密钥 / 日志泄敏感等） |

### L2 集成测试

| 脚本 | 用途 |
|------|------|
| `L2-integration/validate-routing.sh` | 验证 intent-routing.md 中所有引用路径不存在死链接 |
| `L2-integration/validate-domain-config.sh` | 验证 domain-config.yaml 中引用的 agents/skills 都存在 |
| `L2-integration/validate-route-triggers.sh` | 路由触发：三域高频意图 → 路由表命中 + 装配 skill 存在性 |

### L3-intelligence（静态，已收编进 verify.sh）

| 脚本 | 用途 |
|------|------|
| `L3-intelligence/test-skill-routing.sh` | Intelligence Layer Skill 路由配置检查 |
| `L3-intelligence/test-agent-integration.sh` | Agent 与 codebase-memory 集成检查 |
| `L3-intelligence/test-mcp-config.sh` | MCP 配置与 bootstrap/sync 集成检查 |

### L3 评估（未实现，文档阶段）

| 文档 | 用途 |
|------|------|
| `L3-eval/eval-with-llm-judge.md` | LLM 裁判评估计划（脚本未创建，见文档内现状盘点） |

### 旧版脚本（向后兼容）

| 脚本 | 用途 | 状态 |
|------|------|------|
| `validate-config.sh` | 验证配置完整性（v1） | 保留兼容 |
| `validate-references.sh` | 验证文件引用完整性（v1） | 保留兼容 |

## 快速开始

```bash
# 运行所有 L1 + L2 + L3-intelligence 测试
bash harness-foundry/tests/run-all-tests.sh

# 或指定项目根目录
bash harness-foundry/tests/run-all-tests.sh /path/to/project

# Skill 行为测试（有测试的 skill 必须全过）
node harness-foundry/scripts/eval/run-skill-eval.js --all
```

## L1 与 L2 的核心原则

> **"Catch 95% of issues for free"** — L1 + L2 覆盖绝大多数问题，L3 LLM 裁判仅在发版前手动触发（未实现）

- L1: 每次 `bash tests/run-all-tests.sh` 自动运行
- L2: 每次 push 前运行
- L3-intelligence: 静态测试，随 verify.sh 一起运行
- L3 LLM 裁判: 未实现（见 `L3-eval/eval-with-llm-judge.md`）

## CI 集成

```yaml
# .github/workflows/harness-test.yml
name: Test Harness Foundry

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: L1 + L2 Tests
        run: bash harness-foundry/tests/run-all-tests.sh
```

## 最佳实践

1. **提交前运行测试**：确保配置完整性和引用一致性
2. **添加新 agent/skill 后运行**：确保 domain-config 引用正确
3. **修改 hooks/guardrail 后运行**：确保 JSON 格式正确
4. **发版前运行 L3**：确保文档质量和 Skill 触发精度
