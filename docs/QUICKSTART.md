# Harness Foundry 快速开始

> **5 分钟了解 Harness Foundry，在你的项目中使用它**

---

## 1 分钟：什么是 Harness Foundry？

一个**软件开发工具集**，包含：
- **Skills**：可复用的工作流程（设计、计划、TDD、调试、审查）
- **Agents**：专业角色（coder、reviewer、debugger）
- **规则**：强制设计门禁、两阶段审查
- **工具**：安全扫描、Dashboard、连续学习

---

## 2 分钟：快速集成

### 方式 A：Git 拉取（推荐）

```bash
cd your-project/
git clone https://github.com/your-org/harness-foundry.git
```

### 方式 B：作为子模块

```bash
git submodule add https://github.com/your-org/harness-foundry.git harness-foundry
```

---

## 3 分钟：立即使用

### 在 Claude Code 中对话

```
用户：请用 brainstorming skill 设计用户登录功能
Claude：[触发设计流程，提问确认需求，展示方案...]
```

### 常用对话模板

```markdown
# 设计新功能
"用 brainstorming 设计 X 功能"

# 制定计划
"设计已批准，请制定实施计划"

# 开发
"用 TDD 方式实现这个功能"

# 调试
"帮我调试这个 bug"

# 审查
"请审查这段代码"
```

---

## 4 分钟：命令行工具

```bash
cd harness-foundry

# 启动 Dashboard（可视化浏览）
npm run dashboard

# 安全扫描
node scripts/security/scan.js

# 测试 skills
node scripts/eval/run-skill-eval.js --all
```

---

## 5 分钟：理解工作流程

### 完整流程

```
想法 → brainstorming（设计） → [批准] → writing-plans（计划） → [批准]
   → coder（实现） → spec 审查 → code 审查 → 完成
```

### 简单流程（小改动）

```
想法 → brainstorming → 实现 → 简单审查 → 完成
```

---

## 核心 Skills

| Skill | 何时用 | 做什么 |
|-------|--------|--------|
| `brainstorming` | 想加新功能时 | 设计、提问、展示方案 |
| `writing-plans` | 设计批准后 | 拆分任务、写步骤 |
| `test-driven-development` | 开发时 | 红绿重构 |
| `systematic-debugging` | 遇到 bug 时 | 根因分析 |
| `requesting-code-review` | 实现完成后 | 两阶段审查 |

---

## 常见问题

**Q: 需要全部功能吗？**
A: 不需要，告诉 Claude 只用你需要的。

**Q: 跳过设计门禁？**
A: 说"这是小改动，直接改"即可。

**Q: 在哪看文档？**
A: `harness-foundry/docs/USER-GUIDE.md`

---

## 下一本

- [完整用户指南](./USER-GUIDE.md) - 详细说明
- [API 参考](./docs/plans/) - 开发者文档
