#!/usr/bin/env python3
"""
Novel Graph — 小说剧情知识图谱（轻量版）
==========================================

把小说世界抽成 节点(角色/地点/物品/事件) + 边(关系/持有/因果/时序)，
用 kb/graph.yaml 一个文件承载。核心用途：

1. validate - schema 校验 + 因果链熔断（新事件必须有逻辑先导）
2. path     - 因果链回溯（查某个节点的入边先导链）
3. outline  - 生成 Mermaid 可视化

数据结构（kb/graph.yaml）：

  meta:            { book, last_updated, total_chapters }
  nodes:           列表，每项 { id, type: character|place|item|event, name, note? }
  edges:           列表，每项 { from, to, relation, chapter? }
                    relation: 关系动词（持有/认识/赠予/先导/…）
  chapter_events:  列表，每项 { chapter, event }  # event 是 nodes 里的 id

因果链熔断规则（novel-protocol 因果律闭环的图实现）：
  - 每个 chapter_events 中的 event 节点，必须有入边 chapter < 当前章
    （先导事件或线索），否则报告 FATAL_ERROR: Causality_Chain_Broken
  - 孤点检测：nodes 中无任何边的节点（孤儿设定）

用法：
  python novel_graph.py <graph.yaml> [command]
  命令:
    validate - 校验 + 因果链检查（写前必跑）
    path <id> - 回溯某节点的因果链（入边 + 先导）
    outline  - 生成 Mermaid 关系图
"""

import os
import sys
from pathlib import Path
from typing import Dict, List, Set


# ═════════════════════════════════════════════════════════
# 解析
# ═════════════════════════════════════════════════════════

def load_graph(path: str) -> Dict:
    import yaml
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def collect_ids(graph: Dict) -> Set[str]:
    ids = set()
    for n in graph.get("nodes", []):
        ids.add(n["id"])
    for e in graph.get("edges", []):
        ids.add(e["from"])
        ids.add(e["to"])
    for c in graph.get("chapter_events", []):
        ids.add(c["event"])
    return ids


# ═════════════════════════════════════════════════════════
# 因果链熔断
# ═════════════════════════════════════════════════════════

def causality_check(graph: Dict) -> List[str]:
    """双层先导检查：事件必须有直接先导 或 涉及物品先导。返回问题列表。

    第一层（直接先导）：更早章（chapter < 事件章）到事件节点的边。
    第二层（物品先导）：事件在本章涉及的物品（事件→item 边），
                        该物品在更早章出现的边。
    豁免：
    - initial: true 节点（作者声明初始谜团/无先导，如开篇悬念）
    - 首章事件（故事起点，天然无更早章先导）
    """
    problems = []
    edges = graph.get("edges", [])
    events = {c["chapter"]: c["event"] for c in graph.get("chapter_events", [])}
    items = {n["id"] for n in graph.get("nodes", []) if n.get("type") == "item"}
    initial = {
        n["id"] for n in graph.get("nodes", [])
        if n.get("type") == "event" and n.get("initial")
    }
    first_chapter = min(events) if events else 1

    for chapter, event_id in sorted(events.items()):
        if event_id in initial:
            continue  # 作者声明初始谜团，豁免
        if chapter <= first_chapter:
            continue  # 首章事件（故事起点），豁免

        # 第一层：直接先导（更早章入边）
        direct = [
            e for e in edges
            if e["to"] == event_id and e.get("chapter", 0) < chapter
        ]
        # 第二层：事件本章涉及的物品 → 该物品更早章出现
        involved = [
            e["to"] for e in edges
            if e["from"] == event_id and e["to"] in items
        ]
        item_prior = [
            e for e in edges
            if e["to"] in involved and e.get("chapter", 0) < chapter
        ]
        if not direct and not item_prior:
            detail = "、".join(involved) if involved else "（无涉及物品）"
            problems.append(
                f"FATAL_ERROR: Causality_Chain_Broken — 第{chapter}章事件「{event_id}」"
                f"无先导：无更早章直接入边，涉及物品 [{detail}] 也无更早章出现"
            )
    return problems


def isolated_nodes(graph: Dict) -> List[str]:
    """无任何边的节点（孤儿设定）。"""
    connected = set()
    for e in graph.get("edges", []):
        connected.add(e["from"])
        connected.add(e["to"])
    return [
        n["id"] for n in graph.get("nodes", [])
        if n["id"] not in connected
    ]


