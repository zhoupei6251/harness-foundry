---
artifact: spec
title: "Skill 工程化第一里程碑：Frontmatter 标准 + _meta.json Schema + 三层分层"
date: 2026-06-29
status: draft
platform: harness-foundry
route: superpowers:brainstorming
approved: false
related:
  - harness-foundry/core/orchestration/skill-preferences.md
  - harness-foundry/docs/skill-metadata-spec.md
  - harness-foundry/docs/skill-dependency-graph.md
  - harness-foundry/skills/categories.yaml
  - harness-foundry/skills/INDEX.md
  - harness-foundry/scripts/verify.sh
  - harness-foundry/scripts/sync-skills.sh
  - harness-foundry/CHANGELOG.md
---

# Skill 工程化第一里程碑：Frontmatter 标准 + _meta.json Schema + 三层分层

## 1. 背景与问题

harness-foundry 当前拥有 328 个 Skill + 30 个 Agent，覆盖 code / novel / news 三域。当前存在三类问题：

| 问题 | 证据 |
| --- | --- |
| **Skill 数量与质量不匹配** | CHANGELOG 自述：`scripts/heuristic-skill-categories.py — 基于关键词匹配为 289 个技能生成 _meta.json`，说明 289 个 Skill 是「启发式凑数」未经人工审核 |
| **路由层与 Skill 层脱节** | `core/orchestration/skill-preferences.md` 实际路由约 20-30 个 Skill，其余 298 个在 IDE 加载但从未被路由 |
| **Frontmatter 不规范** | 大部分 Skill 的 SKILL.md frontmatter 字段缺失或命名不一致（部分用 `description`，部分用 `when_to_use`，部分用 `tags`），缺乏 schema 化校验 |
| **重复 Skill 未合并** | 例如 `code-review` / `security-review` / `security-scan` 职责重叠；`humanizer` / `humanizer-zh` / `human-writing` 同能力多版本 |

参考开源标杆：
- **gstack**（`SKILL.md.tmpl` + `gen-skill-docs.ts` 模板生成 + 160KB token ceiling + 三层测试）
- **ECC**（按能力分层 + `_meta.json` + 多语言 i18n 目录）
- **superpowers**（Skill-触发方法论 + 模板化）

**本 spec 不做**：模板生成器（D3）、三层测试体系（D4）、Token 预算监控（D5）、Agent 体系精简、novel/news 域差异化。

**本 spec 只做**：Frontmatter 标准 + `_meta.json` Schema + 三层分层（核心 / 外围 / 归档）+ CI 校验。

## 2. 决策摘要（已确认）

| 项 | 选择 |
| --- | --- |
| 范围 | **Skill 层 frontmatter + _meta + 三层标记**，不动 Agent |
| 精简策略 | **分层保留**：核心 ≤80 + 外围 ≤120 + 归档 ~128（不删文件，只标 status） |
| 同步行为 | `sync-skills.sh` 读取 `_layer.yaml`，**只投影 core + peripheral 到 IDE**，archived 不投影 |
| CI 严格度 | **过渡期 1 sprint 只警告不红**，之后严格 |
| Schema 工具 | ajv-cli（JSON Schema draft-07），跨平台 |
| 分类器 | Python（项目已有 `scripts/_skill_meta.py` 等 Python 脚本，统一栈） |

## 3. 目标 / 非目标 / 成功标准

### 3.1 目标

1. 落地 Skill **三层模型**（核心 / 外围 / 归档），328 个 Skill 完成分层标记
2. 落地 Skill **Frontmatter 标准**，所有核心层 Skill 必须满足
3. 落地 **`_meta.json` schema**，与 `core/orchestration/skill-preferences.md` 路由表打通
4. 提供 **机械化分层工具**（`scripts/classify-skills.py`），可重跑、可审计、可交互审核
5. 提供 **frontmatter 校验器**（`tests/L1-static/validate-skill-frontmatter.sh`），CI 必跑
6. 提供 **meta 校验器**（`tests/L1-static/validate-skill-meta.sh`），CI 必跑
7. `scripts/sync-skills.sh` 集成 `_layer.yaml` 过滤，archived 不投影

