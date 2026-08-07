#!/usr/bin/env bash
# L1-16: novel_memory_injector 记忆注入器单元测试
# 直接驱动提取函数 + build_injection，验证：
#   1. count_tokens_estimate / count_words 估算
#   2. extract_characters 核心角色档案提取
#   3. extract_recent_chapters 最近章节摘要提取
#   4. extract_foreshadows 活跃伏笔提取
#   5. extract_world_settings 世界观提取（正负向）
#   6. build_injection 结构（头/角色/摘要/禁忌/目标）
#   7. build_injection token 上限（不超 MAX_TOKENS）
#   8. load_memory 读取（MEMORY.md 优先）
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

# ---- fixture：模拟 MEMORY.md ----
cat > "$TMP_DIR/MEMORY.md" <<'EOF'
# 记忆库

## 人物设定

### 主角: 林风
少年剑客，性格沉稳。佩剑「青锋」。

### 配角: 师父
隐居山中的老剑客。

## 章节索引

| 章节 | 标题 | 状态 |
|---|---|---|
| 第1章 | 开场 | ✓ |
| 第2章 | 出发 | ✓ |
| 第3章 | 抵达 | ✓ |

## 上章摘要

林风抵达城中客栈，掌柜询问其身世。

## 伏笔

| 伏笔ID | 内容 | 状态 | 埋设 | 回收 |
|---|---|---|---|---|
| FP-001 | 师父的旧信 | buried | 第1章 | 第5章 |

## 世界观

- 修行境界：练气 → 筑基 → 金丹 → 元婴，每层突破需心境圆满
- 城邦：云州城，三面环山，北接大漠，商贸往来频繁
- 势力：青岚宗执掌云州修行界，宗门禁地藏有古剑
EOF

# 断言 1: token 估算
run_py "count_tokens_estimate / count_words" '
from novel_memory_injector import count_tokens_estimate, count_words
# 中文 1 字 = 1.5 tokens
assert count_tokens_estimate("你好世界") == 6, count_tokens_estimate("你好世界")
assert count_words("你好世界") == 4
t = count_tokens_estimate("abc")
assert t == 0, t  # 3 * 0.3 = 0.9 → int → 0
print("  [PASS] token 估算: {}".format(count_tokens_estimate("你好世界 abc")))
'

# 断言 2: 角色提取
run_py "extract_characters 角色档案提取" '
import os
from pathlib import Path
from novel_memory_injector import extract_characters, load_memory
m = load_memory(Path(os.environ["TMP_DIR"]))
assert m is not None
out = extract_characters(m)
assert "## 核心角色" in out, out[:100]
assert "林风" in out
assert "师父" in out
print("  [PASS] 角色提取: {} 字".format(len(out)))
'

# 断言 3: 最近章节摘要
run_py "extract_recent_chapters 摘要提取" '
import os
from pathlib import Path
from novel_memory_injector import extract_recent_chapters, load_memory
m = load_memory(Path(os.environ["TMP_DIR"]))
out = extract_recent_chapters(m, 3)
assert "## 最近章节" in out
assert "第1章" in out, out
assert "第3章" in out
assert "## 上章摘要" in out, out
assert "林风抵达城中客栈" in out
print("  [PASS] 摘要提取: {} 字".format(len(out)))
'

# 断言 4: 活跃伏笔提取
run_py "extract_foreshadows 伏笔提取" '
import os
from pathlib import Path
from novel_memory_injector import extract_foreshadows, load_memory
m = load_memory(Path(os.environ["TMP_DIR"]))
out = extract_foreshadows(m)
assert "## 活跃伏笔" in out
assert "FP-001" in out, out
assert "buried" in out
print("  [PASS] 伏笔提取: {} 字".format(len(out)))
'

# 断言 5: 世界观提取（正负向）
run_py "extract_world_settings 世界观提取" '
import os
from pathlib import Path
from novel_memory_injector import extract_world_settings, load_memory
m = load_memory(Path(os.environ["TMP_DIR"]))
out = extract_world_settings(m)
assert "## 世界观" in out
assert "练气" in out, out
assert len(out) > 50  # 非空（有内容）
# 负向：无世界观的记忆 → 空
assert extract_world_settings("# 只有标题\n\n无世界观内容\n") == ""
print("  [PASS] 世界观提取: {} 字".format(len(out)))
'

# 断言 6: build_injection 结构
run_py "build_injection 结构完整" '
import os
from pathlib import Path
from novel_memory_injector import build_injection, load_memory
m = load_memory(Path(os.environ["TMP_DIR"]))
out = build_injection(m, 4)
assert "第4章写作核心记忆" in out
assert "核心角色" in out
assert "最近章节" in out
assert "上章摘要" in out
assert "活跃伏笔" in out
assert "世界观" in out
assert "AI 写作禁忌" in out
assert "本章目标" in out
assert "眼中闪过一丝" in out  # 禁忌清单内容
print("  [PASS] 注入结构: {} 字".format(len(out)))
'

# 断言 7: token 上限
run_py "build_injection token 不超 MAX_TOKENS" '
import os
from pathlib import Path
from novel_memory_injector import build_injection, count_tokens_estimate, load_memory, MAX_TOKENS
# 大量 MEMORY → 注入被裁剪
big = "\n".join("### 主角: 角色{}号\n少年剑客。".format(i) for i in range(50))
m = load_memory(Path(os.environ["TMP_DIR"])) + big
out = build_injection(m, 10)
tokens = count_tokens_estimate(out)
assert tokens <= MAX_TOKENS + 10, (tokens, MAX_TOKENS)
print("  [PASS] tokens={} <= MAX_TOKENS={}".format(tokens, MAX_TOKENS))
'

# 断言 8: load_memory 优先级 + 缺失
run_py "load_memory 读取与缺失" '
import os
from pathlib import Path
from novel_memory_injector import load_memory
# MEMORY.md 优先于 记忆.md
d = Path(os.environ["TMP_DIR"])
(d / "记忆.md").write_text("# 备选记忆\n", encoding="utf-8")
m = load_memory(d)
assert "记忆库" in m, m[:50]
# 无记忆 → None
empty = d / "empty"
empty.mkdir(exist_ok=True)
assert load_memory(empty) is None
print("  [PASS] load_memory 优先级/缺失正确")
'

echo ""
echo "==> L1-16 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
