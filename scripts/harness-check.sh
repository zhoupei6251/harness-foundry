#!/bin/bash
# harness-check.sh — 跨平台 Capability Parity 检查工具
#
# 扫描所有适配器的 capability-matrix.yaml，输出 parity 差异报告
# 参考 ECC 的跨 Harness 适配器 DRY 模式
#
# 用法：bash scripts/harness-check.sh [--diff] [--platform=<name>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDRY_DIR="$(dirname "$SCRIPT_DIR")"
ADAPTERS_DIR="$FOUNDRY_DIR/adapters"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Harness Foundry — Capability Parity Check ==="
echo ""

# 发现所有适配器
adapters=()
for dir in "$ADAPTERS_DIR"/*/; do
    name=$(basename "$dir")
    # 跳过非适配器目录
    case "$name" in
        TEMPLATE|agents|.git) continue ;;
    esac
    if [ -f "$dir/capability-matrix.yaml" ]; then
        adapters+=("$name")
    fi
done

echo "发现适配器: ${adapters[*]}"
echo ""

# 统计每个适配器的 capability 状态
declare -A supported_count
declare -A degraded_count
declare -A manual_count
declare -A unsupported_count
declare -A total_count

for adapter in "${adapters[@]}"; do
    matrix="$ADAPTERS_DIR/$adapter/capability-matrix.yaml"
    version=$(grep -c "matrix_version:" "$matrix" 2>/dev/null || echo "unknown")

    s=$(grep -c "status: supported" "$matrix" 2>/dev/null || echo 0)
    d=$(grep -c "status: degraded" "$matrix" 2>/dev/null || echo 0)
    m=$(grep -c "status: manual" "$matrix" 2>/dev/null || echo 0)
    u=$(grep -c "status: unsupported" "$matrix" 2>/dev/null || echo 0)
    t=$((s + d + m + u))

    supported_count[$adapter]=$s
    degraded_count[$adapter]=$d
    manual_count[$adapter]=$m
    unsupported_count[$adapter]=$u
    total_count[$adapter]=$t

    # 检查 v1 vs v2
    if grep -q "matrix_version: 2" "$matrix" 2>/dev/null; then
        ver="v2"
    elif grep -q "matrix_version: 1" "$matrix" 2>/dev/null; then
        ver="v1 ⚠️ (建议升级到 v2)"
    else
        ver="unknown ⚠️"
    fi

    echo "  $adapter: $ver — $t capabilities ($s supported, $d degraded, $m manual, $u unsupported)"
done

echo ""

# Parity 差异分析
echo "--- Parity 差异分析 ---"
echo ""

# 找出所有 capability ID 的并集
all_caps=$(mktemp)
for adapter in "${adapters[@]}"; do
    grep "^  [a-z]" "$ADAPTERS_DIR/$adapter/capability-matrix.yaml" | \
        sed 's/://g' | sed 's/^  //' >> "$all_caps"
done
unique_caps=$(sort -u "$all_caps" | grep -v "^_" | grep -v "^$")
rm -f "$all_caps"

# 检查哪些 capability 在不同平台间状态不一致
inconsistencies=0
while IFS= read -r cap; do
    statuses=()
    for adapter in "${adapters[@]}"; do
        matrix="$ADAPTERS_DIR/$adapter/capability-matrix.yaml"
        status_line=$(grep -A2 "^  ${cap}:" "$matrix" 2>/dev/null | grep "status:" | head -1)
        if [ -n "$status_line" ]; then
            status=$(echo "$status_line" | sed 's/.*status: //' | tr -d ' ')
            statuses+=("$adapter=$status")
        else
            statuses+=("$adapter=missing")
        fi
    done

    # 检查状态是否一致
    first_status=$(echo "${statuses[0]}" | cut -d= -f2)
    all_same=true
    for s in "${statuses[@]}"; do
        s_status=$(echo "$s" | cut -d= -f2)
        if [ "$s_status" != "$first_status" ]; then
            all_same=false
            break
        fi
    done

    if [ "$all_same" = false ]; then
        echo -e "  ${YELLOW}⚠ ${cap}${NC}"
        for s in "${statuses[@]}"; do
            echo "      $s"
        done
        ((inconsistencies++))
    fi
done <<< "$unique_caps"

echo ""

# 缺失 capability 检查
echo "--- 缺失 Capability 检查 ---"
missing_count=0
for adapter in "${adapters[@]}"; do
    matrix="$ADAPTERS_DIR/$adapter/capability-matrix.yaml"

    # 检查 P0-1 execution-context 相关
    if ! grep -q "orchestration.provision-context" "$matrix" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠ $adapter 缺少 orchestration.provision-context (P0-1)${NC}"
        ((missing_count++))
    fi
    if ! grep -q "orchestration.destroy-context" "$matrix" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠ $adapter 缺少 orchestration.destroy-context (P0-1)${NC}"
        ((missing_count++))
    fi
done

echo ""

# 汇总
echo "--- 汇总 ---"
echo "  适配器总数: ${#adapters[@]}"
echo "  能力差异数: $inconsistencies"
echo "  缺失能力数: $missing_count"
echo ""

if [ $inconsistencies -gt 0 ] || [ $missing_count -gt 0 ]; then
    echo -e "${YELLOW}⚠ 发现 parity 差异，建议对齐各适配器的 capability 声明${NC}"
else
    echo -e "${GREEN}✅ 所有适配器 parity 一致${NC}"
fi

# v1 适配器提醒
v1_adapters=()
for adapter in "${adapters[@]}"; do
    matrix="$ADAPTERS_DIR/$adapter/capability-matrix.yaml"
    if grep -q "matrix_version: 1" "$matrix" 2>/dev/null; then
        v1_adapters+=("$adapter")
    fi
done

if [ ${#v1_adapters[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ 以下适配器仍在使用 v1 schema，建议升级到 v2:${NC}"
    for a in "${v1_adapters[@]}"; do
        echo "  - $a (模板: adapters/TEMPLATE/capability-matrix.yaml)"
    done
fi
