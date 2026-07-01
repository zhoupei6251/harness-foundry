#!/usr/bin/env python3
"""
Novel Continuity Checker — 确定性连续性预检查引擎
====================================================

借鉴 Novel-OS (mrigankad) 的 continuity_engine.py：
- 纯规则/统计检查，无 LLM 调用
- 在 Guardian LLM 验证之前运行
- 将发现注入 Guardian prompt，节省 Token

架构：
  Novel-OS 确定性引擎  ─→  本脚本 continuity_check.py

用法：
  python continuity_check.py <章节正文目录> [--memory MEMORY.md]
"""

import os
import sys
import json
import re
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime, timedelta


class ContinuityIssue:
    """连续性问题"""

    def __init__(self, check_id: str, severity: str, description: str,
                 detail: str = "", suggestion: str = ""):
        self.check_id = check_id
        self.severity = severity  # CRITICAL | WARNING | INFO
        self.description = description
        self.detail = detail
        self.suggestion = suggestion

    def to_dict(self) -> dict:
        return {
            "check_id": self.check_id,
            "severity": self.severity,
            "description": self.description,
            "detail": self.detail,
            "suggestion": self.suggestion
        }


class ContinuityChecker:
    """确定性连续性检查引擎"""

    def __init__(self, chapters_dir: str, memory_file: Optional[str] = None):
        self.chapters_dir = Path(chapters_dir)
        self.memory_file = Path(memory_file) if memory_file else self.chapters_dir / "MEMORY.md"
        self.issues: List[ContinuityIssue] = []
        self.characters: Dict[str, dict] = {}
        self.chapters: List[dict] = []
        self.foreshadowings: List[dict] = []
        self.timeline_events: List[dict] = []

    def load_memory(self) -> bool:
        """加载 MEMORY.md"""
        if not self.memory_file.exists():
            self.issues.append(ContinuityIssue(
                "SYS-001", "WARNING",
                "MEMORY.md 不存在",
                f"路径: {self.memory_file}",
                "创建 MEMORY.md 来维护项目记忆"
            ))
            return False

        with open(self.memory_file, "r", encoding="utf-8") as f:
            content = f.read()

        # 解析 MEMORY.md 中的结构化数据
        self._parse_characters(content)
        self._parse_chapters(content)
        self._parse_foreshadowings(content)
        self._parse_timeline(content)

        return True

    def _parse_characters(self, content: str) -> None:
        """解析人物状态"""
        # 从 MEMORY.md 中提取人物信息
        # 匹配格式: | 角色名 | 状态 | 备注 |
        char_pattern = re.compile(
            r"\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|"
        )
        in_char_table = False
        for line in content.split("\n"):
            if "人物状态" in line or "角色" in line:
                in_char_table = True
                continue
            if in_char_table and line.strip().startswith("|"):
                match = char_pattern.match(line.strip())
                if match and not match.group(1).strip().startswith("-"):
                    name = match.group(1).strip()
                    if name in ["人物", "角色", "姓名"]:
                        continue
                    self.characters[name] = {
                        "status": match.group(2).strip(),
                        "notes": match.group(3).strip(),
                        "last_seen": self._extract_chapter_ref(match.group(3).strip())
                    }

    def _parse_chapters(self, content: str) -> None:
        """解析章节进度"""
        chapter_pattern = re.compile(
            r"第(\d+)章.*?(\d{4}-\d{2}-\d{2})?"
        )
        for match in chapter_pattern.finditer(content):
            self.chapters.append({
                "number": int(match.group(1)),
                "date": match.group(2) if match.group(2) else None
            })

    def _parse_foreshadowings(self, content: str) -> None:
        """解析伏笔状态"""
        # 匹配伏笔表格
        f_pattern = re.compile(
            r"\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(\d+)\s*\|\s*(.+?)\s*\|"
        )
        in_f_table = False
        for line in content.split("\n"):
            if "伏笔" in line:
                in_f_table = True
                continue
            if in_f_table and line.strip().startswith("|"):
                match = f_pattern.match(line.strip())
                if match and not match.group(1).strip().startswith("-"):
                    status = match.group(4).strip()
                    self.foreshadowings.append({
                        "name": match.group(1).strip(),
                        "type": match.group(2).strip(),
                        "planted_chapter": int(match.group(3)),
                        "status": status,
                        "resolved_chapter": self._extract_chapter_ref(status)
                    })

    def _parse_timeline(self, content: str) -> None:
        """解析时间线"""
        # 简单提取时间戳
        date_pattern = re.compile(r"(\d{4}-\d{2}-\d{2})")
        for match in date_pattern.finditer(content):
            self.timeline_events.append({
                "date": match.group(1),
                "line": content[:match.start()].count("\n") + 1
            })

    def _extract_chapter_ref(self, text: str) -> Optional[int]:
        """从文本提取章节引用"""
        match = re.search(r"第(\d+)章", text)
        return int(match.group(1)) if match else None

    # ═══════════════════════════════════════════════════
    # 检查项 — 借鉴 Novel-OS continuity_engine.py
    # ═══════════════════════════════════════════════════

    def check_dormant_threads(self) -> None:
        """检查活跃情节线索是否闲置过久（借鉴 Novel-OS dormant_thread）"""
        if not self.foreshadowings:
            return

        latest_chapter = max([c["number"] for c in self.chapters]) if self.chapters else 1
        for f in self.foreshadowings:
            if "待回收" in f["status"] or "○" in f["status"]:
                chapters_since = latest_chapter - f["planted_chapter"]
                if chapters_since > 3:
                    self.issues.append(ContinuityIssue(
                        "CT-001", "WARNING",
                        f"情节线索闲置: {f['name']}",
                        f"埋设于第{f['planted_chapter']}章，已过{chapters_since}章未回收",
                        f"建议在第{latest_chapter + 1}章或第{latest_chapter + 2}章安排回收"
                    ))

    def check_overdue_threads(self) -> None:
        """检查逾期未完结的线索（借鉴 Novel-OS overdue_thread）"""
        for f in self.foreshadowings:
            # 检查是否有目标回收章节但已超过
            match = re.search(r"计划第(\d+)章回收", f.get("notes", ""))
            if match:
                target_chapter = int(match.group(1))
                latest = max([c["number"] for c in self.chapters]) if self.chapters else 1
                if latest > target_chapter and "回收" not in f["status"] and "✓" not in f["status"]:
                    self.issues.append(ContinuityIssue(
                        "CT-002", "CRITICAL",
                        f"逾期未回收: {f['name']}",
                        f"计划在第{target_chapter}章回收，当前已到第{latest}章",
                        "立即安排回收，或更新计划"
                    ))

    def check_unresolved_foreshadowing(self) -> None:
        """检查长期未回收的伏笔（借鉴 Novel-OS unresolved_foreshadowing）"""
        latest_chapter = max([c["number"] for c in self.chapters]) if self.chapters else 1
        for f in self.foreshadowings:
            if "待回收" in f["status"] or "○" in f["status"]:
                chapters_since = latest_chapter - f["planted_chapter"]
                if chapters_since > 5:
                    self.issues.append(ContinuityIssue(
                        "CT-003", "WARNING",
                        f"长期未回收伏笔: {f['name']}",
                        f"埋设于第{f['planted_chapter']}章，已过{chapters_since}章",
                        "安排回收章节，或标记为'长期伏笔'"
                    ))

    def check_absent_characters(self) -> None:
        """检查主要角色是否长期沉默（借鉴 Novel-OS absent_character）"""
        if not self.chapters:
            return

        latest_chapter = max([c["number"] for c in self.chapters])
        for name, info in self.characters.items():
            last_seen = info.get("last_seen")
            if last_seen and latest_chapter - last_seen > 5:
                self.issues.append(ContinuityIssue(
                    "CT-004", "WARNING",
                    f"角色长期未出现: {name}",
                    f"上次出现于第{last_seen}章，距今{latest_chapter - last_seen}章",
                    f"安排出场或说明去向"
                ))

    def check_dead_characters(self) -> None:
        """检查已死亡角色是否意外出现（借鉴 Novel-OS dead_character_state）"""
        for name, info in self.characters.items():
            if "死亡" in info["status"] and "活跃" in info.get("notes", ""):
                self.issues.append(ContinuityIssue(
                    "CT-005", "CRITICAL",
                    f"已死亡角色标记为活跃: {name}",
                    f"状态'{info['status']}'与备注'{info['notes']}'矛盾",
                    "更新状态为已死亡"
                ))

    def check_missing_chapter_files(self) -> None:
        """检查标记完成但缺文件的章节（借鉴 Novel-OS missing_chapter_file）"""
        if not self.chapters_dir.exists():
            return

        existing_files = list(self.chapters_dir.glob("第*章*.md"))
        existing_numbers = set()
        for f in existing_files:
            match = re.search(r"第(\d+)章", f.name)
            if match:
                existing_numbers.add(int(match.group(1)))

        for ch in self.chapters:
            if ch["number"] not in existing_numbers:
                self.issues.append(ContinuityIssue(
                    "CT-006", "CRITICAL",
                    f"章节文件缺失: 第{ch['number']}章",
                    "MEMORY.md 中标记完成但对应 .md 文件不存在",
                    "恢复文件或更新 MEMORY.md"
                ))

    def check_name_consistency(self) -> None:
        """检查角色名字一致性"""
        # 扫描所有章节文件中的角色名
        names_in_files = {}
        if self.chapters_dir.exists():
            for file in self.chapters_dir.glob("第*章*.md"):
                with open(file, "r", encoding="utf-8") as f:
                    text = f.read()
                for name in self.characters.keys():
                    count = text.count(name)
                    if count > 0:
                        if name not in names_in_files:
                            names_in_files[name] = []
                        names_in_files[name].append({
                            "file": file.name,
                            "count": count
                        })

        # 检查 MEMORY.md 中注册的角色是否在章节中出现
        if self.chapters:
            for name, info in self.characters.items():
                if "登场" in info.get("notes", "") or "活跃" in info.get("status", ""):
                    if name not in names_in_files:
                        self.issues.append(ContinuityIssue(
                            "CT-007", "WARNING",
                            f"标记为活跃但可能未在最近章节出现: {name}",
                            f"状态: {info['status']}",
                            "确认是否需要出场或更新状态"
                        ))

    def check_timeline_order(self) -> None:
        """检查时间线是否顺序正确"""
        if len(self.timeline_events) < 2:
            return

        dates = [e["date"] for e in self.timeline_events]
        for i in range(len(dates) - 1):
            if dates[i] > dates[i + 1]:
                self.issues.append(ContinuityIssue(
                    "CT-008", "CRITICAL",
                    "时间线顺序混乱",
                    f"{dates[i]} 出现在 {dates[i + 1]} 之后",
                    "检查事件排序"
                ))

    # ═══════════════════════════════════════════════════
    # 执行所有检查
    # ═══════════════════════════════════════════════════

    def run_all(self) -> dict:
        """运行所有检查"""
        if not self.load_memory():
            # 即使没有 MEMORY.md 也继续运行部分检查
            pass

        checks = [
            self.check_dormant_threads,
            self.check_overdue_threads,
            self.check_unresolved_foreshadowing,
            self.check_absent_characters,
            self.check_dead_characters,
            self.check_missing_chapter_files,
            self.check_name_consistency,
            self.check_timeline_order,
        ]

        for check_fn in checks:
            try:
                check_fn()
            except Exception as e:
                self.issues.append(ContinuityIssue(
                    "SYS-002", "INFO",
                    f"检查 '{check_fn.__name__}' 执行异常: {e}",
                    "", ""
                ))

        return self.build_report()

    def build_report(self) -> dict:
        """构建报告"""
        criticals = [i for i in self.issues if i.severity == "CRITICAL"]
        warnings = [i for i in self.issues if i.severity == "WARNING"]
        infos = [i for i in self.issues if i.severity == "INFO"]

        if criticals:
            verdict = "FAIL"
        elif warnings:
            verdict = "WARNING"
        else:
            verdict = "PASS"

        return {
            "meta": {
                "tool": "novel-continuity-checker",
                "version": "1.0.0",
                "inspiration": "Novel-OS continuity_engine.py (mrigankad)"
            },
            "verdict": verdict,
            "issues_count": {
                "total": len(self.issues),
                "critical": len(criticals),
                "warning": len(warnings),
                "info": len(infos)
            },
            "issues": [i.to_dict() for i in self.issues],
            "context": {
                "characters_count": len(self.characters),
                "chapters_count": len(self.chapters),
                "foreshadowings_count": len(self.foreshadowings),
                "timeline_events_count": len(self.timeline_events)
            }
        }


