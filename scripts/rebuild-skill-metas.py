#!/usr/bin/env python3
# ============================================================
#  rebuild-skill-metas.py
#  重写所有 skills/*/_meta.json 为标准格式（slug + category + domain + tags）
#  保留原文件的 source / source_version / purpose / cherry_picked / integration_layer 字段
#  丢弃原文件的 ownerId / version / publishedAt（这些是平台字段，不影响 skill 索引）
#
#  用法：python scripts/rebuild-skill-metas.py
# ============================================================
import json
import re
import sys
from pathlib import Path

# 添加 scripts 目录到路径，以便导入共享模块
sys.path.insert(0, str(Path(__file__).resolve().parent))

from _skill_meta import SKILL_META as META

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"

# 保留字段（如果原文件有）
KEEP_FIELDS = [
    "purpose", "source", "source_version", "source_path",
    "cherry_picked", "integration_layer", "skip_from_sync", "compatibility"
]

# 用启发式正则从损坏的 JSON 中抢救关键字段
FIELD_REGEX = {
    "purpose": re.compile(r'"purpose"\s*:\s*"([^"]*)"'),
    "source": re.compile(r'"source"\s*:\s*"([^"]*)"'),
    "source_version": re.compile(r'"source_version"\s*:\s*"([^"]*)"'),
    "source_path": re.compile(r'"source_path"\s*:\s*"([^"]*)"'),
    "cherry_picked": re.compile(r'"cherry_picked"\s*:\s*(true|false)'),
    "integration_layer": re.compile(r'"integration_layer"\s*:\s*"([^"]*)"'),
    "skip_from_sync": re.compile(r'"skip_from_sync"\s*:\s*(true|false)'),
    "compatibility": re.compile(r'"compatibility"\s*:\s*"([^"]*)"'),
}


def salvage_fields(text: str) -> dict:
    """从损坏的 JSON 文本中抢救关键字段"""
    out = {}
    for field, regex in FIELD_REGEX.items():
        m = regex.search(text)
        if m:
            val = m.group(1)
            if field in ("cherry_picked", "skip_from_sync"):
                out[field] = val == "true"
            else:
                out[field] = val
    return out


def rebuild(slug: str, cat_id: str, domain: str, tags: list) -> dict:
    data = {
        "slug": slug,
        "category": cat_id,
        "domain": domain,
        "tags": tags,
    }
    # 抢救原文件字段
    meta_file = SKILLS_DIR / slug / "_meta.json"
    if meta_file.exists():
        text = meta_file.read_text(encoding="utf-8")
        salvaged = salvage_fields(text)
        for k, v in salvaged.items():
            if k in KEEP_FIELDS and k not in data:
                data[k] = v
    return data


def main():
    updated = 0
    skipped = 0

    for slug, (cat_id, domain, tags) in META.items():
        meta_file = SKILLS_DIR / slug / "_meta.json"
        if not meta_file.parent.exists():
            print(f"  [skip-dir-missing] {slug}")
            skipped += 1
            continue

        data = rebuild(slug, cat_id, domain, tags)
        meta_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8"
        )
        print(f"  ✓ {slug} → {cat_id}")
        updated += 1

    print()
    print(f"✅ 完成")
    print(f"  - 已重建: {updated}")
    print(f"  - 跳过: {skipped}")


if __name__ == "__main__":
    main()
