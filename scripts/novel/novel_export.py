#!/usr/bin/env python3
"""
novel-export — 多格式小说导出脚本

支持 EPUB、PDF、HTML、番茄小说格式、起点中文格式的导出。

用法：
    python novel_export.py epub <书籍目录> -o output.epub
    python novel_export.py pdf <书籍目录> -o output.pdf
    python novel_export.py html <书籍目录> -o output_dir/
    python novel_export.py fanqie <书籍目录> -o output.jsonl
    python novel_export.py qidian <书籍目录> -o output.csv
"""

import re
import sys
import json
import argparse
import os
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional
from dataclasses import dataclass


@dataclass
class Chapter:
    """章节"""
    num: int
    title: str
    content: str
    word_count: int


@dataclass
class BookMetadata:
    """书籍元数据"""
    title: str
    author: str = "未知作者"
    description: str = ""
    genre: str = ""
    tags: List[str] = None
    cover: str = ""

    def __post_init__(self):
        if self.tags is None:
            self.tags = []


def count_words(text: str) -> int:
    """统计字数"""
    chinese = len(re.findall(r'[一-鿿]', text))
    return chinese


def parse_chapter_file(file_path: Path) -> Optional[Chapter]:
    """解析章节文件"""
    try:
        content = file_path.read_text(encoding="utf-8")
    except:
        return None

    # 提取章节号和标题
    name = file_path.stem
    match = re.match(r'第(\d+)章[_：](.+)', name)
    if not match:
        return None

    num = int(match.group(1))
    title = match.group(2)

    # 清理内容
    lines = content.split('\n')
    clean_lines = []
    for line in lines:
        # 跳过元信息
        if line.startswith('---') or line.startswith('*'):
            continue
        if line.startswith('#'):
            continue
        clean_lines.append(line)

    clean_content = '\n'.join(clean_lines).strip()

    return Chapter(
        num=num,
        title=title,
        content=clean_content,
        word_count=count_words(clean_content)
    )


def load_metadata(book_dir: Path) -> BookMetadata:
    """加载书籍元数据"""
    metadata = BookMetadata(title=book_dir.name)

    # 尝试从 MEMORY.md 读取
    memory_file = book_dir / "MEMORY.md"
    if memory_file.exists():
        content = memory_file.read_text(encoding="utf-8")

        if match := re.search(r'\| 书名 \| ([^|]+)', content):
            metadata.title = match.group(1).strip()

        if match := re.search(r'\| 题材 \| ([^|]+)', content):
            metadata.genre = match.group(1).strip()

    # 尝试从 metadata.yaml 读取
    yaml_file = book_dir / "metadata.yaml"
    if yaml_file.exists():
        import yaml
        try:
            data = yaml.safe_load(yaml_file.read_text(encoding="utf-8"))
            if data:
                metadata.title = data.get('title', metadata.title)
                metadata.author = data.get('author', metadata.author)
                metadata.description = data.get('description', '')
                metadata.genre = data.get('genre', metadata.genre)
                metadata.tags = data.get('tags', [])
                metadata.cover = data.get('cover', '')
        except:
            pass

    return metadata


def scan_chapters(book_dir: Path) -> List[Chapter]:
    """扫描所有章节"""
    chapters = []

    # 扫描章节目录
    for chapter_dir in [book_dir, book_dir / "章节正文"]:
        if not chapter_dir.exists():
            continue

        for file_path in sorted(chapter_dir.glob("第*章*.md")):
            chapter = parse_chapter_file(file_path)
            if chapter:
                chapters.append(chapter)

    return sorted(chapters, key=lambda c: c.num)


def export_epub(chapters: List[Chapter], metadata: BookMetadata, output_path: Path):
    """导出 EPUB 格式"""
    # 简单 EPUB 生成（不含封面图片）
    import zipfile

    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as epub:
        # mimetype (必须第一个，不压缩)
        epub.writestr('mimetype', 'application/epub+zip', compress_type=zipfile.ZIP_STORED)

        # container.xml
        container = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>'''
        epub.writestr('META-INF/container.xml', container)

        # content.opf
        manifest_items = []
        spine_items = []

        for i, chapter in enumerate(chapters):
            item_id = f'chapter{i+1}'
            manifest_items.append(f'<item id="{item_id}" href="chapter{i+1}.xhtml" media-type="application/xhtml+xml"/>')
            spine_items.append(f'<itemref idref="{item_id}"/>')

        content_opf = f'''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookId">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:title>{metadata.title}</dc:title>
        <dc:creator>{metadata.author}</dc:creator>
        <dc:language>zh-CN</dc:language>
        <dc:identifier id="BookId">urn:uuid:{datetime.now().strftime("%Y%m%d%H%M%S")}</dc:identifier>
    </metadata>
    <manifest>
        {''.join(manifest_items)}
    </manifest>
    <spine>
        {''.join(spine_items)}
    </spine>
</package>'''
        epub.writestr('OEBPS/content.opf', content_opf)

        # 章节内容
        for i, chapter in enumerate(chapters):
            chapter_xhtml = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>{chapter.title}</title>
    <style>
        body {{ font-family: "SimSun", serif; margin: 1em; line-height: 1.8; }}
        h2 {{ text-align: center; margin: 1.5em 0; }}
        p {{ text-indent: 2em; margin: 0.5em 0; }}
    </style>
</head>
<body>
    <h2>{chapter.title}</h2>
    {''.join(f'<p>{para}</p>' for para in chapter.content.split('\\n') if para.strip())}
</body>
</html>'''
            epub.writestr(f'OEBPS/chapter{i+1}.xhtml', chapter_xhtml)

    print(f"✅ EPUB 已导出: {output_path}")


