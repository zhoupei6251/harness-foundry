#!/usr/bin/env python3
"""
novel-metrics — 写作指标追踪脚本

统计和分析写作进度，提供量化反馈。

用法：
    python novel_metrics.py                          # 显示仪表板
    python novel_metrics.py --book 书名            # 指定书籍
    python novel_metrics.py --report weekly        # 生成周报
    python novel_metrics.py --json                  # JSON输出
"""

import re
import json
import argparse
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Chapter:
    """章节信息"""
    num: int
    title: str
    file_path: str
    word_count: int = 0
    review_score: float = 0.0
    review_status: str = ""  # pending/passed/failed
    rework_count: int = 0
    written_date: str = ""


@dataclass
class BookMetrics:
    """书籍指标"""
    book_name: str
    total_chapters_planned: int = 0
    total_words_planned: int = 0
    chapters: list = field(default_factory=list)
    scores: list = field(default_factory=list)
    rework_counts: list = field(default_factory=list)

    @property
    def completed_chapters(self) -> int:
        return len([c for c in self.chapters if c.word_count > 0])

    @property
    def total_words_written(self) -> int:
        return sum(c.word_count for c in self.chapters)

    @property
    def avg_score(self) -> float:
        scores = [c.review_score for c in self.chapters if c.review_score > 0]
        return sum(scores) / len(scores) if scores else 0.0

    @property
    def first_pass_rate(self) -> float:
        passed = len([c for c in self.chapters if c.rework_count == 0 and c.review_score > 0])
        total = len([c for c in self.chapters if c.review_score > 0])
        return (passed / total * 100) if total > 0 else 0.0

    @property
    def avg_rework_count(self) -> float:
        reviewed = [c.rework_count for c in self.chapters if c.review_score > 0]
        return sum(reviewed) / len(reviewed) if reviewed else 0.0


def count_words(text: str) -> int:
    """统计字数"""
    chinese = len(re.findall(r'[一-鿿]', text))
    english = len(re.findall(r'[a-zA-Z]+', text))
    return chinese + english


def parse_chapter_file(file_path: Path) -> Optional[Chapter]:
    """解析章节文件"""
    try:
        content = file_path.read_text(encoding="utf-8")
    except:
        return None

    # 提取章节号和标题
    name = file_path.stem  # 文件名不含扩展名
    match = re.match(r'第(\d+)章[_：](.+)', name)
    if not match:
        return None

    num = int(match.group(1))
    title = match.group(2)

    chapter = Chapter(
        num=num,
        title=title,
        file_path=str(file_path)
    )

    # 统计字数
    chapter.word_count = count_words(content)

    return chapter


def parse_memory_file(memory_path: Path) -> dict:
    """解析 MEMORY.md"""
    if not memory_path.exists():
        return {}

    content = memory_path.read_text(encoding="utf-8")
    data = {}

    # 提取基本信息
    if match := re.search(r'\| 书名 \| ([^|]+)', content):
        data['book_name'] = match.group(1).strip()

    if match := re.search(r'\| 题材 \| ([^|]+)', content):
        data['genre'] = match.group(1).strip()

    # 提取已完成章节
    chapters = []
    for line in content.split('\n'):
        if '|' in line and '第' in line and '章' in line:
            # 解析章节表格行
            parts = [p.strip() for p in line.split('|')]
            if len(parts) >= 4 and '✓' in parts[2]:
                # 格式: | 章节 | 标题 | 状态 | 字数 |
                num_match = re.search(r'第(\d+)章', parts[1])
                if num_match:
                    chapters.append(int(num_match.group(1)))

    data['completed_chapters'] = chapters
    return data


def scan_book_directory(book_dir: Path) -> BookMetrics:
    """扫描书籍目录"""
    metrics = BookMetrics(book_name=book_dir.name)

    # 扫描章节文件
    chapter_files = sorted(book_dir.glob("第*章*.md"))

    chapters = []
    for f in chapter_files:
        chapter = parse_chapter_file(f)
        if chapter:
            chapters.append(chapter)

    metrics.chapters = sorted(chapters, key=lambda c: c.num)

    # 读取 MEMORY.md
    memory_path = book_dir / "MEMORY.md"
    if memory_path.exists():
        memory_data = parse_memory_file(memory_path)
        metrics.total_chapters_planned = memory_data.get('total_chapters', len(chapters) * 2)
        metrics.total_words_planned = memory_data.get('total_words', metrics.total_chapters_planned * 3000)

    return metrics


