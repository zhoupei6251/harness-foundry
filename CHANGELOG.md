# Changelog

所有值得注意的变更都会记录在这个文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，
本项目遵循 [语义化版本](https://semver.org/) 规范。

## [Unreleased]

### Added

- **自动索引生成**：`scripts/gen-skill-index.sh` 从 SKILL.md frontmatter + `_meta.json` 自动生成 `skills/INDEX.md`，支持分类排序与未分类区
- **Windows 版索引生成**：`scripts/gen-skill-index.ps1` — PowerShell 原生版本，功能与 bash 版等价，无需 WSL
- **技能依赖图**：`scripts/gen-skill-graph.py` 从 `_meta.json` 的 `requires`/`complements`/`conflicts` 字段生成 Mermaid 流程图（`docs/skill-dependency-graph.md`），含全局视图 + 按 domain 分面
- **分类体系**：`skills/categories.yaml` 定义 26 个分类（code 11 / novel 4 / shared 6 / biz 2 / crypto 1 / news 2 / science 1），同时映射中文标题
- **元数据补全**：
  - `scripts/rebuild-skill-metas.py` — 为 39 个核心技能重建 `_meta.json`（slug + category + domain + tags）
  - `scripts/heuristic-skill-categories.py` — 基于关键词匹配为 289 个技能生成 `_meta.json`
  - `scripts/add-skill-relations.py` — 为 21 个核心技能补全 `requires` / `complements` / `conflicts` 关系
- **元数据规范**：`docs/skill-metadata-spec.md` 定义 `_meta.json` 所有字段语义（slug、domain、category、tags、purpose、requires、complements、conflicts、source 等）
- **验证命令**：`gen-skill-index.sh --check` 和 `gen-skill-graph.sh --check` 检查生成文件是否与源数据一致

### Changed

- **第三方整合**：将 `skills/third-party/superpowers/` 下的技能整合到 `skills/` 主池，删除 `skills/third-party/` 目录
  - `dispatching-parallel-agents` 迁移到 `skills/dispatching-parallel-agents/`
  - `executing-plans` / `using-git-worktrees` / `subagent-driven-development` 已在主池有改进版，删除第三方副本
- **清理重复目录**：删除 `skills/agents/`（6 个 ecc agent 文件与 `agents/` 重复）
- **删除同步脚本**：移除 `scripts/sync-third-party.sh`（不再需要同步第三方）
- **重建索引**：`skills/INDEX.md` 更新为 333 个技能的完整索引（含分类排序），删除过时的 `skills/INDEX-by-category.md`

### Fixed

- 修复 `novel-generator/novel-generator/` 嵌套目录问题
- 修复 `dispatching-parallel-agents/dispatching-parallel-agents/` 嵌套目录问题（删除内层重复文件）

### Planned

- 自动化 Release Notes
- hooks 外部脚本实现（当前使用内嵌 prompt 钩子）

## [0.1.0] - 2026-06-22

### Added

- **全局 Skill 池**：skills/ 扁平化目录，覆盖代码 / 小说 / 新闻三域，含自有 Skill 及整合后的社区 Skill
- **全局 Agent 池**：agents/ 扁平化目录，含 7 个 harness 核心角色（leader-code/leader-novel/leader-news / coder / implementer / reviewer / test-engineer / debugger / web-investigator）+ 70+ 专项 reviewer 和 build-resolver
- **5 平台适配器**：Trae / Cursor / Claude Code / Codex / Mimocode
- **三域统一路由**：`core/intent-routing.md` 统一意图路由表，code / novel / news 共用
- **编排调度器**：`core/orchestration/dispatcher-workflow.md` 统一 WU 拆分 → 并行派兵 → 整合流程
- **领域配置**：`core/orchestration/domain-config.yaml` 按域加载 Agent/Skill
- **同步脚本**：bootstrap.sh / bootstrap.ps1 / sync-skills.sh / sync-skills.ps1 / harness-worktree.sh
- **`--dry-run` 支持**：所有同步脚本支持干跑
- **`verify.sh`**：CI 验证入口（bash 语法 + dry-run + skill 结构）
- **Skill 索引与元数据**：INDEX.md / categories.yaml / skill-metadata-spec.md / skill-dependency-graph.md
- **规则库**：按技术栈分类的 rules/ 目录（code/novel/news/common）
- **场景化上下文**：contexts/ 目录（code/novel/news/review）
- **自动化钩子**：hooks/hooks.json，支持 PreToolUse / PostToolUse / Stop 三阶段
- **陷阱库**：references/traps.md + traps-archive/ 按域分类
- **运行时产物模板**：artifact-templates/ 含 dispatch-track / execution-log / handoff 等

### Known Limitations

- **防误删机制**：bootstrap_cursor / bootstrap_trae 只同步 `agents/` `rules/`，不碰 `skills/`
- **Windows CRLF 兼容**：sync-skills.sh 自动去 `\r`
- hooks 脚本目前使用内嵌 prompt 类型，后续可扩展为外部 command 脚本

### Notes

- 第一个开源版本，从心悦 AIGC 内部框架抽离
- Agents 和 Skills 已完全扁平化，不再有 third-party 子目录
- 三域（代码/小说/新闻）共用一套编排框架
- GitHub 仓库：https://github.com/zhoupei6251/harness-foundry

[Unreleased]: https://github.com/zhoupei6251/harness-foundry/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/zhoupei6251/harness-foundry/releases/tag/v0.1.0