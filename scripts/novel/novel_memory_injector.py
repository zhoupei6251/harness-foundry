#!/usr/bin/env python3
"""
novel-memory-injector — 核心记忆注入器

解决长篇写作最根本的问题：Agent 纪律。
无论 Agent 是否记得读 MEMORY.md，本脚本都会在写章前
提取并注入最关键的记忆到一个精简文件中。

核心设计：
  - 输出文件: .novel-memory-injection.md
  - 强制注入: 不超过 2000 tokens
  - 包含: 角色核心档案 + 最近伏笔 + 上章摘要 + 禁止事项
  - 写作 Agent 的 system prompt 中引用此文件

用法：
    python novel_memory_injector.py <书籍目录> <当前章节号>
    python novel_memory_injector.py <书籍目录> <当前章节号> --json
"""

import re
import json
import sys
import argparse
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, List


# Token 估算：中文约 1 字 = 1.5 tokens
MAX_TOKENS = 2000  # 最多 2000 tokens 的注入量
MAX_CHARS = int(MAX_TOKENS / 1.5)  # 约 1333 字


def count_tokens_estimate(text: str) -> int:
    """粗略估算 token 数"""
    chinese = len(re.findall(r'[一-鿿]', text))
    other = len(text) - chinese
    return int(chinese * 1.5 + other * 0.3)


def count_words(text: str) -> int:
    """统计字数"""
    chinese = len(re.findall(r'[一-鿿]', text))
    return chinese


def load_memory(book_dir: Path) -> Optional[str]:
    """读取 MEMORY.md"""
    for name in ["MEMORY.md", "记忆.md"]:
        f = book_dir / name
        if f.exists():
            content = f.read_text(encoding="utf-8")
            # 限制长度
            if len(content) > MAX_CHARS * 3:
                content = content[:MAX_CHARS * 3]
            return content
    return None


def extract_characters(memory_content: str) -> str:
    """提取核心角色档案"""
    result = ""
    char_section_started = False

    for line in memory_content.split('\n'):
        if '人物设定' in line or '### 主角' in line or '### 配角' in line or '### 反派' in line:
            char_section_started = True
            result += "## 核心角色\n\n" if not result else ""
            result += line + "\n"
            continue

        if char_section_started:
            if line.startswith('## ') and '人物' not in line:
                char_section_started = False
                continue
            result += line + "\n"

            if len(result) > 300:
                result += "... (更多角色见 MEMORY.md)\n"
                break

    return result


def extract_recent_chapters(memory_content: str, current_chapter: int) -> str:
    """提取最近章节摘要"""
    result = "## 最近章节\n\n"

    # 搜索章节索引表格
    chapter_lines = []
    in_chapter_table = False
    for line in memory_content.split('\n'):
        if '已完成章节' in line or '章节索引' in line or '章节进度' in line:
            in_chapter_table = True
            continue
        if in_chapter_table and line.startswith('## '):
            in_chapter_table = False
            continue
        if in_chapter_table and '|' in line and '章' in line:
            chapter_lines.append(line)

    # 只取最近3章
    recent = chapter_lines[-3:]
    for l in recent:
        result += l.strip() + "\n"

    # 上章摘要
    if '上章摘要' in memory_content or '摘要' in memory_content:
        summary_section_started = False
        result += "\n## 上章摘要\n\n"
        for line in memory_content.split('\n'):
            if '上章摘要' in line or ('摘要' in line and '##' in line):
                summary_section_started = True
                continue
            if summary_section_started:
                if line.startswith('## '):
                    break
                result += line + "\n"
                if len(result) > 800:
                    result += "... (更多摘要见 MEMORY.md)\n"
                    break

    return result


def extract_foreshadows(memory_content: str) -> str:
    """提取活跃伏笔"""
    result = "## 活跃伏笔\n\n"

    in_fs_section = False
    for line in memory_content.split('\n'):
        if '伏笔' in line and ('|' in line or '追踪' in line or '##' in line):
            in_fs_section = True
            result += "| 伏笔ID | 内容 | 状态 | 埋设 | 回收 |\n|---|---|---|---|---|\n"
            continue

        if in_fs_section:
            if not line.strip() or (not '|' in line and line.startswith('#')):
                in_fs_section = False
                continue
            if 'FP' in line and 'buried' in line:
                result += line + "\n"
                if result.count('\n') > 10:
                    result += "... (更多伏笔见 MEMORY.md)\n"
                    break

    return result


