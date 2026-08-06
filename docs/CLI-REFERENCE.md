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

## Guardrail（静态参考）

Guardrail 双层防护配置为静态参考（不挂载 hooks）：

```bash
# 查看配置（Input 并行 + Output 顺序）
cat hooks/guardrails/guardrail-config.json

# 审计日志（运行时人工启用后产生）
.ai-runtime-artifacts/guardrail-audit.jsonl
```

---

## 经验沉淀

```bash
# 用户触发（推荐）：说"记住这个"，写入 references/instincts/
# 手动整理：复盘时更新 references/traps.md 或 instincts/
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
