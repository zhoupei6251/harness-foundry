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
