#!/usr/bin/env bash
# L1-14: novel foreshadowing_dag 伏笔 DAG 单元测试
# 直接驱动 ForeshadowingDAG 类，验证核心能力：
#   1. add_node CRUD + ID 自增 + depends_on 边
#   2. resolve / trigger / abandon 状态流转
#   3. find_overdue 逾期检出（正负向）
#   4. find_dormant 闲置检出（正负向）
#   5. find_circular_dependencies 循环依赖检出（正负向）
#   6. find_orphans 孤立节点检出（正负向）
#   7. get_stats 统计 + recovery_rate
#   8. generate_mermaid 图结构
#   9. scan_chapter 章节伏笔标记扫描
#  10. MEMORY.md 自动导入
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- 通用：跑一段 python 断言脚本 ----
run_py() {
  # $1 = 断言名；$2 = python 代码（退出码 0 为 PASS）
  local name="$1" code="$2"
  if TMP_DIR="$TMP_DIR" python - "$code" <<'PYEOF' 2>&1
import sys, os
sys.path.insert(0, "scripts/novel")
code = sys.argv[1]
exec(compile(code, "<test>", "exec"))
PYEOF
  then
    echo "  [PASS] $name"
  else
    echo "  [FAIL] $name"
    FAILED=$((FAILED + 1))
  fi
}

# ---- fixture：建一个带节点的 DAG 目录 ----
# 每个断言用独立书目录（BOOK=book-N），避免 foreshadowing_dag.json 跨断言累积
mkdir -p "$TMP_DIR/book"
# 章节文件让 meta.total_chapters = 5
for n in 1 3 5 8 12; do printf '# 第%s章\n\n正文内容。\n' "$n" > "$TMP_DIR/book/第${n}章_测试.md"; done

run_py "add_node CRUD + ID 自增 + 依赖边" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-1")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
b = d.add_node("身世", "人物型", "身世伏笔", 3, 8, depends_on=[a])
assert a == "FS-001" and b == "FS-002", (a, b)
assert d.dag["nodes"]["FS-002"]["depends_on"] == ["FS-001"]
assert "FS-002" in d.dag["nodes"]["FS-001"]["required_by"]
assert d.dag["nodes"]["FS-001"]["status"] == "buried"
assert d.dag["meta"]["total_chapters"] == 5, d.dag["meta"]
print("  [PASS] add_node 创建/ID/依赖边正确")
'

run_py "resolve/trigger/abandon 状态流转" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-2")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
d.trigger_node(a)
assert d.dag["nodes"][a]["status"] == "triggered"
d.resolve_node(a, 5, "在第五章回收")
assert d.dag["nodes"][a]["status"] == "resolved"
assert d.dag["nodes"][a]["resolved_chapter"] == 5
b = d.add_node("身世", "人物型", "身世伏笔", 3, 8)
d.abandon_node(b, "大纲调整")
assert d.dag["nodes"][b]["status"] == "abandoned"
assert "废弃原因" in d.dag["nodes"][b]["description"]
assert d.resolve_node("FS-999", 9) is False
assert d.trigger_node("FS-999") is False
print("  [PASS] 状态流转正确")
'

# ---- 逾期：current=12 章 > 目标 5 章 → 逾期 7 章；目标 12 章 → 不逾期 ----
run_py "find_overdue 逾期检出（正负向）" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-3")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
# 补到 13 章，让 current=13
for n in [6, 7, 9, 10, 11, 12, 13]:
    open(os.path.join(book, "第{}章_补.md".format(n)), "w", encoding="utf-8").write("# 第{}章\n\n正文\n".format(n))
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
d.add_node("身世", "人物型", "身世伏笔", 3, 12)
d.add_node("无目标", "设定型", "无目标回收", 1)
overdue = d.find_overdue()
assert len(overdue) == 1, overdue
assert overdue[0]["id"] == "FS-001"
assert overdue[0]["chapters_overdue"] == 7, overdue[0]
# 已回收的不算逾期
d.resolve_node(a, 6)
assert d.find_overdue() == []
print("  [PASS] overdue 检出/排除正确")
'

# ---- 闲置：埋设 1 章，当前 13 章 → 闲置 12 章 > 阈值 3 ----
run_py "find_dormant 闲置检出（正负向）" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-4")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
for n in [6, 7, 9, 10, 11, 12, 13]:
    open(os.path.join(book, "第{}章_补.md".format(n)), "w", encoding="utf-8").write("# 第{}章\n\n正文\n".format(n))
d = ForeshadowingDAG(book)
d.add_node("信物", "情节型", "信物埋设", 1, 5)
d.add_node("近期", "情节型", "近期埋设", 11, 12)
dormant = d.find_dormant()
assert len(dormant) == 1, dormant
assert dormant[0]["id"] == "FS-001"
assert dormant[0]["chapters_since"] == 11
print("  [PASS] dormant 检出/排除正确")
'