### 3.2 非目标

- ❌ 不实现模板生成器（D3，留给下一 spec）
- ❌ 不实现 E2E 测试体系（D4，留给下一 spec）
- ❌ 不实现 Token 预算监控（D5，留给下一 spec）
- ❌ 不动 Agent 体系（`agents/` 目录精简是另一个 spec）
- ❌ 不修改 Skill 正文（只标 status，不改 SKILL.md 内容）
- ❌ 不实现 novel/news 域 Skill 的差异化

### 3.3 成功标准（可度量）

| 指标 | 当前 | 目标 |
| --- | --- | --- |
| Skill 总数 | 328 | 328（不删文件） |
| 核心层 Skill 数 | ~20（隐式） | ≤80 |
| 外围层 Skill 数 | 0（未分类） | ≤120 |
| 归档层 Skill 数 | 0 | ~128 |
| 有完整 frontmatter 的 Skill | <50 | 核心层 100% |
| 有完整 `_meta.json` 的 Skill | 289（启发式） | 核心层 100% |
| CI 校验脚本数 | 1（`validate-never.sh`） | 3（+ frontmatter + meta） |
| `sync-skills.sh` 输出是否过滤 archived | 否 | 是（按 `_layer.yaml`） |

## 4. 架构与数据流

### 4.1 三层模型（核心抽象）

```
┌─────────────────────────────────────────────────────────┐
│  core/orchestration/skill-preferences.md                │
│  ─ WU 级路由表：agent_role + wu_type → skill slug       │
│  ─ 真相源，决定「哪些 Skill 必须被加载」                  │
└─────────────────┬───────────────────────────────────────┘
                  │ 引用
                  ▼
┌─────────────────────────────────────────────────────────┐
│  skills/INDEX.md  +  skills/_layer.yaml                 │
│  ─ INDEX.md: 全部 328 Skill 的可读索引（已有）           │
│  ─ _layer.yaml: 自动生成的层分类（新增）                 │
│      core: [skill-slug-1, skill-slug-2, ...]  ≤80       │
│      peripheral: [...]  ≤120                            │
│      archived: [...]  ~128                              │
└─────────────────┬───────────────────────────────────────┘
                  │ 路由决策
                  ▼
┌─────────────────────────────────────────────────────────┐
│  同步层（bootstrap.sh / sync-skills.sh）                │
│  ─ 只投影 core + peripheral 到 IDE                      │
│  ─ archived 不投影（保留文件供查阅，但不同步）           │
└─────────────────────────────────────────────────────────┘
```

### 4.2 数据流（Skill 从定义到分发）

```
   开发者              分类器           校验器         分发
     │                   │                │              │
     │ 写/改 Skill       │                │              │
     ├──────────────────>│                │              │
     │                   │ 跑 classify    │              │
     │                   ├──────┐         │              │
     │                   │      │         │              │
     │                   │<─────┘ 标记层  │              │
     │                   ├────────────────>              │
     │                   │                │ 跑 validate  │
     │                   │                ├──────┐       │
     │                   │                │      │       │
     │                   │                │<─────┘ OK/FAIL│
     │                   │                ├─────────────>│
     │                   │                │              │ sync
     │                   │                │              ├────┐
     │                   │                │              │    │
     │                   │                │              │<───┘
```

### 4.3 关键组件

| 组件 | 位置 | 职责 |
| --- | --- | --- |
| **`skill-frontmatter-schema.md`** | `docs/skill-frontmatter-schema.md` | Frontmatter 字段定义（必填 / 选填 / 类型 / 示例） |
| **`skill-meta-schema.json`** | `schemas/skill-meta.schema.json` | `_meta.json` 的 JSON Schema（用 ajv-cli 校验） |
| **`classify-skills.py`** | `scripts/classify-skills.py` | 三层自动分类器（基于关键词 + 路由表引用） |
| **`auto-fill-frontmatter.py`** | `scripts/auto-fill-frontmatter.py` | 启发式补全 frontmatter（基于 SKILL.md 第一段 + 已有 `_meta.json`） |
| **`validate-skill-frontmatter.sh`** | `tests/L1-static/validate-skill-frontmatter.sh` | CI 必跑：frontmatter 合规校验 |
| **`validate-skill-meta.sh`** | `tests/L1-static/validate-skill-meta.sh` | CI 必跑：`_meta.json` schema 校验 |
| **`_layer.yaml`** | `skills/_layer.yaml`（自动生成，可入仓） | 三层分类结果 |
| **`sync-skills.sh`** 增强 | `scripts/sync-skills.sh` | 读取 `_layer.yaml`，过滤 archived |

