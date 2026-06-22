# Agents — 项目用到的 Agent 集合

> 10 个 Agent，分两类：7 个 **harness 角色**（编排核心） + 3 个 **ECC 专项 agent**（按需调用）。

## 目录结构

```
agents/
├── README.md                    # 本文件
├── harness/                     # 7 个 harness 角色
│   ├── leader.md                # Leader：意图路由 + 派发
│   ├── coder.md                 # Coder：写代码
│   ├── implementer.md           # Implementer：单点实现
│   ├── reviewer.md              # Reviewer：五轴审查
│   ├── test-engineer.md         # Test Engineer：TDD 测试
│   ├── debugger.md              # Debugger：bug 排查
│   └── web-investigator.md      # Web Investigator：联网调研
└── third-party/                 # 3 个 ECC 专项 agent（按需）
    └── ecc/
        ├── ecc-java-reviewer.md
        ├── ecc-security-reviewer.md
        └── ecc-database-reviewer.md
```

## Harness 角色（7 个，编排核心）

| 角色 | 文件 | 触发 | 主要能力 |
|------|------|------|---------|
| **leader** | [leader.md](harness/leader.md) | 收到任意请求 | 意图路由、阶段门禁、派发 subagent |
| **coder** | [coder.md](harness/coder.md) | 派发 "写代码" WU | 写代码实现（中等复杂度） |
| **implementer** | [implementer.md](harness/implementer.md) | 派发 "实现" WU | 单点实现（复杂度低） |
| **reviewer** | [reviewer.md](harness/reviewer.md) | 派发 "review" WU | 五轴审查（功能/可读/可维护/性能/安全）|
| **test-engineer** | [test-engineer.md](harness/test-engineer.md) | 派发 "测试" WU | TDD 测试 + 覆盖率 |
| **debugger** | [debugger.md](harness/debugger.md) | 派发 "debug" WU | 系统化调试（重现→最小化→假设→插桩）|
| **web-investigator** | [web-investigator.md](harness/web-investigator.md) | 派发 "调研" WU | 联网搜索 + 资料整理 |

## ECC 专项 agent（3 个，按需调用）

| Agent | 文件 | 触发时机 | 适用场景 |
|-------|------|---------|---------|
| **ecc-java-reviewer** | [ecc-java-reviewer.md](third-party/ecc/ecc-java-reviewer.md) | review 阶段对 Java 代码显式调用 | Java/Spring Boot 评审（分层架构、JPA、安全、并发）|
| **ecc-security-reviewer** | [ecc-security-reviewer.md](third-party/ecc/ecc-security-reviewer.md) | 写完 user input/auth/API endpoint/sensitive data 后 | 安全漏洞扫描（OWASP Top 10、secrets、SSRF、injection）|
| **ecc-database-reviewer** | [ecc-database-reviewer.md](third-party/ecc/ecc-database-reviewer.md) | 写 SQL/migration/schema/DB 性能排查 | 数据库评审（query 优化、schema 设计、PostgreSQL 实践）|

### 与 harness-reviewer 的关系

**互补关系**。harness-reviewer 做通用 review；ecc-* 做专项深扫。

```
推荐串联：
1. harness-reviewer   → 通用五轴审查（功能/可读/可维护/性能/安全）
2. ecc-java-reviewer  → Java/Spring 专项深扫（按需）
3. ecc-security-reviewer → 安全专项深扫（按需）
4. ecc-database-reviewer → 数据库专项深扫（按需）
```

调用方式：

```markdown
Task(
  subagent_type="general-purpose",
  prompt="以 ecc-java-reviewer 角色审查 src/main/java/.../UserService.java，重点关注：..."
)
```

## 使用方式

### 通过 Leader 派发

```yaml
# Leader 收到"设计并实现用户认证"的请求
intent: implement
role: leader
dispatch:
  - wu: implement-auth
    role: coder
    skills: [ruoyi-aigc-backend-developer, test-driven-development]
  - wu: review-auth
    role: reviewer
    skills: [requesting-code-review, code-review]
    on_demand:
      - ecc-security-reviewer  # 按需补充
```

### 手动指定 agent role

```bash
# 直接以 ecc-security-reviewer 身份审查
claude --agent ecc-security-reviewer "审查 src/ 下的所有 auth 代码"
```

## 真相源

| 角色/Agent | 真相源 |
|---------|-------|
| 7 个 harness 角色 | [`harness-kit/core/orchestration/agents/<role>.md`](../core/orchestration/agents/) |
| 3 个 ECC agent | [`harness-kit/third-party/ecc/agents/<name>.md`](../third-party/ecc/agents/) |

本目录是**分发快照**，真相源改动后需重新复制。

## 重新同步

```bash
# 7 个 harness 角色（来自 core/orchestration/agents/）
cp harness-kit/core/orchestration/agents/*.md harness-kit/agents/harness/

# 3 个 ECC agent（来自 third-party/ecc/agents/）
cp harness-kit/third-party/ecc/agents/*.md harness-kit/agents/third-party/ecc/

# 自动化
bash harness-kit/scripts/sync-third-party.sh
```

## License

MIT

---

**入口：** [`README.md`](../README.md) · [`skills/README.md`](../skills/README.md) · [`skills/INDEX.md`](../skills/INDEX.md)