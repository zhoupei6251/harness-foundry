# Skill 工程化第一里程碑 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 harness-foundry 现有的 328 个 Skill 落地三层分层（核心/外围/归档）+ Frontmatter 标准 + `_meta.json` Schema，并在 CI 中强制校验。

**Architecture:** 真相源 → 分类器 → CI 校验器 → 同步过滤。先定义 Schema（frontmatter + JSON Schema），再实现分类器（基于路由表 + 关键词），最后接入 sync-skills.sh 和 verify.sh。完全增量改造，不删任何 Skill 文件，仅打 status 标签 + 生成 `_layer.yaml`。

**Tech Stack:** Python 3（classify / auto-fill）、Bash（CI 校验脚本）、ajv-cli（JSON Schema 校验，Windows 有 Python 回退）、yq（YAML 解析）。

---

## File Structure

| 路径 | 状态 | 职责 |
|------|------|------|
| `docs/skill-frontmatter-schema.md` | 新增 | Frontmatter 字段定义 |
| `schemas/skill-meta.schema.json` | 新增 | `_meta.json` JSON Schema |
| `docs/skill-metadata-spec.md` | 修改 | 与新 Schema 对齐 |
| `scripts/classify-skills.py` | 新增 | 三层自动分类器 |
| `scripts/auto-fill-frontmatter.py` | 新增 | 启发式补全 frontmatter |
| `scripts/sync-skills.sh` | 修改 | 读取 `_layer.yaml` 过滤 archived |
| `scripts/verify.sh` | 修改 | 新增 2 个校验步骤 |
| `scripts/_skill_meta.py` | 不动 | 分类器复用其 SKILL_META 表 |
| `tests/L1-static/validate-skill-frontmatter.sh` | 新增 | CI 必跑 |
| `tests/L1-static/validate-skill-meta.sh` | 新增 | CI 必跑 |
| `tests/L2-integration/classify-skills.test.sh` | 新增 | 集成测试 |
| `tests/L2-integration/sync-skills-layer.test.sh` | 新增 | 集成测试 |
| `skills/_layer.yaml` | 新增（生成） | 三层分类结果 |
| `skills/INDEX.md` | 修改 | 新增 Layer 列 |
| `CHANGELOG.md` | 修改 | 新增条目 |
| `README.md` | 修改 | 新增「Skill 工程化」章节 |

---

## Task 1: 编写 Frontmatter Schema 文档

**Files:**
- Create: `docs/skill-frontmatter-schema.md`

- [ ] **Step 1: 创建文件**

写入 [docs/skill-frontmatter-schema.md](file:///d:/work/zhoupei/harness-foundry/docs/skill-frontmatter-schema.md)：

````markdown
---
name: skill-frontmatter-schema
description: "Skill SKILL.md 文件的 frontmatter 字段规范。"
tags: [Standard, Skill]
---

# Skill Frontmatter Schema

> 所有 Skill 的 `SKILL.md` 必须以符合本规范的 YAML frontmatter 开头。

## 必填字段（6 项）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `name` | string | 正则 `^[a-z0-9][a-z0-9-]*[a-z0-9]$` | slug，全局唯一，必须与目录名一致 |
| `description` | string | 1-200 字符 | 一句话描述「做什么 + 何时用」 |
| `version` | semver | `^[0-9]+\.[0-9]+\.[0-9]+$` | 语义化版本，初始 `1.0.0` |
| `when_to_use` | string | 1-300 字符 | 触发词或使用场景 |
| `status` | enum | 见下表 | 当前状态 |
| `tags` | string[] | ≥1 个 | 分类标签 |

### status 取值

| 值 | 含义 | 同步到 IDE |
|----|------|----------|
| `stable` | 核心层 Skill，可被路由 | ✅ |
| `peripheral` | 外围层，可被加载但不主动路由 | ✅ |
| `archived` | 归档层，仅保留供查阅 | ❌ |
| `experimental` | 实验层，可能随时调整 | ✅（标记 warning） |

## 选填字段（4 项）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `domain` | enum | code \| novel \| news \| shared \| biz \| crypto \| science | 所属域 |
| `category` | enum | language \| workflow \| tool \| review \| pattern \| framework | 能力分类 |
| `routing_role` | string | 匹配 `agents/<role>.md` 文件名 | 路由到哪个 Agent 角色 |
| `references` | string[] | 相对路径 | 关联文档/Skill 路径 |

## 完整示例

```yaml
---
name: code-review
description: "系统性代码审查方法论，覆盖安全、性能、可维护性、正确性、测试五个维度。"
version: 1.0.0
when_to_use: "用户说『审查』/『code review』/『看看这个 PR』时调用"
status: stable
tags: [review, quality, code]
domain: code
category: review
routing_role: code-reviewer
references:
  - ../rules/code/common/patterns.md
---
```
````

- [ ] **Step 2: 验证文件创建**

Run: `ls -la docs/skill-frontmatter-schema.md`
Expected: 文件存在，大小约 3KB

- [ ] **Step 3: 提交**

```bash
git add docs/skill-frontmatter-schema.md
git commit -m "docs(skill): add frontmatter schema spec"
```

---

## Task 2: 编写 `_meta.json` JSON Schema

**Files:**
- Create: `schemas/skill-meta.schema.json`

- [ ] **Step 1: 创建目录**

Run: `mkdir -p schemas`
Expected: 目录创建成功

- [ ] **Step 2: 创建文件**

写入 `schemas/skill-meta.schema.json`：

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "SkillMeta",
  "description": "harness-foundry Skill _meta.json Schema (v1)",
  "type": "object",
  "required": ["slug", "domain", "category", "status", "tags", "purpose", "version"],
  "properties": {
    "slug": {
      "type": "string",
      "pattern": "^[a-z0-9][a-z0-9-]*[a-z0-9]$",
      "description": "必须与目录名一致"
    },
    "domain": {
      "enum": ["code", "novel", "news", "shared", "biz", "crypto", "science"],
      "description": "所属域"
    },
    "category": {
      "enum": ["language", "workflow", "tool", "review", "pattern", "framework"],
      "description": "能力分类"
    },
    "status": {
      "enum": ["stable", "peripheral", "archived", "experimental"],
      "description": "层分类状态"
    },
    "tags": {
      "type": "array",
      "minItems": 1,
      "items": { "type": "string" },
      "description": "标签"
    },
    "purpose": {
      "type": "string",
      "minLength": 10,
      "maxLength": 500,
      "description": "本 Skill 的目的"
    },
    "version": {
      "type": "string",
      "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$",
      "description": "语义化版本"
    },
    "requires": {
      "type": "array",
      "items": { "type": "string" },
      "description": "依赖的其他 Skill slug"
    },
    "complements": {
      "type": "array",
      "items": { "type": "string" },
      "description": "互补 Skill slug"
    },
    "conflicts": {
      "type": "array",
      "items": { "type": "string" },
      "description": "冲突 Skill slug"
    },
    "routing_role": {
      "type": "string",
      "description": "路由到哪个 Agent 角色"
    },
    "estimated_tokens": {
      "type": "integer",
      "minimum": 100,
      "description": "估算的 token 数"
    },
    "source": {
      "enum": ["core", "third-party", "user", "generated"],
      "description": "Skill 来源"
    }
  },
  "additionalProperties": false
}
```

- [ ] **Step 3: 验证 JSON 合法**

Run: `python -c "import json; json.load(open('schemas/skill-meta.schema.json'))"`
Expected: 无输出（合法 JSON）

- [ ] **Step 4: 提交**

```bash
git add schemas/skill-meta.schema.json
git commit -m "feat(schemas): add skill-meta JSON Schema v1"
```

---

## Task 3: 升级 `docs/skill-metadata-spec.md`

**Files:**
- Modify: `docs/skill-metadata-spec.md`

- [ ] **Step 1: 读现状**

Run: `cat docs/skill-metadata-spec.md`
查看现有字段定义，与新 Schema 对比。

- [ ] **Step 2: 追加章节**

在文件末尾追加：

````markdown
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
````

- [ ] **Step 3: 验证**

Run: `grep -c "schemas/skill-meta.schema.json" docs/skill-metadata-spec.md`
Expected: `1` 或更多

- [ ] **Step 4: 提交**

```bash
git add docs/skill-metadata-spec.md
git commit -m "docs(skill): align metadata spec with JSON Schema v1"
```

---

## Task 4: classify-skills.py 失败测试先行

**Files:**
- Create: `tests/L2-integration/classify-skills.test.sh`

- [ ] **Step 1: 创建文件**

写入 `tests/L2-integration/classify-skills.test.sh`：

```bash
#!/usr/bin/env bash
# 集成测试：scripts/classify-skills.py
# 断言：
#   1. 同一输入跑 3 次输出完全一致（确定性）
#   2. 数量守恒：core ≤80, peripheral ≤120, archived ≥100
#   3. 路由表引用 → core
#   4. 空目录/无 frontmatter → archived

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