def extract_world_settings(memory_content: str) -> str:
    """提取世界观核心设定（简版）"""
    result = "## 世界观\n\n"

    settings_started = False
    for line in memory_content.split('\n'):
        if '世界观' in line and '##' in line:
            settings_started = True
            continue
        if settings_started:
            if line.startswith('## ') and '世界观' not in line:
                break
            result += line + "\n"
            if len(result) > 400:
                result += "... (更多设定见 MEMORY.md)\n"
                break

    return result if len(result) > 50 else ""


def build_injection(memory_content: str, current_chapter: int, chapter_file: Optional[Path] = None) -> str:
    """构建精简记忆注入"""
    now = datetime.now().isoformat()

    header = f"""## 📌 第{current_chapter}章写作核心记忆
> 自动生成于 {now[:19]}
> 本文件长度可控，确保 Agent 每次写章前强制加载

"""

    body = ""

    # 1. 核心角色档案（最重要，占约 30%）
    chars = extract_characters(memory_content)
    if chars:
        body += chars + "\n"

    # 2. 最近章节摘要（占约 25%）
    recent = extract_recent_chapters(memory_content, current_chapter)
    if recent:
        body += recent + "\n"

    # 3. 活跃伏笔（占约 15%）
    fs = extract_foreshadows(memory_content)
    if fs:
        body += fs + "\n"

    # 4. 世界观简版（占约 10%）
    world = extract_world_settings(memory_content)
    if world:
        body += world + "\n"

    # 5. AI禁忌清单（硬编码，占约 10%）
    body += """## AI 写作禁忌

⚠️ 禁止使用的表达：
- "眼中闪过一丝" "嘴角勾起一抹" "深吸一口气"
- "只见" "就在这时" "突然之间"
- "首先/其次/最后" "与此同时"
- "仿佛" "似乎" "不由得"
- "心中涌起" "命运的齿轮"

✅ 写作要求：
- 直接描述动作和场景，不绕圈
- 对话符合角色身份和性格
- 每章结尾必须有悬念钩子
- 字数 ≥ 2000 字

"""
    # 6. 本章目标提示（占约 10%）
    body += f"""## 本章目标

> 当前章节: 第{current_chapter}章
> 前章结尾: 见「上章摘要」
> 写作要求: 承上启下，推进主线，每章至少一个冲突/转折

"""

    # 合并并裁剪
    full = header + body
    current_tokens = count_tokens_estimate(full)

    if current_tokens > MAX_TOKENS:
        # 按优先级裁剪
        lines = full.split('\n')
        kept_lines = []
        kept_tokens = 0
        for line in lines:
            line_tokens = count_tokens_estimate(line)
            if kept_tokens + line_tokens > MAX_TOKENS:
                break
            kept_lines.append(line)
            kept_tokens += line_tokens
        full = '\n'.join(kept_lines)
        full += f"\n\n> ⚠️ 记忆注入被截断 (token 限制 {MAX_TOKENS})"

    return full


def main():
    parser = argparse.ArgumentParser(
        description="novel-memory-injector — 写章前核心记忆注入"
    )
    parser.add_argument("book_dir", help="书籍目录")
    parser.add_argument("chapter", type=int, help="当前章节号")
    parser.add_argument("--output", "-o", help="输出文件路径", default=".novel-memory-injection.md")
    parser.add_argument("--json", "-j", action="store_true", help="JSON 输出")
    args = parser.parse_args()

    book_dir = Path(args.book_dir)
    if not book_dir.exists():
        print(f"❌ 目录不存在: {book_dir}", file=sys.stderr)
        sys.exit(1)

    # 读取记忆
    memory_content = load_memory(book_dir)
    if not memory_content:
        print("❌ 未找到 MEMORY.md", file=sys.stderr)
        sys.exit(1)

    # 构建注入
    injection = build_injection(memory_content, args.chapter)

    # 统计
    char_count = len(injection)
    token_estimate = count_tokens_estimate(injection)
    word_count = count_words(injection)

    # 输出
    output_path = book_dir / args.output
    output_path.write_text(injection, encoding="utf-8")

    if args.json:
        result = {
            "status": "ok",
            "output_file": str(output_path),
            "chapter": args.chapter,
            "stats": {
                "chars": char_count,
                "estimated_tokens": token_estimate,
                "word_count": word_count
            }
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"✅ 记忆注入完成")
        print(f"   当前章节: 第{args.chapter}章")
        print(f"   输出文件: {output_path}")
        print(f"   注入量: {char_count} 字 (~{token_estimate} tokens)")
        print(f"")


if __name__ == "__main__":
    main()
