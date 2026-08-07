#!/usr/bin/env bash
# L1-12: novel continuity_check 连续性引擎单元测试
# 直接驱动 ContinuityChecker 类，用内存 fixture 验证核心判断逻辑：
#   1. 逾期未回收伏笔 → CT-002 CRITICAL（正负向）
#   2. 情节线索闲置过久 → CT-001 WARNING（正负向）
#   3. 时间线倒序 → CT-008 CRITICAL（正负向）
#   4. 已死角色标记活跃 → CT-005 CRITICAL
#   5. run_all 冒烟：verdict 字段存在且合法
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0

# ---- 通用：跑一段 python 断言脚本，输出 [PASS]/[FAIL] ----
run_py() {
  # $1 = 断言名；$2 = python 代码（退出码 0 为 PASS）
  local name="$1" code="$2"
  if python - "$code" <<'PYEOF' 2>&1
import sys
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

# 断言 1: 逾期未回收伏笔（计划第 2 章回收，当前到第 3 章）
# 注意：状态必须不含子串"回收"（check_overdue_threads 排除含"回收"的状态），
#       故用 "○" 而非 "待回收"（"待回收"含"回收"，会被该检查排除）
run_py "逾期未回收伏笔 → CT-002 CRITICAL" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.chapters = [{"number": 1}, {"number": 2}, {"number": 3}]
c.foreshadowings = [{
    "name": "神秘药瓶", "status": "○", "planted_chapter": 1,
    "notes": "计划第2章回收"
}]
c.check_overdue_threads()
ids = [i.check_id for i in c.issues]
assert "CT-002" in ids, f"CT-002 未触发: {ids}"
assert c.issues[0].severity == "CRITICAL"
print("  [PASS] CT-002 触发且 CRITICAL")
'

# 断言 2: 按时回收的伏笔不误报
run_py "按时回收伏笔 → 不误报 CT-002" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.chapters = [{"number": 1}, {"number": 2}]
c.foreshadowings = [{
    "name": "已回收线索", "status": "已回收 ✓", "planted_chapter": 1,
    "notes": "计划第2章回收"
}]
c.check_overdue_threads()
ids = [i.check_id for i in c.issues]
assert "CT-002" not in ids, f"已回收伏笔误报: {ids}"
print("  [PASS] 已回收伏笔 0 误报")
'

# 断言 3: 情节线索闲置超 3 章 → CT-001 WARNING
run_py "情节线索闲置超 3 章 → CT-001 WARNING" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.chapters = [{"number": 1}, {"number": 5}]
c.foreshadowings = [{
    "name": "玉佩", "status": "待回收", "planted_chapter": 1, "notes": ""
}]
c.check_dormant_threads()
ids = [i.check_id for i in c.issues]
assert "CT-001" in ids, f"CT-001 未触发: {ids}"
assert c.issues[0].severity == "WARNING"
print("  [PASS] CT-001 触发且 WARNING")
'

# 断言 4: 刚埋设的线索不误报
run_py "刚埋设线索 → 不误报 CT-001" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.chapters = [{"number": 1}, {"number": 3}]
c.foreshadowings = [{
    "name": "新线索", "status": "待回收", "planted_chapter": 2, "notes": ""
}]
c.check_dormant_threads()
ids = [i.check_id for i in c.issues]
assert "CT-001" not in ids, f"新线索误报: {ids}"
print("  [PASS] 新埋线索 0 误报")
'

# 断言 5: 时间线倒序 → CT-008 CRITICAL
run_py "时间线倒序 → CT-008 CRITICAL" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.timeline_events = [
    {"date": "2026-08-03", "event": "A"},
    {"date": "2026-08-01", "event": "B"},
]
c.check_timeline_order()
ids = [i.check_id for i in c.issues]
assert "CT-008" in ids, f"CT-008 未触发: {ids}"
print("  [PASS] 时间线倒序被检出")
'

# 断言 6: 顺序时间线不误报
run_py "顺序时间线 → 不误报 CT-008" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.timeline_events = [
    {"date": "2026-08-01", "event": "A"},
    {"date": "2026-08-03", "event": "B"},
]
c.check_timeline_order()
assert not c.issues, f"顺序时间线误报: {[i.check_id for i in c.issues]}"
print("  [PASS] 顺序时间线 0 误报")
'

# 断言 7: 已死角色标记活跃 → CT-005 CRITICAL
run_py "已死角色标记活跃 → CT-005 CRITICAL" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
c.characters = {"林风": {"status": "死亡", "notes": "仍活跃于江湖"}}
c.check_dead_characters()
ids = [i.check_id for i in c.issues]
assert "CT-005" in ids, f"CT-005 未触发: {ids}"
print("  [PASS] 死角色活跃矛盾被检出")
'

# 断言 8: run_all 冒烟（缺 MEMORY.md → SYS-001，verdict 合法）
run_py "run_all 冒烟：verdict 合法" '
from continuity_check import ContinuityChecker
c = ContinuityChecker(".")
report = c.run_all()
assert report["verdict"] in ("PASS", "WARNING", "FAIL"), report["verdict"]
assert "issues" in report and "context" in report
assert isinstance(report["issues_count"]["critical"], int)
# 注意：python 代码外层是 bash 单引号字符串——内部不可再出现单引号；
#        f-string 的 {report[...]} 会与 bash 引号解析冲突，改用 .format()
print("  [PASS] verdict={} issues={}".format(report["verdict"], report["issues_count"]["total"]))
'

echo ""
echo "==> L1-12 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
