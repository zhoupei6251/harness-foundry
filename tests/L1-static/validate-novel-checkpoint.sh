#!/usr/bin/env bash
# L1-17: novel_checkpoint 检查点管理器单元测试
# 直接驱动 CheckpointManager，验证：
#   1. create 持久化（checkpoints.json 落盘）
#   2. verify 找到/找不到
#   3. verify 章节文件检查
#   4. verify MEMORY.md 检查
#   5. list_all 倒序 + is_current
#   6. restore 无 commit 拒绝 / 不存在拒绝
#   7. 损坏 JSON 容错（_load_checkpoints）
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- fixture：书籍目录 + 章节文件 ----
mkdir -p "$TMP_DIR/cpbook"
printf '# 第一章\n\n正文\n' > "$TMP_DIR/cpbook/第001章_开场.md"
printf '# 第二章\n\n正文\n' > "$TMP_DIR/cpbook/第002章_出发.md"
printf '# 记忆库\n\n## 上章摘要\n' > "$TMP_DIR/cpbook/MEMORY.md"

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

# 断言 1: create 持久化
run_py "create 持久化到 checkpoints.json" '
import os, json
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
m = CheckpointManager(book)
cp = m.create("v1", chapter="第1章", status="writing", notes="开场完成")
assert cp.name == "v1"
assert cp.chapter == "第1章"
# 文件已落盘
cpf = book / ".checkpoints" / "checkpoints.json"
assert cpf.exists()
data = json.loads(cpf.read_text(encoding="utf-8"))
assert data["checkpoints"][0]["name"] == "v1"
assert data["last_checkpoint"] == "v1"
print("  [PASS] 检查点已持久化")
'

# 断言 2: verify 找到/找不到
run_py "verify 找到与找不到" '
import os
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
m = CheckpointManager(book)
m.create("v1", chapter="第1章")
r = m.verify("v1")
assert r["found"] is True
assert "MEMORY.md" in [c["name"] for c in r["checks"]]
r2 = m.verify("nope")
assert r2["found"] is False
assert "不存在" in r2["error"]
print("  [PASS] verify 找到/找不到正确")
'

# 断言 3: 章节文件检查
run_py "verify 章节文件匹配" '
import os
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
m = CheckpointManager(book)
m.create("v1", chapter="第1章")
r = m.verify("v1")
chk = next(c for c in r["checks"] if c["name"] == "章节文件")
assert chk["status"] == "✓", chk
m.create("v9", chapter="第9章")  # 不存在的章节
r9 = m.verify("v9")
chk9 = next(c for c in r9["checks"] if c["name"] == "章节文件")
assert chk9["status"] == "✗", chk9
print("  [PASS] 章节文件存在/缺失判定正确")
'

# 断言 4: MEMORY.md 检查
run_py "verify MEMORY.md 存在检查" '
import os, shutil
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
m = CheckpointManager(book)
m.create("v1", chapter="第1章")
r = m.verify("v1")
chk = next(c for c in r["checks"] if c["name"] == "MEMORY.md")
assert chk["status"] == "✓"
# 移除 MEMORY.md → ✗
shutil.move(str(book / "MEMORY.md"), str(book / "MEMORY.md.bak"))
r2 = m.verify("v1")
chk2 = next(c for c in r2["checks"] if c["name"] == "MEMORY.md")
assert chk2["status"] == "✗"
shutil.move(str(book / "MEMORY.md.bak"), str(book / "MEMORY.md"))
print("  [PASS] MEMORY.md 存在/缺失判定正确")
'

# 断言 5: list_all + is_current（先清空残留检查点）
run_py "list_all 与 is_current" '
import os, time, shutil
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
cpd = book / ".checkpoints"
if cpd.exists():
    shutil.rmtree(cpd)
m = CheckpointManager(book)
m.create("first", chapter="第1章")
time.sleep(0.01)
m.create("second", chapter="第2章")
all_cp = m.list_all()
assert len(all_cp) == 2
by_name = {c["name"]: c for c in all_cp}
assert by_name["second"]["is_current"] is True
assert by_name["first"]["is_current"] is False
print("  [PASS] list_all 当前标记正确")
'

# 断言 6: restore 拒绝路径
run_py "restore 无 commit 与不存在" '
import os
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
m = CheckpointManager(book)
m.create("novault", chapter="第1章")  # 无 git commit（非 git 目录）
assert m.restore("novault") is False
assert m.restore("ghost") is False
print("  [PASS] restore 拒绝路径正确")
'

# 断言 7: 损坏 JSON 容错
run_py "损坏 checkpoints.json 容错" '
import os
from pathlib import Path
from novel_checkpoint import CheckpointManager
book = Path(os.environ["TMP_DIR"]) / "cpbook"
cpf = book / ".checkpoints" / "checkpoints.json"
cpf.write_text("{ 这不是合法JSON", encoding="utf-8")
m = CheckpointManager(book)
assert m.checkpoints == {"checkpoints": []}, m.checkpoints
assert m.create("after-corrupt", chapter="第1章").name == "after-corrupt"
print("  [PASS] 损坏 JSON 自动重建")
'

echo ""
echo "==> L1-17 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
