#!/usr/bin/env bash
# L1-20: code_trap_scanner 真代码陷阱扫描器单元测试
# 用好坏 fixture 正负验证扫描器：
#   1. 好代码 → 0 命中
#   2. 坏代码 → 命中 8+ 类禁令（空 catch / SELECT * / N+1 / 拼接SQL / 硬编码密钥 /
#               日志泄敏感 / System.out / 魔法数 / 虚拟线程 synchronized）
#   3. --fail-on-error 退出码（坏代码 1 / 好代码 0）
#   4. 目录递归 + target 跳过
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SCANNER="scripts/code/code_trap_scanner.py"
PASS() { echo "  [PASS] $1"; }
FAIL() { echo "  [FAIL] $1"; FAILED=$((FAILED + 1)); }

# ---- fixture：好代码（全部合规）----
mkdir -p "$TMP_DIR/good"
cat > "$TMP_DIR/good/GoodService.java" <<'EOF'
public class GoodService {
    private static final int MAX_RETRY = 3;

    public List<Order> listByIds(Collection<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyList();
        }
        return orderMapper.selectByIds(ids);
    }

    public void deductStock(Long orderId) {
        RLock lock = redissonClient.getLock("stock:" + orderId);
        try {
            if (!lock.tryLock(3, 10, TimeUnit.SECONDS)) {
                throw new ServiceException("系统繁忙，请稍后重试");
            }
            try {
                orderMapper.updateStock(orderId);
            } finally {
                if (lock.isHeldByCurrentThread()) {
                    lock.unlock();
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ServiceException("系统繁忙，请稍后重试");
        }
    }

    public void logUser(Long userId) {
        log.info("user login: {}", userId);
    }
}
EOF

# ---- fixture：坏代码（命中 9 类禁令）----
mkdir -p "$TMP_DIR/bad"
cat > "$TMP_DIR/bad/BadService.java" <<'EOF'
public class BadService {
    public void login(String username, String password) {
        try {
            User user = userMapper.selectByUsername(username);
            if (user == null) {
                return;
            }
        } catch (Exception e) {
            // 空 catch：静默吞异常
        }
        System.out.println("login: " + username);
    }

    public List<Order> listOrders(List<Long> ids) {
        List<Order> result = new ArrayList<>();
        for (Long id : ids) {
            result.add(orderMapper.selectById(id));
        }
        return result;
    }

    public List<Order> query(String table, Long id) {
        String sql = "SELECT * FROM " + table + " WHERE id = " + id;
        return jdbcTemplate.query(sql, rowMapper);
    }

    private static final String jwtSecret = "abc123secret456";
    private static final String apiKey = "sk-live-xxxxxxxxxxxxxxxx";
    private static final String password = "P@ssw0rd!";

    public void logIt(String pwd) {
        log.info("user password: " + pwd);
    }

    public int getRetry() {
        return 500;
    }

    public void vt() {
        Thread.ofVirtual().start(() -> {
            synchronized (lock) { work(); }
        });
    }
}
EOF

# ---- fixture：target 目录（应被跳过）----
mkdir -p "$TMP_DIR/good/target"
cat > "$TMP_DIR/good/target/Generated.java" <<'EOF'
public class Generated {
    public void x() { try { } catch (Exception e) { } }
}
EOF

run_scanner() {
  python "$SCANNER" "$1" --json
}

# 断言 1: 好代码 0 命中
echo "==> 好代码应 0 命中"
GOOD_JSON="$(run_scanner "$TMP_DIR/good")"
GOOD_ERR="$(echo "$GOOD_JSON" | python -c "import json,sys; print(json.load(sys.stdin)['errors'])")"
if [[ "$GOOD_ERR" == "0" ]]; then
  PASS "好代码 0 命中"
else
  FAIL "好代码有命中: errors=$GOOD_ERR"
fi

# 断言 2: 好代码目录递归含 target 跳过
GOOD_FILES="$(echo "$GOOD_JSON" | python -c "import json,sys; print(json.load(sys.stdin)['files_scanned'])")"
if [[ "$GOOD_FILES" == "1" ]]; then
  PASS "目录递归扫描 + target 跳过（files=$GOOD_FILES）"
else
  FAIL "files_scanned 应为 1（target 未跳过）: $GOOD_FILES"
fi

# 断言 3: 坏代码命中 9 类禁令
echo "==> 坏代码应命中 9 类禁令"
BAD_JSON="$(run_scanner "$TMP_DIR/bad")"
for rule in EMPTY_CATCH SELECT_STAR N_PLUS_ONE SQL_CONCAT HARDCODED_SECRET LOG_SENSITIVE SYSTEM_OUT MAGIC_NUMBER VIRTUAL_THREAD_SYNC; do
  if echo "$BAD_JSON" | python -c "import json,sys; d=json.load(sys.stdin); assert '$rule' in d['rules'], 'missing $rule'" 2>/dev/null; then
    PASS "$rule 被检出"
  else
    FAIL "$rule 未被检出"
  fi
done

# 断言 4: --fail-on-error 退出码
echo "==> 退出码语义"
if python "$SCANNER" "$TMP_DIR/bad" --fail-on-error > /dev/null 2>&1; then
  FAIL "坏代码 --fail-on-error 应退出 1"
else
  PASS "坏代码 --fail-on-error 退出 1"
fi
if python "$SCANNER" "$TMP_DIR/good" --fail-on-error > /dev/null 2>&1; then
  PASS "好代码 --fail-on-error 退出 0"
else
  FAIL "好代码 --fail-on-error 应退出 0"
fi

# 断言 5: 不存在的路径退出非 0
echo "==> 路径校验"
if python "$SCANNER" "$TMP_DIR/not-exist" > /dev/null 2>&1; then
  FAIL "不存在路径应退出非 0"
else
  PASS "不存在路径退出非 0"
fi

echo ""
echo "==> L1-20 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
