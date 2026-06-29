#!/usr/bin/env bash
# 校验所有 Skill 的 _meta.json
# 依据：schemas/skill-meta.schema.json

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

LAYER_FILE="skills/_layer.yaml"
if [[ -f "$LAYER_FILE" ]]; then
  # 用 Python 解析 _layer.yaml（避免 yq 路径问题 + trailing newline 问题）
  read -r CORE_SLUGS PERI_SLUGS ARCH_SLUGS < <(python3 -c "
import yaml
with open('$LAYER_FILE') as f:
    data = yaml.safe_load(f)
print(' '.join(data.get('core', [])))
print(' '.join(data.get('peripheral', [])))
print(' '.join(data.get('archived', [])))
" 2>/dev/null || echo " ")
else
  CORE_SLUGS=""; PERI_SLUGS=""; ARCH_SLUGS=""
fi

FAILED=0
WARNED=0
SKIPPED=0
TOTAL=0

for skill_dir in skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  slug=$(basename "$skill_dir")
  [[ "$slug" == _* ]] && continue
  TOTAL=$((TOTAL + 1))

  is_core=false; is_peri=false; is_arch=false
  [[ " $CORE_SLUGS " == *" $slug "* ]] && is_core=true
  [[ " $PERI_SLUGS " == *" $slug "* ]] && is_peri=true
  [[ " $ARCH_SLUGS " == *" $slug "* ]] && is_arch=true

  meta_path="$skill_dir/_meta.json"

  if [[ ! -f "$meta_path" ]]; then
    if [[ "$is_core" == true ]]; then
      echo "[FAIL] $slug: _meta.json missing (core layer requires)"
      FAILED=$((FAILED + 1))
    elif [[ "$is_arch" == true ]]; then
      SKIPPED=$((SKIPPED + 1))
    else
      echo "[WARN] $slug: _meta.json missing (peripheral layer)"
      WARNED=$((WARNED + 1))
    fi
    continue
  fi

  # 用 jsonschema Python 包校验（跨平台回退）
  err=$(python3 - "$meta_path" "schemas/skill-meta.schema.json" 2>&1 <<'PYEOF' || true
import sys, json
from pathlib import Path

try:
    import jsonschema
except ImportError:
    print("jsonschema not installed; skipping schema validation", file=sys.stderr)
    sys.exit(2)

meta_path = Path(sys.argv[1])
schema_path = Path(sys.argv[2])

try:
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as e:
    print(f"{meta_path.parent.name}: JSON parse error: {e}")
    sys.exit(1)

schema = json.loads(schema_path.read_text(encoding="utf-8"))
validator = jsonschema.Draft7Validator(schema)
errors = list(validator.iter_errors(meta))

if errors:
    err_msgs = [f"{'/'.join(str(p) for p in e.absolute_path)}: {e.message}" for e in errors]
    print(f"{meta_path.parent.name}: " + "; ".join(err_msgs))
    sys.exit(1)

# 额外校验：slug == dir name
if meta.get("slug") != meta_path.parent.name:
    print(f"{meta_path.parent.name}: slug mismatch: {meta.get('slug')} != {meta_path.parent.name}")
    sys.exit(1)
PYEOF
  )
  rc=$?
  if [[ $rc -eq 1 ]]; then
    echo "[FAIL] $err"
    FAILED=$((FAILED + 1))
  elif [[ $rc -eq 2 ]]; then
    SKIPPED=$((SKIPPED + 1))
  fi
done

# 交叉校验：路由表引用 vs 实际 slug 集合
if [[ -f "core/orchestration/skill-preferences.md" ]]; then
  echo ""
  echo "==> Cross-check: routing references"
  python3 - <<'PYEOF'
import re, sys
from pathlib import Path

routing = Path("core/orchestration/skill-preferences.md").read_text(encoding="utf-8")
referenced = set(re.findall(r"`([a-z0-9][a-z0-9-]*[a-z0-9])`", routing))

# 排除非 skill 标识符：字段名、状态、wu_type 值、平台名
# 这些出现在文档中作为代码片段，但不是 skill slug 引用
NON_SLUG = {
    "auto",        # wu_skills: auto（字段值）
    "overrides",   # overrides 字段
    "exclude",     # exclude 字段
    "skipped",     # skipped 状态
    "ui-bug",      # wu_type 值
    "infsh",       # 平台名
    "wu_type",     # 字段名
    "wu_skills",   # 字段名
    "agent_role",  # 字段名
    "include_layers",  # manifest 字段
    "project",     # manifest layer 名
    "core",        # manifest layer 名
    "peripheral",  # manifest layer 名
    "archived",    # manifest layer 名
}
referenced -= NON_SLUG

# 修复 p.parent.name -> p.name（path 为 skills/<slug> 时，p.parent.name 是 skills）
existing = {p.name for p in Path("skills").iterdir()
            if p.is_dir() and not p.name.startswith("_")}
missing = referenced - existing
if missing:
    print(f"[FAIL] routing references non-existent skills: {sorted(missing)}")
    sys.exit(1)
print(f"  [ok] all {len(referenced)} routing references exist")
PYEOF
fi

echo ""
echo "==> _meta validation: total=$TOTAL failed=$FAILED warned=$WARNED skipped=$SKIPPED"
[[ "$FAILED" -eq 0 ]] || exit 1