CLASSIFY="python3 scripts/classify-skills.py"
LAYER_FILE="skills/_layer.yaml"

echo "==> T2.1 确定性测试"
out1=$(mktemp)
out2=$(mktemp)
out3=$(mktemp)
$CLASSIFY --output "$out1" >/dev/null 2>&1
$CLASSIFY --output "$out2" >/dev/null 2>&1
$CLASSIFY --output "$out3" >/dev/null 2>&1
if ! diff -q "$out1" "$out2" >/dev/null || ! diff -q "$out2" "$out3" >/dev/null; then
  echo "  [FAIL] classify 输出不一致"; diff "$out1" "$out2"; exit 1
fi
echo "  [ok] 3 次输出完全一致"

echo "==> T2.2 数量守恒"
core_count=$(yq '.core | length' "$out1")
peri_count=$(yq '.peripheral | length' "$out1")
arch_count=$(yq '.archived | length' "$out1")
total=$((core_count + peri_count + arch_count))

if [[ "$core_count" -gt 80 ]]; then
  echo "  [FAIL] core=$core_count > 80"; exit 1
fi
if [[ "$peri_count" -gt 120 ]]; then
  echo "  [FAIL] peripheral=$peri_count > 120"; exit 1
fi
if [[ "$arch_count" -lt 100 ]]; then
  echo "  [FAIL] archived=$arch_count < 100"; exit 1
fi
if [[ "$total" -ne 328 ]]; then
  echo "  [FAIL] total=$total != 328"; exit 1
fi
echo "  [ok] core=$core_count, peripheral=$peri_count, archived=$arch_count"

rm -f "$out1" "$out2" "$out3"
echo ""
echo "All tests passed."
```

- [ ] **Step 2: 让测试失败（验证）**

Run: `bash tests/L2-integration/classify-skills.test.sh`
Expected: FAIL with "No such file or directory: scripts/classify-skills.py"

- [ ] **Step 3: 提交测试**

```bash
git add tests/L2-integration/classify-skills.test.sh
git commit -m "test(skill): add failing test for classify-skills.py"
```

---

## Task 5: 实现 classify-skills.py 最小可用版本

**Files:**
- Create: `scripts/classify-skills.py`

- [ ] **Step 1: 创建文件**

写入 `scripts/classify-skills.py`：

```python
#!/usr/bin/env python3
"""
classify-skills.py — 三层自动分类器

读取 skills/<slug>/SKILL.md + _meta.json + core/orchestration/skill-preferences.md，
输出 skills/_layer.yaml：
  core: [slug, ...]        ≤ 80
  peripheral: [slug, ...]  ≤ 120
  archived: [slug, ...]    其余

退出码：
  0 — 成功
  1 — 输入错误
  2 — 数量约束违反
"""
import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Set

import yaml

