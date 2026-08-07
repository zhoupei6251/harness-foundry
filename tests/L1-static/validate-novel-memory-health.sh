#!/usr/bin/env bash
# L1-15: novel_memory_health 记忆健康度单元测试
# 直接驱动 MemoryHealth / 解析 / 分析函数，验证：
#   1. health_score 扣分逻辑（沉默角色 >5 章扣 5 / >10 章扣 10）
#   2. health_score 边界 clamp（0-100）
#   3. health_level 分级
#   4. parse_characters_from_memory 角色解析 + 出场检测
#   5. parse_foreshadows_from_memory 伏笔解析
#   6. analyze_issues 沉默角色 / 逾期伏笔
#   7. analyze_issues 章节摘要缺失 / 设定检查
#   8. scan_book 集成（章节数 / 字数 / 报告结构）
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- 通用：跑一段 python 断言脚本 ----
run_py() {
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

# ---- fixture：一个模拟书籍目录（文件名/章节/MEMORY 格式匹配脚本解析规则） ----
mkdir -p "$TMP_DIR/healthbook"
cat > "$TMP_DIR/healthbook/第1章_开场.md" <<'EOF'
# 第一章 开场

林风推开木门，屋里坐着师父。师父把一封信推到他面前，说：去城里走一趟。
EOF
cat > "$TMP_DIR/healthbook/第2章_出发.md" <<'EOF'
# 第二章 出发

林风收拾好行囊，路过集市时买了干粮。他想起师父的叮嘱，把信贴身收好。
EOF
cat > "$TMP_DIR/healthbook/第3章_抵达.md" <<'EOF'
# 第三章 抵达

林风到了城里，在客栈住下。掌柜的打量他片刻，问：可是林家的后生？
EOF
cat > "$TMP_DIR/healthbook/MEMORY.md" <<'EOF'
# 记忆库

## 人物设定

### 主角: 林风
少年剑客，性格沉稳。

### 配角: 师父
隐居山中的老剑客。

## 伏笔

| 伏笔ID | 内容 | 埋设章 | 状态 | 回收章 |
|---|---|---|---|---|
| FP-001 | 师父的旧信 | 第1章 | buried | 第5章 |
| FP-002 | 客栈暗号 | 第3章 | buried | 第4章 |
EOF

# 断言 1: health_score 扣分 + clamp
run_py "health_score 扣分（沉默角色 11 章→-10）" '
from novel_memory_health import MemoryHealth, Character, Foreshadowing
h = MemoryHealth(total_chapters=15)
h.characters.append(Character(name="林风", first_appearance=1, last_appearance=4, importance="main"))
h.characters.append(Character(name="师父", first_appearance=1, last_appearance=2, importance="supporting"))
h.characters.append(Character(name="路人", first_appearance=1, last_appearance=14, importance="minor"))
assert h.health_score == 80, h.health_score  # main 扣 10 + supporting 扣 10
# 阈值边界：gap=6 扣 5
h2 = MemoryHealth(total_chapters=7)
h2.characters.append(Character(name="林风", first_appearance=1, last_appearance=1, importance="main"))
assert h2.health_score == 95, h2.health_score
# 伏笔：gap>10 扣 10
h.foreshadows.append(Foreshadowing(id="FP-001", planted_chapter=1, status="buried"))
assert h.health_score == 70, h.health_score
print("  [PASS] score={} 扣分正确".format(h.health_score))
'

# 断言 2: 边界 clamp
run_py "health_score clamp 到 [0, 100]" '
from novel_memory_health import MemoryHealth, Character, Foreshadowing
# 大量扣分 → 不低于 0
h = MemoryHealth(total_chapters=99)
for i in range(15):
    h.characters.append(Character(name="c{}".format(i), first_appearance=1, last_appearance=1, importance="main"))
for i in range(15):
    h.foreshadows.append(Foreshadowing(id="FP-{:03d}".format(i), planted_chapter=1, status="buried"))
assert h.health_score == 0, h.health_score
# 空数据 → 满分
empty = MemoryHealth()
assert empty.health_score == 100
print("  [PASS] clamp 正确: 0 / 100")
'

# 断言 3: health_level 分级
run_py "health_level 分级" '
from novel_memory_health import MemoryHealth, Character
# 空数据 → 健康
assert MemoryHealth().health_level == "🟢 健康"
# 3 个 main 角色各 gap=9 → 各扣 5 → 85 → 健康（>=80）
h = MemoryHealth(total_chapters=10)
for n in ["a", "b", "c"]:
    h.characters.append(Character(name=n, last_appearance=1, importance="main"))
assert h.health_score == 85, h.health_score
assert h.health_level == "🟢 健康", h.health_level
# 5 个 main 角色各 gap=9 → 75 → 关注（60-79）
h2 = MemoryHealth(total_chapters=10)
for n in ["a", "b", "c", "d", "e"]:
    h2.characters.append(Character(name=n, last_appearance=1, importance="main"))
assert h2.health_score == 75, h2.health_score
assert h2.health_level == "🟡 关注", h2.health_level
print("  [PASS] 分级正确: 85→{} / 75→{}".format(h.health_level, h2.health_level))
'

# 断言 4: 角色解析 + 出场检测
run_py "parse_characters_from_memory 角色+出场" '
import os
from pathlib import Path
import novel_memory_health as mh
book = Path(os.environ["TMP_DIR"]) / "healthbook"
chapters = []
for f in sorted(book.glob("第*章*.md")):
    ch = mh.parse_chapter_file(f)
    if ch:
        chapters.append(ch)
content = (book / "MEMORY.md").read_text(encoding="utf-8")
chars = mh.parse_characters_from_memory(content, chapters)
assert len(chars) == 2, [c.name for c in chars]
by_name = {c.name: c for c in chars}
assert by_name["林风"].importance == "main"
assert by_name["师父"].importance == "supporting"
assert by_name["林风"].first_appearance == 1
assert by_name["林风"].last_appearance == 3, by_name["林风"]
print("  [PASS] 角色 {} 出场检测正确".format([c.name for c in chars]))
'

# 断言 5: 伏笔解析
run_py "parse_foreshadows_from_memory 伏笔解析" '
import os
from pathlib import Path
from novel_memory_health import parse_foreshadows_from_memory
book = Path(os.environ["TMP_DIR"]) / "healthbook"
content = (book / "MEMORY.md").read_text(encoding="utf-8")
fs_list = parse_foreshadows_from_memory(content)
assert len(fs_list) == 2, [f.id for f in fs_list]
f1 = next(f for f in fs_list if f.id == "FP-001")
assert f1.planted_chapter == 1
assert f1.status == "buried"
assert f1.resolved_chapter == 5
print("  [PASS] 伏笔解析: {} / {}".format(f1.id, f1.description))
'

# 断言 6: analyze_issues 沉默角色 + 逾期伏笔
run_py "analyze_issues 沉默角色与逾期伏笔" '
from novel_memory_health import MemoryHealth, Character, Foreshadowing, analyze_issues
h = MemoryHealth(total_chapters=12)
h.characters.append(Character(name="林风", last_appearance=2, importance="main"))
h.foreshadows.append(Foreshadowing(id="FP-001", description="旧信", planted_chapter=1, status="buried"))
issues = analyze_issues(h, [])
types = [i["type"] for i in issues]
assert "SILENT_CHARACTER" in types, types
assert "OVERDUE_FORESHADOW" in types, types
overdue = next(i for i in issues if i["type"] == "OVERDUE_FORESHADOW")
assert overdue["severity"] == "WARNING"
print("  [PASS] issues: {}".format(types))
'

# 断言 7: analyze_issues 摘要缺失 + 设定检查
run_py "analyze_issues 摘要缺失与设定检查" '
from novel_memory_health import MemoryHealth, analyze_issues
# 无 MEMORY.md（当前目录无）→ MISSING_SUMMARIES
h = MemoryHealth(total_chapters=6)
issues = analyze_issues(h, [])
types = [i["type"] for i in issues]
assert "MISSING_SUMMARIES" in types, types
assert "SETTING_CHECK" in types, types  # >5 章
miss = next(i for i in issues if i["type"] == "MISSING_SUMMARIES")
assert miss["severity"] == "INFO"
# 4 章 → 无设定检查（<=5 不查）
h2 = MemoryHealth(total_chapters=4)
t2 = [i["type"] for i in analyze_issues(h2, [])]
assert "SETTING_CHECK" not in t2  # 4 <= 5
print("  [PASS] 摘要/设定检查正确")
'

# 断言 8: scan_book 集成
run_py "scan_book 集成（章节/字数/报告结构）" '
import os, io, contextlib
from pathlib import Path
from novel_memory_health import scan_book, print_report
book = Path(os.environ["TMP_DIR"]) / "healthbook"
h = scan_book(book)
assert h.total_chapters == 3, h.total_chapters
assert h.total_words > 50, h.total_words
assert len(h.characters) == 2, len(h.characters)
assert len(h.foreshadows) == 2, len(h.foreshadows)
# 报告可打印（print_report 冒烟，包含书名）
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    print_report(h)
assert "healthbook" in buf.getvalue()
print("  [PASS] scan_book: {} 章 {} 字 {} 角色".format(h.total_chapters, h.total_words, len(h.characters)))
'

echo ""
echo "==> L1-15 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
