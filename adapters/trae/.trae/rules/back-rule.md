# 后端开发规范（Trae）

与 Cursor `Backend-Develop-Rule.mdc` 等价。

## 适用

修改 `ruoyi-modules/ruoyi-aigc` 及关联模块时。

## 必做

1. Load `ruoyi-aigc-backend-developer` skill（`.trae/skills/` 或 `.agents/skills/`）
2. 跨模块时 Read `harness-kit/context-map.md`

## 规范摘要

- 分层：controller → service → domain → mapper
- JDK21 + Spring Boot 3.5.6 + RuoYi 5.5.0
- 关键逻辑：日志 + 中文注释
- 验证：`harness-kit/project.verification.md`

## 禁令

Controller 写业务、循环 SQL、空 catch、泄露敏感信息。
