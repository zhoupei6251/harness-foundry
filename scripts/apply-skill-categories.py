#!/usr/bin/env python3
# ============================================================
#  apply-skill-categories.py
#  批量为 skills/*/_meta.json 补 category / domain / tags 字段
#  （已存在的字段不会被覆盖）
#
#  用法：python3 scripts/apply-skill-categories.py
# ============================================================
import json
import os
import sys
from pathlib import Path

# 添加 scripts 目录到路径，以便导入共享模块
sys.path.insert(0, str(Path(__file__).resolve().parent))

from _skill_meta import SKILL_META as META

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"


def load_or_init(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        text = path.read_text(encoding="utf-8")
        return json.loads(text)
    except json.JSONDecodeError:
        print(f"  [warn] {path.name} 现有 JSON 损坏，尝试自动修复", file=sys.stderr)
        # 尝试简单修复：移除最后一行最后一个逗号
        fixed = text.rstrip()
        if fixed.endswith(","):
            fixed = fixed[:-1]
        try:
            return json.loads(fixed)
        except Exception:
            print(f"  [error] {path.name} 无法修复，跳过", file=sys.stderr)
            return {}


def main():
    updated = 0
    skipped = 0
    no_meta = 0

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        slug = skill_dir.name
        meta_file = skill_dir / "_meta.json"

        if not meta_file.exists():
            no_meta += 1
            continue

        if slug not in META:
            skipped += 1
            continue

        cat_id, domain, tags = META[slug]
        data = load_or_init(meta_file)
        if not data:
            continue

        changed = False
        if data.get("category") != cat_id:
            data["category"] = cat_id
            changed = True
        if data.get("domain") != domain:
            data["domain"] = domain
            changed = True
        if data.get("tags") != tags:
            data["tags"] = tags
            changed = True

        if not changed:
            print(f"  [no-change] {slug}")
            continue

        # 写回（带缩进 2）
        meta_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8"
        )
        print(f"  ✓ {slug} → {cat_id}")
        updated += 1

    print()
    print(f"✅ 完成")
    print(f"  - 已更新: {updated}")
    print(f"  - 跳过 (无映射): {skipped}")
    print(f"  - 无 _meta.json: {no_meta}")
    print()
    print("下一步：bash scripts/gen-skill-index.sh 重新生成 INDEX.md")


if __name__ == "__main__":
    main()
