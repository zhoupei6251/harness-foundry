#!/usr/bin/env bash
# 集成测试：sync-skills.sh 过滤 archived Skill
# 验证 _layer.yaml 正确反映在 sync 输出中

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# yq 在 PATH 中（verify.sh 已确保）
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/local/bin:$PATH"

LAYER_FILE="skills/_layer.yaml"
[[ -f "$LAYER_FILE" ]] || { echo "[FAIL] _layer.yaml not found"; exit 1; }

# 1. 提取 dry-run 输出
output=$(bash scripts/sync-skills.sh --target all --dry-run 2>&1 || true)

# 2. 检查 archived Skill 不在输出中
arch_count=$(python3 -c "import yaml; d=yaml.safe_load(open('$LAYER_FILE')); print(len(d['archived']))")
hit=0
for slug in $(python3 -c "import yaml; d=yaml.safe_load(open('$LAYER_FILE')); print(' '.join(d['archived']))"); do
  if echo "$output" | grep -q "skills/$slug/"; then
    hit=$((hit + 1))
  fi
done

if [[ "$hit" -gt 0 ]]; then
  echo "[FAIL] $hit archived skills leaked into sync output"
  exit 1
fi

echo "[ok] $arch_count archived skills filtered out"

# 3. 检查 sync 输出中的 [dry] 行只包含 core + peripheral 的 slug
#    解析 _layer.yaml 获取允许集（core + peripheral 全量）
allowed_set=$(mktemp)
{
  python3 -c "import yaml; d=yaml.safe_load(open('$LAYER_FILE')); print('\n'.join(d['core'] + d['peripheral']))"
} | sort -u > "$allowed_set"

# 从 sync output 中提取所有 [dry] 行内的 slug（精确匹配行首 + 已知前缀）
# 注意排除平台标签行（"[dry] claude: strategic -> ..." → awk 截出 "claude"）—— 字面量排除
sourced_slugs=$(mktemp)
echo "$output" | grep -oE '^\s*\[(dry|skip-from-sync)\] [a-z0-9][a-z0-9-]*[a-z0-9]' | awk '{print $2}' | grep -vE '^(claude|trae)$' | sort -u > "$sourced_slugs"
sourced_count=$(wc -l < "$sourced_slugs" | tr -d ' ')

leaked=0
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  if ! grep -qx "$slug" "$allowed_set"; then
    echo "  [LEAK] $slug — 在 sync 输出中但不在 core+peripheral"
    leaked=$((leaked + 1))
  fi
done < "$sourced_slugs"

rm -f "$allowed_set" "$sourced_slugs"

if [[ "$leaked" -gt 0 ]]; then
  echo "[FAIL] $leaked non-core/peripheral skills leaked into sync output"
  exit 1
fi

echo "[ok] sync 输出 $sourced_count 个 slug 全部属于 core/peripheral"

# 4. 抽样核心 skill（仓库内 skill）必须在输出中
#    注意：test-driven-development / verification-before-completion 已与 superpowers
#    插件去重（运行时加载），不再投影 —— 改用仓库内 skill 断言
must_present=("requesting-code-review" "two-stage-review" "brainstorming")
miss=0
for slug in "${must_present[@]}"; do
  # 匹配 [dry] <slug> 这种行（即 sync 计划实际复制该 skill）
  if ! echo "$output" | grep -qE "^\s*\[dry\] ${slug}\b"; then
    echo "  [MISS] $slug — 核心 skill 应在 sync 输出中"
    miss=$((miss + 1))
  fi
done

if [[ "$miss" -gt 0 ]]; then
  echo "[FAIL] $miss must-present core skills missing from sync output"
  exit 1
fi

echo "[ok] ${#must_present[@]} 个核心 skill 都在 sync 输出中"
echo ""
echo "All sync-layer tests passed."