### 4.4 关键文件改动清单

**新增**：

- `docs/skill-frontmatter-schema.md`
- `schemas/skill-meta.schema.json`
- `scripts/classify-skills.py`
- `scripts/auto-fill-frontmatter.py`
- `tests/L1-static/validate-skill-frontmatter.sh`
- `tests/L1-static/validate-skill-meta.sh`
- `skills/_layer.yaml`（生成产物，可入仓或 gitignore）
- `tests/L2-integration/classify-skills.test.sh`
- `tests/L2-integration/sync-skills-layer.test.sh`

**修改**：

- `scripts/verify.sh`（新增 2 个校验步骤，末尾追加，不破坏老流程）
- `scripts/sync-skills.sh`（读取 `_layer.yaml`，过滤 archived；缺文件时全部同步以保持向后兼容）
- `skills/INDEX.md`（新增「Layer」列）
- `CHANGELOG.md`（新增条目）
- `README.md`（新增「Skill 工程化」章节）
- `docs/skill-metadata-spec.md`（升级为与新 schema 一致）

**不动**：

- `core/orchestration/skill-preferences.md`（真相源，本 spec 只「读」不「写」）
- `skills/<slug>/SKILL.md`（正文不动，只补 frontmatter）
- `skills/<slug>/_meta.json`（已有则升级字段，缺失则新增）
- `agents/`（不在本 spec 范围）

## 5. 核心契约

### 5.1 Frontmatter 契约（YAML）

```yaml
---
# 必填 6 项
name: string                   # slug，全局唯一，匹配目录名 ^[a-z0-9][a-z0-9-]*[a-z0-9]$
description: string            # 1-200 字符，描述「做什么 + 何时用」
version: semver                # 格式 X.Y.Z，初始 1.0.0
when_to_use: string            # 触发词或场景，1-300 字符
status: enum                   # stable | peripheral | archived | experimental
tags: string[]                 # ≥1 个 tag

# 选填 4 项
domain: enum                   # code | novel | news | shared | biz | crypto | science
category: enum                 # language | workflow | tool | review | pattern | framework
routing_role: string           # 对应 agents/<role>.md 之一
references: string[]           # 关联 SKILL.md / docs 路径
---
```

### 5.2 `_meta.json` Schema（JSON Schema draft-07）

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "SkillMeta",
  "type": "object",
  "required": ["slug", "domain", "category", "status", "tags", "purpose", "version"],
  "properties": {
    "slug":             { "type": "string", "pattern": "^[a-z0-9][a-z0-9-]*[a-z0-9]$" },
    "domain":           { "enum": ["code", "novel", "news", "shared", "biz", "crypto", "science"] },
    "category":         { "enum": ["language", "workflow", "tool", "review", "pattern", "framework"] },
    "status":           { "enum": ["stable", "peripheral", "archived", "experimental"] },
    "tags":             { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "purpose":          { "type": "string", "minLength": 10, "maxLength": 500 },
    "version":          { "type": "string", "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$" },
    "requires":         { "type": "array", "items": { "type": "string" } },
    "complements":      { "type": "array", "items": { "type": "string" } },
    "conflicts":        { "type": "array", "items": { "type": "string" } },
    "routing_role":     { "type": "string" },
    "estimated_tokens": { "type": "integer", "minimum": 100 },
    "source":           { "enum": ["core", "third-party", "user", "generated"] }
  },
  "additionalProperties": false
}
```

### 5.3 三层分类规则（classify-skills.py 输入）

```python
# 输入：skill 路径 + frontmatter + _meta + core/orchestration/skill-preferences.md
# 输出：status ∈ {stable, peripheral, archived}

