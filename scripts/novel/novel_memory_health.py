#!/usr/bin/env python3
"""
novel-memory-health — 长篇写作记忆健康度检查

防止长篇小说写作中的"记忆丢失"问题：
- 角色遗忘（超过N章未出场的主要角色）
- 伏笔逾期（埋设后超过N章未回收）
- 设定遗忘（世界观/能力/地名等设定在后期被忽略）
- 章节摘要缺失

用法：
    python novel_memory_health.py <书籍目录>         # 常规检查
    python novel_memory_health.py <书籍目录> --json  # JSON输出
    python novel_memory_health.py <书籍目录> --alert # 告警模式（只输出问题）
"""

import re
import json
import argparse
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass, field


@dataclass
class Character:
    """角色"""
    name: str
    first_appearance: int = 0  # 首次出场章节
    last_appearance: int = 0   # 最近出场章节
    status: str = "alive"      # alive | dead | unknown
    importance: str = "supporting"  # main | supporting | minor
    notes: str = ""


@dataclass
class Foreshadowing:
    """伏笔"""
    id: str
    description: str = ""
    planted_chapter: int = 0
    target_chapter: int = 0  # 预计回收章节
    resolved_chapter: int = 0  # 实际回收章节
    status: str = "buried"  # buried | triggered | resolved | dropped


@dataclass
class MemoryHealth:
    """记忆健康度"""
    book_name: str = ""
    total_chapters: int = 0
    total_words: int = 0
    characters: List[Character] = field(default_factory=list)
    foreshadows: List[Foreshadowing] = field(default_factory=list)
    issues: List[Dict] = field(default_factory=list)

    @property
    def health_score(self) -> int:
        """健康度评分（0-100）"""
        score = 100

        # 沉默角色（>5章未出场）扣分
        for ch in self.characters:
            if ch.importance in ("main", "supporting"):
                gap = self.total_chapters - ch.last_appearance
                if gap > 10:
                    score -= 10
                elif gap > 5:
                    score -= 5

        # 逾期伏笔（>5章未回收）扣分
        for fs in self.foreshadows:
            if fs.status == "buried":
                gap = self.total_chapters - fs.planted_chapter
                if gap > 10:
                    score -= 10
                elif gap > 5:
                    score -= 5

        return max(0, min(100, score))

    @property
    def health_level(self) -> str:
        """健康等级"""
        if self.health_score >= 80:
            return "🟢 健康"
        elif self.health_score >= 60:
            return "🟡 关注"
        elif self.health_score >= 40:
            return "🟠 警告"
        else:
            return "🔴 危险"


def count_words(text: str) -> int:
    """统计字数"""
    chinese = len(re.findall(r'[一-鿿]', text))
    return chinese


def parse_chapter_file(file_path: Path) -> Optional[Dict]:
    """解析章节文件"""
    try:
        content = file_path.read_text(encoding="utf-8")
    except:
        return None

    name = file_path.stem
    match = re.match(r'第(\d+)章[_：](.+)', name)
    if not match:
        return None

    return {
        "num": int(match.group(1)),
        "title": match.group(2),
        "content": content,
        "word_count": count_words(content)
    }


def scan_book(book_dir: Path) -> MemoryHealth:
    """扫描书籍并分析记忆健康度"""
    health = MemoryHealth(book_name=book_dir.name)

    # 扫描章节
    chapters = []
    for pattern in ["第*章*.md", "章节正文/第*章*.md"]:
        for file_path in sorted(book_dir.glob(pattern)):
            ch = parse_chapter_file(file_path)
            if ch:
                chapters.append(ch)

    chapters.sort(key=lambda x: x["num"])
    health.total_chapters = len(chapters)
    health.total_words = sum(c["word_count"] for c in chapters)

    # 读取 MEMORY.md 解析角色和伏笔
    memory_paths = [book_dir / "MEMORY.md", book_dir / "记忆.md"]
    memory_content = ""
    for mp in memory_paths:
        if mp.exists():
            memory_content = mp.read_text(encoding="utf-8")
            break

    if memory_content:
        health.characters = parse_characters_from_memory(memory_content, chapters)
        health.foreshadows = parse_foreshadows_from_memory(memory_content)

    # 分析问题
    health.issues = analyze_issues(health, chapters)

    return health


