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
    """补全单个 Skill 的 frontmatter，返回是否变更

    Wave 5 强化：
    - name 强制等于目录名（覆盖任何不一致值）
    - description 强制 ≤200 字符
    - version 强制 semver（X.Y.Z）
    - tags 强制非空数组
    - status 强制 enum
    """
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

    # 强制 name == slug（覆盖第三方不一致值）
    if fm.get("name") != skill_dir.name:
        fm["name"] = skill_dir.name
        changed = True

    # 强制 description ≤200 字符（覆盖任何超长值）
    desc = fm.get("description") or first_para[:200].strip() or f"Skill for {skill_dir.name}"
    desc = str(desc).replace("\n", " ").strip()
    if len(desc) > 200:
        desc = desc[:197] + "..."
    if fm.get("description") != desc:
        fm["description"] = desc
        changed = True

    # 强制 version 是 semver（X.Y.Z）
    ver = fm.get("version") or meta.get("version") or "1.0.0"
    ver = str(ver).strip()
    import re as _re
    if not _re.match(r"^\d+\.\d+\.\d+$", ver):
        # 提取主要数字，转换为 semver
        m = _re.search(r"(\d+)\.(\d+)(?:\.(\d+))?", ver)
        if m:
            major = m.group(1)
            minor = m.group(2)
            patch = m.group(3) or "0"
            ver = f"{major}.{minor}.{patch}"
        else:
            ver = "1.0.0"
    if fm.get("version") != ver:
        fm["version"] = ver
        changed = True

    # 强制 when_to_use 存在
    wtu = fm.get("when_to_use") or f"调用 {skill_dir.name} 时"
    wtu = str(wtu)
    if len(wtu) > 300:
        wtu = wtu[:297] + "..."
    if fm.get("when_to_use") != wtu:
        fm["when_to_use"] = wtu
        changed = True

    # 强制 status 是 enum
    valid_status = {"stable", "peripheral", "archived", "experimental"}
    cur_status = fm.get("status") or meta.get("status") or "peripheral"
    if cur_status not in valid_status:
        cur_status = "peripheral"
    if fm.get("status") != cur_status:
        fm["status"] = cur_status
        changed = True

    # 强制 tags 是非空数组
    tags = fm.get("tags") or meta.get("tags") or []
    if not isinstance(tags, list) or not tags:
        tags = [infer_domain(first_para or skill_dir.name)]
    # 过滤非字符串
    tags = [str(t) for t in tags if t]
    if not tags:
        tags = ["shared"]
    if fm.get("tags") != tags:
        fm["tags"] = tags
        changed = True

    # 强制 domain 存在
    domain = fm.get("domain") or meta.get("domain") or infer_domain(first_para or skill_dir.name)
    if fm.get("domain") != domain:
        fm["domain"] = domain
        changed = True

    # 强制 category 存在
    category = fm.get("category") or meta.get("category") or "workflow"
    if fm.get("category") != category:
        fm["category"] = category
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