def classify(skill):
    # P1: 路由表引用 → 核心
    if skill.slug in routing_table["all_skills"]:
        return "stable"

    # P2: frontmatter/_meta 完整 + 内容 > 500 字 → 核心候选
    if skill.has_frontmatter and skill.has_meta and skill.body_length > 500:
        return "stable"

    # P3: frontmatter/_meta 部分完整 + 内容 > 200 字 → 外围
    if skill.has_any_meta and skill.body_length > 200:
        return "peripheral"

    # P4: 启发式生成（source=generated）或内容 < 100 字 → 归档
    if skill.meta.source == "generated" or skill.body_length < 100:
        return "archived"

    # P5: 其余 → 外围（保守）
    return "peripheral"
```

**核心层数量守恒**：若 P1+P2 产出超过 80，按以下优先级削减：
1. 先砍 `experimental` 状态
2. 再砍 `requires` 链最长的（孤立 Skill 优先保留）
3. 再砍 `body_length` 最小的
4. 多余的降级为 `peripheral`
5. 输出 `core_overflow.yaml` 报告给开发者人工确认

### 5.4 同步层契约（sync-skills.sh 读取 _layer.yaml）

```bash
# 读取 skills/_layer.yaml，仅同步 core + peripheral
LAYER_FILE="${LAYER_FILE:-skills/_layer.yaml}"
if [[ -f "$LAYER_FILE" ]]; then
  ALLOWED_LAYERS=$(yq '.core + .peripheral | .[]' "$LAYER_FILE")
  for skill_dir in skills/*/; do
    slug=$(basename "$skill_dir")
    if [[ " $ALLOWED_LAYERS " == *" $slug "* ]]; then
      sync_to_ide "$slug"
    fi
  done
else
  # 向后兼容：缺 _layer.yaml 时全部同步
  for skill_dir in skills/*/; do
    sync_to_ide "$(basename "$skill_dir")"
  done