def parse_characters_from_memory(memory_content: str, chapters: list) -> List[Character]:
    """从 MEMORY.md 解析角色"""
    characters = []

    # 尝试解析角色表格
    in_character_section = False
    for line in memory_content.split('\n'):
        if '人物设定' in line or '角色' in line or '### 主角' in line or '### 配角' in line or '### 反派' in line:
            in_character_section = True
            continue

        if in_character_section and line.startswith('## '):
            in_character_section = False
            continue

        if in_character_section:
            # 解析角色名
            name_match = re.search(r'[：:]?\s*(.{1,8})\s*$', line)
            if not name_match and '###' not in line:
                continue

            # 从章节内容中检测角色出场
            name = ""
            if '### 主角' in line:
                name = re.search(r'### 主角[：:]\s*(.+)', line)
                if name:
                    characters.append(Character(
                        name=name.group(1).strip(),
                        importance="main"
                    ))
            elif '### 配角' in line:
                name = re.search(r'### 配角[：:]\s*(.+)', line)
                if name:
                    characters.append(Character(
                        name=name.group(1).strip(),
                        importance="supporting"
                    ))
            elif '### 反派' in line:
                name = re.search(r'### 反派[：:]\s*(.+)', line)
                if name:
                    characters.append(Character(
                        name=name.group(1).strip(),
                        importance="supporting"
                    ))

    # 检测每个角色的出场情况
    for ch in characters:
        for ch_data in chapters:
            if ch.name in ch_data.get("content", ""):
                if ch.first_appearance == 0 or ch_data["num"] < ch.first_appearance:
                    ch.first_appearance = ch_data["num"]
                if ch_data["num"] > ch.last_appearance:
                    ch.last_appearance = ch_data["num"]

    return characters


def parse_foreshadows_from_memory(memory_content: str) -> List[Foreshadowing]:
    """从 MEMORY.md 解析伏笔"""
    foreshadows = []

    # 解析伏笔表格
    in_fs_section = False
    for line in memory_content.split('\n'):
        if '伏笔' in line and '|' in line:
            in_fs_section = True
            continue

        if in_fs_section:
            if not line.strip() or not '|' in line:
                if '## ' in line:
                    in_fs_section = False
                continue

            parts = [p.strip() for p in line.split('|') if p.strip()]
            if len(parts) >= 2 and 'FP' in parts[0]:
                fs = Foreshadowing(id=parts[0])
                if len(parts) >= 2:
                    fs.description = parts[1]
                if len(parts) >= 6:
                    # 格式: ID | 内容 | 埋设章节 | 状态 | 回收章节
                    try:
                        fs.planted_chapter = int(re.search(r'(\d+)', parts[2]).group(1)) if re.search(r'(\d+)', parts[2]) else 0
                        fs.status = parts[3].strip() if parts[3].strip() in ('buried', 'triggered', 'resolved', 'dropped') else 'buried'
                        resolved_match = re.search(r'(\d+)', parts[4]) if len(parts) > 4 else None
                        fs.resolved_chapter = int(resolved_match.group(1)) if resolved_match else 0
                    except:
                        pass

                foreshadows.append(fs)

    return foreshadows


def analyze_issues(health: MemoryHealth, chapters: list) -> List[Dict]:
    """分析记忆问题"""
    issues = []

    # 1. 沉默角色检查
    for ch in health.characters:
        if ch.importance in ("main", "supporting"):
            gap = health.total_chapters - ch.last_appearance
            if gap > 5:
                issues.append({
                    "type": "SILENT_CHARACTER",
                    "severity": "WARNING" if gap > 10 else "INFO",
                    "detail": f"角色「{ch.name}」已 {gap} 章未出场（最近出场：第{ch.last_appearance}章）",
                    "suggestion": "考虑安排角色重新出场或标记为暂离"
                })

    # 2. 逾期伏笔
    for fs in health.foreshadows:
        if fs.status == "buried":
            gap = health.total_chapters - fs.planted_chapter
            if gap > 5:
                issues.append({
                    "type": "OVERDUE_FORESHADOW",
                    "severity": "WARNING",
                    "detail": f"伏笔 {fs.id}「{fs.description}」已 {gap} 章未回收（第{fs.planted_chapter}章埋设）",
                    "suggestion": f"计划在后续2-3章内回收，或标记为dropped"
                })

    # 3. 章节摘要缺失
    if health.total_chapters > 3:
        has_summary = False
        for mp in [Path("MEMORY.md"), Path("记忆.md")]:
            if mp.exists() and "上章摘要" in mp.read_text(encoding="utf-8"):
                has_summary = True
                break

        if not has_summary:
            issues.append({
                "type": "MISSING_SUMMARIES",
                "severity": "INFO",
                "detail": "MEMORY.md 中缺少章节摘要",
                "suggestion": "在 MEMORY.md 中添加「上章摘要」部分"
            })

    # 4. 设定完整性
    if health.total_chapters > 5:
        issues.append({
            "type": "SETTING_CHECK",
            "severity": "INFO",
            "detail": "建议每5章运行一次完整的 Guardian 核查",
            "suggestion": "运行 python scripts/novel/novel_memory_health.py --full-check"
        })

    return issues


