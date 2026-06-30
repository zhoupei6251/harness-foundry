#!/bin/bash
# 运行所有测试（L1 + L2）
# P2-6 升级：3 层测试体系
# 用途：一键验证 harness-foundry 配置

PROJECT_ROOT="${1:-.}"
TESTS_DIR="$PROJECT_ROOT/harness-foundry/tests"

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

# === L2 集成测试（本地） ===
echo "--- L2 集成测试 ---"
echo ""

run_test "L2-1: Routing 完整性" "$TESTS_DIR/L2-integration/validate-routing.sh"
run_test "L2-2: Domain Config 引用一致性" "$TESTS_DIR/L2-integration/validate-domain-config.sh"

# 旧的验证脚本（向后兼容）
if [ -f "$TESTS_DIR/validate-config.sh" ]; then
    run_test "L2-3: 配置完整性 (legacy)" "$TESTS_DIR/validate-config.sh"
fi
if [ -f "$TESTS_DIR/validate-references.sh" ]; then
    run_test "L2-4: 文件引用完整性 (legacy)" "$TESTS_DIR/validate-references.sh"
fi

# === L3 评估（可选，手动触发） ===
echo "--- L3 评估 ---"
echo "  未触发。使用 EVALS=1 手动激活（需要 LLM API 调用）。"
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