fi
```

### 5.5 CI 校验失败处理

| 失败项 | 行为 |
| --- | --- |
| core 层 Skill 缺 frontmatter 必填项 | ❌ CI 红 |
| core 层 Skill 缺 `_meta.json` | ❌ CI 红 |
| peripheral 层缺必填项 | ⚠️ CI 警告（不阻塞） |
| archived 层缺必填项 | ✅ 跳过（不校验） |
| `_meta.json` 不符合 schema | ❌ CI 红 |
| frontmatter 字段值非法（如 status 不在 enum 内） | ❌ CI 红 |
| `_meta.slug` ≠ `basename(skill_dir)` | ❌ CI 红 |
| 路由表引用了不存在的 slug | ❌ CI 红（路由表一致性） |
| `_layer.yaml` 与实际不符 | ⚠️ 警告 + 重新生成（自愈） |

## 6. 错误处理与边界条件

### 6.1 错误场景与处理

| 错误场景 | 检测点 | 错误处理 |
| --- | --- | --- |
| Skill 目录无 SKILL.md | classify-skills.py 扫描阶段 | 标记 `archived`（空壳），不阻断 |
| frontmatter YAML 解析失败 | validate-skill-frontmatter.sh | 输出错误行号 + 修复建议，CI 红 |
| `_meta.json` 不存在 | validate-skill-meta.sh | core → 阻断；peripheral → 警告；archived → 跳过 |
| `_meta.json` JSON 解析失败 | ajv 校验前 | CI 红（明确指向文件:行号） |
| slug 与目录名不一致 | 两个校验器 | CI 红（强制 slug = basename(skill_dir)） |
| `core/orchestration/skill-preferences.md` 引用不存在的 slug | validate-skill-meta.sh 交叉校验 | CI 红（路由表真相源一致性） |
| `_layer.yaml` 与实际不符 | sync-skills.sh 启动 | 仅警告 + 重新生成（自愈） |
| 重复 slug（`_meta.slug` ≠ 目录名） | classify 阶段 | CI 红，列出冲突的目录 |

### 6.2 边界条件

1. **Skill 目录无 `_meta.json`**：classify 脚本自动生成最小可用 `_meta.json`
   （slug + domain=shared + category=tool + status=peripheral + version=0.1.0 + source=generated），
   由开发者后续补充
2. **`_meta.json` 已是启发式生成**（source=generated）：classify 保留原 source 标记，便于审计
3. **frontmatter 与 `_meta.json` 冲突**（如 status 不同）：以 `_meta.json` 为准（更结构化），CI 警告 frontmatter 让其对齐
4. **`_layer.yaml` 缺失**：sync-skills.sh 默认同步所有 Skill（保持向后兼容）
5. **核心层 Skill 数量超过 80**：见 5.3 优先级削减规则
6. **ajv-cli 在 Windows 不可用**：提供 Python 回退（`tests/L1-static/validate-skill-meta.sh` 内置 `jsonschema` Python 包校验）

### 6.3 兼容性策略

- 现有 328 个 Skill 全部保留文件，仅标记 status（不破坏 git 历史）
- `sync-skills.sh` 在 `_layer.yaml` 缺失时按「全部同步」行为运行（向后兼容老脚本调用）
- `verify.sh` 新增步骤在末尾追加，老 CI 流程不破坏
- 新增 JSON Schema 文件不强制现有 `_meta.json` 立刻合规，给 1 个 sprint 的过渡期，期间 CI 只警告不红

### 6.4 回滚策略

全部改动都是**新增文件** + **追加校验步骤**，无破坏性变更。如需回滚：

```bash
git revert <commit-sha>   # 撤销新增
rm skills/_layer.yaml      # 让 sync 退回到全部同步
```

`_layer.yaml` 建议入仓以便版本可追溯；如不愿入仓，加入 `.gitignore` 并在 sync-skills.sh 中提供 `--regenerate-layer` 选项。

## 7. 测试与验收

### 7.1 测试金字塔

```
                  ▲
                 ╱ ╲
                ╱ E2E ╲          ← Phase 3（抽样，不在本 spec）
               ╱________╲
              ╱  集成测试  ╲      ← Phase 2（classify 端到端 + sync 集成）
             ╱______________╲
            ╱    静态校验     ╲   ← Phase 1（frontmatter + schema + 交叉引用）
           ╱__________________╲
