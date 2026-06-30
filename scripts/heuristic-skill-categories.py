#!/usr/bin/env python3
# ============================================================
#  heuristic-skill-categories.py
#  为无 _meta.json 的 skill 自动创建 _meta.json
#  基于 SKILL.md frontmatter 的 description 关键词启发式分类
#
#  用法：python scripts/heuristic-skill-categories.py
# ============================================================
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / "skills"

# slug -> (category, domain) 启发式规则
# 优先级：从上到下匹配关键词
HEURISTIC = [
    # novel 域
    (r"novel|story|fiction|chapter|小说|网文|连载|短剧|drama", "novel.creation", "novel"),
    (r"humaniz|去ai|文风|人写感", "novel.polish", "novel"),
    (r"fanqie|番茄|publish|发布|publication|平台", "novel.publish", "novel"),
    (r"writing|article|content|brand|seo|文案|营销", "shared.docs", "shared"),

    # news 域
    (r"news|journal|新闻|fact.?check|事实核查", "news.creation", "news"),

    # code 域
    (r"architecture|pattern|design.?system|api.?design|架构|ddd|hexagonal|clean|整洁", "code.architecture", "code"),
    (r"review|code.?review|simplify|quality", "code.review", "code"),
    (r"test|tdd|e2e|spec|verify|verification|benchmark|验证", "code.testing", "code"),
    (r"debug|systematic|bug|问题|故障", "code.debug", "code"),
    (r"security|secure|auth|owasp|vulnerab|合规|hipaa|compliance", "code.security", "code"),
    (r"standard|norm|spec|coding.?rules|编码规范", "code.standards", "code"),
    (r"javascript|typescript|node|react|vue|angular|next|nestjs|nuxt|vite|frontend|web.?dev", "code.languages", "code"),
    (r"python|django|fastapi|pytorch|mle|ml|生成python|installer", "code.languages", "code"),
    (r"java|spring|kotlin|quarkus|jpa|hibernate", "code.languages", "code"),
    (r"golang|rust|swift|flutter|dart|android|ios|perl|php|laravel|cpp|c#|dotnet|f#", "code.languages", "code"),
    (r"ui.?ux|figma|design|界面|交互|动效|动画|frontend.?design|无障碍|accessibility", "code.frontend", "code"),
    (r"mysql|postgres|sql|database|cache|redis|mongo|clickhouse|数据", "code.database", "code"),
    (r"docker|kubernetes|k8s|deploy|network|nginx|cisco|homelab|pihole|wireguard|vlan|netmiko|bgp|ci.?cd|canary", "code.ops", "code"),
    (r"agent|mcp|prompt|llm|model|recommend|recsys|prediction|social.?graph|ml.?eval|eval", "code.ai-agent", "code"),
    (r"git|workflow|commit|工具|tool|cli|命令行", "code.tooling", "code"),

    # shared 域
    (r"brainstorm|plan|spec|规划|设计|构思", "shared.planning", "shared"),
    (r"memory|context|token.?budget|记忆|上下文", "shared.memory", "shared"),
    (r"pdf|word|excel|docx|xlsx|文档|办公", "shared.docs", "shared"),
    (r"tts|voice|video|image|audio|媒体|语音|视频|视觉|figma|manim|remotion|blender|fal", "shared.media", "shared"),
    (r"search|research|deep.?research|exa|检索|搜索|文献", "shared.research", "shared"),
    (r"browser|playwright|playwright.?mcp|web.?scrap|web.?tool|网页", "shared.workflow", "shared"),
    (r"skill|find.?skill|vet.?skill|stocktake|scout|comply", "shared.workflow", "shared"),
    (r"self.?improve|self.?learn|self.?eval|continuous|自我", "code.ai-agent", "code"),
    (r"summarize|内容摘要|摘要", "shared.workflow", "shared"),
    (r"auto.?update|update.?skill|skill.?update", "shared.workflow", "shared"),
    (r"ops|email|message|notification|github.?ops|jira|google.?workspace", "code.ops", "code"),

    # 商业
    (r"finance|billing|invoice|财务|账单|cost.?track|订阅", "biz.finance", "biz"),
    (r"logistic|inventory|supply|warehouse|carrier|质量|生产|调度|物流|退货", "biz.operations", "biz"),
    (r"market|investor|sales|lead|marketing|营销|销售|客户|投资者|线索|品牌", "biz.operations", "biz"),
    (r"custom|trade|合规|合规|policy", "biz.operations", "biz"),
    (r"health|medical|emr|phi|cdss|医疗|临床", "biz.operations", "biz"),
    (r"energy|procurement|能源|采购", "biz.operations", "biz"),
    (r"scientific|pubmed|uspto|scholar|科研|科学|literature", "science.research", "science"),
    (r"crypto|defi|evm|web3|区块链|加密|token|keccak|prediction.?market", "crypto.web3", "crypto"),
]


def extract_description(text: str) -> str:
    """从 SKILL.md 提取 frontmatter description（支持单行 + YAML 多行）"""
    m = re.search(r"^---\s*\n(.*?)\n---", text, re.DOTALL | re.MULTILINE)
    if not m:
        return ""
    fm = m.group(1)
    # 单行
    m2 = re.search(r"^description:\s*(.+)$", fm, re.MULTILINE)
    if m2:
        line = m2.group(1).strip()
        if line.startswith("|") or line.startswith(">"):
            # 多行块：取后续缩进行
            lines = []
            for l in fm[m2.end():].splitlines():
                if re.match(r"^\s+\S", l):
                    lines.append(l.strip())
                elif l.strip() == "":
                    continue
                else:
                    break
            return " ".join(lines)
        return line.strip('"\' ')
    return ""


def classify(slug: str, desc: str) -> tuple:
    """启发式分类"""
    text = f"{slug} {desc}".lower()
    for pattern, cat_id, domain in HEURISTIC:
        if re.search(pattern, text, re.IGNORECASE):
            return cat_id, domain
    # 兜底
    return "shared.workflow", "shared"


def main():
    updated = 0
    skipped = 0
    no_skill = 0

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        slug = skill_dir.name
        meta_file = skill_dir / "_meta.json"
        skill_file = skill_dir / "SKILL.md"

        if meta_file.exists():
            skipped += 1
            continue
        if not skill_file.exists():
            no_skill += 1
            continue

        text = skill_file.read_text(encoding="utf-8")
        desc = extract_description(text)
        cat_id, domain = classify(slug, desc)

        data = {
            "slug": slug,
            "category": cat_id,
            "domain": domain,
            "tags": [],
            "auto_classified": True,
            "purpose": desc[:200] if desc else ""
        }
        meta_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8"
        )
        print(f"  ✓ {slug} → {cat_id} ({domain})")
        updated += 1

    print()
    print(f"✅ 完成")
    print(f"  - 启发式新建: {updated}")
    print(f"  - 已有 _meta.json 跳过: {skipped}")
    print(f"  - 无 SKILL.md: {no_skill}")


if __name__ == "__main__":
    main()
