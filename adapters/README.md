# Adapters — 平台适配层

> 平台物理绑定（薄壳）。每个适配器把 harness 的逻辑原语映射到对应 IDE 的配置面。

## 适配器状态一览

| 适配器 | 状态 | 投影目标 | 说明 |
|--------|------|---------|------|
| **claude** | ✅ 可用 | `.claude/` | Claude Code（含桌面版）。bindings + capability-matrix；skills 由 sync-skills 投影 |
| **trae** | ✅ 可用 | `.trae/` | Trae IDE（含 Trae Work）。bindings + capability-matrix + skill-binding + trae-quick-ref |
| **codex** | ✅ 可用 | `.codex/` | Codex Desktop / CLI / ChatGPT 桌面版（共享配置栈）。README + overlay + routing + bindings + skill-mapping + `.codex/` 投影源 |
| **workbuddy** | ✅ 可用 | `.codebuddy/` | WorkBuddy（= CodeBuddy 双品牌）。README + bindings + capability-matrix + skill-mapping + `.codebuddy/` 投影源 |
| **TEMPLATE** | — | — | 新适配器模板 |

## 投影机制

```bash
# 从 harness-foundry 投影适配器 + skills 到项目（sh）
bash scripts/bootstrap.sh --target all          # claude + trae + codex + workbuddy + AGENTS.md
bash scripts/bootstrap.sh --target claude       # 仅 Claude Code
bash scripts/bootstrap.sh --target trae         # 仅 Trae
bash scripts/bootstrap.sh --target codex        # 仅 Codex
bash scripts/bootstrap.sh --target workbuddy    # 仅 WorkBuddy

# PowerShell 等价（target 集合与 sh 对齐）
.\scripts\bootstrap.ps1 -Target all
```

## 使用说明

- **claude / trae / codex / workbuddy**：全部可用。`bootstrap.sh` 投影各平台配置与 skills（codex/workbuddy 共用 `.agents/skills/` 开放标准目录），路由表见 `core/intent-routing.md`。