```

### 7.2 Phase 1：静态校验（CI 必跑，本 spec 交付）

| 测试 | 文件 | 断言 |
| --- | --- | --- |
| T1.1 frontmatter 解析 | `validate-skill-frontmatter.sh` | 所有 core 层 Skill 的 SKILL.md 都能被 YAML 解析 |
| T1.2 frontmatter 必填 | 同上 | name / description / version / when_to_use / status / tags 必填 |
| T1.3 frontmatter 字段值 | 同上 | status ∈ enum；slug 格式合法；version 是 semver |
| T1.4 `_meta.json` 存在性 | `validate-skill-meta.sh` | core 层必须有 `_meta.json`；peripheral 警告；archived 跳过 |
| T1.5 `_meta.json` schema | 同上（ajv） | 所有字段类型、enum、pattern 合规 |
| T1.6 交叉引用一致性 | 同上 | `_meta.slug == basename(skill_dir)`；`core/orchestration/skill-preferences.md` 引用的所有 slug 都存在 |
| T1.7 `_layer.yaml` 一致性 | 同上 | `_layer.yaml` 列出的 slug 都对应真实目录；反之亦然 |

### 7.3 Phase 2：集成测试（CI 必跑，本 spec 交付）

| 测试 | 文件 | 断言 |
| --- | --- | --- |
| T2.1 classify 确定性 | `tests/L2-integration/classify-skills.test.sh` | 同一输入跑 3 次，输出完全一致 |
| T2.2 classify 数量约束 | 同上 | core ≤80, peripheral ≤120, archived ≥100（数量守恒） |
| T2.3 sync 过滤 | `tests/L2-integration/sync-skills-layer.test.sh` | `--dry-run` 输出只包含 core + peripheral 的 Skill，不含 archived |
| T2.4 verify.sh 集成 | `tests/L2-integration/verify-full.test.sh` | `bash scripts/verify.sh` 退出码 0 |

### 7.4 Phase 3：抽样 E2E（不交付，留给下一 spec）

- 抽 5 个 core 层 Skill，跑「加载 → 模拟用户输入 → 验证输出」流程
- 用 Bun 守护进程调用（参考 gstack 的 `browse/test/`）

### 7.5 验收清单（DoD）

- [ ] `docs/skill-frontmatter-schema.md` 入仓
- [ ] `schemas/skill-meta.schema.json` 入仓
- [ ] `scripts/classify-skills.py` 入仓 + 单测通过
- [ ] `scripts/auto-fill-frontmatter.py` 入仓
- [ ] `scripts/verify.sh` 集成新增 2 个步骤
- [ ] `tests/L1-static/validate-skill-frontmatter.sh` 入仓
- [ ] `tests/L1-static/validate-skill-meta.sh` 入仓
- [ ] `tests/L2-integration/classify-skills.test.sh` 入仓
- [ ] `tests/L2-integration/sync-skills-layer.test.sh` 入仓
- [ ] `skills/_layer.yaml` 生成并入仓
- [ ] 现有 328 Skill 完成分层（core ≤80, peripheral ≤120, archived ~128）
- [ ] 核心层 Skill 100% 有完整 frontmatter
- [ ] 核心层 Skill 100% 有完整 `_meta.json`
- [ ] `bash scripts/verify.sh` 全绿
- [ ] `bash scripts/sync-skills.sh --dry-run --target all` 输出不含 archived
- [ ] CHANGELOG.md 更新
- [ ] README.md 新增「Skill 工程化」章节
- [ ] spec 自审通过（占位符 / 一致性 / 范围 / 歧义）

## 8. 风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| 289 个启发式生成 Skill 突然被归档导致 IDE 加载变快但某些边缘场景失败 | 中 | archived 文件保留在 git；提供 `sync-skills.sh --include-archived` 选项回退 |
| classify 误判（把有用的标记为 archived） | 中 | Phase 2 提供 `classify-skills.py --review` 交互模式，人工审核 |
| JSON Schema 校验过于严格，老 `_meta.json` 大量报错 | 高 | 过渡期（1 sprint）CI 只警告不红 |
| 开发者不愿补 frontmatter | 中 | 自动化工具 `scripts/auto-fill-frontmatter.py`（基于 SKILL.md 第一段和已有 `_meta`） |
| sync-skills.sh 兼容老调用方 | 低 | `--layer-file` 选项默认 `skills/_layer.yaml`，缺文件时全部同步 |
| ajv-cli 在 Windows 不可用 | 低 | 校验脚本内置 Python 回退（`jsonschema` 包） |
| `_layer.yaml` 文件冲突（多人同时改） | 低 | 标记为自动生成 + `.gitattributes` 标注 merge=ours |

## 9. 后续 Spec（不交付，仅声明）

- **SP-2026-07-XX：Skill 模板生成器（D3）** — `.tmpl` → 多平台输出
- **SP-2026-07-XX：三层测试体系（D4）** — L1 静态 + L2 集成 + L3 抽样 E2E
- **SP-2026-07-XX：Token 预算监控（D5）** — 单 Skill ≤8K、全量 ≤160K
- **SP-2026-07-XX：Agent 体系精简** — 30 → ≤20，明确 Leader / Worker / Reviewer 三象限
- **SP-2026-08-XX：核心域纵深（code 域）** — 对标 ECC 30+ Agent + 50+ Skill 深度

---

## 自审记录

写完后做自审：

- [x] 占位符扫描：无 TBD / TODO / 「待定」
- [x] 内部一致性：架构图与数据流一致；契约与组件一致；测试与验收一致
- [x] 范围检查：聚焦 Skill 工程化第一里程碑，不混入 Agent / Runtime / Test 体系
- [x] 歧义检查：所有 enum 都有明确取值；所有数量阈值都给出具体数字；`archived` 文件保留在 git 的承诺已明确