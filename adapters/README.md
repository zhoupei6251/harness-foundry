# Adapters — 平台适配层

> 平台物理绑定（薄壳）。每个适配器把 harness 的逻辑原语映射到对应 IDE 的配置面。

## 适配器状态一览

| 适配器 | 状态 | 投影目标 | 说明 |
|--------|------|---------|------|
| **claude** | ✅ 可用 | `.claude/` | Claude Code。bindings + capability-matrix；skills 由 sync-skills 投影 |
| **trae** | ✅ 可用 | `.trae/` | Trae IDE。bindings + capability-matrix + skill-binding + trae-quick-ref |
| **codex** | 📄 设计文档 | — | Codex Desktop/CLI。routing.codex + overlay + bindings；**投影未实现**（无 bootstrap target） |
| **workbuddy** | 📄 设计文档 | `.codebuddy/` | WorkBuddy（= CodeBuddy 双品牌）。README + bindings + capability-matrix + skill-mapping；**投影源未提供**（bootstrap 有 target 但源目录缺失时跳过） |
| **TEMPLATE** | — | — | 新适配器模板 |

## 投影机制

```bash
# 从 harness-foundry 投影适配器 + skills 到项目（sh）
bash scripts/bootstrap.sh --target all          # claude + trae + workbuddy + AGENTS.md
bash scripts/bootstrap.sh --target claude       # 仅 Claude Code
bash scripts/bootstrap.sh --target trae         # 仅 Trae
bash scripts/bootstrap.sh --target workbuddy    # 仅 WorkBuddy（源缺失时 warn）

# PowerShell 等价（target 集合与 sh 对齐）
.\scripts\bootstrap.ps1 -Target all
```

## 使用说明

- **claude / trae**：完整可用。`bootstrap.sh` 投影 AGENTS.md 与 skills，路由表见 `core/intent-routing.md`。
- **codex / workbuddy**：当前为**设计文档**（bindings / capability-matrix / routing 已就绪），投影实现未完成。如需启用，先补投影源目录（见各适配器 README），再接入 bootstrap。
