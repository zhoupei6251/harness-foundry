#!/usr/bin/env python3
"""
Novel Foreshadowing DAG — 伏笔有向无环图管理
================================================

借鉴 Openwrite (LiPu-jpg) 的伏笔 DAG 管理：
- 每个伏笔有：埋设点、触发条件、目标回收点、依赖关系
- 自动检测逾期未回收的伏笔
- 可视化当前伏笔状态

数据结构：
  Openwrite data/foreshadowing/dag.yaml  ─→  本脚本 + foreshadowing_dag.json

用法：
  python foreshadowing_dag.py <章节正文目录> [command]
  命令:
    list     - 列出所有伏笔状态
    add      - 添加新伏笔 (交互式)
    resolve  - 标记伏笔已回收
    overdue  - 列出逾期未回收的伏笔
    graph    - 生成 Mermaid 伏笔关系图
    check    - 检查伏笔逻辑错误 (循环依赖、孤立节点等)
"""

import os
import sys
import json
import re
from pathlib import Path
from typing import List, Dict, Optional, Set, Tuple
from datetime import datetime
from collections import defaultdict


# ═════════════════════════════════════════════════════════
# 数据结构 — 借鉴 Openwrite data/foreshadowing/dag.yaml
# ═════════════════════════════════════════════════════════

"""
foreshadowing_dag.json 格式：

{
  "meta": {
    "book_title": "书名",
    "last_updated": "2026-07-01",
    "total_chapters": 10
  },
  "nodes": {
    "伏笔ID": {
      "id": "FS-001",
      "name": "伏笔名称",
      "type": "设定型 | 情节型 | 人物型",
      "description": "伏笔说明",
      "planted_chapter": 3,
      "planted_context": "埋设时的上下文（原文引用）",
      "target_chapter": 5,
      "resolved_chapter": null,
      "resolved_context": null,
      "status": "buried | triggered | resolved | abandoned",
      "priority": "high | medium | low",
      "depends_on": [],  // 依赖的其他伏笔 ID
      "required_by": [],  // 被哪些伏笔依赖
      "trigger_condition": "触发条件",
      "created_at": "2026-07-01",
      "resolved_at": null
    }
  },
  "edges": [
    {"from": "FS-001", "to": "FS-003", "type": "depends_on"},
    {"from": "FS-003", "to": "FS-001", "type": "required_by"}
  ],
  "warnings": [
    {"type": "overdue", "foreshadowing_id": "FS-002", "message": "..."}
  ]
}
"""


