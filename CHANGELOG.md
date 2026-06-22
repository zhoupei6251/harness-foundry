# Changelog

所有值得注意的变更都会记录在这个文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
本项目遵循 [语义化版本](https://semver.org/) 规范。

## [Unreleased]

### Fixed

- `sync-third-party.sh`：`ECC_AGENTS` 数组从硬编码 3 个改为 `discover_ecc_agents()` 函数动态扫描 `third-party/ecc/agents/*.md`，实际发现 70 个 ECC agent，与 README 一致；新增 macOS BSD find fallback

### Planned

- 完整 CONTRIBUTING.md 流程
- 自动化 Release Notes
- 多语言支持（英文 README）

## [0.1.0] - 2026-06-22

### Added

- **291 Skill**：16 个 harness 自有 + 4 个 Superpowers 第三方 + 271 个 ECC 第三方 cherry-pick
  - harness 自有 16：
    - leader 层（4）：brainstorming / writing-plans / git-xywh / harness-orchestration
    - wu 层（8）：test-driven-development / systematic-debugging / requesting-code-review / receiving-code-review / agent-browser / verification-before-completion / ui-ux-pro-max / frontend-design
    - project 层（6）：ruoyi-aigc-backend-developer / backend-doc-generator / architecture-patterns / security-auditor / refactor-safely / code-review
    - cursor_only（2）：cursor-orchestration / document-review
  - Superpowers 第三方（4）：subagent-driven-development / dispatching-parallel-agents / using-git-worktrees / executing-plans
  - ECC 第三方（271）：详见 [`skills/INDEX.md`](skills/INDEX.md)
- **77 Agent**：7 个 harness 角色 + 70 个 ECC 专项
  - harness 角色（7）：leader / coder / implementer / reviewer / test-engineer / debugger / web-investigator
  - ECC 专项（70）：java / cpp / dart / fastapi / flutter / fsharp / go / healthcare / homelab / kotlin / mle / network / perl / php / python / pytorch / react / rust / security / springboot / swift / typescript / vue 等专项 reviewer + build-resolver，详见 [`agents/third-party/ecc/`](agents/third-party/ecc/)
- **5 平台适配器**：Trae / Cursor / Claude Code / Codex / Mimocode
- **同步脚本**：bootstrap.sh / bootstrap.ps1 / sync-skills.sh / sync-skills.ps1 / sync-third-party.sh / harness-worktree.sh
- **`--dry-run` 支持**：所有同步脚本支持干跑
- **`verify.sh`**：CI 验证入口（bash 语法 + dry-run + skill 结构）

### Known Limitations

- `third-party/ecc/` 与 `third-party/superpowers/` 首次使用前需按 `LICENSE` 指引补齐上游 LICENSE 副本。
- **防误删机制**：bootstrap_cursor / bootstrap_trae 只同步 `agents/` `rules/`，不碰 `skills/`
- **Windows CRLF 兼容**：sync-skills.sh 自动去 `\r`
- **4 份 README**：顶层 / skills / skills/INDEX / agents
- **OpenAPI 文档示例**：artifact-templates/runtime/

### Notes

- 第一个开源版本，从心悦 AIGC 内部框架抽离
- 第三方 cherry-pick 真相源在 `third-party/`，升级路径已文档化
- GitHub 仓库：https://github.com/zhoupei6251/harness-kit

[Unreleased]: https://github.com/zhoupei6251/harness-kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/zhoupei6251/harness-kit/releases/tag/v0.1.0