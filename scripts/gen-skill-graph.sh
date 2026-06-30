#!/usr/bin/env bash
# ============================================================
#  gen-skill-graph.sh
#  扫描 skills/*/_meta.json 中的 requires / conflicts / complements
#  生成 docs/skill-dependency-graph.md（Mermaid 图）
#
#  用法：
#    bash scripts/gen-skill-graph.sh                # 直接生成
#    bash scripts/gen-skill-graph.sh --check        # 校验是否最新
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 探测 Python 解释器
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "❌ 未找到 python3/python，请安装 Python 3"
  exit 1
fi

# 委托给 Python 实现（性能更好，328 个 skill 一次性处理）
exec "$PY" "$SCRIPT_DIR/gen-skill-graph.py" "$@"
