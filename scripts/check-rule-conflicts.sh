#!/usr/bin/env bash
# 规则冲突检测 — 对比 harness-foundry 规则与主项目约定（CODING_CONVENTIONS.md / CLAUDE.md）的硬约束
# 检测项:
#   1. 行数上限（如 Service 类行数上限 1000）
#   2. 端口号（如 8080）
#   3. 包名根路径（如 org.xywh）
# 用法: bash scripts/check-rule-conflicts.sh [主项目根目录]
# 默认主项目根目录: ../../ (harness-foundry 的上一级)
# 退出码: 0 = 无冲突; 1 = 发现冲突

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_PROJECT="${1:-$(cd "$ROOT/.." && pwd)}"

echo "==> 规则冲突检测"
echo "    harness-foundry: $ROOT"
echo "    主项目:          $MAIN_PROJECT"
echo ""

CONFLICTS=0

# 主项目约定文件
CONV="$MAIN_PROJECT/CODING_CONVENTIONS.md"
CLAUDE_MD="$MAIN_PROJECT/CLAUDE.md"

if [[ ! -f "$CONV" ]]; then
  echo "  [WARN] 未找到 $CONV，跳过主项目对比"
  exit 0
fi

# 规则文件清单（harness-foundry 侧的约束来源）
RULE_FILES=(
  "$ROOT/traps-archive/code/springboot-checklist.md"
  "$ROOT/traps-archive/code/00-all.md"
)
for f in "$ROOT"/rules/code/java/*.md; do
  RULE_FILES+=("$f")
done

# ---- 1. 行数上限对比 ----
# 来源1: 主项目约定（若存在 "X 行" 措辞）
# 来源2: harness-foundry 规则文件之间互相比对（同一主体不同值）
echo "==> [1] 行数上限"

# 1a. 主项目 CODING_CONVENTIONS.md 中的行数约束
if [[ -f "$CONV" ]]; then
  while IFS= read -r main_line; do
    [[ -z "$main_line" ]] && continue
    limit=$(echo "$main_line" | grep -oE '[0-9]+[[:space:]]*行' | grep -oE '[0-9]+' | head -1) || true
    [[ -z "$limit" ]] && continue
    # 提取主体（行限制前的名词短语，如 Service/Controller/方法）
    subject=$(echo "$main_line" | grep -oE '^[^：:]{0,20}' | tr -d '[:space:]') || true
    [[ -z "$subject" ]] && continue
    echo "  [主项目] $subject = $limit 行: $main_line"
    for rf in "${RULE_FILES[@]}"; do
      [[ -f "$rf" ]] || continue
      while IFS= read -r rf_line; do
        if echo "$rf_line" | grep -qE '[0-9]+[[:space:]]*行'; then
          other=$(echo "$rf_line" | grep -oE '[0-9]+[[:space:]]*行' | grep -oE '[0-9]+' | head -1) || true
          if [[ -n "$other" && "$other" != "$limit" ]]; then
            echo "  [冲突] ${rf#$ROOT/}: '$rf_line' (值 $other ≠ 主项目 $limit)"
            CONFLICTS=$((CONFLICTS + 1))
          fi
        fi
      done < "$rf"
    done
  done < <(grep -E '行' "$CONV" 2>/dev/null || true)
fi

# 1b. harness-foundry 规则文件之间互相比对（traps-archive vs rules/）
# 只匹配 "主体紧邻数字" 形态，避免同行其他主体的数值干扰
echo "  [交叉] 规则文件间比对"
for subject in "Service" "Controller" "方法"; do
  main_val=""
  main_src=""
  for rf in "${RULE_FILES[@]}"; do
    [[ -f "$rf" ]] || continue
    # 匹配: Service >1000 行 / Controller >300 行 / 方法 >60 行（主体后 ≤15 个非数字字符内出现限制）
    val=$(grep -oE "${subject}[^0-9]{0,15}(>|超过|不超过|上限)[^0-9]{0,3}[0-9]+[[:space:]]*行" "$rf" 2>/dev/null | grep -oE '[0-9]+[[:space:]]*行' | grep -oE '[0-9]+' | head -1) || true
    if [[ -n "$val" ]]; then
      if [[ -z "$main_val" ]]; then
        main_val="$val"
        main_src="${rf#$ROOT/}"
        echo "  [基准] $subject = $val 行 ($main_src)"
      elif [[ "$val" != "$main_val" ]]; then
        echo "  [冲突] $subject: ${rf#$ROOT/} 写 $val 行, $main_src 写 $main_val 行"
        CONFLICTS=$((CONFLICTS + 1))
      fi
    fi
  done
done

# ---- 2. 端口号对比 ----
echo ""
echo "==> [2] 端口号"
MAIN_PORT=$(grep -oE 'port:[[:space:]]*[0-9]+' "$MAIN_PROJECT/ruoyi-admin/src/main/resources/application.yml" 2>/dev/null | head -1 | grep -oE '[0-9]+') || true
if [[ -n "$MAIN_PORT" ]]; then
  echo "  主项目端口: $MAIN_PORT"
  for rf in "${RULE_FILES[@]}"; do
    [[ -f "$rf" ]] || continue
    while IFS= read -r rf_line; do
      # 排除日期格式 (2026-06-17) 和年份
      if echo "$rf_line" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
        continue
      fi
      # 只匹配 "端口" 或 "port" 上下文中的数字
      if echo "$rf_line" | grep -qiE '(端口|port[:：]?)[^0-9]{0,6}[0-9]{4,5}'; then
        p=$(echo "$rf_line" | grep -oiE '(端口|port[:：]?)[^0-9]{0,6}[0-9]{4,5}' | grep -oE '[0-9]{4,5}' | head -1) || true
        if [[ -n "$p" && "$p" != "$MAIN_PORT" ]]; then
          echo "  [冲突] 端口 $p (${rf#$ROOT/}) 与主项目 $MAIN_PORT 不一致"
          CONFLICTS=$((CONFLICTS + 1))
        fi
      fi
    done < "$rf"
  done
else
  echo "  [WARN] 未找到主项目端口配置，跳过"
fi

# ---- 3. 包名根路径对比 ----
echo ""
echo "==> [3] 包名根路径"
MAIN_PKG=$(grep -oE 'org\.[a-z]+\.[a-z_]+' "$CLAUDE_MD" 2>/dev/null | head -1) || true
if [[ -z "$MAIN_PKG" ]]; then
  MAIN_PKG=$(grep -oE 'org\.[a-z]+\.[a-z_]+' "$CONV" 2>/dev/null | head -1) || true
fi
if [[ -n "$MAIN_PKG" ]]; then
  echo "  主项目包名: $MAIN_PKG"
  for rf in "${RULE_FILES[@]}"; do
    [[ -f "$rf" ]] || continue
    while IFS= read -r rf_line; do
      if echo "$rf_line" | grep -qE 'org\.[a-z]+\.[a-z_]+' && ! echo "$rf_line" | grep -q "$MAIN_PKG"; then
        other=$(echo "$rf_line" | grep -oE 'org\.[a-z]+\.[a-z_]+' | head -1) || true
        echo "  [冲突] ${rf#$ROOT/} 提到 $other, 主项目根包为 $MAIN_PKG"
        CONFLICTS=$((CONFLICTS + 1))
      fi
    done < "$rf"
  done
fi

# ---- 4. 插件副本版本检查（ecc/superpowers 等外部来源副本是否与插件脱节）----
echo ""
echo "==> [4] 插件副本版本检查"
PLUGIN_CACHE="$HOME/.claude/plugins/cache"
if [[ -d "$PLUGIN_CACHE" ]]; then
  # 扫描 harness 里标注了外部来源的 meta.json
  for meta in "$ROOT"/agents/*.meta.json; do
    [[ -f "$meta" ]] || continue
    src=$(grep -oE '"source": *"[^"]*"' "$meta" 2>/dev/null | head -1 | grep -oE '"[^"]*"$' | tr -d '"')
    [[ -z "$src" || "$src" == "harness" ]] && continue
    ver=$(grep -oE '"source_version": *"[^"]*"' "$meta" 2>/dev/null | head -1 | grep -oE '"[^"]*"$' | tr -d '"')
    [[ -z "$ver" ]] && continue
    # 找插件实际版本（宽松匹配插件名）
    plugin_dir=""
    case "$src" in
      ECC|ecc) plugin_dir="$PLUGIN_CACHE/ecc/ecc" ;;
      superpowers|Superpowers) plugin_dir="$PLUGIN_CACHE/claude-plugins-official/superpowers" ;;
    esac
    if [[ -n "$plugin_dir" && -d "$plugin_dir" ]]; then
      actual=$(ls "$plugin_dir" 2>/dev/null | sort -V | tail -1)
      if [[ -n "$actual" && "$actual" != "$ver" ]]; then
        echo "  [冲突] $(basename "$meta" .meta.json): meta 记录 $src@$ver, 插件实际 $src@$actual"
        echo "        文件: ${meta#$ROOT/}"
        CONFLICTS=$((CONFLICTS + 1))
      else
        echo "  [ok] $(basename "$meta" .meta.json): $src@$ver 与插件一致"
      fi
    fi
  done
else
  echo "  [WARN] 未找到插件缓存目录 $PLUGIN_CACHE，跳过"
fi

echo ""
if [[ $CONFLICTS -gt 0 ]]; then
  echo "==> 发现 $CONFLICTS 处潜在冲突"
  exit 1
else
  echo "==> 未发现冲突"
  exit 0
fi