class ForeshadowingDAG:
    """伏笔有向无环图管理器"""

    def __init__(self, book_dir: str):
        self.book_dir = Path(book_dir)
        self.dag_file = self.book_dir / "foreshadowing_dag.json"
        self.memory_file = self.book_dir / "MEMORY.md"
        self.dag = self._load_or_create()
        # 自动从 MEMORY.md 导入伏笔（如 DAG 为空但有 MEMORY）
        self._auto_import_from_memory()

    def _load_or_create(self) -> dict:
        """加载或创建 DAG 文件"""
        if self.dag_file.exists():
            with open(self.dag_file, "r", encoding="utf-8") as f:
                return json.load(f)

        book_title = self.book_dir.name
        # 扫描章节文件获取总章数
        chapters = sorted(self.book_dir.glob("第*章*.md"))
        total = len(chapters)

        return {
            "meta": {
                "book_title": book_title,
                "last_updated": datetime.now().strftime("%Y-%m-%d"),
                "total_chapters": total
            },
            "nodes": {},
            "edges": [],
            "warnings": []
        }

    def _auto_import_from_memory(self) -> None:
        """从 MEMORY.md 自动导入伏笔（首次运行时 DAG 为空）"""
        if self.dag["nodes"]:
            return  # 已有数据，不覆盖

        if not self.memory_file.exists():
            return

        with open(self.memory_file, "r", encoding="utf-8") as f:
            content = f.read()

        # 解析伏笔表格
        # | 伏笔名 | 类型 | 埋设章 | 状态 |
        f_pattern = re.compile(
            r"\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*第?(\d+).*?\s*\|\s*(.+?)\s*\|"
        )
        in_f_table = False
        imported = 0
        for line in content.split("\n"):
            if "伏笔" in line:
                in_f_table = True
                continue
            if in_f_table and line.strip().startswith("|"):
                match = f_pattern.match(line.strip())
                if match and not match.group(1).strip().startswith("-"):
                    name = match.group(1).strip()
                    if name in ["伏笔", "名称"]:
                        continue
                    ftype = match.group(2).strip()
                    planted = int(match.group(3))
                    status = match.group(4).strip()

                    # 映射状态
                    node_status = "buried"
                    if "回收" in status or "✓" in status or "已回收" in status:
                        node_status = "resolved"
                    elif "触发" in status:
                        node_status = "triggered"

                    # 对于从 MEMORY 导入的伏笔，如果状态是"待回收"应该是 buried 而非 resolved
                    if "待回收" in status or "○" in status:
                        node_status = "buried"

                    target_chapter = None
                    t_match = re.search(r"第(\d+)章", status)
                    if t_match:
                        target_chapter = int(t_match.group(1))

                    self.add_node(name, ftype, f"从 MEMORY.md 自动导入",
                                  planted, target_chapter)
                    imported += 1

        if imported > 0:
            # 更新状态：对于 node_status 已经在 add_node 时设置，但需要通过修改节点状态来修正
            for node_id, node in self.dag["nodes"].items():
                node["status"] = "buried"  # 从 MEMORY 导入的统一为 buried（待回收）
            self.save()

    def save(self) -> None:
        """保存 DAG"""
        self.dag["meta"]["last_updated"] = datetime.now().strftime("%Y-%m-%d")
        chapters = sorted(self.book_dir.glob("第*章*.md"))
        self.dag["meta"]["total_chapters"] = len(chapters)

        with open(self.dag_file, "w", encoding="utf-8") as f:
            json.dump(self.dag, f, ensure_ascii=False, indent=2)

    # ═══════════════════════════════════════════════════
    # CRUD 操作
    # ═══════════════════════════════════════════════════

    def add_node(self, name: str, ftype: str, description: str,
                 planted_chapter: int, target_chapter: int = None,
                 depends_on: List[str] = None,
                 trigger_condition: str = "",
                 priority: str = "medium") -> str:
        """添加伏笔节点"""

        # 生成 ID
        existing = len(self.dag["nodes"])
        node_id = f"FS-{existing + 1:03d}"

        node = {
            "id": node_id,
            "name": name,
            "type": ftype,  # 设定型 | 情节型 | 人物型
            "description": description,
            "planted_chapter": planted_chapter,
            "planted_context": "",
            "target_chapter": target_chapter,
            "resolved_chapter": None,
            "resolved_context": None,
            "status": "buried",
            "priority": priority,
            "depends_on": depends_on or [],
            "required_by": [],
            "trigger_condition": trigger_condition,
            "created_at": datetime.now().strftime("%Y-%m-%d"),
            "resolved_at": None
        }

        self.dag["nodes"][node_id] = node

        # 更新依赖边
        for dep_id in depends_on or []:
            if dep_id in self.dag["nodes"]:
                self.dag["edges"].append({
                    "from": node_id,
                    "to": dep_id,
                    "type": "depends_on"
                })
                if node_id not in self.dag["nodes"][dep_id]["required_by"]:
                    self.dag["nodes"][dep_id]["required_by"].append(node_id)

        self.save()
        return node_id

    def resolve_node(self, node_id: str, chapter: int, context: str = "") -> bool:
        """标记伏笔已回收"""
        if node_id not in self.dag["nodes"]:
            return False

        node = self.dag["nodes"][node_id]
        node["status"] = "resolved"
        node["resolved_chapter"] = chapter
        node["resolved_context"] = context
        node["resolved_at"] = datetime.now().strftime("%Y-%m-%d")

        self.save()
        return True

    def trigger_node(self, node_id: str) -> bool:
        """标记伏笔已触发（进入回收阶段）"""
        if node_id not in self.dag["nodes"]:
            return False

        self.dag["nodes"][node_id]["status"] = "triggered"
        self.save()
        return True

    def abandon_node(self, node_id: str, reason: str = "") -> bool:
        """标记伏笔已废弃"""
        if node_id not in self.dag["nodes"]:
            return False

        self.dag["nodes"][node_id]["status"] = "abandoned"
        if reason:
            self.dag["nodes"][node_id]["description"] += f" [废弃原因: {reason}]"
        self.save()
        return True

    # ═══════════════════════════════════════════════════
    # 分析操作 — 借鉴 Openwrite DAG 分析
    # ═══════════════════════════════════════════════════

    def find_overdue(self) -> List[dict]:
        """查找逾期未回收的伏笔"""
        current_chapter = self.dag["meta"]["total_chapters"]
        overdue = []

        for node_id, node in self.dag["nodes"].items():
            if node["status"] in ["buried", "triggered"]:
                target = node.get("target_chapter")
                if target and current_chapter > target:
                    overdue.append({
                        "id": node_id,
                        "name": node["name"],
                        "planted": node["planted_chapter"],
                        "target": target,
                        "current": current_chapter,
                        "chapters_overdue": current_chapter - target,
                        "priority": node["priority"]
                    })

        return sorted(overdue, key=lambda x: x["chapters_overdue"], reverse=True)

    def find_circular_dependencies(self) -> List[List[str]]:
        """检查循环依赖（DAG 的 D 是无环的！）"""
        # 构建邻接表
        adj = defaultdict(set)
        for node_id, node in self.dag["nodes"].items():
            for dep_id in node.get("depends_on", []):
                if dep_id in self.dag["nodes"]:
                    adj[node_id].add(dep_id)

        # DFS 检测环
        cycles = []
        visited = set()
        rec_stack = set()
        path = []

        def dfs(node: str) -> bool:
            visited.add(node)
            rec_stack.add(node)
            path.append(node)

            for neighbor in adj[node]:
                if neighbor not in visited:
                    if dfs(neighbor):
                        return True
                elif neighbor in rec_stack:
                    # 找到环
                    cycle_start = path.index(neighbor)
                    cycles.append(path[cycle_start:] + [neighbor])
                    return True

            path.pop()
            rec_stack.discard(node)
            return False

        for node_id in self.dag["nodes"]:
            if node_id not in visited:
                dfs(node_id)

        return cycles

    def find_orphans(self) -> List[str]:
        """查找孤立的伏笔（不被任何其他伏笔引用）"""
        in_degree = defaultdict(int)
        for node_id, node in self.dag["nodes"].items():
            for dep_id in node.get("depends_on", []):
                in_degree[dep_id] += 1
            for req_id in node.get("required_by", []):
                in_degree[node_id] += 1

        # 没有入度的节点 = 孤立节点
        # 也没有出度的 = 完全孤立
        orphans = []
        for node_id, node in self.dag["nodes"].items():
            if node_id not in in_degree:
                if not node.get("depends_on") and not node.get("required_by"):
                    orphans.append(node_id)

        return orphans

    def find_dormant(self, threshold: int = 3) -> List[dict]:
        """查找闲置过久的伏笔"""
        current_chapter = self.dag["meta"]["total_chapters"]
        dormant = []

        for node_id, node in self.dag["nodes"].items():
            if node["status"] == "buried":
                chapters_since = current_chapter - node["planted_chapter"]
                if chapters_since > threshold:
                    dormant.append({
                        "id": node_id,
                        "name": node["name"],
                        "planted": node["planted_chapter"],
                        "chapters_since": chapters_since,
                        "priority": node["priority"]
                    })

        return sorted(dormant, key=lambda x: x["chapters_since"], reverse=True)

    def get_stats(self) -> dict:
        """获取伏笔统计"""
        total = len(self.dag["nodes"])
        buried = sum(1 for n in self.dag["nodes"].values() if n["status"] == "buried")
        triggered = sum(1 for n in self.dag["nodes"].values() if n["status"] == "triggered")
        resolved = sum(1 for n in self.dag["nodes"].values() if n["status"] == "resolved")
        abandoned = sum(1 for n in self.dag["nodes"].values() if n["status"] == "abandoned")

        overdue = self.find_overdue()
        dormant = self.find_dormant()
        cycles = self.find_circular_dependencies()
        orphans = self.find_orphans()

        return {
            "total": total,
            "buried": buried,
            "triggered": triggered,
            "resolved": resolved,
            "abandoned": abandoned,
            "recovery_rate": round(resolved / max(total, 1) * 100, 1),
            "overdue_count": len(overdue),
            "dormant_count": len(dormant),
            "cycle_count": len(cycles),
            "orphan_count": len(orphans),
            "overdue": overdue,
            "dormant": dormant,
            "cycles": cycles,
            "orphans": orphans
        }

    def generate_mermaid(self) -> str:
        """生成 Mermaid 伏笔关系图"""
        lines = ["```mermaid", "graph TD"]
        lines.append("    title[伏笔关系图]")

        # 状态颜色
        status_colors = {
            "buried": "#f9f",
            "triggered": "#ff9",
            "resolved": "#9f9",
            "abandoned": "#ddd"
        }

        for node_id, node in self.dag["nodes"].items():
            color = status_colors.get(node["status"], "#fff")
            label = f"{node['name']}<br/>第{node['planted_chapter']}章 → "
            if node.get("resolved_chapter"):
                label += f"第{node['resolved_chapter']}章 ✓"
            elif node.get("target_chapter"):
                label += f"目标第{node['target_chapter']}章"
            else:
                label += "待定"
            lines.append(f"    {node_id}[\"{label}\"]")
            lines.append(f"    style {node_id} fill:{color}")

        for edge in self.dag["edges"]:
            arrow = "==>" if edge["type"] == "depends_on" else "-->"
            lines.append(f"    {edge['from']} {arrow} {edge['to']}")

        lines.append("```")
        return "\n".join(lines)

    # ═══════════════════════════════════════════════════
    # 自动扫描章节发现伏笔
    # ═══════════════════════════════════════════════════

    FORESHADOW_MARKERS = [
        r"伏笔[：:]\s*(.+)",
        r"伏笔\d+[：:]\s*(.+)",
        r"埋下[了]?伏笔[：:]\s*(.+)",
        r"这里.{0,5}伏笔",
        r"为后文.{0,5}铺垫",
        r"暗示.{0,10}伏笔",
    ]

    def scan_chapter(self, chapter_file: Path) -> List[dict]:
        """扫描章节中的伏笔标记（半自动发现）"""
        if not chapter_file.exists():
            return []

        chapter_num = 0
        match = re.search(r"第(\d+)章", chapter_file.name)
        if match:
            chapter_num = int(match.group(1))

        findings = []
        with open(chapter_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        for i, line in enumerate(lines, 1):
            for pattern in self.FORESHAD_MARKERS:
                if re.search(pattern, line):
                    findings.append({
                        "line": i,
                        "chapter": chapter_num,
                        "text": line.strip()[:60],
                        "pattern": pattern
                    })
                    break

        return findings


# ═══════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════

def print_stats(dag: ForeshadowingDAG) -> None:
    """打印统计信息"""
    stats = dag.get_stats()
    print(f"\n{'=' * 50}")
    print("  🔮 伏笔 DAG 统计")
    print(f"{'=' * 50}")
    print(f"  总计: {stats['total']}")
    print(f"    已埋设: {stats['buried']}")
    print(f"    已触发: {stats['triggered']}")
    print(f"    已回收: {stats['resolved']}")
    print(f"    已废弃: {stats['abandoned']}")
    print(f"  回收率: {stats['recovery_rate']}%")
    print(f"  逾期: {stats['overdue_count']}")
    print(f"  闲置: {stats['dormant_count']}")
    print(f"  循环依赖: {stats['cycle_count']}")
    print(f"  孤立节点: {stats['orphan_count']}")

    if stats["overdue"]:
        print(f"\n  ⚠ 逾期伏笔:")
        for o in stats["overdue"]:
            print(f"    {o['id']}: {o['name']} (逾期 {o['chapters_overdue']} 章)")

    if stats["dormant"]:
        print(f"\n  💤 闲置伏笔:")
        for d in stats["dormant"]:
            print(f"    {d['id']}: {d['name']} (闲置 {d['chapters_since']} 章)")

    if stats["cycles"]:
        print(f"\n  🔴 循环依赖:")
        for cycle in stats["cycles"]:
            print(f"    {' → '.join(cycle)}")

    if stats["orphans"]:
        print(f"\n  🟡 孤立伏笔:")
        for o in stats["orphans"]:
            print(f"    {o}: {dag.dag['nodes'][o]['name']}")

    print()


def print_list(dag: ForeshadowingDAG) -> None:
    """打印所有伏笔"""
    print(f"\n{'=' * 60}")
    print(f"  🔮 伏笔列表")
    print(f"{'=' * 60}")
    print(f"  {'ID':8s} {'名称':20s} {'类型':8s} {'状态':8s} {'埋设':4s} {'目标':4s} {'回收':4s}")
    print(f"  {'-' * 56}")

    for node_id, node in dag.dag["nodes"].items():
        status_icon = {
            "buried": "○ 已埋",
            "triggered": "→ 触发",
            "resolved": "✓ 回收",
            "abandoned": "✕ 废弃"
        }.get(node["status"], node["status"])

        print(f"  {node_id:8s} {node['name'][:18]:20s} "
              f"{node['type']:8s} {status_icon:8s} "
              f"第{node['planted_chapter']:2d}章 "
              f"{'第' + str(node['target_chapter']) + '章' if node.get('target_chapter') else '--':6s} "
              f"{'第' + str(node['resolved_chapter']) + '章' if node.get('resolved_chapter') else '--':6s}")

    print()


def interactive_add(dag: ForeshadowingDAG) -> None:
    """交互式添加伏笔"""
    print("\n  添加新伏笔")
    print("  " + "-" * 40)

    name = input("  伏笔名称: ").strip()
    if not name:
        print("  已取消")
        return

    ftype = input("  类型 (设定型/情节型/人物型) [情节型]: ").strip() or "情节型"
    desc = input("  描述: ").strip()
    planted = int(input("  埋设章节: ").strip() or "1")
    target = input("  目标回收章节 (可选): ").strip()
    target = int(target) if target else None
    deps = input("  依赖的伏笔 ID (逗号分隔, 可选): ").strip()
    deps = [d.strip() for d in deps.split(",") if d.strip()] if deps else []
    trigger = input("  触发条件 (可选): ").strip()
    priority = input("  优先级 (high/medium/low) [medium]: ").strip() or "medium"

    node_id = dag.add_node(name, ftype, desc, planted, target, deps, trigger, priority)
    print(f"\n  ✓ 伏笔已添加: {node_id} — {name}\n")


def main():
    if len(sys.argv) < 2:
        print("用法: python foreshadowing_dag.py <书籍目录> [命令]")
        print()
        print("命令:")
        print("  list     - 列出所有伏笔")
        print("  stats    - 显示统计数据")
        print("  add      - 交互式添加伏笔")
        print("  overdue  - 列出逾期伏笔")
        print("  dormant  - 列出闲置伏笔")
        print("  graph    - 生成 Mermaid 图")
        print("  check    - 完整性检查")
        print("  scan     - 扫描章节中的伏笔标记")
        print()
        print("示例:")
        print("  python foreshadowing_dag.py 章节正文/我的小说 stats")
        print("  python foreshadowing_dag.py 章节正文/我的小说 overdue")
        print("  python foreshadowing_dag.py 章节正文/我的小说 graph > 伏笔关系图.md")
        sys.exit(1)

    book_dir = sys.argv[1]
    command = sys.argv[2] if len(sys.argv) > 2 else "stats"

    if not os.path.isdir(book_dir):
        print(f"错误: 目录不存在 — {book_dir}")
        sys.exit(1)

    dag = ForeshadowingDAG(book_dir)

    commands = {
        "list": lambda: print_list(dag),
        "stats": lambda: print_stats(dag),
        "add": lambda: interactive_add(dag),
        "overdue": lambda: [print(f"  {o['id']}: {o['name']} (逾期 {o['chapters_overdue']} 章)")
                             for o in dag.find_overdue()] or print("  ✓ 无逾期伏笔"),
        "dormant": lambda: [print(f"  {d['id']}: {d['name']} (闲置 {d['chapters_since']} 章)")
                            for d in dag.find_dormant()] or print("  ✓ 无闲置伏笔"),
        "graph": lambda: print(dag.generate_mermaid()),
        "check": lambda: _run_check(dag),
        "scan": lambda: _run_scan(dag),
    }

    if command in commands:
        commands[command]()
    else:
        print(f"未知命令: {command}")
        print(f"可用: {', '.join(commands.keys())}")
        sys.exit(1)


def _run_check(dag: ForeshadowingDAG) -> None:
    """完整性检查"""
    stats = dag.get_stats()
    print(f"\n{'=' * 50}")
    print("  🔮 伏笔完整性检查")
    print(f"{'=' * 50}")

    all_ok = True

    if stats["overdue_count"] > 0:
        all_ok = False
        print(f"  ❌ 逾期伏笔: {stats['overdue_count']} 个")

    if stats["cycle_count"] > 0:
        all_ok = False
        print(f"  ❌ 循环依赖: {stats['cycle_count']} 处")

    if stats["orphan_count"] > 0:
        print(f"  ⚠ 孤立伏笔: {stats['orphan_count']} 个")

    if stats["recovery_rate"] < 50:
        print(f"  ⚠ 回收率偏低: {stats['recovery_rate']}%")

    if all_ok:
        print("  ✓ 伏笔系统健康")

    print()


def _run_scan(dag: ForeshadowingDAG) -> None:
    """扫描章节中的伏笔标记"""
    print(f"\n  扫描章节中的伏笔标记...\n")
    chapters = sorted(dag.book_dir.glob("第*章*.md"))
    total_found = 0

    for ch_file in chapters:
        findings = dag.scan_chapter(ch_file)
        if findings:
            ch_num = findings[0]["chapter"]
            print(f"  第{ch_num}章 ({len(findings)} 处):")
            for f in findings:
                print(f"    行 {f['line']:4d}: {f['text'][:55]}")
                total_found += 1

    if total_found == 0:
        print("  未发现伏笔标记")
    else:
        print(f"\n  共发现 {total_found} 处伏笔标记")
        print("  提示: 使用 'add' 命令手动添加到 DAG")


if __name__ == "__main__":
    main()