def main():
    if len(sys.argv) < 2:
        print("用法: python continuity_check.py <章节正文目录> [--memory MEMORY.md] [--json]")
        print()
        print("示例:")
        print("  python continuity_check.py 章节正文/")
        print("  python continuity_check.py 章节正文/ --memory 章节正文/MEMORY.md --json")
        sys.exit(1)

    chapters_dir = sys.argv[1]
    memory_file = None
    use_json = "--json" in sys.argv

    for i, arg in enumerate(sys.argv):
        if arg == "--memory" and i + 1 < len(sys.argv):
            memory_file = sys.argv[i + 1]

    if not os.path.isdir(chapters_dir):
        print(f"错误: 目录不存在 — {chapters_dir}")
        sys.exit(1)

    checker = ContinuityChecker(chapters_dir, memory_file)
    report = checker.run_all()

    if use_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"\n{'=' * 50}")
        print("  🛡️ Novel Continuity Checker")
        print("  借鉴 Novel-OS continuity_engine.py")
        print(f"{'=' * 50}")
        print(f"\n  判定: {report['verdict']}")
        print(f"  发现: {report['issues_count']['critical']} CRITICAL, "
              f"{report['issues_count']['warning']} WARNING, "
              f"{report['issues_count']['info']} INFO")
        print(f"\n  上下文:")
        print(f"    人物: {report['context']['characters_count']}")
        print(f"    章节: {report['context']['chapters_count']}")
        print(f"    伏笔: {report['context']['foreshadowings_count']}")
        print(f"    时间事件: {report['context']['timeline_events_count']}")

        if report['issues']:
            print(f"\n{'─' * 50}")
            for issue in report['issues']:
                print(f"  [{issue['severity']:8s}] {issue['check_id']}: {issue['description']}")
                if issue['detail']:
                    print(f"            详情: {issue['detail']}")
                if issue['suggestion']:
                    print(f"            建议: {issue['suggestion']}")

        print(f"\n{'=' * 50}\n")


if __name__ == "__main__":
    main()