def generate_dashboard(metrics: BookMetrics) -> str:
    """生成仪表板输出"""
    progress = metrics.completed_chapters
    total = max(metrics.total_chapters_planned, progress)
    progress_pct = (progress / total * 100) if total > 0 else 0

    word_progress = metrics.total_words_written
    word_total = max(metrics.total_words_planned, word_progress)
    word_pct = (word_progress / word_total * 100) if word_total > 0 else 0

    # 进度条
    bar_len = 30
    filled = int(bar_len * progress_pct / 100)
    progress_bar = '█' * filled + '░' * (bar_len - filled)

    output = f"""
╔════════════════════════════════════════════════════════════════════════╗
║                    📊 《{metrics.book_name}》写作统计                    ║
╠════════════════════════════════════════════════════════════════════════╣

📈 进度
┌────────────────────────────────────────────────────────────────────────┐
│ {progress_bar} │
│ {progress}/{total} 章 完成                                                    │
└────────────────────────────────────────────────────────────────────────┘

📝 字数
┌────────────────────────────────────────────────────────────────────────┐
│ 已写: {word_progress:,} 字 / 预计: {word_total:,} 字 ({word_pct:.1f}%)                    │
└────────────────────────────────────────────────────────────────────────┘

📊 质量
┌────────────────────────────────────────────────────────────────────────┐
│ 平均评分: {metrics.avg_score:.1f}/10                                              │
│ 首次通过率: {metrics.first_pass_rate:.0f}%                                              │
│ 平均返修: {metrics.avg_rework_count:.1f} 次                                             │
└────────────────────────────────────────────────────────────────────────┘

📋 章节详情
┌──────────┬────────────────┬────────┬────────┬─────────┐
│ 章节     │ 标题           │ 字数    │ 评分   │ 状态    │
├──────────┼────────────────┼────────┼────────┼─────────┤"""

    for c in metrics.chapters[:10]:  # 最多显示10章
        status = "✓通过" if c.review_score >= 7 else ("⏳待审" if c.review_score == 0 else "✗返修")
        score_str = f"{c.review_score:.1f}" if c.review_score > 0 else "-"
        title = c.title[:12] if len(c.title) > 12 else c.title
        output += f"""
│ 第{c.num:2d}章    │ {title:12s} │ {c.word_count:6,} │ {score_str:6s} │ {status:6s} │"""

    if len(metrics.chapters) > 10:
        output += f"""
│ ...      │ ({len(metrics.chapters) - 10} 更多章节)       │        │        │         │"""

    output += """
└──────────┴────────────────┴────────┴────────┴─────────┘

╚════════════════════════════════════════════════════════════════════════╝
"""
    return output


def generate_weekly_report(metrics: BookMetrics) -> str:
    """生成周报"""
    now = datetime.now()
    week_ago = now - timedelta(days=7)

    # 本周完成的章节
    recent_chapters = [c for c in metrics.chapters if c.written_date]
    # TODO: 实际应检查日期

    output = f"""# {metrics.book_name} 第{now.strftime('%Y-%W')}周写作报告

## 本周概况
- 完成章节：{metrics.completed_chapters} 章
- 完成字数：{metrics.total_words_written:,} 字
- 审稿通过：{metrics.completed_chapters}/{metrics.completed_chapters}

## 质量趋势
- 平均评分：{metrics.avg_score:.1f}/10
- 首次通过率：{metrics.first_pass_rate:.0f}%
- 平均返修次数：{metrics.avg_rework_count:.1f}

## 下周计划
- 目标：完成第 {metrics.completed_chapters + 1}-{metrics.completed_chapters + 3} 章
- 重点：解决 AI 痕迹问题
- 挑战：伏笔回收节奏

## 问题与改进
1. AI 痕迹：需要加强 humanizer 处理
2. 节奏控制：部分章节节奏过快
3. 钩子设计：结尾悬念需要强化
"""
    return output


def main():
    parser = argparse.ArgumentParser(description="novel-metrics — 写作指标追踪")
    parser.add_argument("--book", "-b", help="书籍目录名")
    parser.add_argument("--path", "-p", help="书籍目录路径")
    parser.add_argument("--report", "-r", choices=["weekly", "monthly"], help="生成报告")
    parser.add_argument("--json", "-j", action="store_true", help="JSON输出")
    args = parser.parse_args()

    # 查找书籍目录
    if args.path:
        book_dir = Path(args.path)
    else:
        # 默认查找 examples/novel-demo 或当前目录
        candidates = [
            Path("examples/novel-demo"),
            Path("章节正文"),
            Path("."),
        ]
        book_dir = None
        for candidate in candidates:
            if candidate.exists() and any(candidate.glob("第*章*.md")):
                book_dir = candidate
                break

        if not book_dir:
            print("❌ 未找到书籍目录，请使用 --path 指定")
            return

    if not book_dir.exists():
        print(f"❌ 目录不存在: {book_dir}")
        return

    # 扫描指标
    metrics = scan_book_directory(book_dir)

    # 输出
    if args.json:
        output = {
            "book_name": metrics.book_name,
            "progress": {
                "completed_chapters": metrics.completed_chapters,
                "total_chapters_planned": metrics.total_chapters_planned,
                "progress_pct": (metrics.completed_chapters / max(metrics.total_chapters_planned, 1)) * 100
            },
            "words": {
                "written": metrics.total_words_written,
                "planned": metrics.total_words_planned,
                "word_pct": (metrics.total_words_written / max(metrics.total_words_planned, 1)) * 100
            },
            "quality": {
                "avg_score": metrics.avg_score,
                "first_pass_rate": metrics.first_pass_rate,
                "avg_rework_count": metrics.avg_rework_count
            },
            "chapters": [
                {
                    "num": c.num,
                    "title": c.title,
                    "word_count": c.word_count,
                    "review_score": c.review_score,
                    "status": c.review_status
                }
                for c in metrics.chapters
            ]
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    elif args.report == "weekly":
        print(generate_weekly_report(metrics))
    else:
        print(generate_dashboard(metrics))


if __name__ == "__main__":
    main()
