# Changelog

所有值得注意的变更都会记录在这个文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
本项目遵循 [语义化版本](https://semver.org/) 规范。

## [Unreleased]

### Planned

- 完整 CONTRIBUTING.md 流程
- 自动化 Release Notes
- 多语言支持（英文 README）

## [0.1.0] - 2026-06-22

### Added

- **20 Skill**：16 个 harness 自有 + 4 个 Superpowers 第三方 cherry-pick
  - wu 层：test-driven-development / systematic-debugging / requesting-code-review / receiving-code-review / agent-browser / verification-before-completion / ui-ux-pro-max / frontend-design
  - project 层：ruoyi-aigc-backend-developer / backend-doc-generator / architecture-patterns / security-auditor / refactor-safely / code-review
  - cursor_only 层：cursor-orchestration / document-review
  - 第三方：subagent-driven-development / dispatching-parallel-agents / using-git-worktrees / executing-plans
- **10 Agent**：7 个 harness 角色 + 3 个 ECC 专项
  - 角色：leader / coder / implementer / reviewer / test-engineer / debugger / web-investigator
  - ECC：ecc-java-reviewer / ecc-security-reviewer / ecc-database-reviewer
- **5 平台适配器**：Trae / Cursor / Claude Code / Codex / Mimocode
- **同步脚本**：bootstrap.sh / sync-skills.sh / sync-third-party.sh
- **`--dry-run` 支持**：所有同步脚本支持干跑
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