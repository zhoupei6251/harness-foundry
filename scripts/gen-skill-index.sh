#!/usr/bin/env bash
# ============================================================
#  gen-skill-index.sh
#  自动从 skills/*/SKILL.md + _meta.json + categories.yaml
#  生成 skills/INDEX.md。
#
#  用法：
#    bash scripts/gen-skill-index.sh             # 直接生成
#    bash scripts/gen-skill-index.sh --dry-run   # 打印到 stdout
#    bash scripts/gen-skill-index.sh --check     # 仅校验：未更新则 exit 1
#
#  要求：bash 4+，依赖 awk/sed/grep，无外部依赖
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
INDEX_FILE="$SKILLS_DIR/INDEX.md"
CATEGORIES_FILE="$SKILLS_DIR/categories.yaml"

MODE="write"
[ "${1:-}" = "--dry-run" ] && MODE="stdout"
[ "${1:-}" = "--check" ] && MODE="check"

# ---------- 工具函数 ----------
# 从 stdin 读，去掉首尾单/双引号
strip_quotes() { sed -E "s/^['\"]//; s/['\"]$//"; }

get_frontmatter() {
  local file="${1:-}" field="${2:-}"
  if [ -z "$file" ] || [ -z "$field" ]; then
    echo ""
    return 1
  fi
  awk '/^---$/{c++; next} c==1' "$file" \
    | awk -v f="$field" '
        BEGIN { collecting=0; buf="" }
        $0 ~ "^"f":" {
          line=$0
          sub("^"f":[[:space:]]*","",line)
          # YAML 多行块：| > 标记符
          if (line=="|" || line==">" || line==">-" || line=="|-") {
            collecting=1; next
          }
          # 普通单行
          print line; exit
        }
        collecting==1 {
          # 多行内容：缩进非空行累积
          if ($0 ~ "^[[:space:]]+[^[:space:]]") {
            if (buf!="") buf=buf" "
            gsub(/^[[:space:]]+/,"",$0)
            buf=buf$0
          } else if ($0 ~ "^[^[:space:]]") {
            # 遇到非缩进行 → 结束
            print buf; exit
          }
          # 空行忽略，继续
        }
        END {
          if (collecting && buf!="") print buf
        }
      ' \
    | strip_quotes \
    || true
}

get_meta() {
  local file="${1:-}" field="${2:-}"
  if [ -z "$file" ] || [ -z "$field" ]; then
    echo ""
    return 1
  fi
  [ -f "$file" ] || { echo ""; return; }
  grep -E "\"${field}\"\s*:" "$file" \
    | head -1 \
    | sed -E "s/.*\"${field}\"\s*:\s*\"([^\"]*)\".*/\1/" \
    || true
}

# ---------- 1. 收集所有 skill ----------
declare -A DESC=() CAT=() DOMAIN=()
SLUGS=()

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  slug=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] || continue

  desc="$(get_frontmatter "$dir/SKILL.md" description)"
  purpose="$(get_meta "$dir/_meta.json" purpose)"
  cat_id="$(get_meta "$dir/_meta.json" category)"
  domain="$(get_meta "$dir/_meta.json" domain)"

  [ -n "$purpose" ] && desc="$purpose"
  [ -z "$desc" ] && desc="（无描述）"
  [ -z "$domain" ] && domain="shared"

  SLUGS+=("$slug")
  DESC["$slug"]="$desc"
  CAT["$slug"]="$cat_id"
  DOMAIN["$slug"]="$domain"
done

IFS=$'\n' SLUGS=($(printf '%s\n' "${SLUGS[@]}" | sort))
unset IFS
COUNT=${#SLUGS[@]}

# ---------- 2. 解析 categories.yaml ----------
declare -A CAT_TITLE=() CAT_DESC=()
cur_id=""
while IFS= read -r line; do
  case "$line" in
    "  - id:"*)
      cur_id=$(echo "$line" | sed -E 's/^  - id:\s*//')
      ;;
    "    title:"*)
      cur_title=$(echo "$line" | sed -E 's/^    title:\s*//')
      [ -n "$cur_id" ] && CAT_TITLE["$cur_id"]="$cur_title"
      ;;
    "    description:"*)
      cur_desc=$(echo "$line" | sed -E 's/^    description:\s*//')
      [ -n "$cur_id" ] && CAT_DESC["$cur_id"]="$cur_desc"
      ;;
  esac
