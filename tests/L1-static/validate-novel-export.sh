#!/usr/bin/env bash
# L1-18: novel_export 多格式导出单元测试
# 直接驱动解析 / 扫描 / 各导出函数，验证：
#   1. parse_chapter_file 章节解析 + 清理（跳 metadata/#）
#   2. scan_chapters 排序（按章号）
#   3. load_metadata 从 MEMORY.md 读书名/题材
#   4. export_json 产物结构（title/total/章节）
#   5. export_fanqie JSONL 行格式
#   6. export_qidian CSV 表头
#   7. export_html index + 章节页
#   8. export_epub zip 结构（mimetype/container/content.opf）
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- fixture：书籍目录 ----
mkdir -p "$TMP_DIR/expbook"
cat > "$TMP_DIR/expbook/第2章_中途.md" <<'EOF'
---
chapter: 2
---
# 第二章 中途

林风走在官道上，远处传来马蹄声。

*一些注记*
EOF
cat > "$TMP_DIR/expbook/第1章_开场.md" <<'EOF'
# 第一章 开场

林风推开木门，屋里坐着师父。
EOF
cat > "$TMP_DIR/expbook/MEMORY.md" <<'EOF'
# 记忆库

| 书名 | 剑起云州 |
| 题材 | 仙侠 |
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

# 断言 1: 章节解析 + 清理
run_py "parse_chapter_file 解析与清理" '
import os
from pathlib import Path
from novel_export import parse_chapter_file
p = Path(os.environ["TMP_DIR"]) / "expbook" / "第2章_中途.md"
ch = parse_chapter_file(p)
assert ch is not None
assert ch.num == 2
assert ch.title == "中途"
assert "---" not in ch.content, ch.content  # frontmatter 分隔符已清理
assert "林风走在官道" in ch.content
assert "注记" not in ch.content, ch.content  # * 行已清理
assert "# 第二章" not in ch.content  # 标题行已清理
assert ch.word_count > 0
# 不合规文件名 → None
bad = Path(os.environ["TMP_DIR"]) / "随便.md"
bad.write_text("无章节名", encoding="utf-8")
assert parse_chapter_file(bad) is None
print("  [PASS] 解析/清理正确: 第{}章 {} 字".format(ch.num, ch.word_count))
'

# 断言 2: scan_chapters 排序
run_py "scan_chapters 按章号排序" '
import os
from pathlib import Path
from novel_export import scan_chapters
book = Path(os.environ["TMP_DIR"]) / "expbook"
chapters = scan_chapters(book)
assert [c.num for c in chapters] == [1, 2], [c.num for c in chapters]
assert chapters[0].title == "开场"
print("  [PASS] 章节排序: {}".format([c.num for c in chapters]))
'

# 断言 3: load_metadata
run_py "load_metadata 从 MEMORY.md" '
import os
from pathlib import Path
from novel_export import load_metadata
book = Path(os.environ["TMP_DIR"]) / "expbook"
md = load_metadata(book)
assert md.title == "剑起云州", md.title
assert md.genre == "仙侠", md.genre
print("  [PASS] 元数据: {} / {}".format(md.title, md.genre))
'

# 断言 4: export_json
run_py "export_json 产物结构" '
import os, json
from pathlib import Path
from novel_export import load_metadata, scan_chapters, export_json
book = Path(os.environ["TMP_DIR"]) / "expbook"
out = Path(os.environ["TMP_DIR"]) / "out.json"
chapters = scan_chapters(book)
export_json(chapters, load_metadata(book), out)
data = json.loads(out.read_text(encoding="utf-8"))
assert data["title"] == "剑起云州"
assert data["total_chapters"] == 2
assert data["chapters"][0]["num"] == 1
assert data["chapters"][0]["word_count"] > 0
assert data["total_words"] == sum(c["word_count"] for c in data["chapters"])
print("  [PASS] JSON 导出: {} 章 {} 字".format(data["total_chapters"], data["total_words"]))
'

# 断言 5: export_fanqie JSONL
run_py "export_fanqie JSONL 行格式" '
import os, json
from pathlib import Path
from novel_export import load_metadata, scan_chapters, export_fanqie
book = Path(os.environ["TMP_DIR"]) / "expbook"
out = Path(os.environ["TMP_DIR"]) / "out.jsonl"
chapters = scan_chapters(book)
export_fanqie(chapters, load_metadata(book), out)
lines = out.read_text(encoding="utf-8").strip().split("\n")
assert len(lines) == 2
first = json.loads(lines[0])
assert first["title"] == "第1章 开场"
assert first["chapter_index"] == 1
assert "content" in first and first["word_count"] > 0
print("  [PASS] 番茄 JSONL: {} 行".format(len(lines)))
'

# 断言 6: export_qidian CSV
run_py "export_qidian CSV 表头" '
import os, csv
from pathlib import Path
from novel_export import load_metadata, scan_chapters, export_qidian
book = Path(os.environ["TMP_DIR"]) / "expbook"
out = Path(os.environ["TMP_DIR"]) / "out.csv"
chapters = scan_chapters(book)
export_qidian(chapters, load_metadata(book), out)
rows = list(csv.reader(out.open(encoding="utf-8")))
assert rows[0] == ["chapter_name", "content", "word_count"], rows[0]
assert rows[1][0] == "第1章 开场"
assert rows[1][2] == str(chapters[0].word_count)
print("  [PASS] 起点 CSV: {} 行".format(len(rows)))
'

# 断言 7: export_html
run_py "export_html index + 章节页" '
import os
from pathlib import Path
from novel_export import load_metadata, scan_chapters, export_html
book = Path(os.environ["TMP_DIR"]) / "expbook"
outdir = Path(os.environ["TMP_DIR"]) / "htmlout"
chapters = scan_chapters(book)
export_html(chapters, load_metadata(book), outdir)
toc = (outdir / "index.html").read_text(encoding="utf-8")
assert "剑起云州" in toc
assert "chapter_1.html" in toc
ch1 = (outdir / "chapter_1.html").read_text(encoding="utf-8")
assert "第1章" in ch1
assert "林风推开木门" in ch1
print("  [PASS] HTML 导出: index + {} 章页".format(len(chapters)))
'

# 断言 8: export_epub zip 结构
run_py "export_epub zip 结构" '
import os, zipfile
from pathlib import Path
from novel_export import load_metadata, scan_chapters, export_epub
book = Path(os.environ["TMP_DIR"]) / "expbook"
out = Path(os.environ["TMP_DIR"]) / "out.epub"
chapters = scan_chapters(book)
export_epub(chapters, load_metadata(book), out)
with zipfile.ZipFile(out) as z:
    names = z.namelist()
    assert "mimetype" in names
    assert "META-INF/container.xml" in names
    assert "OEBPS/content.opf" in names
    assert "OEBPS/chapter1.xhtml" in names
    assert "OEBPS/chapter2.xhtml" in names
    # mimetype 必须第一个且不压缩
    info = z.getinfo("mimetype")
    assert info.compress_type == zipfile.ZIP_STORED
    assert z.read("mimetype") == b"application/epub+zip"
    opf = z.read("OEBPS/content.opf").decode("utf-8")
    assert "剑起云州" in opf
print("  [PASS] EPUB 结构: {} 项".format(len(names)))
'

echo ""
echo "==> L1-18 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
