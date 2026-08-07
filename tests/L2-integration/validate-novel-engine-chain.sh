#!/usr/bin/env bash
# L2-4: novel 引擎链集成测试
# 端到端 fixture 跑完整引擎链：MEMORY.md → memory_injector 注入 → foreshadowing_dag 建 DAG
# → continuity_check 连续性核查，验证三个引擎的数据格式互通（同一 MEMORY.md 都能解析）。
# 覆盖 L1 单引擎测试无法覆盖的跨引擎链路：伏笔登记表 → 注入 → 连续性。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NOVEL_DIR="scripts/novel"
PASS() { echo "  [PASS] $1"; }
FAIL() { echo "  [FAIL] $1"; FAILED=$((FAILED + 1)); }

# ---- fixture：一个模拟书籍目录（章节 + MEMORY.md）----
# 格式要求（三引擎共通）：
#   - 伏笔表埋设/回收列用纯数字（continuity 要求 \d+）
#   - 角色同时给 "### 主角"（injector 用）和 "人物状态" 表格（continuity 用）
#   - 章节索引 + 上章摘要（injector 用）
BOOK="$TMP_DIR/chainbook"
mkdir -p "$BOOK"
cat > "$BOOK/第1章_信物.md" <<'EOF'
# 第一章 信物

林风推开木门，屋里坐着师父。师父把一封信推到他面前，说：去城里走一趟。
EOF
cat > "$BOOK/第2章_客栈.md" <<'EOF'
# 第二章 客栈

林风到了城里，在客栈住下。掌柜的打量他片刻，问：可是林家的后生？
EOF
cat > "$BOOK/第3章_旧信.md" <<'EOF'
# 第三章 旧信

林风拆开师父的信，里面掉出一块玉佩。
EOF
cat > "$BOOK/MEMORY.md" <<'EOF'
# 记忆库

## 人物设定

### 主角: 林风
少年剑客，性格沉稳。佩剑「青锋」。

### 配角: 师父
隐居山中的老剑客。

## 人物状态

| 角色 | 状态 | 备注 |
|---|---|---|
| 林风 | 存活 | 最近出场：第3章 |
| 师父 | 存活 | 最近出场：第1章 |

## 章节索引

| 章节 | 标题 | 状态 |
|---|---|---|
| 第1章 | 信物 | ✓ |
| 第2章 | 客栈 | ✓ |
| 第3章 | 旧信 | ✓ |

## 上章摘要

林风拆开师父的信，信里掉出一块玉佩。

## 伏笔

| 伏笔ID | 内容 | 埋设章 | 状态 | 回收章 |
|---|---|---|---|---|
| FP-001 | 师父的旧信 | 1 | buried | 3 |
| FP-002 | 客栈暗号 | 2 | buried | 3 |

## 世界观

- 修行境界：练气 → 筑基 → 金丹
EOF

# 断言 1: memory_injector 解析同一 MEMORY.md 并产出注入文件（角色 + 伏笔 + 摘要）
echo "==> memory_injector 解析 MEMORY.md"
INJECT_OUT="$TMP_DIR/injection.md"
if python "$NOVEL_DIR/novel_memory_injector.py" "$BOOK" 3 --output "$INJECT_OUT" > /dev/null 2>&1 \
   && [[ -f "$INJECT_OUT" ]]; then
  CONTENT="$(cat "$INJECT_OUT")"
  PASS "注入文件已生成"
  if echo "$CONTENT" | grep -q "林风"; then
    PASS "注入含角色 林风"
  else
    FAIL "注入缺角色"
  fi
  if echo "$CONTENT" | grep -q "FP-001"; then
    PASS "注入含伏笔 FP-001"
  else
    FAIL "注入缺伏笔"
  fi
  if echo "$CONTENT" | grep -q "上章摘要"; then
    PASS "注入含上章摘要"
  else
    FAIL "注入缺摘要"
  fi
else
  FAIL "memory_injector 未产出注入文件"
fi

# 断言 2: foreshadowing_dag 能从同一 MEMORY.md 自动导入伏笔
echo "==> foreshadowing_dag 从 MEMORY.md 导入伏笔"
python "$NOVEL_DIR/foreshadowing_dag.py" "$BOOK" stats > "$TMP_DIR/dag_stats.txt" 2>&1
if grep -q "总计: 2" "$TMP_DIR/dag_stats.txt"; then
  PASS "DAG 自动导入 2 条伏笔（总计: 2）"
else
  FAIL "DAG 导入失败: $(head -3 "$TMP_DIR/dag_stats.txt")"
fi

# 断言 3: continuity_check 能核查同一书籍（角色 + 伏笔 + 章节）
echo "==> continuity_check 连续性核查"
CONT_JSON="$(python "$NOVEL_DIR/continuity_check.py" "$BOOK" --memory "$BOOK/MEMORY.md" --json 2>&1)"
if echo "$CONT_JSON" | python -c "
import json, sys
d = json.load(sys.stdin)
assert 'context' in d, '缺少 context'
ctx = d['context']
assert ctx['characters_count'] >= 1, ctx
assert ctx['chapters_count'] >= 3, ctx
assert ctx['foreshadowings_count'] >= 1, ctx
print('  [PASS] 上下文: {} 角色 {} 章 {} 伏笔'.format(
    ctx['characters_count'], ctx['chapters_count'], ctx['foreshadowings_count']))
" 2>/dev/null; then
  PASS "continuity 上下文正确"
else
  FAIL "continuity 输出异常: $(echo "$CONT_JSON" | head -c 300)"
fi

# 断言 4: 引擎间伏笔数一致性（同一 MEMORY.md 三引擎都解析出伏笔）
echo "==> 引擎间伏笔数一致性"
INJECT_FS="$(grep -c "FP-" "$INJECT_OUT" 2>/dev/null || echo "0")"
if [[ "$INJECT_FS" -ge "1" ]]; then
  PASS "injector 注入伏笔引用（$INJECT_FS 处）"
else
  FAIL "injector 未注入任何伏笔引用"
fi

echo ""
echo "==> L2-4 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
