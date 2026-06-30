#!/bin/bash
# canary-rotate.sh — Canary Token 轮换脚本
#
# 用法：bash scripts/canary-rotate.sh [--domain=<code|novel|news|all>]
#       bash scripts/canary-rotate.sh --emergency  # 检测到泄露时立即轮换

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDRY_DIR="$(dirname "$SCRIPT_DIR")"
TOKENS_FILE="$FOUNDRY_DIR/core/security/canary-tokens.yaml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 生成 32 位 hex nonce
generate_nonce() {
    openssl rand -hex 16 2>/dev/null || {
        # fallback: 使用 /dev/urandom
        cat /dev/urandom | tr -dc 'a-f0-9' | head -c 32
    }
}

# 轮换单个 domain 的 token
rotate_domain() {
    local domain="$1"
    local nonce
    nonce=$(generate_nonce)
    local token="HF_CANARY_${domain}_${nonce}"
    echo "$token"
}

# 主逻辑
DOMAIN="${1:-all}"
EMERGENCY=false

if [ "$DOMAIN" = "--emergency" ]; then
    EMERGENCY=true
    DOMAIN="all"
fi

echo "=== Canary Token 轮换 ==="

NOW=$(date -Iseconds)
EXPIRE=$(date -Iseconds -d "+7 days" 2>/dev/null || date -Iseconds)

if [ "$EMERGENCY" = true ]; then
    echo -e "${RED}⚠️  紧急轮换模式（检测到疑似泄露）${NC}"
fi

if [ "$DOMAIN" = "all" ]; then
    echo "轮换所有域..."

    CODE_TOKEN=$(rotate_domain "code")
    NOVEL_TOKEN=$(rotate_domain "novel")
    NEWS_TOKEN=$(rotate_domain "news")

    echo ""
    echo "新 Token:"
    echo "  code:  $CODE_TOKEN"
    echo "  novel: $NOVEL_TOKEN"
    echo "  news:  $NEWS_TOKEN"

    # 更新 tokens 文件（如果存在）
    if [ -f "$TOKENS_FILE" ]; then
        cat > "$TOKENS_FILE" << EOF
# Canary Token 定义文件
# ⚠️ 本文件包含安全凭据，不得提交到版本控制！
# 上次轮换: $NOW
# 下次轮换: $EXPIRE
# 轮换触发: $( [ "$EMERGENCY" = true ] && echo "emergency" || echo "scheduled" )

active_session:
  generated_at: "$NOW"
  expires_at: "$EXPIRE"
  tokens:
    code: "$CODE_TOKEN"
    novel: "$NOVEL_TOKEN"
    news: "$NEWS_TOKEN"
EOF
        echo ""
        echo -e "${GREEN}✅ Tokens updated at $TOKENS_FILE${NC}"
    fi
else
    TOKEN=$(rotate_domain "$DOMAIN")
    echo "  $DOMAIN: $TOKEN"

    if [ -f "$TOKENS_FILE" ]; then
        echo -e "${YELLOW}⚠️  请手动更新 $TOKENS_FILE 中 $DOMAIN 的 token${NC}"
    fi
fi

echo ""
echo "注意:"
echo "  1. Token 不得提交到版本控制"
echo "  2. 旧 Token 标记为 revoked"
echo "  3. 如为紧急轮换，分析 audit log 确认泄露范围"
