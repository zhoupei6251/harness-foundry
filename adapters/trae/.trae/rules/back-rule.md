# 后端开发规范（Trae）

## 适用

修改后端 Java 模块时。

## 必做

1. 加载相关 domain skill（如有）
2. 跨模块时 Read `harness-foundry/references/context-map.md`

## 规范摘要

- 分层：controller → service → domain → mapper
- 关键逻辑：日志 + 中文注释
- 验证：`harness-foundry/artifact-templates/project.verification.md`

## 禁令

Controller 写业务、循环 SQL、空 catch、泄露敏感信息。
