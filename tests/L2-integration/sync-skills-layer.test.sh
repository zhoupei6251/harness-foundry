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
arch_count=$(yq '.archived | length' "$LAYER_FILE")
hit=0
for slug in $(yq '.archived | .[]' "$LAYER_FILE"); do
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
#    解析 _layer.yaml 获取允许集
allowed_set=$(mktemp)
{
  yq '.core + .peripheral | .[]' "$LAYER_FILE"
  # 第三方保留技能（不在 _layer.yaml 中但 sync 保留）
  echo "subagent-driven-development"
  echo "dispatching-parallel-agents"
  echo "using-git-worktrees"
  echo "executing-plans"
} | sort -u > "$allowed_set"

# 从 sync output 中提取所有 [dry] 行内的 slug（精确匹配行首 + 已知前缀）
sourced_slugs=$(mktemp)
echo "$output" | grep -oE '^\s*\[(dry|skip-from-sync)\] [a-z0-9][a-z0-9-]*[a-z0-9]' | awk '{print $2}' | sort -u > "$sourced_slugs"
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

echo "[ok] sync 输出 $sourced_count 个 slug 全部属于 core/peripheral/第三方保留集"

# 4. 抽样核心 skill（test-driven-development / verification-before-completion）必须在输出中
#    sync output 的格式是: [dry] <slug> -> .../<slug>
must_present=("test-driven-development" "verification-before-completion" "requesting-code-review")
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