#!/usr/bin/env bash
# Harness Kit CI 验证脚本（平台无关）
# 适用：GitHub Actions / Gitee Go / GitLab CI / 本地手动验证

set -euo pipefail

# 确保 yq / python3 在 PATH（Wave 3 报告的 PATH 缺失问题）
export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/local/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Platform-adaptive temp dir
if [[ -n "${RUNNER_TEMP:-}" ]]; then
  # GitHub Actions / Gitee Go
  TMP_DIR="$RUNNER_TEMP"
elif [[ -n "${TMPDIR:-}" ]]; then
  TMP_DIR="$TMPDIR"
elif [[ -d /tmp ]]; then
  TMP_DIR=/tmp
else
  TMP_DIR="${ROOT}/tmp"
  mkdir -p "$TMP_DIR"
fi

BOOTSTRAP_LOG="${TMP_DIR}/bootstrap-dryrun.log"
SYNC_LOG="${TMP_DIR}/sync-skills-dryrun.log"

# 1. 验证 bash 脚本语法
echo "==> [1/9] 验证 bash 脚本语法"
for script in scripts/*.sh; do
  bash -n "$script" && echo "  [ok] $script"
done

# 2. 验证 dry-run（不会真实修改文件）
echo ""
echo "==> [2/9] 规则冲突检测"
bash scripts/check-rule-conflicts.sh > "$TMP_DIR/rule-conflicts.log" 2>&1 && echo "  [ok] 规则冲突检测通过" || { echo "  [FAIL] 规则冲突检测"; cat "$TMP_DIR/rule-conflicts.log"; exit 1; }

echo ""
echo "==> [3/9] bootstrap dry-run"
bash scripts/bootstrap.sh --target all --dry-run > "$BOOTSTRAP_LOG" 2>&1 && \
  echo "  [ok] bootstrap --target all --dry-run" || \
  { echo "  [FAIL] bootstrap --dry-run"; cat "$BOOTSTRAP_LOG"; exit 1; }

echo ""
echo "==> [4/9] sync-skills dry-run"
bash scripts/sync-skills.sh --target all --dry-run > "$SYNC_LOG" 2>&1 && \
  echo "  [ok] sync-skills --target all --dry-run" || \
  { echo "  [FAIL] sync-skills --dry-run"; cat "$SYNC_LOG"; exit 1; }

# 5. 验证 skill 目录结构
echo ""
echo "==> [5/9] 验证 skill 目录结构（每个 skill 必须有 SKILL.md）"
missing=0
for skill_dir in skills/*/; do
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

# 6. 验证 Skill frontmatter（严格：失败即退出）
echo ""
echo "==> [6/9] 验证 Skill frontmatter"
if bash tests/L1-static/validate-skill-frontmatter.sh 2>&1 | tail -n 50; then
  echo "  [ok] frontmatter validation"
else
  echo "  [FAIL] frontmatter validation"
  exit 1
fi

# 7. 验证 Skill _meta.json（严格：失败即退出）
echo ""
echo "==> [7/9] 验证 Skill _meta.json"
if bash tests/L1-static/validate-skill-meta.sh 2>&1 | tail -n 50; then
  echo "  [ok] _meta validation"
else
  echo "  [FAIL] _meta validation"
  exit 1
fi

# 8. 验证 agent 格式 + config schema + routing + domain-config + intelligence（L1/L2 静态与集成）
echo ""
echo "==> [8/9] 运行 tests/ 静态与集成测试套件"
for t in \
  tests/L1-static/validate-agent-format.sh \
  tests/L1-static/validate-config-schema.sh \
  tests/L1-static/validate-never.sh \
  tests/L1-static/validate-orphan-skills.sh \
  tests/L1-static/validate-novel-graph.sh \
  tests/L1-static/validate-novel-redlines.sh \
  tests/L1-static/validate-novel-continuity.sh \
  tests/L1-static/validate-novel-scorer.sh \
  tests/L1-static/validate-novel-foreshadowing.sh \
  tests/L1-static/validate-novel-memory-health.sh \
  tests/L1-static/validate-novel-memory-injector.sh \
  tests/L1-static/validate-novel-checkpoint.sh \
  tests/L1-static/validate-novel-export.sh \
  tests/L1-static/validate-novel-metrics.sh \
  tests/L1-static/validate-news-checklist.sh \
  tests/L1-static/validate-code-checklist.sh \
  tests/L2-integration/validate-routing.sh \
  tests/L2-integration/validate-domain-config.sh \
  tests/L2-integration/validate-route-triggers.sh \
  tests/validate-intelligence-layer.sh \
  tests/L3-intelligence/test-skill-routing.sh \
  tests/L3-intelligence/test-agent-integration.sh \
  tests/L3-intelligence/test-mcp-config.sh; do
  echo "  -- $t"
  if ! bash "$t" 2>&1 | tail -n 40; then
    echo "  [FAIL] $t"
    exit 1
  fi
done
echo "  [ok] tests/ 静态与集成测试全部通过"

# Skill 行为测试（eval runner；无测试的 skill 不阻塞，有测试的必须全过）
echo "  -- node scripts/eval/run-skill-eval.js --all"
if node scripts/eval/run-skill-eval.js --all 2>&1 | tail -n 15; then
  echo "  [ok] skill eval"
else
  echo "  [FAIL] skill eval"
  exit 1
fi

# 9. 总体状态
echo ""
echo "==> [9/9] 汇总"
echo "All checks passed."