done < "$CATEGORIES_FILE"

# ---------- 3. 计算分类成员 + 未分类 ----------
declare -A CAT_MEMBERS=()
unclassified=()

for slug in "${SLUGS[@]}"; do
  c="${CAT[$slug]:-}"
  if [ -n "$c" ] && [ -n "${CAT_TITLE[$c]:-}" ]; then
    CAT_MEMBERS["$c"]+="${slug}|"
  else
    unclassified+=("$slug")
  fi
done

# ---------- 4. 拼接内容到 tmp 文件（用 cat heredoc + printf）----------
NOW=$(date +%Y-%m-%d)
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

{
  cat <<EOF
# Skill 索引

> 自动生成的 Skill 索引 — 共 $COUNT 个 Skill，采用扁平目录结构。
> 最后更新：$NOW
> 生成方式：\`bash scripts/gen-skill-index.sh\`

## 按字母顺序索引

| 序号 | Skill 目录 | 说明 |
|------|-----------|------|
EOF

  i=1
  for slug in "${SLUGS[@]}"; do
    printf "| %d | \`%s\` | %s |\n" "$i" "$slug" "${DESC[$slug]}"
    i=$((i+1))
  done

  cat <<'EOF'

## 按功能分类

> 分类定义见 [categories.yaml](./categories.yaml)。新 skill 请在 `_meta.json` 中声明 `category` 字段。

EOF

  # 按 categories.yaml 中声明的顺序输出
  cur_id=""
  while IFS= read -r line; do
    case "$line" in
      "  - id:"*)
        cur_id=$(echo "$line" | sed -E 's/^  - id:\s*//')
        if [ -n "$cur_id" ] && [ -n "${CAT_MEMBERS[$cur_id]:-}" ]; then
          title="${CAT_TITLE[$cur_id]}"
          desc="${CAT_DESC[$cur_id]:-}"
          echo "### $title"
          [ -n "$desc" ] && {
            echo ""
            echo "_${desc}_"
          }
          echo ""
          IFS='|' read -ra members <<< "${CAT_MEMBERS[$cur_id]}"
          for m in "${members[@]}"; do
            [ -n "$m" ] && echo "- \`$m\` - ${DESC[$m]}"
          done
          echo ""
        fi
        ;;
    esac
  done < "$CATEGORIES_FILE"

  if [ ${#unclassified[@]} -gt 0 ]; then
    cat <<'EOF'
### 未分类（待补 category 字段）

> 以下 skill 尚未在 `_meta.json` 中声明 `category`，建议补充。

EOF
    for slug in "${unclassified[@]}"; do
      echo "- \`$slug\` - ${DESC[$slug]}"
    done
    echo ""
  fi

  cat <<EOF
---

_本文件由脚本自动生成，请勿手改。如需修改分类，请编辑 \`skills/categories.yaml\`；如需修改 skill 描述，请编辑 \`SKILL.md\` 的 frontmatter 或 \`_meta.json\` 的 \`purpose\` 字段。_
EOF
} > "$TMP"

# ---------- 5. 输出 ----------
case "$MODE" in
  stdout)
    cat "$TMP"
    exit 0
    ;;
  check)
    if ! diff -q "$TMP" "$INDEX_FILE" >/dev/null 2>&1; then
      echo "❌ INDEX.md 与脚本生成内容不一致，请运行：bash scripts/gen-skill-index.sh"
      exit 1
    fi
    echo "✅ INDEX.md 是最新的"
    exit 0
    ;;
  write)
    mv "$TMP" "$INDEX_FILE"
    trap - EXIT
    echo "✅ INDEX.md 已更新（$COUNT 个 skill）"
    if [ ${#unclassified[@]} -gt 0 ]; then
      echo "ℹ️  有 ${#unclassified[@]} 个 skill 未分类，详见 INDEX.md 末尾"
    fi
    exit 0
    ;;
esac
