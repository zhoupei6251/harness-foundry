#!/usr/bin/env bash
# L1-13: novel mechanical_scorer 机械评分器单元测试
# 直接驱动 MechanicalScorer 类 + CLI --json 冒烟，验证核心检查：
#   1. AI 高频词扫描（AI-001 眼中闪过一丝 / AI-002 嘴角勾起一抹）→ WARN
#   2. 好章节无 AI 命中 → 不误报
#   3. 字数严重不足 → WC-001 BLOCK + 处理决定 BLOCK
#   4. run_all 报告结构（score / verdict / findings_count）
#   5. CLI --json 集成可用
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- fixture：坏章节（AI 高频词 + 字数不足）----
cat > "$TMP_DIR/bad-chapter.md" <<'EOF'
# 第一章 初入江湖

林风的眼中闪过一丝光芒。他深吸一口气，嘴角勾起一抹微笑。

就在这时，他看见山路上走来一个人影。那人仿佛从雾中走出，似乎已经等了很久。

林风心中一动，不由得握紧了剑柄。
EOF

# ---- fixture：好章节（无 AI 词、篇幅足）----
cat > "$TMP_DIR/good-chapter.md" <<'EOF'
# 第一章 初入江湖

林风站在山门前，数着脚下的青石板。第七块石板缺了一角，裂痕里夹着半片枯叶，像是有人刻意留下的标记。

他蹲下身，指尖沿着裂纹摸过去。石缝深处，一道细痕笔直地指向东侧崖壁。崖壁下堆着几捆柴，压着一只破旧的布鞋——那是师父的旧鞋，林风认得鞋底的补丁。

山风从谷口灌进来，卷起他衣摆。他直起身，向崖壁走去。柴堆后露出一条窄道，被灌木遮得严实。若不是那半片枯叶，他绝不会多看一眼。

窄道尽头是一扇石门，门上刻着三行字，前两行已被青苔盖住。林风伸手擦去青苔，第三行字露出来：勿要回头。

他回头看了一眼来路。山门处，师兄弟们的笑声隐约传来。他又看向石门，掌心贴在石面上，轻轻一推，门开了。
EOF

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

# 断言 1: 坏章节命中 AI 高频词
run_py "AI 高频词被检出（AI-001/AI-002）" '
import os
from mechanical_scorer import MechanicalScorer
p = os.path.join(os.environ["TMP_DIR"], "bad-chapter.md")
s = MechanicalScorer(p)
r = s.run_all()
ids = [f["check_id"] for f in r["findings"]]
assert "AI-001" in ids, f"AI-001 未触发: {ids}"
assert "AI-002" in ids, f"AI-002 未触发: {ids}"
ai = [f for f in r["findings"] if f["check_id"].startswith("AI-")]
assert all(f["severity"] == "WARN" for f in ai), "AI 命中应为 WARN"
print("  [PASS] AI-001/AI-002 触发且为 WARN")
'

# 断言 2: 好章节无 AI 命中
run_py "好章节 AI 0 命中（不误报）" '
import os
from mechanical_scorer import MechanicalScorer
p = os.path.join(os.environ["TMP_DIR"], "good-chapter.md")
s = MechanicalScorer(p)
r = s.run_all()
ids = [f["check_id"] for f in r["findings"]]
ai = [i for i in ids if i.startswith("AI-")]
assert not ai, f"好章节误报 AI: {ai}"
print("  [PASS] 好章节 AI 0 命中")
'

# 断言 3: 坏章节字数不足 → WC-001 BLOCK
run_py "字数不足 → WC-001 BLOCK" '
import os
from mechanical_scorer import MechanicalScorer
p = os.path.join(os.environ["TMP_DIR"], "bad-chapter.md")
s = MechanicalScorer(p)
r = s.run_all()
ids = [f["check_id"] for f in r["findings"]]
assert "WC-001" in ids, f"WC-001 未触发: {ids}"
wc = next(f for f in r["findings"] if f["check_id"] == "WC-001")
assert wc["severity"] == "BLOCK"
print("  [PASS] WC-001 触发且为 BLOCK")
'

# 断言 4: 处理决定随 BLOCK 置为拒绝
run_py "有 BLOCK → 处理决定为 BLOCK" '
import os
from mechanical_scorer import MechanicalScorer
p = os.path.join(os.environ["TMP_DIR"], "bad-chapter.md")
s = MechanicalScorer(p)
r = s.run_all()
assert r["processing"]["decision"] == "BLOCK", r["processing"]["decision"]
assert r["findings_count"]["block"] >= 1
print("  [PASS] processing=BLOCK，block 计数 >= 1")
'

# 断言 5: 好章节无 BLOCK（用生成的长文本验证 ≥500 字门槛）
run_py "好章节无 BLOCK" '
import os
from mechanical_scorer import MechanicalScorer
p = os.path.join(os.environ["TMP_DIR"], "good-long.md")
body = "\n\n".join(
    "山道蜿蜒，林风数着沿途的石碑前行。碑上刻着陌生的名字，风把苔藓吹开一角，他停下来，把碑文抄进册子里。"
    for _ in range(30)
)
open(p, "w", encoding="utf-8").write("# 第一章 山道\n\n" + body)
s = MechanicalScorer(p)
r = s.run_all()
assert r["findings_count"]["block"] == 0, [f for f in r["findings"] if f["severity"] == "BLOCK"]
print("  [PASS] 长章节 block=0")
'

# 断言 6: 报告结构完整（score/verdict/stats）
run_py "报告结构完整" '
import os
from mechanical_scorer import MechanicalScorer
p = os.path.join(os.environ["TMP_DIR"], "good-chapter.md")
s = MechanicalScorer(p)
r = s.run_all()
assert 0 <= r["score"] <= 100, r["score"]
assert isinstance(r["stats"].get("char_count"), int)
assert r["max_score"] == 100
print("  [PASS] score={} char_count={}".format(r["score"], r["stats"]["char_count"]))
'

# 断言 7: CLI --json 集成可用
# 注意：heredoc 内嵌 if 条件时，`; then` 会被吞进 heredoc 内容，then 必须另起一行；
#       python 从环境变量取路径（heredoc 内容不做变量展开）
echo "==> L1-13: CLI --json 集成"
if python scripts/novel/mechanical_scorer.py "$TMP_DIR/good-chapter.md" --json > "$TMP_DIR/cli.json" 2>&1
then
  if TMP_DIR="$TMP_DIR" python - > "$TMP_DIR/cli-check.txt" 2>&1 <<PYEOF
import json, os
r = json.load(open(os.path.join(os.environ["TMP_DIR"], "cli.json"), encoding="utf-8"))
assert r["meta"]["tool"] == "novel-mechanical-scorer"
assert "score" in r
print("  [PASS] CLI --json 输出合法 JSON")
PYEOF
  then
    cat "$TMP_DIR/cli-check.txt"
  else
    echo "  [FAIL] CLI --json 输出非法"
    cat "$TMP_DIR/cli-check.txt"
    FAILED=$((FAILED + 1))
  fi
else
  echo "  [FAIL] CLI --json 退出码非 0"
  cat "$TMP_DIR/cli.json"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "==> L1-13 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
