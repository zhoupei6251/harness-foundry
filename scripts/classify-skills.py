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

# 强制 core 层白名单（人工审核兜底，详见 _must_core_skills.py）
try:
    from _must_core_skills import must_core as _must_core_set
    MUST_CORE: Set[str] = _must_core_set()
except ImportError:  # pragma: no cover - 单独运行时不依赖
    MUST_CORE = set()

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
    """两路提取路由表引用的 skill slug：

    1) 反引号包裹的 slug（行内 ``xxx``）
    2) 已知 skill 名作为独立 token 出现的 slug（解决路由表中
       裸文本引用如 `brainstorming`、`writing-plans` 没被反引号
       包裹导致 P1 路由规则失效的问题）

    返回两类结果的并集。
    """
    if not ROUTING_FILE.exists():
        return set()
    text = ROUTING_FILE.read_text(encoding="utf-8")

    # 路 1：反引号包裹
    backtick_slugs = set(re.findall(r"`([a-z0-9][a-z0-9-]*[a-z0-9])`", text))

    # 路 2：已知 skill 名（独立 token）
    known_skills: Set[str] = set()
    if SKILLS_DIR.exists():
        for p in SKILLS_DIR.iterdir():
            if p.is_dir() and not p.name.startswith("_"):
                known_skills.add(p.name)

    text_tokens = set(re.findall(r"\b([a-z0-9][a-z0-9-]*[a-z0-9])\b", text))
    token_slugs = text_tokens & known_skills

    return backtick_slugs | token_slugs


def classify_one(slug: str, skill_dir: Path, routing: Set[str]) -> str:
    """核心分类规则 P0-P5（见 spec §5.3）

    P0: 强制 core 白名单（人工审核，最高优先级，覆盖任何后续规则）
    P1: 路由表引用 → stable (core)
    P2: frontmatter + _meta 完整 + 内容 > 500 字 → core 候选
    P3: 任何 meta + 内容 > 200 字 → peripheral
    P4: 启发式生成（source=generated）或内容 < 100 字 → archived
    P5: 其余 → peripheral（保守）
    """
    skill_md = skill_dir / "SKILL.md"
    fm = parse_frontmatter(skill_md) if skill_md.exists() else {}
    meta = load_meta(skill_dir)
    body_len = len(skill_md.read_text(encoding="utf-8")) if skill_md.exists() else 0
    has_fm = bool(fm)
    has_meta = bool(meta)
    has_any_meta = has_fm or has_meta

    # P0: 强制 core 白名单（人工审核兜底，覆盖任何后续规则）
    if slug in MUST_CORE:
        return "stable"

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


def apply_caps(layers: Dict[str, List[str]]) -> Dict[str, List[str]]:
    """三层数量守恒：core ≤80, peripheral ≤120

    优先级削减规则：
    1. MUST_CORE 白名单内的 slug 永远不能从 stable 被降级
    2. 其他 stable 超出 CORE_LIMIT 时按字母序靠后的先降级
    3. peripheral 超出 PERIPHERAL_LIMIT 时按字母序靠后的先降级
    """
    # 必须保证 MUST_CORE 不被降级
    if len(layers["stable"]) > CORE_LIMIT:
        must_in_core = [s for s in layers["stable"] if s in MUST_CORE]
        others = [s for s in layers["stable"] if s not in MUST_CORE]
        # 排序后从尾部开始截断
        others_sorted = sorted(others)
        overflow_count = len(layers["stable"]) - CORE_LIMIT
        overflow = others_sorted[-overflow_count:] if overflow_count > 0 else []
        for slug in overflow:
            layers["stable"].remove(slug)
            layers["peripheral"].append(slug)
    if len(layers["peripheral"]) > PERIPHERAL_LIMIT:
        overflow_count = len(layers["peripheral"]) - PERIPHERAL_LIMIT
        overflow = sorted(layers["peripheral"])[-overflow_count:] if overflow_count > 0 else []
        for slug in overflow:
            layers["peripheral"].remove(slug)
            layers["archived"].append(slug)
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

    apply_caps(layers)

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
