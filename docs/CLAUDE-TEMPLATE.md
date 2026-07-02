# Harness Foundry 集成模板

> 将此文件内容复制到你的项目 `.claude/CLAUDE.md`，即可启用 Harness Foundry

---

```markdown
# 项目配置

## 项目信息
- 项目名：your-project-name
- 技术栈：你的技术栈
- 规范：参考 harness-foundry/rules/

## Harness Foundry

本项目使用 [harness-foundry](../harness-foundry/) 作为开发工具集。

### 启用功能

#### 1. 设计门禁（推荐开启）
实现前必须先完成设计并获得批准：
- 参考：`../harness-foundry/core/rules/design-gate.md`
- 简单改动可以说"直接改，不需要设计"

#### 2. 两阶段审查
实现完成后进行：
1. Spec 合规审查（是否满足设计）
2. 代码质量审查（风格/安全/测试）
- 参考：`../harness-foundry/core/review/two-stage-protocol.md`

#### 3. 连续学习
从会话中自动提取有用的模式：
- 保存位置：`~/.claude/memory/learned/`
- 参考：`../harness-foundry/skills/continuous-learning/SKILL.md`

### 开发流程

```
想法 → brainstorming → 设计批准 → writing-plans → 实现 → 审查 → 完成
```

### 可用 Skills

| Skill | 命令 | 何时用 |
|-------|------|--------|
| brainstorming | `/skill brainstorming` | 设计新功能 |
| writing-plans | `/skill writing-plans` | 制定实施计划 |
| test-driven-development | `/skill test-driven-development` | TDD 开发 |
| systematic-debugging | `/skill systematic-debugging` | 调试 bug |
| requesting-code-review | `/skill requesting-code-review` | 代码审查 |
| two-stage-review | `/skill two-stage-review` | 两阶段审查 |
| continuous-learning | `/skill continuous-learning` | 查看学习成果 |
| auto-compact | `/skill auto-compact` | 上下文压缩建议 |

### 可用命令

```bash
# Dashboard（需要先 cd harness-foundry）
npm run dashboard

# 安全扫描
node harness-foundry/scripts/security/scan.js

# Eval 测试
node harness-foundry/scripts/eval/run-skill-eval.js --all
```

### 安全设置

```bash
# 启用连续学习（默认开启）
export CONTINUOUS_LEARNING=enabled

# Token 优化
export MAX_THINKING_TOKENS=10000
```

## 开发规范

### 必须
- [ ] 实现前先设计（除简单改动外）
- [ ] 写测试（参考 TDD skill）
- [ ] 实现后审查

### 推荐
- [ ] 使用 brainstorming 设计复杂功能
- [ ] 使用 systematic-debugging 调试
- [ ] 定期运行安全扫描

## 禁止

- ❌ 不经设计直接实现复杂功能
- ❌ 提交未审查的代码
- ❌ 硬编码 secrets（使用环境变量）
```

---

## 使用方式

### 1. 将 harness-foundry 克隆到项目根目录

```bash
git clone https://github.com/your-org/harness-foundry.git
```

### 2. 创建/更新 CLAUDE.md

```bash
# 如果已有 CLAUDE.md，将上方内容追加
# 如果没有，直接创建
cp harness-foundry/docs/CLAUDE-TEMPLATE.md .claude/CLAUDE.md
```

### 3. 编辑 CLAUDE.md

根据你的项目修改：
- 项目名
- 技术栈
- 开发规范

### 4. 开始使用

在 Claude Code 中：

```
用户：我想添加用户认证
Claude：[自动触发 brainstorming，设计中...]
```

---

## 自定义

### 只使用部分功能？

在 CLAUDE.md 中注释掉不需要的部分，或告诉 Claude：

```
我只用 brainstorming 和 requesting-code-review
```

### 添加项目特定规则？

在 `.claude/rules/` 创建你自己的规则文件。

### 禁用连续学习？

```bash
export CONTINUOUS_LEARNING=disabled
```
