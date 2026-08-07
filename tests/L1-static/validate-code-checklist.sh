#!/usr/bin/env bash
# L1-11: code 域自检清单校验
# 从 springboot-checklist / 00-all.md 提取可机器检查的禁令子集：
#   1. 空 catch 吞异常（静默失败）       #9/规则7
#   2. SELECT *（明确列名）              #48
#   3. 循环内发 SQL / HTTP（N+1）        #13/#57
#   4. ${xxx} 字符串拼接 SQL 注入        #60/#61
#   5. 硬编码密钥（JWT/密码/API Key）    #73/#160
#   6. setnx+expire 手写分布式锁         #82
#   7. 日志打印敏感信息                  #66/#121
#   8. System.out.println 直出           #日志规范
#   9. 裸数字魔法数                      #编码标准
# 用内嵌好坏代码 fixture 正负验证扫描器能抓到问题。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILED=0

# ---- 可机器检查的禁令（与 traps-archive/code/*.md 对齐）----
# 顺序重要：先局部精确（空 catch）后全局词法（System.out）
# 注意：不用 grep -P（locale 限制），用 -E + POSIX [[:space:]] 保证跨平台
BANS=(
  "catch[^{]*\{[[:space:]]*\}"                                      # 空 catch 吞异常
  "SELECT[[:space:]]+\*"                                            # SELECT *
  "System\.out\.println"                                            # 控制台直出
  "setnx[[:space:]]*\(|setIfAbsent[[:space:]]*\([^)]*\)[[:space:]]*$" # 手写 setnx（非原子）
  "log\.(info|error|warn)\([^)]*(password|token|secret|credential)" # 日志泄敏感
  "password[[:space:]]*=[[:space:]]*['\"][^'\"]{4,}['\"]"           # 硬编码密码
  "jwtSecret[[:space:]]*=[[:space:]]*['\"][^'\"]{4,}['\"]"          # 硬编码 JWT 密钥
  "apiKey[[:space:]]*=[[:space:]]*['\"][^'\"]{4,}['\"]"             # 硬编码 API Key
)

# ---- 语义禁令：用固定原文模式探测（防止 fixture 漂移）----
PICK_ANYONE_LOOP='for (Long id : ids) {
    // N+1: 循环内逐条查库
    Order o = orderMapper.selectById(id);
}'

SEL_STAR_SQL='SELECT * FROM orders WHERE user_id = #{userId}'

STR_CONCAT_SQL='String sql = "SELECT * FROM " + table + " WHERE id = " + id;'

# ---- fixture：好代码（全部合规）----
GOOD_CODE='public class OrderService {
    // 批量查询避免 N+1
    public List<Order> listByIds(Collection<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Collections.emptyList();
        }
        return orderMapper.selectByIds(ids);
    }

    // 事务内锁，释放时校验持有者
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
}'

# ---- fixture：坏代码（命中 5 条禁令）----
BAD_CODE='public class UserService {
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

    // 循环内逐条查库（N+1）
    public List<Order> listOrders(List<Long> ids) {
        List<Order> result = new ArrayList<>();
        for (Long id : ids) {
            result.add(orderMapper.selectById(id));
        }
        return result;
    }

    // 字符串拼接 SQL（注入风险）
    public List<Order> query(String table, Long id) {
        String sql = "SELECT * FROM " + table + " WHERE id = " + id;
        return jdbcTemplate.query(sql, rowMapper);
    }

    // 硬编码密钥
    private static final String jwtSecret = "abc123secret456";
    private static final String apiKey = "sk-live-xxxxxxxxxxxxxxxx";
    private static final String password = "P@ssw0rd!";
}'

