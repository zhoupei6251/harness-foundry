# Skill 元数据规范

> 所有 `skills/<slug>/_meta.json` 的字段定义。本规范是自动索引、依赖图谱、领域路由的依据。

## 1. 字段一览

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `slug` | string | 推荐 | Skill 目录名（去重于目录名） |
| `domain` | enum | 推荐 | `code` / `novel` / `news` / `shared` |
| `category` | string | 可选 | 主分类标识符（对应 `skills/categories.yaml` 的 key） |
| `tags` | string[] | 可选 | 检索标签 |
| `purpose` | string | 可选 | 一句话用途说明（中文优先） |
| `requires` | string[] | 可选 | 强依赖：缺少时本 skill 无法工作 |
| `conflicts` | string[] | 可选 | 互斥：与本 skill 同时加载会导致冲突 |
| `complements` | string[] | 可选 | 互补：与本 skill 一起使用效果更好 |
| `source` | string | 可选 | 来源（`superpowers` / `ecc` / `harness`） |
| `source_version` | string | 可选 | 上游版本 |
| `cherry_picked` | bool | 可选 | 是否为精选 |
| `integration_layer` | string | 可选 | 整合层级（如 `L2-auxiliary`） |

## 2. 字段语义

### 2.1 `domain` 必填值

- `code` — 软件工程类（编程语言、架构、测试、调试）
- `novel` — 小说创作类（生成、编排、润色、评估）
- `news` — 新闻类（生成、润色、事实核查）
- `shared` — 跨域通用（规划、记忆、工具、Agent 编排）

### 2.2 `requires` vs `complements`

- `requires`：本 skill 的核心流程**必须**先加载该 skill（如 `dispatching-parallel-agents` 依赖 `subagent-driven-development`）
- `complements`：建议**同时**加载以获得完整体验（如 `brainstorming` + `writing-plans`）

### 2.3 `conflicts` 互斥

- 表示两个 skill 加载后**会互相覆盖意图路由或资源**
- 例如：两个 `*-orchestration` 类 skill 一般互斥

## 3. 完整示例

```json
{
  "slug": "dispatching-parallel-agents",
  "domain": "code",
  "category": "code.ai-orchestration",
  "tags": ["parallel", "agent", "dispatch"],
  "purpose": "并行派发独立任务的判断准则与执行模式（2+ 独立任务时使用）",
  "requires": ["subagent-driven-development"],
  "complements": ["cursor-orchestration", "orch-pipeline"],
  "source": "superpowers",
  "source_version": "6.0.3",
  "cherry_picked": true,
  "integration_layer": "L2-auxiliary"
}
```

## 4. 工具链

| 工具 | 作用 |
|------|------|
| `scripts/gen-skill-index.sh` | 扫描所有 `_meta.json` + `SKILL.md`，生成 `skills/INDEX.md` |
| `scripts/gen-skill-graph.sh` | 扫描 `requires / conflicts / complements`，生成 `docs/skill-dependency-graph.md` |
| `skills/categories.yaml` | 分类映射配置（`category` → 中文标题） |

## 5. 兼容性

- 所有新字段均为**可选**，现有 `_meta.json` 无需修改即可继续工作
- 脚本会跳过缺字段的项并在结尾报告
- 强烈建议为**核心 skill**（被广泛依赖的）补全 `requires / complements` 字段

## 与 schemas/skill-meta.schema.json 对齐

本文档描述性版本已统一到 [`schemas/skill-meta.schema.json`](../schemas/skill-meta.schema.json)。
任何字段冲突以 JSON Schema 为准。

### 新增字段（v1.1）

- `status`: enum, 新增 `archived` / `experimental` 取值
- `estimated_tokens`: integer, ≥100
- `source`: enum, 新增 `generated` 标识启发式生成

### 移除字段（v1.1 → deprecated）

- 任何 `*_by` / `*_at` 字段（如非必要）→ 移除

### 迁移指引

对于已存在的 `_meta.json`：
1. 用 `python -c "import json; json.load(open('_meta.json'))"` 先确认 JSON 合法
2. 用 ajv-cli 或 `jsonschema` Python 包校验 schema
3. 不合规字段在过渡期（1 sprint）只警告不红
