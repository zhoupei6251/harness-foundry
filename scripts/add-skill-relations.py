#!/usr/bin/env python3
"""
为几个核心 skill 添加 requires / complements 字段
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"

# slug -> (requires[], complements[], conflicts[])
RELATIONS = {
    "brainstorming": {
        "requires": ["writing-plans"],
        "complements": ["planning-with-files", "project-planner"]
    },
    "writing-plans": {
        "requires": ["brainstorming"],
        "complements": ["executing-plans", "planning-with-files"]
    },
    "executing-plans": {
        "requires": ["writing-plans"],
        "complements": ["subagent-driven-development"]
    },
    "planning-with-files": {
        "complements": ["brainstorming", "project-planner"]
    },
    "project-planner": {
        "complements": ["brainstorming", "planning-with-files"]
    },
    "dispatching-parallel-agents": {
        "requires": ["subagent-driven-development"],
        "complements": ["cursor-orchestration"]
    },
    "subagent-driven-development": {
        "complements": ["dispatching-parallel-agents", "executing-plans"]
    },
    "refactor-safely": {
        "requires": ["test-driven-development"],
        "complements": ["code-review", "simplify"]
    },
    "code-review": {
        "complements": ["refactor-safely", "requesting-code-review"]
    },
    "requesting-code-review": {
        "complements": ["code-review", "verification-before-completion"]
    },
    "verification-before-completion": {
        "complements": ["test-driven-development"]
    },
    "security-auditor": {
        "complements": ["code-review"]
    },
    "ui-ux-pro-max": {
        "conflicts": ["frontend-design-direction"],
        "complements": ["superdesign"]
    },
    "novel-orchestrator": {
        "complements": ["junli-ai-novel", "novel-evaluator", "humanizer"]
    },
    "novel-generator": {
        "complements": ["novel-orchestrator", "junli-ai-novel"]
    },
    "inkos": {
        "complements": ["novel-orchestrator"]
    },
    "humanizer": {
        "complements": ["humanizer-zh"]
    },
    "fanqie-novel-auto-publish": {
        "requires": ["fanqie"],
        "complements": ["web-novel-publishing-readiness-and-quality-check-skill"]
    },
    "playwright": {
        "complements": ["agent-browser"]
    },
    "find-skills": {
        "complements": ["skill-vetter", "skill-stocktake"]
    },
    "skill-vetter": {
        "complements": ["find-skills", "skill-comply"]
    },
}


def main():
    updated = 0
    for slug, rels in RELATIONS.items():
        meta_file = SKILLS_DIR / slug / "_meta.json"
        if not meta_file.exists():
            print(f"  [skip] {slug} - _meta.json missing")
            continue

        data = json.loads(meta_file.read_text(encoding="utf-8"))
        changed = False
        for field in ("requires", "complements", "conflicts"):
            if rels.get(field):
                if data.get(field) != rels[field]:
                    data[field] = rels[field]
                    changed = True

        if not changed:
            print(f"  [no-change] {slug}")
            continue

        meta_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8"
        )
        print(f"  ✓ {slug} → {', '.join(k for k in rels if rels[k])}")
        updated += 1

    print()
    print(f"✅ 完成，已更新 {updated} 个 skill")


if __name__ == "__main__":
    main()