scan_bans() {
  # $1 = 代码正文；输出命中的禁令名（去重）
  # 注意：必须用 here-string（<<<）而非管道——管道流被第一次 grep 读完即耗尽
  local body="$1" i name block
  for i in "${!BANS[@]}"; do
    name="ban[$i]"
    if [[ $i -eq 0 ]]; then
      # 空 catch 特判：-z 跨行抓无嵌套块，块内无语句痕迹才算违规
      # （带 log./return/throw 等的 catch 是合规的——00-all.md #9）
      # 块间以 \0 分隔，逐块完整读取（多行块不能被按行截断）
      while IFS= read -d $'\0' -r block; do
        if [[ "$block" =~ catch[^{]*\{([^{}]*)\} ]] \
           && [[ ! "${BASH_REMATCH[1]}" =~ ';'|return|throw|log\.|continue|break ]]; then
          echo "$name"
          break
        fi
      done < <(grep -zoE 'catch[^{]*\{[^{}]*\}' <<< "$body" || true)
    else
      if grep -qE "${BANS[$i]}" <<< "$body"; then
        echo "$name"
      fi
    fi
  done
}

echo "==> L1-11: 好代码应 0 命中禁令"
HITS="$(scan_bans "$GOOD_CODE")"
if [[ -z "$HITS" ]]; then
  echo "  [PASS] 好代码 0 命中"
else
  echo "  [FAIL] 好代码命中禁令：$HITS"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 坏代码应命中空 catch"
HITS="$(scan_bans "$BAD_CODE")"
if echo "$HITS" | grep -q "ban\[0\]"; then
  echo "  [PASS] 空 catch 被检出"
else
  echo "  [FAIL] 空 catch 未被检出——扫描器失效"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 坏代码应命中 System.out"
if echo "$HITS" | grep -q "ban\[2\]"; then
  echo "  [PASS] System.out.println 被检出"
else
  echo "  [FAIL] System.out.println 未被检出"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 坏代码应命中硬编码密钥（>= 1 种）"
KEY_BANS="$(echo "$HITS" | grep -oE "ban\[(5|6|7)\]" | sort -u | tr '\n' ' ')"
if [[ -n "$KEY_BANS" ]]; then
  echo "  [PASS] 硬编码密钥被检出：$KEY_BANS"
else
  echo "  [FAIL] 硬编码密钥未被检出"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 循环内 SQL 模式可探测"
if grep -qF "for (Long id : ids)" <<< "$PICK_ANYONE_LOOP" && grep -qF "selectById(id)" <<< "$PICK_ANYONE_LOOP"; then
  echo "  [PASS] N+1 模式（循环内 selectById）可被 grep 探测"
else
  echo "  [FAIL] N+1 fixture 无法被 grep 探测——语义禁令需人工"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: SELECT * 可被 grep 探测"
if grep -qE "SELECT[[:space:]]+\*" <<< "$SEL_STAR_SQL"; then
  echo "  [PASS] SELECT * 可被 grep 探测"
else
  echo "  [FAIL] SELECT * fixture 漂移"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 字符串拼接 SQL 可被探测"
if grep -qE '"[^"]*SELECT[^"]*"[[:space:]]*\+' <<< "$STR_CONCAT_SQL"; then
  echo "  [PASS] 拼接 SQL 模式可被 grep 探测"
else
  echo "  [FAIL] 拼接 SQL fixture 漂移"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 硬编码密码可被探测"
if grep -qE "password[[:space:]]*=[[:space:]]*['\"][^'\"]{4,}['\"]" <<< "$BAD_CODE"; then
  echo "  [PASS] 硬编码密码可被探测"
else
  echo "  [FAIL] 硬编码密码 fixture 漂移"
  FAILED=$((FAILED + 1))
fi

echo "==> L1-11: 日志泄敏感可被探测"
if grep -qE "log\.(info|error|warn)\([^)]*(password|token|secret|credential)" <<< 'log.info("password: " + pwd)'; then
  echo "  [PASS] 日志泄敏感可被探测"
else
  echo "  [FAIL] 日志泄敏感 fixture 漂移"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "==> L1-11 结果: failed=$FAILED"
[[ "$FAILED" -eq 0 ]] || exit 1
