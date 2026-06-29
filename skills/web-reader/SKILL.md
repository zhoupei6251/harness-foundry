---
name: web-reader
description: 网页抓取，从 URL 提取结构化正文内容
metadata:
  origin: placeholder
  priority: P1
  tags:
  - shared
  - fetch
  - web
version: 1.0.0
when_to_use: 调用 web-reader 时
status: peripheral
tags:
- shared
domain: shared
category: shared.workflow
---
# 网页抓取

## 激活条件

- 需要从 URL 提取网页正文
- 需要抓取文档、公告、博客内容
- 需要 Markdown 化的页面结构

## 核心能力

### 抓取能力
- 使用 `web_fetch` 工具
- 自动 Markdown 化
- 结构化提取

## 产物

- 网页正文内容（Markdown 格式）