def print_report(health: MemoryHealth):
    """打印记忆健康度报告"""
    print(f"""
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🧠 {health.book_name} 记忆健康度报告              ║
╠══════════════════════════════════════════════════════════════════════════════╣

📊 基础信息
┌──────────────────────────────────────────────────────────────────────────────┐
│ 总分: {health.health_score}/100 — {health.health_level}                            │
│ 章节: {health.total_chapters}章 | 字数: {health.total_words:,}字                   │
│ 角色: {len(health.characters)}个 | 伏笔: {len(health.foreshadows)}个                     │
└──────────────────────────────────────────────────────────────────────────────┘
""")

    # 角色表
    if health.characters:
        print("👤 角色状态")
        print("┌──────────┬────────┬────────┬────────┬────────┬────────┐")
        print("│ 角色     │ 重要度 │ 初登场 │ 最近   │ 沉默   │ 状态   │")
        print("├──────────┼────────┼────────┼────────┼────────┼────────┤")
        for ch in health.characters:
            gap = health.total_chapters - ch.last_appearance
            gap_str = f"{gap}章" if gap > 0 else "活跃"
            status = "🟢" if gap <= 3 else ("🟡" if gap <= 5 else "🔴")
            print(f"│ {ch.name:8s} │ {ch.importance:6s} │ 第{ch.first_appearance:2d}章 │ 第{ch.last_appearance:2d}章 │ {gap_str:6s} │ {status:6s} │")
        print("└──────────┴────────┴────────┴────────┴────────┴────────┘")

    # 伏笔表
    if health.foreshadows:
        print(f"""
🎯 伏笔状态
┌──────────┬──────────────────────────────┬────────────┬──────────┬──────────┐
│ ID       │ 内容                               │ 埋设 │ 状态     │ 逾期   │
├──────────┼──────────────────────────────┼────────────┼──────────┼──────────┤""")
        for fs in health.foreshadows:
            gap = health.total_chapters - fs.planted_chapter
            overdue = f"{gap}章" if fs.status == "buried" and gap > 5 else "正常"
            desc = fs.description[:26] if fs.description else "-"
            print(f"│ {fs.id:8s} │ {desc:28s} │ 第{fs.planted_chapter:2d}章   │ {fs.status:8s} │ {overdue:8s} │")
        print("└──────────┴──────────────────────────────┴────────────┴──────────┴──────────┘")

    # 问题清单
    if health.issues:
        print(f"""
⚠️  发现问题 ({len(health.issues)}处)
""")
        for i, issue in enumerate(health.issues, 1):
            icon = {"WARNING": "🟡", "INFO": "🔵", "CRITICAL": "🔴"}.get(issue["severity"], "🔵")
            print(f"   {icon} [{issue['severity']}] {issue['detail']}")
            print(f"      💡 {issue['suggestion']}")
            print()

    if not health.issues:
        print("\n✅ 未发现问题 — 记忆状态健康")

    print("╚══════════════════════════════════════════════════════════════════════════════╝")


def main():
    parser = argparse.ArgumentParser(description="novel-memory-health — 长篇写作记忆健康度检查")
    parser.add_argument("book_dir", help="书籍目录")
    parser.add_argument("--json", "-j", action="store_true", help="JSON 输出")
    parser.add_argument("--alert", "-a", action="store_true", help="告警模式（只输出问题）")
    args = parser.parse_args()

    book_dir = Path(args.book_dir)
    if not book_dir.exists():
        print(f"❌ 目录不存在: {book_dir}")
        return

    # 扫描书籍
    health = scan_book(book_dir)

    # 输出
    if args.json:
        output = {
            "book_name": health.book_name,
            "total_chapters": health.total_chapters,
            "total_words": health.total_words,
            "health_score": health.health_score,
            "health_level": health.health_level,
            "characters": [
                {
                    "name": c.name,
                    "importance": c.importance,
                    "first_appearance": c.first_appearance,
                    "last_appearance": c.last_appearance,
                    "silent_chapters": health.total_chapters - c.last_appearance
                }
                for c in health.characters
            ],
            "foreshadows": [
                {
                    "id": f.id,
                    "description": f.description,
                    "planted_chapter": f.planted_chapter,
                    "status": f.status,
                    "overdue_chapters": health.total_chapters - f.planted_chapter
                }
                for f in health.foreshadows
            ],
            "issues": health.issues
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    elif args.alert:
        if health.issues:
            for issue in health.issues:
                if issue["severity"] in ("WARNING", "CRITICAL"):
                    print(f"[{issue['severity']}] {issue['detail']}")
        else:
            print("✅ 无告警")
    else:
        print_report(health)


if __name__ == "__main__":
    main()
