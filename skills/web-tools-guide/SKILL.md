---
name: web-tools-guide
description: 考据调研，使用 web_search 和 Read 工具查证历史背景、地理、文化细节
metadata:
  origin: harness-ink
  priority: P1
  tags:
  - research
  - web
  - investigation
version: 1.0.0
when_to_use: 调用 web-tools-guide 时
status: peripheral
tags:
- shared
domain: code
category: code.tooling
---
# 考据调研

## 激活条件

- 用户要求查资料（"查资料"、"考据"、"找素材"）
- 需要查证历史背景
- 需要确认地理/文化细节

## 核心能力

### 网络搜索
- 使用 `web_search` 搜索关键词
- 使用 `web_fetch` 抓取网页内容
- 多平台搜索（Google、Bing 等）

### 资料整理
- 提取关键信息
- 标注来源
- 分类整理

### 考据验证
- 交叉验证多个来源
- 标注不确定的信息
- 区分事实与推测

## 工作流程

1. **明确调研目标**
   - 确定调研问题
   - 确定调研范围
   - 确定调研深度

2. **执行搜索**
   - 使用 `web_search` 搜索
   - 使用 `web_fetch` 抓取
   - 记录来源 URL

3. **整理资料**
   - 提取关键信息
   - 标注来源
   - 分类到 `素材库/` 对应子目录

4. **产出产物**
   - 调研报告
   - 素材文件
   - 来源清单

## 禁止事项

- ❌ 凭空捏造历史事实/地理信息
- ❌ 未注明来源的调研结果
- ❌ 不确定的信息标注为确定

## 产物

- `素材库/` 下的参考资料文件
- 调研报告（可选）

## 依赖

- `agents/web-investigator.md`：调研员角色定义
