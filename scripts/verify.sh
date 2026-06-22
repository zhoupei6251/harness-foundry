#!/usr/bin/env bash
# Harness Kit CI 验证脚本（平台无关）
# 适用：GitHub Actions / Gitee Go / GitLab CI / 本地手动验证

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 1. 验证 bash 脚本语法
echo "==> [1/4] 验证 bash 脚本语法"
for script in scripts/*.sh; do
  bash -n "$script" && echo "  [ok] $script"
done

# 2. 验证 dry-run（不会真实修改文件）
echo ""
echo "==> [2/4] bootstrap dry-run"
bash scripts/bootstrap.sh --target all --dry-run > /tmp/bootstrap-dryrun.log 2>&1 && \
  echo "  [ok] bootstrap --target all --dry-run" || \
  { echo "  [FAIL] bootstrap --dry-run"; cat /tmp/bootstrap-dryrun.log; exit 1; }

echo ""
echo "==> [3/4] sync-skills dry-run"
bash scripts/sync-skills.sh --target all --dry-run > /tmp/sync-skills-dryrun.log 2>&1 && \
  echo "  [ok] sync-skills --target all --dry-run" || \
  { echo "  [FAIL] sync-skills --dry-run"; cat /tmp/sync-skills-dryrun.log; exit 1; }

# 3. 验证 skill 目录结构
echo ""
echo "==> [4/4] 验证 skill 目录结构（每个 skill 必须有 SKILL.md）"
missing=0
for skill_dir in skills/harness/*/ skills/third-party/superpowers/*/; do
  if [[ -d "$skill_dir" ]]; then
    if [[ -f "${skill_dir}SKILL.md" ]]; then
      echo "  [ok] ${skill_dir}"
    else
      echo "  [FAIL] ${skill_dir} missing SKILL.md"
      missing=$((missing + 1))
    fi
  fi
done

if [[ $missing -gt 0 ]]; then
  echo "==> $missing skill(s) missing SKILL.md"
  exit 1
fi

echo ""
echo "==> All checks passed."