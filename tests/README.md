# 测试套件

> **P2-6 升级**：参考 gstack 的 3 层测试体系 —— "Catch 95% of issues for free"

## 测试分层

| 层级 | 内容 | 成本 | 速度 | 运行方式 |
|------|------|------|------|---------|
| **L1 静态验证** | Config schema / Agent 格式 / Skill meta / NEVER 规则 | 免费 | <2s | `bash tests/run-all-tests.sh` |
| **L2 集成测试** | Routing 完整性 / Domain config 引用一致性 / 文件引用 | 免费 | ~5s | `bash tests/run-all-tests.sh` |
| **L3 LLM 裁判** | 文档清晰度 / 规则完整性 / Skill 触发精度 | ~$0.30 | ~30s | `EVALS=1 bash tests/L3-eval/...` |

## 测试脚本

### L1 静态验证

| 脚本 | 用途 |
|------|------|
| `L1-static/validate-config-schema.sh` | 验证所有 JSON/YAML 配置文件的结构合法性 |
| `L1-static/validate-agent-format.sh` | 检查 Agent 文件格式一致性（YAML frontmatter vs 纯 Markdown） |
| `L1-static/validate-skill-meta.sh` | 检查所有 SKILL.md 的基本元数据字段 |
| `L1-static/validate-never.sh` | 检查 NEVER.md 规则可与 guardrail 的覆盖情况 |

### L2 集成测试

| 脚本 | 用途 |
|------|------|
| `L2-integration/validate-routing.sh` | 验证 intent-routing.md 中所有引用路径不存在死链接 |
| `L2-integration/validate-domain-config.sh` | 验证 domain-config.yaml 中引用的 agents/skills 都存在 |

### L3 评估（可选，手动触发）

| 文档 | 用途 |
|------|------|
| `L3-eval/eval-with-llm-judge.md` | LLM 裁判评估文档（当前为文档阶段） |

### 旧版脚本（向后兼容）

| 脚本 | 用途 | 状态 |
|------|------|------|
| `validate-config.sh` | 验证配置完整性（v1） | 保留兼容 |
| `validate-references.sh` | 验证文件引用完整性（v1） | 保留兼容 |

## 快速开始

```bash
# 运行所有 L1 + L2 测试
bash harness-foundry/tests/run-all-tests.sh

# 或指定项目根目录
bash harness-foundry/tests/run-all-tests.sh /path/to/project

# 运行 L3 评估（需要 LLM API key）
EVALS=1 bash harness-foundry/tests/run-all-tests.sh
```

## L1 与 L2 的核心原则

> **"Catch 95% of issues for free"** — L1 + L2 覆盖绝大多数问题，L3 仅在发版前手动触发

- L1: 每次 `bun test` / `bash tests/run-all-tests.sh` 自动运行
- L2: 每次 push 前运行
- L3: 发版前 + 月度审计，`EVALS=1` 手动激活

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
