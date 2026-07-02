# Harness Foundry CLI Reference

> 常用命令速查

---

## Dashboard

```bash
cd harness-foundry
npm run dashboard
# 或
python scripts/dashboard/dashboard.py
```

---

## 安全扫描

```bash
# 扫描整个项目
node scripts/security/scan.js

# 指定路径
node scripts/security/scan.js --path ./src

# 指定类型
node scripts/security/scan.js --type secrets
node scripts/security/scan.js --type hooks
node scripts/security/scan.js --type all

# JSON 输出
node scripts/security/scan.js --format json
```

---

## Eval 测试

```bash
# 测试单个 skill
node scripts/eval/run-skill-eval.js --skill brainstorming

# 测试全部
node scripts/eval/run-skill-eval.js --all

# 指定类型
node scripts/eval/run-skill-eval.js --skill brainstorming --type behavior
node scripts/eval/run-skill-eval.js --skill brainstorming --type output
```

---

## 可视化伴侣

```bash
# 启动服务器
node scripts/visual-companion/server.js --open

# 访问
http://localhost:3847
```

---

## Hooks

```bash
# 检查设计门禁状态
node hooks/pre-implementation/check-gate.js --status

# 清除批准状态
node hooks/pre-implementation/check-gate.js --clear

# 运行安全预检
node hooks/security/pre-prompt-guard.js --input "your prompt"
```

---

## 连续学习

```bash
# 提取模式（手动触发）
node core/memory/continuous-learning/extractor.js

# 查看学习成果
ls ~/.claude/memory/learned/

# 查看统计
cat ~/.claude/memory/learned/learned.json
```

---

## Skill 测试（手动）

```bash
# brainstorming
node scripts/eval/run-skill-eval.js --skill brainstorming

# writing-plans
node scripts/eval/run-skill-eval.js --skill writing-plans

# test-driven-development
node scripts/eval/run-skill-eval.js --skill test-driven-development

# requesting-code-review
node scripts/eval/run-skill-eval.js --skill requesting-code-review
```

---

## 项目集成

```bash
# 在项目中创建符号链接（可选）
ln -s /path/to/harness-foundry/ ./harness-foundry

# 运行项目特定扫描
node harness-foundry/scripts/security/scan.js --path ./src
```

---

## 环境变量

```bash
# 连续学习
export CONTINUOUS_LEARNING=enabled

# Token 优化
export MAX_THINKING_TOKENS=10000
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50

# 安全严格模式
export SECURITY_SCAN_STRICT=true
```

---

## 快捷操作

| 操作 | 命令 |
|------|------|
| 启动 Dashboard | `npm run dashboard` |
| 安全扫描 | `node scripts/security/scan.js` |
| 测试所有 Skills | `node scripts/eval/run-skill-eval.js --all` |
| 启动可视化 | `node scripts/visual-companion/server.js --open` |
