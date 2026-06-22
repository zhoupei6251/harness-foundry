---
name: project-verification-template
description: "项目级验证清单模板。开源版本含占位符，使用前请按项目替换。"
tags: [Standard, Runbook, Template]
---

# 项目验证清单（模板）

> **本文件是 Harness Kit 开源版本提供的模板**。克隆到你的项目后，按以下顺序替换：
>
> 1. `${BUILD_CMD}`：你的构建命令（如 `mvn -pl <module> -am compile -q`、`pnpm build`）
> 2. `${TEST_CMD}`：单元测试命令（如 `mvn test`、`pytest`）
> 3. `${LINT_CMD}`：lint 命令（如 `mvn checkstyle:check`、`ruff check`）
> 4. `${START_CMD}`：本地启动命令（如 `mvn spring-boot:run`、`pnpm dev`）
> 5. `${TEST_FRAMEWORK}`：测试框架（如 `JUnit 5` / `pytest` / `vitest`）
> 6. 若项目不是 Spring Boot，删除 L2 中的 `mvn -pl ruoyi-modules/ruoyi-aigc` 等 Java 特定命令

> 改完代码**不许**说"完成了"。按本清单逐项跑过，每项有命令 / 路径。

---

## 占位符速查

| 占位符 | 含义 | 示例 |
|--------|------|------|
| `${BUILD_CMD}` | 单模块编译命令 | `mvn -pl <module> -am compile -q` |
| `${TEST_CMD}` | 单测命令 | `mvn -pl <module> test` |
| `${LINT_CMD}` | lint 命令 | `mvn checkstyle:check` |
| `${START_CMD}` | 本地启动命令 | `mvn spring-boot:run` |
| `${TEST_FRAMEWORK}` | 测试框架 | `JUnit 5` |
| `${API_DOC}` | API 文档工具 | `Knife4j / Swagger UI` |

---

## Layer 1 — 静态检查（每次提交前）

| # | 项 | 命令 / 路径 |
|---|----|------------|
| 1.1 | 死链扫描 | `bash harness-kit/scripts/verify.sh` |
| 1.2 | 禁止空 catch | `Grep "catch\s*\([^\)]+\)\s*\{\s*\}"` 在改动文件里必须 0 命中 |
| 1.3 | 禁止 shell 写文本 | 本会话内不应出现 `Set-Content` / `Out-File` / `echo >` |
| 1.4 | 命名规范 | 类名 PascalCase、常量 UPPER_SNAKE、boolean getter `isXxx` |
| 1.5 | lint 通过 | `${LINT_CMD}` 退出码 0 |

## Layer 2 — 编译（影响模块时）

```bash
# 只编译改动模块（按团队约定不全量构建）
${BUILD_CMD}
```

> **例外**：用户明确说"不要构建"时跳过本项，但必须在交付前告知"未验证编译"。

## Layer 3 — 单元测试（写新方法 / 改关键路径时）

| 场景 | 必做 |
|------|------|
| 加 Service 写方法 | 先写 `${TEST_FRAMEWORK}` 测试覆盖 happy path + 1 个边界 |
| 改 SQL 查询 | 至少 1 条集成测试（连真实 DB 或 testcontainers） |
| 改缓存 Key | 至少 1 条缓存集成测试 |
| 加 API 接口 | MockMvc / Supertest 覆盖参数校验 + 鉴权 + 成功路径 |

测试目录约定：`<填入你的项目测试目录，如 src/test/java/...>`

## Layer 4 — 集成（影响跨模块 / 改主链路时）

| 检查 | 方法 |
|------|------|
| 启动后不报错 | `${START_CMD}`（开发机） |
| 接口联调 | 通过 `${API_DOC}` 调通主链路 |
| 数据隔离 | 切换租户/用户确认数据不串 |

## 验证门禁（不可跳）

| 改动范围 | 必须通过的 Layer |
|----------|------------------|
| 注释 / 文档 / Markdown | L1.1 死链扫描 |
| 单文件 < 50 行且无业务逻辑 | L1 全部 |
| 单文件含业务逻辑 | L1 + L2 |
| 跨文件 / 跨模块 | L1 + L2 + L3 |
| 改主链路（核心业务 / 登录 / 计费） | L1 + L2 + L3 + L4 |

## 验证证据格式

完成验证后，回复里**必须**写：

```
✅ Layer X 通过：<具体证据>
❌ Layer Y 失败：<失败原因 + 下一步>
```

不允许写"已验证通过"而没附证据。

---

## 模板填充示例（仅供参考，删除）

```
${BUILD_CMD}    = mvn -pl ruoyi-modules/ruoyi-aigc -am compile -q
${TEST_CMD}     = mvn -pl ruoyi-modules/ruoyi-aigc test
${START_CMD}    = mvn -pl ruoyi-modules/ruoyi-aigc spring-boot:run
${API_DOC}      = Knife4j / Swagger UI
```