# ---- 循环依赖：FS-002 依赖 FS-001，FS-001 再依赖 FS-002 ----
run_py "find_circular_dependencies 循环检出（正负向）" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-5")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
b = d.add_node("身世", "人物型", "身世伏笔", 3, 8, depends_on=[a])
d.add_node("独立", "设定型", "独立伏笔", 1)
assert d.find_circular_dependencies() == []
# 手动制造环：FS-001 也依赖 FS-002
d.dag["nodes"][a]["depends_on"].append(b)
cycles = d.find_circular_dependencies()
assert any(a in c and b in c for c in cycles), cycles
print("  [PASS] 循环依赖检出/不误报正确")
'

# ---- 孤立：无依赖无被依赖 ----
run_py "find_orphans 孤立节点检出（正负向）" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-6")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
d.add_node("身世", "人物型", "身世伏笔", 3, 8, depends_on=[a])
d.add_node("孤悬", "设定型", "孤立伏笔", 1)
orphans = d.find_orphans()
assert orphans == ["FS-003"], orphans
print("  [PASS] orphans 检出/排除正确")
'

# ---- get_stats ----
run_py "get_stats 统计 + recovery_rate" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-7")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
d.resolve_node(a, 5)
d.add_node("身世", "人物型", "身世伏笔", 3, 3)
d.add_node("孤悬", "设定型", "孤立伏笔", 1)
s = d.get_stats()
assert s["total"] == 3
assert s["resolved"] == 1
assert s["recovery_rate"] == 33.3, s["recovery_rate"]
assert s["orphan_count"] >= 1
assert s["overdue_count"] == 1, s["overdue"]
print("  [PASS] stats 统计正确: recovery_rate={}".format(s["recovery_rate"]))
'

# ---- mermaid ----
run_py "generate_mermaid 图结构" '
import os, shutil
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-8")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
a = d.add_node("信物", "情节型", "信物埋设", 1, 5)
d.add_node("身世", "人物型", "身世伏笔", 3, 8, depends_on=[a])
g = d.generate_mermaid()
assert g.startswith("```mermaid") and g.rstrip().endswith("```")
assert "graph TD" in g
assert "FS-001" in g and "FS-002" in g
assert "FS-002 ==> FS-001" in g, g
assert "目标第5章" in g
print("  [PASS] mermaid 结构/边/目标正确")
'

# ---- scan_chapter ----
run_py "scan_chapter 伏笔标记扫描" '
import os, shutil
from pathlib import Path
from foreshadowing_dag import ForeshadowingDAG
book = os.path.join(os.environ["TMP_DIR"], "book-9")
shutil.copytree(os.path.join(os.environ["TMP_DIR"], "book"), book)
d = ForeshadowingDAG(book)
p = os.path.join(os.environ["TMP_DIR"], "第3章_扫描.md")
with open(p, "w", encoding="utf-8") as f:
    f.write("# 第一章\n\n伏笔：师父的旧鞋\n\n为后文的身世之谜铺垫\n\n普通叙述行\n")
findings = d.scan_chapter(Path(p))
assert len(findings) == 2, findings
assert all(f["chapter"] == 3 for f in findings)
assert "伏笔" in findings[0]["text"]
# 不存在文件返回空
assert d.scan_chapter(Path(p + ".none")) == []
print("  [PASS] 扫描检出 {} 处伏笔标记".format(len(findings)))
'

# ---- MEMORY.md 自动导入 ----
run_py "MEMORY.md 自动导入" '
import os
from pathlib import Path
from foreshadowing_dag import ForeshadowingDAG
book = Path(os.environ["TMP_DIR"]) / "book2"
book.mkdir()
for n in [1, 2, 3]:
    (book / "第{}章_测试.md".format(n)).write_text("# 第{}章\n\n正文\n".format(n), encoding="utf-8")
(book / "MEMORY.md").write_text(
    "# 记忆\n\n## 伏笔\n\n| 伏笔名 | 类型 | 埋设章 | 状态 |\n|---|---|---|---|\n"
    "| 师父的旧鞋 | 情节型 | 第2章 | 待回收 |\n", encoding="utf-8")
d = ForeshadowingDAG(str(book))
assert len(d.dag["nodes"]) == 1, d.dag["nodes"]
node = d.dag["nodes"]["FS-001"]
assert node["name"] == "师父的旧鞋"
assert node["status"] == "buried"
assert d.dag_file.exists()
print("  [PASS] MEMORY 自动导入 1 个伏笔")
'

echo ""
echo "==> L1-14 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