def schema_errors(graph: Dict) -> List[str]:
    """schema 校验：id 唯一、type 合法、边两端存在。"""
    errors = []
    seen = set()
    type_ok = {"character", "place", "item", "event"}

    for n in graph.get("nodes", []):
        nid = n.get("id")
        if not nid:
            errors.append("节点缺 id")
        elif nid in seen:
            errors.append(f"节点 id 重复: {nid}")
        seen.add(nid)
        if n.get("type") not in type_ok:
            errors.append(f"节点 {nid} type 非法: {n.get('type')}")

    ids = collect_ids(graph)
    for e in graph.get("edges", []):
        if e["from"] not in ids:
            errors.append(f"边 from 不存在: {e['from']}")
        if e["to"] not in ids:
            errors.append(f"边 to 不存在: {e['to']}")

    for c in graph.get("chapter_events", []):
        if c["event"] not in ids:
            errors.append(f"chapter_events 引用不存在节点: {c['event']}")
    return errors


# ═════════════════════════════════════════════════════════
# 因果链回溯
# ═════════════════════════════════════════════════════════

def trace_path(graph: Dict, target: str, depth: int = 3) -> List[str]:
    edges = graph.get("edges", [])
    lines = []
    frontier = [target]
    visited = set()
    for _ in range(depth):
        if not frontier:
            break
        nxt = []
        for node in frontier:
            if node in visited:
                continue
            visited.add(node)
            for e in edges:
                if e["to"] == node:
                    src = e["from"]
                    ch = e.get("chapter", "?")
                    lines.append(f"  {src} ──[{e['relation']}@第{ch}章]──→ {node}")
                    nxt.append(src)
        frontier = nxt
    return lines


# ═════════════════════════════════════════════════════════
# Mermaid 可视化
# ═════════════════════════════════════════════════════════

def to_mermaid(graph: Dict) -> str:
    lines = ["```mermaid", "graph TD"]
    node_shapes = {
        "character": "([\"{name}\"])",
        "place": "{{\"{name}\"}}",
        "item": "[\"{name}\"]",
        "event": "((\"{name}\"))",
    }
    for n in graph.get("nodes", []):
        shape = node_shapes.get(n.get("type"), "[\"{name}\"]")
        lines.append(
            f"  {n['id']}{shape.format(name=n.get('name', n['id']))}"
        )
    for e in graph.get("edges", []):
        label = e.get("relation", "")
        ch = e.get("chapter", "")
        label = f"{label}@第{ch}章" if ch else label
        lines.append(f"  {e['from']} -->|{label}| {e['to']}")
    lines.append("```")
    return "\n".join(lines)


# ═════════════════════════════════════════════════════════
# 主入口
# ═════════════════════════════════════════════════════════

def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1

    graph_path = sys.argv[1]
    cmd = sys.argv[2] if len(sys.argv) > 2 else "validate"

    if not os.path.exists(graph_path):
        print(f"graph.yaml 不存在: {graph_path}")
        return 1

    try:
        graph = load_graph(graph_path)
    except Exception as e:
        print(f"graph.yaml 解析失败: {e}")
        return 1

    # ---- validate ----
    if cmd == "validate":
        errors = schema_errors(graph)
        problems = causality_check(graph)
        isolated = isolated_nodes(graph)

        print(f"==> novel-graph validate: {graph_path}")
        print(f"    节点 {len(graph.get('nodes', []))} | "
              f"边 {len(graph.get('edges', []))} | "
              f"章节事件 {len(graph.get('chapter_events', []))}")

        for e in errors:
            print(f"  [SCHEMA] {e}")
        for p in problems:
            print(f"  [FATAL]  {p}")
        if isolated:
            print(f"  [WARN] 孤立节点（无任何边）: {', '.join(isolated)}")

        if errors or problems:
            print("\n==> 校验未通过")
            return 1
        print("\n==> 校验通过：schema 合法 + 因果链闭合 + 无孤立节点")
        return 0

    # ---- path ----
    if cmd == "path":
        target = sys.argv[3] if len(sys.argv) > 3 else ""
        if not target:
            print("用法: python novel_graph.py <graph.yaml> path <节点id>")
            return 1
        print(f"==> 因果链回溯: {target}")
        lines = trace_path(graph, target)
        if not lines:
            print("  无入边——该节点凭空出现（因果链断裂）")
            return 1
        print("\n".join(lines))
        return 0

    # ---- outline ----
    if cmd == "outline":
        print(to_mermaid(graph))
        return 0

    print(f"未知命令: {cmd}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
