# 贡献指南

欢迎为 Harness Kit 做贡献！

## 行为准则

请保持友好与建设性。所有参与者都应被尊重，无论经验水平。

## 我能贡献什么？

### 1. 新增 Skill

```bash
# 1. 在 skills/harness/ 下创建新 skill
mkdir -p skills/harness/my-new-skill

# 2. 写 SKILL.md（含 YAML frontmatter）
cat > skills/harness/my-new-skill/SKILL.md <<'EOF'
---
name: my-new-skill
description: 简短描述这个 skill 的用途（AI 自动用此触发）
---

# My New Skill

详细使用说明...
EOF

# 3. 写 _meta.json
cat > skills/harness/my-new-skill/_meta.json <<'EOF'
{
  "source": "harness",
  "tags": ["wu"],
  "added_at": "2026-06-22"
}
EOF

# 4. 更新 skills/INDEX.md
```

### 2. 新增 Agent

```bash
# 1. 在 agents/harness/ 下创建 agent 定义
# 2. 写 agent 定义（含 YAML frontmatter + Markdown）
# 3. 更新 agents/README.md
```

### 3. 修改规则

- `core/` 或 `adapters/` 的修改需通过 PR
- 至少 1 个 reviewer 批准
- 必须通过 CI（`bash scripts/verify.sh`）

### 4. 升级第三方 Skill

详见 [`README.md` § 升级上游 Skill](README.md#升级上游第三方-skill)。

```bash
# 1. 临时克隆上游
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/sp
git clone --depth 1 https://github.com/affaan-m/ECC.git /tmp/ecc

# 2. diff 比对
diff -r /tmp/sp/skills/<slug> third-party/superpowers/skills/<slug>

# 3. 手工同步变更
# 4. 更新 _meta.json 的 source_version
# 5. 跑 sync 投影
bash scripts/sync-third-party.sh

# 6. 提交 + 描述升级内容
# 7. 清理
rm -rf /tmp/sp /tmp/ecc
```

## PR 流程

1. **Fork** 仓库
2. **创建 feature 分支**：`git checkout -b feat/my-new-skill`
3. **提交**：`git commit -m "feat(skills): add my-new-skill"`
4. **本地验证**：`bash scripts/verify.sh`
5. **推送到 fork**：`git push origin feat/my-new-skill`
6. **创建 PR** 描述清楚变更动机与内容

## Commit 信息规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <subject>

<body>

<footer>
```

类型：
- `feat`：新功能
- `fix`：修复 bug
- `docs`：仅文档变更
- `refactor`：代码重构（不修复 bug 也不加功能）
- `test`：增加或修改测试
- `chore`：构建过程或辅助工具变更

示例：
- `feat(skills): add my-new-skill for X scenario`
- `fix(scripts): handle Windows CRLF in manifest parsing`
- `docs(readme): clarify third-party upgrade process`

## 质量要求

每个 PR 必须满足：

- [ ] 通过 CI（GitHub Actions / Gitee Go）
- [ ] 至少 1 个 reviewer 批准
- [ ] 新增 skill/agent 在 INDEX.md / README.md 登记
- [ ] 第三方 cherry-pick 标注来源与版本

## License

提交即表示同意按 [MIT License](LICENSE) 授权您的贡献。

## 联系方式

- GitHub Issues：https://github.com/zhoupei6251/harness-kit/issues
- GitHub Pull Requests：https://github.com/zhoupei6251/harness-kit/pulls