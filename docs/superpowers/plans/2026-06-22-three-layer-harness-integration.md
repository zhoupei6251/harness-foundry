# 三层 Harness 集成实施计划

> **状态说明**：本计划描述的是 2026-06-22 的实施步骤。2026-06-25 已完成第三方整合，所有 skill 统一在 `skills/` 扁平结构下，`third-party/` 目录已删除。当前架构见 [README.md](../../../README.md)。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 在 aigc_platfrom_back 项目中以 Cherry-pick 方式叠加 Superpowers 4 个缺失 skill + ECC 3 个专项 agent，零冲突。

**Architecture:** L1 主=harness-foundry（不动）/ L2 辅=Superpowers 补缺（4 个 skill）/ L3 按需=ECC 专项（3 个 agent）。

**Tech Stack:** 文件复制（cp）+ JSON 来源追踪 + Bash 跳过规则。

**TDD Required:** N/A（文件型；每 Task 以文件存在性与 `_meta.json` 完整性校验替代）。

---

## 现状

- ✅ Spec 已批准（2026-06-22）
- ✅ `harness-foundry` 已包含 Superpowers 80% 核心 skill
- ✅ 4 个 Superpowers 缺失 skill 已 cherry-pick
- ✅ 3 个 ECC 专项 agent 已 cherry-pick
- ✅ 真相源已迁移至 `skills/` 和 `agents/`（扁平化，无 third-party/）
- ✅ `sync-skills.sh` 统一管理投影（SKIP_FROM_SYNC 保留第三方 cherry-pick）
- ✅ 原 `ECC/`、`superpowers/` 目录已删除
- ✅ CI 验证已集成（`scripts/verify.sh`）

---

### Task 1: 准备阶段 — 校验上游完整性

**Files:** 无（只读）

- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\superpowers\skills\subagent-driven-development\SKILL.md` 存在
- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\superpowers\skills\dispatching-parallel-agents\SKILL.md` 存在
- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\superpowers\skills\using-git-worktrees\SKILL.md` 存在
- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\superpowers\skills\executing-plans\SKILL.md` 存在
- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\ECC\agents\java-reviewer.md` 存在
- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\ECC\agents\security-reviewer.md` 存在
- [x] 确认 `d:\work\xinyue\aigc_platfrom_back\ECC\agents\database-reviewer.md` 存在

### Task 2: L2 辅层 — 复制 Superpowers 4 个 skill

**Files:**
- Create: `.trae/skills/subagent-driven-development/SKILL.md`
- Create: `.trae/skills/subagent-driven-development/_meta.json`
- Create: `.trae/skills/subagent-driven-development/implementer-prompt.md`
- Create: `.trae/skills/subagent-driven-development/task-reviewer-prompt.md`
- Create: `.trae/skills/subagent-driven-development/scripts/review-package`
- Create: `.trae/skills/subagent-driven-development/scripts/sdd-workspace`
- Create: `.trae/skills/subagent-driven-development/scripts/task-brief`
- Create: `.trae/skills/dispatching-parallel-agents/SKILL.md`
- Create: `.trae/skills/dispatching-parallel-agents/_meta.json`
- Create: `.trae/skills/using-git-worktrees/SKILL.md`
- Create: `.trae/skills/using-git-worktrees/_meta.json`
- Create: `.trae/skills/executing-plans/SKILL.md`
- Create: `.trae/skills/executing-plans/_meta.json`
- Create: `.trae/skills/executing-plans/plan-document-reviewer-prompt.md`

- [ ] 复制 `subagent-driven-development` 完整目录到 `.trae/skills/`
- [ ] 复制 `dispatching-parallel-agents` 到 `.trae/skills/`
- [ ] 复制 `using-git-worktrees` 到 `.trae/skills/`
- [ ] 复制 `executing-plans` 到 `.trae/skills/`
- [ ] 为 4 个 skill 各创建 `_meta.json`（标记 `source: superpowers`）
- [ ] 校验复制完整性（比对文件数量与大小）

### Task 3: L3 按需层 — 复制 ECC 3 个专项 agent

**Files:**
- Create: `.trae/agents/ecc-java-reviewer.md`
- Create: `.trae/agents/ecc-java-reviewer.meta.json`
- Create: `.trae/agents/ecc-security-reviewer.md`
- Create: `.trae/agents/ecc-security-reviewer.meta.json`
- Create: `.trae/agents/ecc-database-reviewer.md`
- Create: `.trae/agents/ecc-database-reviewer.meta.json`

- [ ] 复制 `ECC/agents/java-reviewer.md` → `.trae/agents/ecc-java-reviewer.md`
- [ ] 复制 `ECC/agents/security-reviewer.md` → `.trae/agents/ecc-security-reviewer.md`
- [ ] 复制 `ECC/agents/database-reviewer.md` → `.trae/agents/ecc-database-reviewer.md`
- [ ] 为 3 个 agent 各创建 `.meta.json`（标记 `source: ECC`）

### Task 4: 登记与防冲突

**Files:**
- Modify: `harness-foundry/adapters/trae/skill-binding.md`（新增"第三方来源"章节）
- Modify: `harness-foundry/agents/registry.md`（新增 ECC agent 注册）
- Modify: `harness-foundry/scripts/sync-skills.sh`（新增 SKIP_FROM_SYNC 跳过规则）

- [ ] `skill-binding.md` 新增"第三方来源"小节，列出 4 个 Superpowers skill
- [ ] `agents/registry.md` 新增 3 个 ECC agent 的 role/source/on_demand 字段
- [ ] `sync-skills.sh` 新增 `SKIP_FROM_SYNC` 数组，避免被覆盖

### Task 5: 验证 — 文件存在性与完整性

- [ ] 4 个 Superpowers skill 目录在 `.trae/skills/` 下完整存在
- [ ] 3 个 ECC agent 在 `.trae/agents/` 下完整存在
- [ ] 每个 `_meta.json` 都包含 `source` / `source_version` / `imported_at`
- [ ] `skill-binding.md` 与 `registry.md` 已更新
- [ ] `sync-skills.sh` 的 SKIP_FROM_SYNC 包含 4 个 slug
- [ ] harness-foundry 现有 skill 文件未被修改（git status 校验）

### Task 6: 更新 state.json

**Files:**
- Modify: `.ai-runtime-artifacts/memory/state.json`

- [ ] `active_phase` 设为 `idle`
- [ ] `last_updated` 更新为当前时间
- [ ] `context_summary` 新增"三层集成完成"记录