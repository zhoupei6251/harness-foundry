---
name: index-project
description: "为项目建立代码索引。触发：大型项目、需要精准定位符号、快速查找调用关系。"
tags: [Intelligence, Code, Tactical]
triggers:
  - "建立索引"
  - "索引项目"
  - "需要快速查找"
  - "建立代码索引"
layer: tactical
---

# /index-project

使用 CodeGraph 为项目建立代码索引。

## 使用场景

| 场景 | 说明 |
|------|------|
| 大型项目 (>100 文件) | 索引后查询效率提升 57%+ |
| 需要快速定位符号 | 代替逐文件 grep |
| 分析影响范围 | 变更前的必要准备 |

## 调用方式

```markdown
使用 CodeGraph 的 index-project 能力：
- project_path: {项目路径}
- languages: ["java", "python", "typescript"] (自动检测)
```

## 索引过程

```
1. 扫描项目文件结构
2. 解析 AST 提取符号
3. 构建引用关系图
4. 存储到 SQLite 数据库
```

## 索引存储位置

索引存储在项目的 `.codegraph/` 目录：

```
/path/to/project/.codegraph/
├── graph.db           # SQLite 索引数据库
├── symbols.json       # 符号映射
└── watch-list.json    # 监视文件列表
```

## 索引后可用工具

| 工具 | 用途 |
|------|------|
| `/query-symbol` | 搜索符号定义 |
| `/get-callers` | 查找调用方 |
| `/get-callees` | 查找被调用方 |
| `/analyze-impact` | 评估变更影响 |

## 性能指标

| 指标 | 目标 |
|------|------|
| 10万行代码 | < 5 分钟 |
| 查询响应时间 | < 100ms |
| Token 节省 | >= 30% |

## 示例

```
用户: 帮我索引这个项目
AI:   调用 /index-project
      ↓
      正在扫描项目...
      已解析 1,234 个文件
      已提取 5,678 个符号
      已建立 12,345 个引用关系
      索引完成 ✓
```

## 增量索引

项目代码变更后，CodeGraph 支持增量索引：

```bash
# 仅索引变更的文件
codegraph sync

# 监视文件变更，自动索引
codegraph watch
```
