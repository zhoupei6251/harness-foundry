#!/bin/bash
# 运行所有测试（L1 + L2）
# P2-6 升级：3 层测试体系
# 用途：一键验证 harness-foundry 配置

# 从脚本自身位置定位 tests 目录：
#   - 在 harness-foundry 根运行: bash tests/run-all-tests.sh
#   - 从宿主项目根运行:         bash harness-foundry/tests/run-all-tests.sh
# 两种方式均正确解析；PROJECT_ROOT 参数仅向后兼容保留。
PROJECT_ROOT="${1:-}"
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 运行 harness-foundry 测试套件..."
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local name="$1"
    local script="$2"
    echo "═══════════════════════════════════════"
    echo "📦 $name"
    echo "─────────────────────────────────────"
    if [ -f "$script" ]; then
        if bash "$script" "$PROJECT_ROOT"; then
            ((PASSED_TESTS++))
        else
            ((FAILED_TESTS++))
        fi
    else
        echo "  ⚠️  跳过（文件不存在）: $script"
    fi
    ((TOTAL_TESTS++))
    echo ""
}

# === L1 静态测试（免费/<2s） ===
echo "--- L1 静态测试 ---"
echo ""

run_test "L1-1: Config Schema 验证" "$TESTS_DIR/L1-static/validate-config-schema.sh"
run_test "L1-2: Agent 格式一致性" "$TESTS_DIR/L1-static/validate-agent-format.sh"
run_test "L1-3: Skill Metadata 完整性" "$TESTS_DIR/L1-static/validate-skill-meta.sh"
run_test "L1-4: NEVER.md 可检测性" "$TESTS_DIR/L1-static/validate-never.sh"
run_test "L1-5: 文档数字一致性" "$TESTS_DIR/L1-static/validate-doc-numbers.sh"
run_test "L1-6: 孤儿 Skill 检测" "$TESTS_DIR/L1-static/validate-orphan-skills.sh"
run_test "L1-8: novel-graph 校验" "$TESTS_DIR/L1-static/validate-novel-graph.sh"
run_test "L1-9: novel AI 痕迹红线回归" "$TESTS_DIR/L1-static/validate-novel-redlines.sh"
run_test "L1-10: news 自检清单" "$TESTS_DIR/L1-static/validate-news-checklist.sh"
run_test "L1-11: code 自检清单" "$TESTS_DIR/L1-static/validate-code-checklist.sh"
run_test "L1-12: novel continuity 连续性引擎" "$TESTS_DIR/L1-static/validate-novel-continuity.sh"
run_test "L1-13: novel mechanical scorer" "$TESTS_DIR/L1-static/validate-novel-scorer.sh"

# === L2 集成测试（本地） ===
echo "--- L2 集成测试 ---"
echo ""

run_test "L2-1: Routing 完整性" "$TESTS_DIR/L2-integration/validate-routing.sh"
run_test "L2-2: Domain Config 引用一致性" "$TESTS_DIR/L2-integration/validate-domain-config.sh"
run_test "L2-3: 路由触发（意图→路由命中）" "$TESTS_DIR/L2-integration/validate-route-triggers.sh"

# === L3-intelligence（静态，无外部依赖，已收编进 verify.sh） ===
echo "--- L3 Intelligence 集成测试（静态） ---"
echo ""

run_test "L3I-1: Skill 路由配置" "$TESTS_DIR/L3-intelligence/test-skill-routing.sh"
run_test "L3I-2: Agent 集成" "$TESTS_DIR/L3-intelligence/test-agent-integration.sh"
run_test "L3I-3: MCP 配置" "$TESTS_DIR/L3-intelligence/test-mcp-config.sh"

# 旧的验证脚本（向后兼容）
# 不传参数：legacy 脚本内部自动检测 harness 根目录（见脚本头部用法说明）
if [ -f "$TESTS_DIR/validate-config.sh" ]; then
    run_test "L2-3: 配置完整性 (legacy)" "$TESTS_DIR/validate-config.sh"
fi
if [ -f "$TESTS_DIR/validate-references.sh" ]; then
    run_test "L2-4: 文件引用完整性 (legacy)" "$TESTS_DIR/validate-references.sh"
fi

# === L3 评估（未实现，见 L3-eval/eval-with-llm-judge.md） ===
echo "--- L3 评估 ---"
echo "  未实现。LLM 裁判层脚本不存在（见 tests/L3-eval/eval-with-llm-judge.md 现状盘点）。"
echo ""

# 汇总结果
echo "═══════════════════════════════════════"
echo "📊 测试结果汇总"
echo "═══════════════════════════════════════"
echo "总测试数: $TOTAL_TESTS"
echo "通过: $PASSED_TESTS"
echo "失败: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ 所有测试通过！"
    exit 0
else
    echo "❌ 有 $FAILED_TESTS 个测试失败"
    exit 1
fi