def export_html(chapters: List[Chapter], metadata: BookMetadata, output_dir: Path):
    """导出 HTML 格式"""
    output_dir.mkdir(parents=True, exist_ok=True)

    # 生成 index.html（目录页）
    toc_html = f'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>{metadata.title}</title>
    <style>
        body {{ font-family: "Microsoft YaHei", sans-serif; max-width: 800px; margin: 0 auto; padding: 2em; }}
        h1 {{ text-align: center; border-bottom: 2px solid #333; padding-bottom: 0.5em; }}
        .toc {{ line-height: 2; }}
        .toc a {{ color: #0066cc; text-decoration: none; }}
        .toc a:hover {{ text-decoration: underline; }}
        .chapter-num {{ color: #666; font-size: 0.9em; }}
    </style>
</head>
<body>
    <h1>{metadata.title}</h1>
    <p style="text-align:center;color:#666;">作者: {metadata.author} | 共 {len(chapters)} 章</p>
    <hr>
    <div class="toc">
'''

    for chapter in chapters:
        toc_html += f'        <div><span class="chapter-num">第{chapter.num}章</span> <a href="chapter_{chapter.num}.html">{chapter.title}</a> ({chapter.word_count}字)</div>\n'

    toc_html += '''    </div>
</body>
</html>'''

    (output_dir / 'index.html').write_text(toc_html, encoding='utf-8')

    # 生成各章节 HTML
    for chapter in chapters:
        chapter_html = f'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>第{chapter.num}章 {chapter.title}</title>
    <style>
        body {{ font-family: "Microsoft YaHei", sans-serif; max-width: 800px; margin: 0 auto; padding: 2em; line-height: 1.8; }}
        h2 {{ text-align: center; border-bottom: 1px solid #ddd; padding-bottom: 0.5em; }}
        p {{ text-indent: 2em; margin: 0.8em 0; }}
        .nav {{ position: fixed; bottom: 20px; right: 20px; }}
        .nav a {{ display: block; background: #333; color: white; padding: 0.5em 1em; text-decoration: none; margin: 0.2em 0; }}
        .nav a:hover {{ background: #555; }}
    </style>
</head>
<body>
    <h2>第{chapter.num}章 {chapter.title}</h2>
    {''.join(f'<p>{para}</p>' for para in chapter.content.split('\\n') if para.strip())}
    <div class="nav">
        <a href="index.html">目录</a>
    </div>
</body>
</html>'''

        (output_dir / f'chapter_{chapter.num}.html').write_text(chapter_html, encoding='utf-8')

    print(f"✅ HTML 已导出: {output_dir}/")


def export_fanqie(chapters: List[Chapter], metadata: BookMetadata, output_path: Path):
    """导出番茄小说格式（JSONL）"""
    with open(output_path, 'w', encoding='utf-8') as f:
        for chapter in chapters:
            data = {
                "title": f"第{chapter.num}章 {chapter.title}",
                "content": chapter.content,
                "word_count": chapter.word_count,
                "chapter_index": chapter.num
            }
            f.write(json.dumps(data, ensure_ascii=False) + '\n')

    print(f"✅ 番茄小说格式已导出: {output_path}")


def export_qidian(chapters: List[Chapter], metadata: BookMetadata, output_path: Path):
    """导出起点中文格式（CSV）"""
    import csv

    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['chapter_name', 'content', 'word_count'])

        for chapter in chapters:
            writer.writerow([
                f"第{chapter.num}章 {chapter.title}",
                chapter.content,
                chapter.word_count
            ])

    print(f"✅ 起点中文格式已导出: {output_path}")


def export_json(chapters: List[Chapter], metadata: BookMetadata, output_path: Path):
    """导出 JSON 格式"""
    data = {
        "title": metadata.title,
        "author": metadata.author,
        "genre": metadata.genre,
        "description": metadata.description,
        "total_chapters": len(chapters),
        "total_words": sum(c.word_count for c in chapters),
        "chapters": [
            {
                "num": c.num,
                "title": c.title,
                "content": c.content,
                "word_count": c.word_count
            }
            for c in chapters
        ]
    }

    output_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"✅ JSON 已导出: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="novel-export — 多格式小说导出")
    parser.add_argument("format", choices=["epub", "html", "fanqie", "qidian", "json", "pdf"],
                        help="导出格式")
    parser.add_argument("book_dir", help="书籍目录")
    parser.add_argument("-o", "--output", required=True, help="输出路径")

    args = parser.parse_args()

    book_dir = Path(args.book_dir)
    if not book_dir.exists():
        print(f"❌ 目录不存在: {book_dir}")
        sys.exit(1)

    # 加载元数据
    metadata = load_metadata(book_dir)

    # 扫描章节
    chapters = scan_chapters(book_dir)
    if not chapters:
        print("❌ 未找到章节文件")
        sys.exit(1)

    print(f"📖 {metadata.title} — {len(chapters)} 章, {sum(c.word_count for c in chapters):,} 字")

    # 导出
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.format == "epub":
        export_epub(chapters, metadata, output_path)
    elif args.format == "html":
        export_html(chapters, metadata, output_path)
    elif args.format == "fanqie":
        export_fanqie(chapters, metadata, output_path)
    elif args.format == "qidian":
        export_qidian(chapters, metadata, output_path)
    elif args.format == "json":
        export_json(chapters, metadata, output_path)
    elif args.format == "pdf":
        print("⚠️ PDF 导出需要 weasyprint 库，请使用 html 格式或手动转换")
        export_html(chapters, metadata, output_path)


if __name__ == "__main__":
    main()