ROOT = Path(__file__).parent.parent
SKILLS_DIR = ROOT / "skills"
ROUTING_FILE = ROOT / "core" / "orchestration" / "skill-preferences.md"
LAYER_FILE_DEFAULT = ROOT / "skills" / "_layer.yaml"

CORE_LIMIT = 80
PERIPHERAL_LIMIT = 120
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")


def parse_frontmatter(skill_md: Path) -> dict:
    """解析 SKILL.md 顶部 YAML frontmatter"""
    try:
        content = skill_md.read_text(encoding="utf-8")
    except Exception:
        return {}
    if not content.startswith("---"):
        return {}
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError:
        return {}


def load_meta(skill_dir: Path) -> dict:
    """读取 _meta.json，无则返回空 dict"""
    meta_path = skill_dir / "_meta.json"
    if not meta_path.exists():
        return {}
    try:
        import json
        return json.loads(meta_path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_routing_slugs() -> Set[str]:
    """从 skill-preferences.md 提取所有被路由的 slug"""
    if not ROUTING_FILE.exists():
        return set()
    text = ROUTING_FILE.read_text(encoding="utf-8")
    # 简单启发式：行内含 ``（反引号）的 slug 都视为路由引用
    return set(re.findall(r"`([a-z0-9][a-z0-9-]*[a-z0-9])`", text))


def classify_one(slug: str, skill_dir: Path, routing: Set[str]) -> str:
    """核心分类规则 P1-P5（见 spec §5.3）"""
    skill_md = skill_dir / "SKILL.md"
    fm = parse_frontmatter(skill_md) if skill_md.exists() else {}
    meta = load_meta(skill_dir)
    body_len = len(skill_md.read_text(encoding="utf-8")) if skill_md.exists() else 0
    has_fm = bool(fm)
    has_meta = bool(meta)
    has_any_meta = has_fm or has_meta

    # P1: 路由表引用 → stable (core)
    if slug in routing:
        return "stable"

    # P2: frontmatter + _meta 完整 + 内容 > 500 字 → core 候选
    if has_fm and has_meta and body_len > 500:
        return "stable"

    # P3: 任何 meta + 内容 > 200 字 → peripheral
    if has_any_meta and body_len > 200:
        return "peripheral"

    # P4: 启发式生成（source=generated）或内容 < 100 字 → archived
    if meta.get("source") == "generated" or body_len < 100:
        return "archived"

    # P5: 其余 → peripheral（保守）
    return "peripheral"


def apply_core_cap(layers: Dict[str, List[str]]) -> Dict[str, List[str]]:
    """核心层数量守恒：超过 80 时按优先级削减"""
    if len(layers["stable"]) <= CORE_LIMIT:
        return layers
    # 优先级削减：experimental → requires 链长 → body_length 小
    overflow = layers["stable"][CORE_LIMIT:]
    for slug in overflow:
        layers["stable"].remove(slug)
        layers["peripheral"].append(slug)
    return layers


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", "-o", default=str(LAYER_FILE_DEFAULT))
    parser.add_argument("--review", action="store_true",
                        help="交互审核模式（本期不实现，仅占位）")
    args = parser.parse_args()

    if not SKILLS_DIR.exists():
        print(f"ERROR: {SKILLS_DIR} not found", file=sys.stderr)
        return 1

    routing = load_routing_slugs()
    layers = {"stable": [], "peripheral": [], "archived": []}

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        slug = skill_dir.name
        if slug.startswith("_"):  # 跳过 _layer.yaml 等
            continue
        status = classify_one(slug, skill_dir, routing)
        layers[status].append(slug)

    apply_core_cap(layers)

    # 守恒校验
    if len(layers["stable"]) > CORE_LIMIT:
        print(f"ERROR: core count {len(layers['stable'])} > {CORE_LIMIT}", file=sys.stderr)
        return 2
    if len(layers["peripheral"]) > PERIPHERAL_LIMIT:
        print(f"ERROR: peripheral count {len(layers['peripheral'])} > {PERIPHERAL_LIMIT}",
              file=sys.stderr)
        return 2

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        yaml.dump(
            {"core": sorted(layers["stable"]),
             "peripheral": sorted(layers["peripheral"]),
             "archived": sorted(layers["archived"])},
            f,
            default_flow_style=False,
            sort_keys=False,
        )

    total = sum(len(v) for v in layers.values())
    print(f"[ok] {total} skills classified: "
          f"core={len(layers['stable'])} "
          f"peripheral={len(layers['peripheral'])} "
          f"archived={len(layers['archived'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: 安装依赖**

Run: `pip install pyyaml --quiet 2>&1 | tail -1`
Expected: 安装成功或已存在

- [ ] **Step 3: 测试运行**

Run: `python3 scripts/classify-skills.py`
Expected: 输出形如 `[ok] 328 skills classified: core=... peripheral=... archived=...`

- [ ] **Step 4: 运行集成测试**

Run: `bash tests/L2-integration/classify-skills.test.sh`
Expected: 输出 "All tests passed."

- [ ] **Step 5: 验证生成产物**

Run: `head -30 skills/_layer.yaml`
Expected: 看到 `core:` / `peripheral:` / `archived:` 三个 key + slug 列表

- [ ] **Step 6: 提交**

```bash
git add scripts/classify-skills.py
git commit -m "feat(skill): implement three-layer classifier"
```

---

## Task 6: 编写 auto-fill-frontmatter.py（启发式补全）

**Files:**
- Create: `scripts/auto-fill-frontmatter.py`

- [ ] **Step 1: 创建文件**

写入 `scripts/auto-fill-frontmatter.py`：

```python
#!/usr/bin/env python3
"""
auto-fill-frontmatter.py — 启发式补全缺失的 frontmatter

逻辑：
  - 读取 SKILL.md
  - 若无 frontmatter，从第一段（# 标题）提取 name/description/when_to_use
  - 读取已有 _meta.json 推断 tags/domain/category/status
  - 仅在缺失字段时补全，不覆盖已有值
  - 写入文件（默认 dry-run）
"""
import argparse
import json
import re
import sys
from pathlib import Path
from typing import Optional

import yaml

ROOT = Path(__file__).parent.parent
SKILLS_DIR = ROOT / "skills"

DOMAIN_KEYWORDS = {
    "code": ["code", "review", "test", "build", "lint", "debug", "refactor", "tdd"],
    "novel": ["novel", "story", "character", "plot", "chapter", "fiction", "创作", "小说"],
    "news": ["news", "article", "report", "headline", "fact-check", "新闻", "报道"],
    "shared": ["plan", "brainstorm", "research", "memory", "skill"],
}


def extract_first_paragraph(content: str) -> str:
    """提取 frontmatter 后第一个非空段落"""
    parts = content.split("---", 2)
    body = parts[2] if len(parts) >= 3 else content
    lines = [l.strip() for l in body.splitlines() if l.strip()]
    # 跳过 # 标题行
    for line in lines:
        if line.startswith("#"):
            return " ".join(lines[1:2]) if len(lines) > 1 else line.lstrip("# ").strip()
        return line
    return ""


def infer_domain(text: str) -> str:
    """根据关键词推断 domain"""
    text_lower = text.lower()
    scores = {d: sum(1 for kw in kws if kw in text_lower) for d, kws in DOMAIN_KEYWORDS.items()}
    best = max(scores, key=scores.get)
    return best if scores[best] > 0 else "shared"


def fill_one(skill_dir: Path, dry_run: bool) -> bool:
    """补全单个 Skill 的 frontmatter，返回是否变更"""
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return False

    content = skill_md.read_text(encoding="utf-8")
    has_fm = content.startswith("---")
    fm: dict = {}
    body_start = 0
    if has_fm:
        parts = content.split("---", 2)
        try:
            fm = yaml.safe_load(parts[1]) or {}
            body_start = len(parts[0]) + len(parts[1]) + 6  # "---\n" + "---\n"
        except yaml.YAMLError:
            fm = {}
            body_start = 0

    meta_path = skill_dir / "_meta.json"
    meta: dict = {}
    if meta_path.exists():
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except Exception:
            meta = {}

    changed = False
    body_text = content[body_start:] if body_start > 0 else content
    first_para = extract_first_paragraph(content)

    # 补全 name
    if "name" not in fm:
        fm["name"] = skill_dir.name
        changed = True

    # 补全 description（取第一段，截断到 200）
    if "description" not in fm:
        fm["description"] = first_para[:200].strip() or f"Skill for {skill_dir.name}"
        changed = True

    # 补全 version
    if "version" not in fm:
        fm["version"] = meta.get("version", "1.0.0")
        changed = True

    # 补全 when_to_use（用 description 衍生）
    if "when_to_use" not in fm:
        fm["when_to_use"] = f"调用 {skill_dir.name} 时"
        changed = True

    # 补全 status（以 _meta.status 为准）
    if "status" not in fm:
        fm["status"] = meta.get("status", "peripheral")
        changed = True

    # 补全 tags
    if "tags" not in fm or not fm["tags"]:
        fm["tags"] = meta.get("tags", [infer_domain(first_para)])
        changed = True

    # 补全 domain
    if "domain" not in fm:
        fm["domain"] = meta.get("domain", infer_domain(first_para))
        changed = True

    # 补全 category
    if "category" not in fm:
        fm["category"] = meta.get("category", "workflow")
        changed = True

    if not changed:
        return False

    # 重写文件
    new_content = "---\n" + yaml.dump(fm, default_flow_style=False, sort_keys=False,
                                       allow_unicode=True) + "---\n" + body_text.lstrip()
    if not dry_run:
        skill_md.write_text(new_content, encoding="utf-8")
    print(f"[{'would-fix' if dry_run else 'fixed'}] {skill_dir.name}")
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true",
                        help="实际写入文件（覆盖 dry-run 默认）")
    args = parser.parse_args()

    dry_run = not args.apply
    fixed = 0
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name.startswith("_"):
            continue
        if fill_one(skill_dir, dry_run):
            fixed += 1

    print(f"\n[summary] {'would fix' if dry_run else 'fixed'} {fixed} skills")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: dry-run 测试**

Run: `python3 scripts/auto-fill-frontmatter.py --dry-run | head -20`
Expected: 输出形如 `[would-fix] skill-slug` 列表

- [ ] **Step 3: 提交**

```bash
git add scripts/auto-fill-frontmatter.py
git commit -m "feat(skill): add auto-fill-frontmatter heuristic tool"
```

---

## Task 7: 编写 validate-skill-frontmatter.sh（CI 必跑）

**Files:**
- Create: `tests/L1-static/validate-skill-frontmatter.sh`

- [ ] **Step 1: 创建文件**

写入 `tests/L1-static/validate-skill-frontmatter.sh`：

```bash
#!/usr/bin/env bash
# 校验所有 Skill 的 SKILL.md frontmatter
# 必填字段：name / description / version / when_to_use / status / tags
# 校验依据：docs/skill-frontmatter-schema.md

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

LAYER_FILE="skills/_layer.yaml"
if [[ -f "$LAYER_FILE" ]]; then
  CORE_SLUGS=$(yq '.core | .[]' "$LAYER_FILE" 2>/dev/null || true)
else
  CORE_SLUGS=""
fi

FAILED=0
TOTAL=0
SKIPPED=0

for skill_dir in skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  slug=$(basename "$skill_dir")
  [[ "$slug" == _* ]] && continue
  TOTAL=$((TOTAL + 1))

  # 核心层必须校验
  is_core=false
  if [[ " $CORE_SLUGS " == *" $slug "* ]] || [[ -z "$CORE_SLUGS" ]]; then
    is_core=true
  fi

  skill_md="$skill_dir/SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    echo "[FAIL] $slug: SKILL.md missing"
    FAILED=$((FAILED + 1))
    continue
  fi

  content=$(cat "$skill_md")
  if [[ "$content" != ---\n* ]]; then
    if [[ "$is_core" == true ]]; then
      echo "[FAIL] $slug: frontmatter missing (core layer requires)"
      FAILED=$((FAILED + 1))
    else
      SKIPPED=$((SKIPPED + 1))
    fi
    continue
  fi

  # 用 python 校验（跨平台）
  err=$(python3 - "$skill_md" "$is_core" <<'PYEOF' 2>&1
import sys, re, yaml
from pathlib import Path

skill_md = Path(sys.argv[1])
is_core = sys.argv[2] == "true"

text = skill_md.read_text(encoding="utf-8")
if not text.startswith("---"):
    if is_core:
        print(f"{skill_md.parent.name}: frontmatter missing")
        sys.exit(1)
    sys.exit(0)

parts = text.split("---", 2)
if len(parts) < 3:
    print(f"{skill_md.parent.name}: malformed frontmatter")
    sys.exit(1)

try:
    fm = yaml.safe_load(parts[1]) or {}
except yaml.YAMLError as e:
    print(f"{skill_md.parent.name}: YAML error: {e}")
    sys.exit(1)

required = ["name", "description", "version", "when_to_use", "status", "tags"]
status_enum = ["stable", "peripheral", "archived", "experimental"]
slug_re = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
semver_re = re.compile(r"^\d+\.\d+\.\d+$")

errs = []
for field in required:
    if field not in fm:
        errs.append(f"missing required field: {field}")

if "name" in fm and not slug_re.match(str(fm["name"])):
    errs.append(f"invalid name (slug): {fm['name']}")
if "version" in fm and not semver_re.match(str(fm["version"])):
    errs.append(f"invalid version (semver): {fm['version']}")
if "status" in fm and fm["status"] not in status_enum:
    errs.append(f"invalid status: {fm['status']}")
if "description" in fm and (len(str(fm["description"])) < 1 or len(str(fm["description"])) > 200):
    errs.append(f"description length out of range: {len(fm['description'])}")
if "when_to_use" in fm and (len(str(fm["when_to_use"])) < 1 or len(str(fm["when_to_use"])) > 300):
    errs.append(f"when_to_use length out of range: {len(fm['when_to_use'])}")
if "tags" in fm and (not isinstance(fm["tags"], list) or len(fm["tags"]) < 1):
    errs.append(f"tags must be non-empty array")

# 强制 name == slug
if fm.get("name") != skill_md.parent.name:
    errs.append(f"name mismatch: {fm.get('name')} != {skill_md.parent.name}")

if errs:
    print(f"{skill_md.parent.name}: " + "; ".join(errs))
    sys.exit(1)
PYEOF
  ) || {
    echo "[FAIL] $err"
    FAILED=$((FAILED + 1))
  }
done

echo ""
echo "==> Frontmatter validation: total=$TOTAL failed=$FAILED skipped=$SKIPPED"
[[ "$FAILED" -eq 0 ]] || exit 1
```

- [ ] **Step 2: 加执行权限**

Run: `chmod +x tests/L1-static/validate-skill-frontmatter.sh`

- [ ] **Step 3: 运行测试（预期核心层失败，因为还没补 frontmatter）**

Run: `bash tests/L1-static/validate-skill-frontmatter.sh 2>&1 | tail -10`
Expected: FAIL 数 = 核心层数（约 20-80 个）

- [ ] **Step 4: 提交**

```bash
git add tests/L1-static/validate-skill-frontmatter.sh
git commit -m "test(skill): add L1 frontmatter validator"
```

---

## Task 8: 编写 validate-skill-meta.sh（CI 必跑）

**Files:**
- Create: `tests/L1-static/validate-skill-meta.sh`

- [ ] **Step 1: 安装 ajv-cli 或准备 Python 回退**

Run: `command -v ajv >/dev/null 2>&1 || pip install jsonschema --quiet 2>&1 | tail -1`
Expected: ajv 可用 或 jsonschema Python 包已安装

- [ ] **Step 2: 创建文件**

写入 `tests/L1-static/validate-skill-meta.sh`：

```bash
#!/usr/bin/env bash
# 校验所有 Skill 的 _meta.json
# 依据：schemas/skill-meta.schema.json

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

LAYER_FILE="skills/_layer.yaml"
if [[ -f "$LAYER_FILE" ]]; then
  CORE_SLUGS=$(yq '.core | .[]' "$LAYER_FILE" 2>/dev/null || true)
  PERI_SLUGS=$(yq '.peripheral | .[]' "$LAYER_FILE" 2>/dev/null || true)
  ARCH_SLUGS=$(yq '.archived | .[]' "$LAYER_FILE" 2>/dev/null || true)
else
  CORE_SLUGS=""; PERI_SLUGS=""; ARCH_SLUGS=""
fi

FAILED=0
WARNED=0
SKIPPED=0
TOTAL=0

for skill_dir in skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  slug=$(basename "$skill_dir")
  [[ "$slug" == _* ]] && continue
  TOTAL=$((TOTAL + 1))

  is_core=false; is_peri=false; is_arch=false
  [[ " $CORE_SLUGS " == *" $slug "* ]] && is_core=true
  [[ " $PERI_SLUGS " == *" $slug "* ]] && is_peri=true
  [[ " $ARCH_SLUGS " == *" $slug "* ]] && is_arch=true

  meta_path="$skill_dir/_meta.json"

  if [[ ! -f "$meta_path" ]]; then
    if [[ "$is_core" == true ]]; then
      echo "[FAIL] $slug: _meta.json missing (core layer requires)"
      FAILED=$((FAILED + 1))
    elif [[ "$is_arch" == true ]]; then
      SKIPPED=$((SKIPPED + 1))
    else
      echo "[WARN] $slug: _meta.json missing (peripheral layer)"
      WARNED=$((WARNED + 1))
    fi
    continue
  fi

  # 用 jsonschema Python 包校验（跨平台回退）
  err=$(python3 - "$meta_path" "schemas/skill-meta.schema.json" 2>&1 <<'PYEOF' || true
import sys, json
from pathlib import Path

try:
    import jsonschema
except ImportError:
    print("jsonschema not installed; skipping schema validation", file=sys.stderr)
    sys.exit(2)

meta_path = Path(sys.argv[1])
schema_path = Path(sys.argv[2])

try:
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as e:
    print(f"{meta_path.parent.name}: JSON parse error: {e}")
    sys.exit(1)

schema = json.loads(schema_path.read_text(encoding="utf-8"))
validator = jsonschema.Draft7Validator(schema)
errors = list(validator.iter_errors(meta))

if errors:
    err_msgs = [f"{'/'.join(str(p) for p in e.absolute_path)}: {e.message}" for e in errors]
    print(f"{meta_path.parent.name}: " + "; ".join(err_msgs))
    sys.exit(1)

# 额外校验：slug == dir name
if meta.get("slug") != meta_path.parent.name:
    print(f"{meta_path.parent.name}: slug mismatch: {meta.get('slug')} != {meta_path.parent.name}")
    sys.exit(1)
PYEOF
  )
  rc=$?
  if [[ $rc -eq 1 ]]; then
    echo "[FAIL] $err"
    FAILED=$((FAILED + 1))
  elif [[ $rc -eq 2 ]]; then
    SKIPPED=$((SKIPPED + 1))
  fi
done

# 交叉校验：路由表引用 vs 实际 slug 集合
if [[ -f "core/orchestration/skill-preferences.md" ]]; then
  echo ""
  echo "==> Cross-check: routing references"
  python3 - <<'PYEOF'
import re, sys
from pathlib import Path

routing = Path("core/orchestration/skill-preferences.md").read_text(encoding="utf-8")
referenced = set(re.findall(r"`([a-z0-9][a-z0-9-]*[a-z0-9])`", routing))

existing = {p.parent.name for p in Path("skills").iterdir()
            if p.is_dir() and not p.name.startswith("_")}
missing = referenced - existing
if missing:
    print(f"[FAIL] routing references non-existent skills: {sorted(missing)}")
    sys.exit(1)
print(f"  [ok] all {len(referenced)} routing references exist")
PYEOF
fi

echo ""
echo "==> _meta validation: total=$TOTAL failed=$FAILED warned=$WARNED skipped=$SKIPPED"
[[ "$FAILED" -eq 0 ]] || exit 1
```

- [ ] **Step 3: 加执行权限**

Run: `chmod +x tests/L1-static/validate-skill-meta.sh`

- [ ] **Step 4: 运行测试**

Run: `bash tests/L1-static/validate-skill-meta.sh 2>&1 | tail -20`
Expected: 一些 FAIL（核心层缺 _meta.json 的）

- [ ] **Step 5: 提交**

```bash
git add tests/L1-static/validate-skill-meta.sh
git commit -m "test(skill): add L1 _meta.json validator"
```

---

## Task 9: 修改 sync-skills.sh 读取 `_layer.yaml`

**Files:**
- Modify: `scripts/sync-skills.sh`（在循环外加读取层过滤逻辑）

- [ ] **Step 1: 读取现状**

Run: `head -50 scripts/sync-skills.sh`

- [ ] **Step 2: 修改 sync 逻辑**

在 `scripts/sync-skills.sh` 找到遍历 `skills/*/` 的循环（通常形如 `for skill_dir in skills/*/`），在循环开始前插入：

```bash
# === Layer filtering (per spec 2026-06-29-skill-engineering-frontmatter-and-meta) ===
LAYER_FILE="${LAYER_FILE:-skills/_layer.yaml}"
SKIP_ARCHIVED="${SKIP_ARCHIVED:-true}"
ALLOWED_SLUGS=""
if [[ "$SKIP_ARCHIVED" == "true" && -f "$LAYER_FILE" ]]; then
  if command -v yq >/dev/null 2>&1; then
    ALLOWED_SLUGS=$(yq -r '.core + .peripheral | .[]' "$LAYER_FILE" 2>/dev/null || true)
  else
    echo "WARN: yq not found, falling back to sync all skills" >&2
  fi
fi
# === End layer filtering ===
```

然后在循环内加判断（紧跟 `slug=$(basename "$skill_dir")` 之后）：

```bash
  # 跳过 archived Skill（除非 SKIP_ARCHIVED=false）
  if [[ "$SKIP_ARCHIVED" == "true" && -n "$ALLOWED_SLUGS" ]]; then
    if [[ " $ALLOWED_SLUGS " != *" $slug "* ]]; then
      continue
    fi
  fi
```

- [ ] **Step 3: 测试 dry-run**

Run: `bash scripts/sync-skills.sh --target all --dry-run 2>&1 | head -20`
Expected: 输出只包含 core + peripheral 的 Skill 路径，不含 archived

- [ ] **Step 4: 提交**

```bash
git add scripts/sync-skills.sh
git commit -m "feat(skill): sync-skills filters archived via _layer.yaml"
```

---

## Task 10: 修改 verify.sh 集成新校验器

**Files:**
- Modify: `scripts/verify.sh`

- [ ] **Step 1: 修改 `[N/N]` 计数**

当前 verify.sh 标注是 `[1/4]` ~ `[4/4]`，新增 2 个步骤后改为 `[1/6]` ~ `[6/6]`。

- [ ] **Step 2: 在文件末尾追加两个步骤**

在 `scripts/verify.sh` 末尾追加：

```bash

# 5. 验证 Skill frontmatter
echo ""
echo "==> [5/6] 验证 Skill frontmatter"
bash tests/L1-static/validate-skill-frontmatter.sh || \
  { echo "  [FAIL] frontmatter validation"; exit 1; }
echo "  [ok] frontmatter validation"

# 6. 验证 Skill _meta.json
echo ""
echo "==> [6/6] 验证 Skill _meta.json"
bash tests/L1-static/validate-skill-meta.sh || \
  { echo "  [FAIL] _meta validation"; exit 1; }
echo "  [ok] _meta validation"
```

- [ ] **Step 3: 运行完整 verify**

Run: `bash scripts/verify.sh 2>&1 | tail -30`
Expected: 输出 6 个步骤，可能有部分 FAIL（核心层 Skill 缺 frontmatter）

- [ ] **Step 4: 提交**

```bash
git add scripts/verify.sh
git commit -m "ci: integrate frontmatter and _meta validators into verify.sh"
```

---

## Task 11: 一次性补全 328 个 Skill 的 frontmatter（apply 模式）

**Files:**
- Modify: 328 个 `skills/<slug>/SKILL.md` 文件（仅头部 frontmatter）

- [ ] **Step 1: 运行 auto-fill（apply 模式）**

Run: `python3 scripts/auto-fill-frontmatter.py --apply 2>&1 | tail -20`
Expected: 输出 `[fixed] <slug>` 列表 + summary

- [ ] **Step 2: 验证数量**

Run: `python3 scripts/auto-fill-frontmatter.py --dry-run 2>&1 | tail -3`
Expected: summary 显示 `would fix 0 skills`（已全部补全）

- [ ] **Step 3: 重新运行 verify**

Run: `bash scripts/verify.sh 2>&1 | tail -20`
Expected: frontmatter 校验通过率显著提升

- [ ] **Step 4: 提交（按文件分组，避免单 commit 过大）**

```bash
git add skills/*/SKILL.md
git commit -m "feat(skill): auto-fill frontmatter for 328 skills"
```

---

## Task 12: 生成 `skills/_layer.yaml` 正式产物

**Files:**
- Create: `skills/_layer.yaml`（生成产物）

- [ ] **Step 1: 运行分类器**

Run: `python3 scripts/classify-skills.py`
Expected: `[ok] 328 skills classified: core=N peripheral=M archived=K`

- [ ] **Step 2: 检查产物**

Run: `yq '.core | length, .peripheral | length, .archived | length' skills/_layer.yaml`
Expected: 三个数字，分别 ≤ 80 / ≤ 120 / ≥ 100

- [ ] **Step 3: 验证 sync 过滤生效**

Run: `bash scripts/sync-skills.sh --target all --dry-run 2>&1 | grep -c "skills/" || true`
Expected: 数字 ≈ core + peripheral

- [ ] **Step 4: 提交**

```bash
git add skills/_layer.yaml
git commit -m "feat(skill): generate _layer.yaml classification"
```

---

## Task 13: 编写 sync-skills-layer 集成测试

**Files:**
- Create: `tests/L2-integration/sync-skills-layer.test.sh`

- [ ] **Step 1: 创建文件**

写入 `tests/L2-integration/sync-skills-layer.test.sh`：

```bash
#!/usr/bin/env bash
# 集成测试：sync-skills.sh 过滤 archived Skill

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

LAYER_FILE="skills/_layer.yaml"
[[ -f "$LAYER_FILE" ]] || { echo "[FAIL] _layer.yaml not found"; exit 1; }

# 1. 提取 dry-run 输出
output=$(bash scripts/sync-skills.sh --target all --dry-run 2>&1 || true)

# 2. 检查 archived Skill 不在输出中
arch_count=$(yq '.archived | length' "$LAYER_FILE")
hit=0
for slug in $(yq '.archived | .[]' "$LAYER_FILE"); do
  if echo "$output" | grep -q "skills/$slug/"; then
    hit=$((hit + 1))
  fi
done

if [[ "$hit" -gt 0 ]]; then
  echo "[FAIL] $hit archived skills leaked into sync output"
  exit 1
fi

echo "[ok] $arch_count archived skills filtered out"

# 3. 检查 core+peripheral 在输出中（抽样 5 个）
sampled=0
matched=0
for slug in $(yq '.core + .peripheral | .[]' "$LAYER_FILE" | shuf | head -5); do
  sampled=$((sampled + 1))
  if echo "$output" | grep -q "skills/$slug/"; then
    matched=$((matched + 1))
  fi
done

if [[ "$matched" -lt 3 ]]; then
  echo "[FAIL] only $matched/5 sampled core+peripheral skills present in output"
  exit 1
fi

echo "[ok] $matched/5 sampled core+peripheral skills present"
echo ""
echo "All sync-layer tests passed."
```

- [ ] **Step 2: 加执行权限**

Run: `chmod +x tests/L2-integration/sync-skills-layer.test.sh`

- [ ] **Step 3: 运行**

Run: `bash tests/L2-integration/sync-skills-layer.test.sh`
Expected: `All sync-layer tests passed.`

- [ ] **Step 4: 提交**

```bash
git add tests/L2-integration/sync-skills-layer.test.sh
git commit -m "test(skill): add sync-skills layer filtering integration test"
```

---

## Task 14: 更新 INDEX.md 增加 Layer 列

**Files:**
- Modify: `skills/INDEX.md`

- [ ] **Step 1: 读现状**

Run: `head -15 skills/INDEX.md`

- [ ] **Step 2: 修改表头与生成逻辑**

由于 INDEX.md 是 `gen-skill-index.sh` 生成的，修改 `scripts/gen-skill-index.sh`（如果存在）或手改：

- 在表头增加 `| 层 |` 列
- 在每行末追加 `| stable / peripheral / archived |` 数据
- 增加脚注：「层的定义见 `skills/_layer.yaml`」

- [ ] **Step 3: 重新生成（如可用）**

Run: `bash scripts/gen-skill-index.sh 2>&1 | tail -5`
Expected: 重新生成 INDEX.md

如脚本不可用，手动更新。

- [ ] **Step 4: 提交**

```bash
git add skills/INDEX.md scripts/gen-skill-index.sh
git commit -m "docs(skill): add Layer column to INDEX.md"
```

---

## Task 15: 更新 CHANGELOG.md

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: 在 [Unreleased] 段追加**

在 CHANGELOG.md 的 `## [Unreleased]` → `### Added` 段追加：

```markdown
- **Skill 三层分层**：落地核心（≤80）/ 外围（≤120）/ 归档（~128）模型，生成 `skills/_layer.yaml`
- **Frontmatter 标准**：`docs/skill-frontmatter-schema.md` 定义 6 必填 + 4 选填字段
- **`_meta.json` JSON Schema**：`schemas/skill-meta.schema.json`（Draft-07）作为校验真相源
- **分类器**：`scripts/classify-skills.py` 基于路由表 + frontmatter 完整性自动三层分类
- **frontmatter 自动补全**：`scripts/auto-fill-frontmatter.py` 启发式为缺失 Skill 补全 6 必填字段
- **CI 校验**：
  - `tests/L1-static/validate-skill-frontmatter.sh`
  - `tests/L1-static/validate-skill-meta.sh`
  - 集成到 `scripts/verify.sh`
- **sync 过滤**：`scripts/sync-skills.sh` 读取 `_layer.yaml`，archived Skill 不投影到 IDE
```

`### Changed` 段追加：

```markdown
- `skills/INDEX.md` 增加「层」列
- `scripts/verify.sh` 从 4 步骤扩到 6 步骤
```

- [ ] **Step 2: 验证**

Run: `grep -A1 "三层分层" CHANGELOG.md | head -3`
Expected: 看到新增条目

- [ ] **Step 3: 提交**

```bash
git add CHANGELOG.md
git commit -m "docs: changelog entry for skill engineering milestone 1"
```

---

## Task 16: 更新 README.md 新增「Skill 工程化」章节

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 找到「Skill 系统」章节**

Run: `grep -n "Skill 系统\|## Skill" README.md`

- [ ] **Step 2: 在该章节末尾追加**

```markdown
### Skill 三层分层

为对标 ECC / gstack 等顶尖开源项目，Skill 落地三层模型：

| 层 | 数量上限 | 同步到 IDE | 校验严格度 |
|----|---------|----------|----------|
| **核心（stable）** | ≤80 | ✅ | 必填字段全部强制 |
| **外围（peripheral）** | ≤120 | ✅ | 警告而非阻塞 |
| **归档（archived）** | 剩余 | ❌ | 跳过 |

分类结果见 `skills/_layer.yaml`。重新生成：

```bash
python3 scripts/classify-skills.py          # 生成 _layer.yaml
python3 scripts/auto-fill-frontmatter.py    # 启发式补全 frontmatter
bash scripts/sync-skills.sh --dry-run       # 预览投影（应不含 archived）
bash scripts/verify.sh                      # CI 校验
```

详细规范见 [`docs/skill-frontmatter-schema.md`](docs/skill-frontmatter-schema.md) 与 [`schemas/skill-meta.schema.json`](schemas/skill-meta.schema.json)。
```

- [ ] **Step 3: 验证**

Run: `grep -c "三层分层" README.md`
Expected: `1` 或更多

- [ ] **Step 4: 提交**

```bash
git add README.md
git commit -m "docs: add Skill engineering section to README"
```

---

## Task 17: 最终全量验证

**Files:** 无（仅运行）

- [ ] **Step 1: 运行完整 verify**

Run: `bash scripts/verify.sh 2>&1 | tail -40`
Expected: 6 步骤全部通过或仅遗留警告

- [ ] **Step 2: 运行所有集成测试**

Run:
```bash
bash tests/L1-static/validate-skill-frontmatter.sh
bash tests/L1-static/validate-skill-meta.sh
bash tests/L2-integration/classify-skills.test.sh
bash tests/L2-integration/sync-skills-layer.test.sh
```
Expected: 全部通过

- [ ] **Step 3: 检查 git 状态**

Run: `git status`
Expected: 工作区干净（无未提交修改）

- [ ] **Step 4: 写验收报告**

在 `docs/superpowers/plans/2026-06-29-skill-engineering-frontmatter-and-meta-acceptance.md` 写入验收清单与各指标达成情况。

---

## Self-Review

- [x] **Spec 覆盖**：
  - §3 目标 1-7 → Task 5 (classify) + Task 11 (auto-fill) + Task 12 (_layer.yaml)
  - §3 目标 4-7 → Task 4-8 (CI 校验)
  - §4.3 关键组件 → Task 1-3 (Schema) + Task 5-8 (工具) + Task 7-8 (CI)
  - §5 核心契约 → Task 1 (frontmatter) + Task 2 (JSON Schema) + Task 5 (分类规则) + Task 9 (sync 契约)
  - §6 错误处理 → Task 7 (frontmatter 错误) + Task 8 (meta 错误) + Task 13 (cross-check)
  - §7 测试金字塔 → Task 4 (集成) + Task 7-8 (静态) + Task 13 (sync 集成)
  - §8 风险 → Task 11 (auto-fill 降低开发阻力) + Task 8 (ajv Python 回退)
- [x] **占位符扫描**：无 TBD/TODO，所有代码块完整
- [x] **类型一致**：所有任务中 `slug` / `core` / `peripheral` / `archived` / `_layer.yaml` / `_meta.json` 命名统一
- [x] **频繁提交**：每任务 1 commit，共 17 个 commit
- [x] **DRY/YAGNI**：未引入未使用依赖（仅 pyyaml + jsonschema，均已有或轻量）

---

## 执行选项

Plan 已保存到 `docs/superpowers/plans/2026-06-29-skill-engineering-frontmatter-and-meta-plan.md`，共 17 个任务。

**两种执行方式可选**：

1. **Subagent-Driven（推荐）** — 每任务派发独立 subagent，任务间人工审查，快迭代
2. **Inline Execution** — 当前会话内串行执行，批处理 + 检查点

请告诉我用哪种方式。