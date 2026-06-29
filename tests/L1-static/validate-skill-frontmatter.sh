#!/usr/bin/env bash
# 校验所有 Skill 的 SKILL.md frontmatter
# 必填字段：name / description / version / when_to_use / status / tags
# 校验依据：docs/skill-frontmatter-schema.md

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

LAYER_FILE="skills/_layer.yaml"
if [[ -f "$LAYER_FILE" ]]; then
  # 用 Python 解析 _layer.yaml（避免 yq 路径问题 + trailing newline 问题）
  CORE_SLUGS=$(python3 -c "
import yaml
with open('$LAYER_FILE') as f:
    data = yaml.safe_load(f)
print(' '.join(data.get('core', [])))
" 2>/dev/null || echo "")
else
  CORE_SLUGS=""
fi

FAILED=0
TOTAL=0
SKIPPED=0

for skill_dir in skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  slug=$(basename "$skill_dir")
  [[ "$slug" == _* ]] && continue
  TOTAL=$((TOTAL + 1))

  # 核心层必须校验
  is_core=false
  if [[ -n "$CORE_SLUGS" && " $CORE_SLUGS " == *" $slug "* ]]; then
    is_core=true
  elif [[ -z "$CORE_SLUGS" ]]; then
    # _layer.yaml 不存在或解析失败时，保守地只校验有 frontmatter 的
    is_core=false
  fi

  skill_md="$skill_dir/SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    echo "[FAIL] $slug: SKILL.md missing"
    FAILED=$((FAILED + 1))
    continue
  fi

  content=$(cat "$skill_md")
  # 检查文件是否以 "---" 开头（frontmatter 分隔符）
  if [[ ! "$content" =~ ^---[[:space:]] ]]; then
    if [[ "$is_core" == true ]]; then
      echo "[FAIL] $slug: frontmatter missing (core layer requires)"
      FAILED=$((FAILED + 1))
    else
      SKIPPED=$((SKIPPED + 1))
    fi
    continue
  fi

  # 用 python 校验（跨平台）
  err=$(python3 - "$skill_md" "$is_core" <<'PYEOF' 2>&1
import sys, re, yaml
from pathlib import Path

skill_md = Path(sys.argv[1])
is_core = sys.argv[2] == "true"

text = skill_md.read_text(encoding="utf-8")
if not text.startswith("---"):
    if is_core:
        print(f"{skill_md.parent.name}: frontmatter missing")
        sys.exit(1)
    sys.exit(0)

parts = text.split("---", 2)
if len(parts) < 3:
    print(f"{skill_md.parent.name}: malformed frontmatter")
    sys.exit(1)

try:
    fm = yaml.safe_load(parts[1]) or {}
except yaml.YAMLError as e:
    print(f"{skill_md.parent.name}: YAML error: {e}")
    sys.exit(1)

required = ["name", "description", "version", "when_to_use", "status", "tags"]
status_enum = ["stable", "peripheral", "archived", "experimental"]
slug_re = re.compile(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$")
semver_re = re.compile(r"^\d+\.\d+\.\d+$")

errs = []
for field in required:
    if field not in fm:
        errs.append(f"missing required field: {field}")

if "name" in fm and not slug_re.match(str(fm["name"])):
    errs.append(f"invalid name (slug): {fm['name']}")
if "version" in fm and not semver_re.match(str(fm["version"])):
    errs.append(f"invalid version (semver): {fm['version']}")
if "status" in fm and fm["status"] not in status_enum:
    errs.append(f"invalid status: {fm['status']}")
if "description" in fm and (len(str(fm["description"])) < 1 or len(str(fm["description"])) > 200):
    errs.append(f"description length out of range: {len(fm['description'])}")
if "when_to_use" in fm and (len(str(fm["when_to_use"])) < 1 or len(str(fm["when_to_use"])) > 300):
    errs.append(f"when_to_use length out of range: {len(fm['when_to_use'])}")
if "tags" in fm and (not isinstance(fm["tags"], list) or len(fm["tags"]) < 1):
    errs.append(f"tags must be non-empty array")

# 强制 name == slug
if fm.get("name") != skill_md.parent.name:
    errs.append(f"name mismatch: {fm.get('name')} != {skill_md.parent.name}")

if errs:
    print(f"{skill_md.parent.name}: " + "; ".join(errs))
    sys.exit(1)
PYEOF
  ) || {
    echo "[FAIL] $err"
    FAILED=$((FAILED + 1))
  }
done

echo ""
echo "==> Frontmatter validation: total=$TOTAL failed=$FAILED skipped=$SKIPPED"
[[ "$FAILED" -eq 0 ]] || exit 1
