#!/usr/bin/env python3
# ============================================================
#  gen-skill-graph.py
#  一次性扫描所有 skills/*/_meta.json
#  生成 docs/skill-dependency-graph.md（Mermaid 图）
# ============================================================
import json
import sys
from pathlib import Path
from datetime import date

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"
OUT_FILE = ROOT / "docs" / "skill-dependency-graph.md"

MODE = "write"
if len(sys.argv) > 1 and sys.argv[1] == "--check":
    MODE = "check"


def main():
    rows = []  # (slug, domain, requires, complements, conflicts)
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        meta = skill_dir / "_meta.json"
        if not meta.exists():
            continue
        try:
            data = json.loads(meta.read_text(encoding="utf-8"))
        except Exception:
            continue
        slug = data.get("slug", skill_dir.name)
        rows.append((
            slug,
            data.get("domain", "shared"),
            data.get("requires", []) or [],
            data.get("complements", []) or [],
            data.get("conflicts", []) or [],
        ))

    # 统计
    cnt_requires = sum(1 for r in rows if r[2])
    cnt_complements = sum(1 for r in rows if r[3])
    cnt_conflicts = sum(1 for r in rows if r[4])

    today = date.today().isoformat()
    lines = [
        "# Skill 依赖图谱",
        "",
        f"> 自动生成的 Skill 关系图（Mermaid）。基于 `_meta.json` 中的 `requires / conflicts / complements` 字段。",
        f"> 最后更新：{today}",
        "> 生成方式：`bash scripts/gen-skill-graph.sh`",
        "",
        "## 图例",
        "",
        "| 关系 | 含义 | Mermaid 语法 |",
        "|------|------|--------------|",
        "| `requires` | 强依赖 | `A --> B` |",
        "| `complements` | 互补 | `A -.-> B` |",
        "| `conflicts` | 互斥 | `A ==x B` |",
        "",
        "## 全局依赖图",
        "",
        "```mermaid",
        "flowchart LR",
    ]

    for slug, _, reqs, comps, confs in rows:
        for r in reqs:
            lines.append(f"  {slug}[{slug}] --> {r}[{r}]")
        for c in comps:
            lines.append(f"  {slug}[{slug}] -. complements .-> {c}[{c}]")
        for x in confs:
            lines.append(f"  {slug}[{slug}] ==x {x}[{x}]")
    lines.append("```")
    lines.append("")

    lines.append("## 按域分组")
    lines.append("")

    for domain in ("code", "novel", "news", "shared", "biz", "science", "crypto"):
        dom_rows = [r for r in rows if r[1] == domain]
        if not dom_rows:
            continue
        lines.append(f"### {domain} 域")
        lines.append("")
        lines.append("```mermaid")
        lines.append("flowchart LR")
        for slug, _, reqs, comps, confs in dom_rows:
            for r in reqs:
                if r in {x[0] for x in rows}:
                    lines.append(f"  {slug}[{slug}] --> {r}[{r}]")
            for c in comps:
                if c in {x[0] for x in rows}:
                    lines.append(f"  {slug}[{slug}] -. complements .-> {c}[{c}]")
            for x in confs:
                if x in {x[0] for x in rows}:
                    lines.append(f"  {slug}[{slug}] ==x {x}[{x}]")
        lines.append("```")
        lines.append("")

    lines.extend([
        "## 添加新依赖",
        "",
        "在 `skills/<slug>/_meta.json` 中声明：",
        "",
        "```json",
        "{",
        '  "slug": "my-skill",',
        '  "requires": ["other-skill-1", "other-skill-2"],',
        '  "complements": ["another-skill"],',
        '  "conflicts": ["rival-skill"]',
        "}",
        "```",
        "",
        "然后重新跑：",
        "",
        "```bash",
        "bash scripts/gen-skill-graph.sh",
        "```",
        "",
        "## 维护说明",
        "",
        "- 所有字段均为**可选**",
        "- `requires`：本 skill 的核心流程**必须**先加载该 skill",
        "- `complements`：建议**同时**加载以获得完整体验",
        "- `conflicts`：与本 skill 同时加载会**互相覆盖意图路由或资源**",
    ])

    content = "\n".join(lines) + "\n"

    if MODE == "check":
        if not OUT_FILE.exists():
            print("❌ skill-dependency-graph.md 不存在")
            sys.exit(1)
        if OUT_FILE.read_text(encoding="utf-8") != content:
            print("❌ skill-dependency-graph.md 与脚本生成内容不一致")
            print("   请运行：bash scripts/gen-skill-graph.sh")
            sys.exit(1)
        print("✅ skill-dependency-graph.md 是最新的")
        return

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(content, encoding="utf-8")
    print(f"✅ skill-dependency-graph.md 已生成")
    print(f"  - requires: {cnt_requires} 个")
    print(f"  - complements: {cnt_complements} 个")
    print(f"  - conflicts: {cnt_conflicts} 个")
    if cnt_requires == 0 and cnt_complements == 0 and cnt_conflicts == 0:
        print()
        print("ℹ️  当前没有任何 skill 声明依赖关系。")
        print("   在 _meta.json 中加 requires / complements / conflicts 字段后重跑。")


if __name__ == "__main__":
    main()
