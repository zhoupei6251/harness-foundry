#!/usr/bin/env bash
# 把 harness-kit/third-party/ 内容投影到 .trae/ (Trae IDE 读取路径)
#
# 用法:
#   sync-third-party.sh                  # 正向: third-party/ -> .trae/
#   sync-third-party.sh --reverse        # 反向: .trae/ -> third-party/  (升级/回填)
#   sync-third-party.sh --dry-run        # 仅显示计划
#
# 详见:
#   harness-kit/docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md

set -euo pipefail

# TRUTH_SOURCE 根：harness-kit 仓库根（独立仓库）
TRUTH_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$TRUTH_ROOT" ]]; then
  TRUTH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
fi

# PROJECT 根：harness-kit 的父目录（含 .trae/）
# 可被环境变量 HARNESS_PROJECT_ROOT 覆盖
if [[ -z "${HARNESS_PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(cd "${TRUTH_ROOT}/.." >/dev/null 2>&1 && pwd)"
else
  PROJECT_ROOT="${HARNESS_PROJECT_ROOT}"
fi

THIRD_PARTY="${TRUTH_ROOT}/third-party"
TRAE_SKILLS="${PROJECT_ROOT}/.trae/skills"
TRAE_AGENTS="${PROJECT_ROOT}/.trae/agents"

echo "TRUTH_ROOT=${TRUTH_ROOT}"
echo "PROJECT_ROOT=${PROJECT_ROOT}"

DRY_RUN=0
REVERSE=0

usage() {
  cat <<EOF
Usage: sync-third-party.sh [--reverse] [--dry-run]

默认（正向）：harness-kit/third-party/ -> .trae/
--reverse：   .trae/ -> harness-kit/third-party/（升级或回填）
--dry-run：   仅打印，不执行
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reverse) REVERSE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown: $1" >&2; usage; exit 1 ;;
  esac
done

# 第三方来源清单（hard-coded，不走 manifest）
SP_SKILLS=(
  "subagent-driven-development"
  "dispatching-parallel-agents"
  "using-git-worktrees"
  "executing-plans"
)

# 第三方 agent 清单：
# - SP 4 个 / ECC SKILLS 271 个走硬编码（与 sync-skills.sh SKIP_FROM_SYNC 一致）
# - ECC AGENTS 改动态发现：扫描 third-party/ecc/agents/*.md，
#   与 README 宣称的"70 个 ECC agent"保持一致，无需手工维护清单。
# 详情：https://github.com/your-org/harness-kit/blob/main/docs/CHANGELOG.md
discover_ecc_agents() {
  local agents_dir="${THIRD_PARTY}/ecc/agents"
  if [[ ! -d "$agents_dir" ]]; then
    echo "    [warn] ${agents_dir} not found, ECC_AGENTS will be empty" >&2
    return 0
  fi
  # 找出所有 *.md（agent body），跳过 .meta.json。Windows 下 find 不支持 -printf 时用 -exec basename。
  if find "$agents_dir" -maxdepth 1 -name '*.md' -type f -printf '%f\n' >/dev/null 2>&1; then
    find "$agents_dir" -maxdepth 1 -name '*.md' -type f -printf '%f\n' 2>/dev/null \
      | sed -e 's/\.md$//' -e 's/[[:space:]]*$//' \
      | grep -v '^\.meta$' \
      | sort
  else
    # macOS / 部分 BSD find fallback
    find "$agents_dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null \
      | while IFS= read -r f; do basename "$f" .md; done \
      | sort
  fi
}

ECC_AGENTS=()
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  # 防御性去 Windows CRLF（PowerShell 写入时可能留下 \r）
  name="${name%$'\r'}"
  ECC_AGENTS+=("$name")
done < <(discover_ecc_agents)

ECC_SKILLS=(
  "accessibility"
  "agent-architecture-audit"
  "agent-eval"
  "agent-harness-construction"
  "agentic-engineering"
  "agentic-os"
  "agent-introspection-debugging"
  "agent-payment-x402"
  "agent-self-evaluation"
  "agent-sort"
  "ai-first-engineering"
  "ai-regression-testing"
  "android-clean-architecture"
  "angular-developer"
  "api-connector-builder"
  "api-design"
  "architecture-decision-records"
  "article-writing"
  "automation-audit-ops"
  "autonomous-agent-harness"
  "autonomous-loops"
  "backend-patterns"
  "benchmark"
  "benchmark-methodology"
  "benchmark-optimization-loop"
  "blender-motion-state-inspection"
  "blueprint"
  "brand-discovery"
  "brand-voice"
  "browser-qa"
  "bun-runtime"
  "canary-watch"
  "carrier-relationship-management"
  "cisco-ios-patterns"
  "ck"
  "claude-devfleet"
  "clickhouse-io"
  "click-path-audit"
  "codebase-onboarding"
  "codehealth-mcp"
  "code-tour"
  "coding-standards"
  "competitive-platform-analysis"
  "competitive-report-structure"
  "compose-multiplatform-patterns"
  "config-gc"
  "configure-ecc"
  "connections-optimizer"
  "content-engine"
  "content-hash-cache-pattern"
  "context-budget"
  "continuous-agent-loop"
  "continuous-learning"
  "continuous-learning-v2"
  "cost-aware-llm-pipeline"
  "cost-tracking"
  "council"
  "cpp-coding-standards"
  "cpp-testing"
  "crosspost"
  "csharp-testing"
  "customer-billing-ops"
  "customs-trade-compliance"
  "dart-flutter-patterns"
  "dashboard-builder"
  "database-migrations"
  "data-scraper-agent"
  "data-throughput-accelerator"
  "deep-research"
  "defi-amm-security"
  "deployment-patterns"
  "design-system"
  "django-celery"
  "django-patterns"
  "django-security"
  "django-tdd"
  "django-verification"
  "dmux-workflows"
  "docker-patterns"
  "documentation-lookup"
  "dotnet-patterns"
  "dynamic-workflow-mode"
  "e2e-testing"
  "ecc-guide"
  "ecc-tools-cost-audit"
  "email-ops"
  "energy-procurement"
  "enterprise-agent-ops"
  "error-handling"
  "eval-harness"
  "evm-token-decimals"
  "exa-search"
  "fal-ai-media"
  "fastapi-patterns"
  "finance-billing-ops"
  "flox-environments"
  "flutter-dart-code-review"
  "foundation-models-on-device"
  "frontend-a11y"
  "frontend-design-direction"
  "frontend-patterns"
  "frontend-slides"
  "fsharp-testing"
  "gan-style-harness"
  "gateguard"
  "generating-python-installer"
  "github-ops"
  "git-workflow"
  "golang-patterns"
  "golang-testing"
  "google-workspace-ops"
  "healthcare-cdss-patterns"
  "healthcare-emr-patterns"
  "healthcare-eval-harness"
  "healthcare-phi-compliance"
  "hermes-imports"
  "hexagonal-architecture"
  "hipaa-compliance"
  "homelab-network-readiness"
  "homelab-network-setup"
  "homelab-pihole-dns"
  "homelab-vlan-segmentation"
  "homelab-wireguard-vpn"
  "hookify-rules"
  "inherit-legacy-style"
  "intent-driven-development"
  "inventory-demand-planning"
  "investor-materials"
  "investor-outreach"
  "ios-icon-gen"
  "iterative-retrieval"
  "ito-basket-compare"
  "ito-data-atlas-agent"
  "ito-market-intelligence"
  "ito-trade-planner"
  "java-coding-standards"
  "jira-integration"
  "jpa-patterns"
  "knowledge-ops"
  "kotlin-coroutines-flows"
  "kotlin-exposed-patterns"
  "kotlin-ktor-patterns"
  "kotlin-patterns"
  "kotlin-testing"
  "kubernetes-patterns"
  "laravel-patterns"
  "laravel-plugin-discovery"
  "laravel-security"
  "laravel-tdd"
  "laravel-verification"
  "latency-critical-systems"
  "lead-intelligence"
  "liquid-glass-design"
  "llm-trading-agent-security"
  "logistics-exception-management"
  "make-interfaces-feel-better"
  "manim-video"
  "marketing-campaign"
  "market-research"
  "mcp-server-patterns"
  "messages-ops"
  "ml-adoption-playbook"
  "mle-workflow"
  "motion-advanced"
  "motion-foundations"
  "motion-patterns"
  "motion-ui"
  "mysql-patterns"
  "nanoclaw-repl"
  "nestjs-patterns"
  "netmiko-ssh-automation"
  "network-bgp-diagnostics"
  "network-config-validation"
  "network-interface-health"
  "nextjs-turbopack"
  "nodejs-keccak256"
  "nutrient-document-processing"
  "nuxt4-patterns"
  "openclaw-persona-forge"
  "opensource-pipeline"
  "orch-add-feature"
  "orch-build-mvp"
  "orch-change-feature"
  "orch-fix-defect"
  "orch-pipeline"
  "orch-refine-code"
  "parallel-execution-optimizer"
  "perl-patterns"
  "perl-security"
  "perl-testing"
  "plankton-code-quality"
  "plan-orchestrate"
  "postgres-patterns"
  "prediction-market-oracle-research"
  "prediction-market-risk-review"
  "prisma-patterns"
  "product-capability"
  "production-audit"
  "production-scheduling"
  "product-lens"
  "project-flow-ops"
  "prompt-optimizer"
  "python-patterns"
  "python-testing"
  "pytorch-patterns"
  "quality-nonconformance"
  "quarkus-patterns"
  "quarkus-security"
  "quarkus-tdd"
  "quarkus-verification"
  "ralphinho-rfc-pipeline"
  "react-patterns"
  "react-performance"
  "react-testing"
  "recsys-pipeline-architect"
  "recursive-decision-ledger"
  "redis-patterns"
  "regex-vs-llm-structured-text"
  "remotion-video-creation"
  "repo-scan"
  "research-ops"
  "returns-reverse-logistics"
  "rules-distill"
  "rust-patterns"
  "rust-testing"
  "safety-guard"
  "santa-method"
  "scientific-db-pubmed-database"
  "scientific-db-uspto-database"
  "scientific-pkg-gget"
  "scientific-thinking-literature-review"
  "scientific-thinking-scholar-evaluation"
  "search-first"
  "security-bounty-hunter"
  "security-review"
  "security-scan"
  "seo"
  "skill-comply"
  "skill-scout"
  "skill-stocktake"
  "social-graph-ranker"
  "social-publisher"
  "springboot-patterns"
  "springboot-security"
  "springboot-tdd"
  "springboot-verification"
  "strategic-compact"
  "swift-actor-persistence"
  "swift-concurrency-6-2"
  "swift-protocol-di-testing"
  "swiftui-patterns"
  "taste"
  "tdd-workflow"
  "team-agent-orchestration"
  "team-builder"
  "terminal-ops"
  "tinystruct-patterns"
  "token-budget-advisor"
  "ui-demo"
  "ui-to-vue"
  "uncloud"
  "unified-notifications-ops"
  "verification-loop"
  "videodb"
  "video-editing"
  "visa-doc-translate"
  "vite-patterns"
  "vue-patterns"
  "windows-desktop-e2e"
  "workspace-surface-audit"
  "x-api"
)

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "    [dry] $*"
  else
    "$@"
  fi
}

sync_sp_skill() {
  local slug="$1"
  # 去除 Windows CRLF 残留（PowerShell 写入时可能留下 \r）
  slug="${slug%$'\r'}"
  local src dst
  if [[ "$REVERSE" -eq 1 ]]; then
    src="${TRAE_SKILLS}/${slug}"
    dst="${THIRD_PARTY}/superpowers/skills/${slug}"
  else
    src="${THIRD_PARTY}/superpowers/skills/${slug}"
    dst="${TRAE_SKILLS}/${slug}"
  fi

  if [[ ! -d "$src" ]]; then
    echo "  [skip] ${slug} — source not found: ${src}"
    return 0
  fi

  echo "  [ok] ${slug}"
  run rm -rf "$dst"
  run mkdir -p "$(dirname "$dst")"
  run cp -a "$src" "$dst"
}

sync_ecc_skill() {
  local slug="$1"
  # 去除 Windows CRLF 残留（PowerShell 写入时可能留下 \r）
  slug="${slug%$'\r'}"
  local src dst
  if [[ "$REVERSE" -eq 1 ]]; then
    src="${TRAE_SKILLS}/${slug}"
    dst="${THIRD_PARTY}/ecc/skills/${slug}"
  else
    src="${THIRD_PARTY}/ecc/skills/${slug}"
    dst="${TRAE_SKILLS}/${slug}"
  fi

  if [[ ! -d "$src" ]]; then
    echo "  [skip] ${slug} — source not found: ${src}"
    return 0
  fi

  echo "  [ok] ${slug}"
  run rm -rf "$dst"
  run mkdir -p "$(dirname "$dst")"
  run cp -a "$src" "$dst"
}

sync_agent() {
  local name="$1"
  # 去除 Windows CRLF 残留
  name="${name%$'\r'}"
  local src dst
  local src_meta dst_meta
  if [[ "$REVERSE" -eq 1 ]]; then
    src="${TRAE_AGENTS}/${name}.md"
    dst="${THIRD_PARTY}/ecc/agents/${name}.md"
    src_meta="${TRAE_AGENTS}/${name}.meta.json"
    dst_meta="${THIRD_PARTY}/ecc/agents/${name}.meta.json"
  else
    src="${THIRD_PARTY}/ecc/agents/${name}.md"
    dst="${TRAE_AGENTS}/${name}.md"
    src_meta="${THIRD_PARTY}/ecc/agents/${name}.meta.json"
    dst_meta="${TRAE_AGENTS}/${name}.meta.json"
  fi

  if [[ ! -f "$src" ]]; then
    echo "  [skip] ${name} — source not found: ${src}"
    return 0
  fi

  echo "  [ok] ${name}.md"
  run mkdir -p "$(dirname "$dst")"
  run cp "$src" "$dst"

  if [[ -f "$src_meta" ]]; then
    echo "  [ok] ${name}.meta.json"
    run cp "$src_meta" "$dst_meta"
  fi
}

# 主流程
mode="forward (third-party -> .trae)"
[[ "$REVERSE" -eq 1 ]] && mode="reverse (.trae -> third-party)"
[[ "$DRY_RUN" -eq 1 ]] && mode="${mode} [dry-run]"

echo "==> Sync third-party: ${mode}"
mkdir -p "${TRAE_SKILLS}" "${TRAE_AGENTS}" \
         "${THIRD_PARTY}/superpowers/skills" \
         "${THIRD_PARTY}/ecc/agents" \
         "${THIRD_PARTY}/ecc/skills"

echo "==> Superpowers Skills (${#SP_SKILLS[@]}):"
for s in "${SP_SKILLS[@]}"; do
  sync_sp_skill "$s"
done

echo "==> ECC Skills (${#ECC_SKILLS[@]}):"
for s in "${ECC_SKILLS[@]}"; do
  sync_ecc_skill "$s"
done

echo "==> ECC Agents (${#ECC_AGENTS[@]}):"
for a in "${ECC_AGENTS[@]}"; do
  sync_agent "$a"
done

echo "Done."