#!/usr/bin/env bash
# L1-19: novel_metrics 写作指标单元测试
# 直接驱动 BookMetrics / 解析 / 生成函数，验证：
#   1. BookMetrics 属性（completed/total_words/avg_score/first_pass_rate/avg_rework）
#   2. parse_chapter_file 章节解析
#   3. parse_memory_file 已完成章节提取
#   4. scan_book_directory 集成（章节排序 + 计划值）
#   5. generate_dashboard 内容
#   6. generate_weekly_report 结构
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- fixture：书籍目录 ----
mkdir -p "$TMP_DIR/metricbook"
cat > "$TMP_DIR/metricbook/第2章_中途.md" <<'EOF'
# 第二章 中途

林风走在官道上，远处传来马蹄声。
EOF
cat > "$TMP_DIR/metricbook/第1章_开场.md" <<'EOF'
# 第一章 开场

林风推开木门，屋里坐着师父。
EOF
cat > "$TMP_DIR/metricbook/MEMORY.md" <<'EOF'
# 记忆库

| 书名 | 剑起云州 |
| 题材 | 仙侠 |

| 章节 | 状态 | 标题 | 字数 |
|---|---|---|---|
| 第1章 | ✓ | 开场 | 1200 |
| 第2章 | ✓ | 中途 | 1500 |
EOF

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

# 断言 1: BookMetrics 属性
run_py "BookMetrics 属性计算" '
from novel_metrics import BookMetrics, Chapter
m = BookMetrics(book_name="测试")
m.chapters = [
    Chapter(num=1, title="a", file_path="", word_count=100, review_score=8.0, review_status="passed", rework_count=0),
    Chapter(num=2, title="b", file_path="", word_count=200, review_score=6.0, review_status="failed", rework_count=2),
    Chapter(num=3, title="c", file_path="", word_count=0, review_score=0.0),
]
assert m.completed_chapters == 2  # word_count>0
assert m.total_words_written == 300
assert m.avg_score == 7.0  # (8+6)/2
assert m.first_pass_rate == 50.0  # 1/2 通过
assert m.avg_rework_count == 1.0  # (0+2)/2
# 空数据 → 0
e = BookMetrics(book_name="empty")
assert e.completed_chapters == 0 and e.avg_score == 0.0 and e.first_pass_rate == 0.0
print("  [PASS] 属性: {}章 {}字 avg={} rate={}%".format(m.completed_chapters, m.total_words_written, m.avg_score, m.first_pass_rate))
'

# 断言 2: 章节解析
run_py "parse_chapter_file 解析" '
import os
from pathlib import Path
from novel_metrics import parse_chapter_file
book = Path(os.environ["TMP_DIR"]) / "metricbook"
ch = parse_chapter_file(book / "第2章_中途.md")
assert ch.num == 2 and ch.title == "中途"
assert ch.word_count > 0
print("  [PASS] 解析: 第{}章 {} 字".format(ch.num, ch.word_count))
'

# 断言 3: 已完成章节提取
run_py "parse_memory_file 已完成章节" '
import os
from pathlib import Path
from novel_metrics import parse_memory_file
book = Path(os.environ["TMP_DIR"]) / "metricbook"
data = parse_memory_file(book / "MEMORY.md")
assert data["book_name"] == "剑起云州"
assert data["genre"] == "仙侠"
assert data["completed_chapters"] == [1, 2], data["completed_chapters"]
# 缺失文件 → {}
assert parse_memory_file(book / "NOPE.md") == {}
print("  [PASS] 已完成章节: {}".format(data["completed_chapters"]))
'

# 断言 4: scan_book_directory 集成
run_py "scan_book_directory 集成" '
import os
from pathlib import Path
from novel_metrics import scan_book_directory
book = Path(os.environ["TMP_DIR"]) / "metricbook"
m = scan_book_directory(book)
assert m.book_name == "metricbook"
assert [c.num for c in m.chapters] == [1, 2]
assert m.total_chapters_planned == 4, m.total_chapters_planned  # len(chapters)*2
assert m.total_words_planned == 12000, m.total_words_planned  # 4*3000
print("  [PASS] 扫描: {} 章 计划 {} 章".format(len(m.chapters), m.total_chapters_planned))
'

# 断言 5: generate_dashboard
run_py "generate_dashboard 内容" '
import os
from pathlib import Path
from novel_metrics import scan_book_directory, generate_dashboard
book = Path(os.environ["TMP_DIR"]) / "metricbook"
m = scan_book_directory(book)
out = generate_dashboard(m)
assert "metricbook" in out
assert "进度" in out and "字数" in out and "质量" in out
assert "第 1章" in out or "第1章" in out  # 章节行（宽度填充后可能带空格）
assert "开场" in out  # 章节标题
print("  [PASS] dashboard 含进度/字数/质量")
'

# 断言 6: generate_weekly_report
run_py "generate_weekly_report 结构" '
import os
from pathlib import Path
from novel_metrics import scan_book_directory, generate_weekly_report
book = Path(os.environ["TMP_DIR"]) / "metricbook"
m = scan_book_directory(book)
out = generate_weekly_report(m)
assert "# " in out  # 标题
assert "写作报告" in out
assert "本周概况" in out
assert "质量趋势" in out
assert "下周计划" in out
assert "问题与改进" in out
print("  [PASS] 周报结构完整")
'

echo ""
echo "==> L1-19 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
