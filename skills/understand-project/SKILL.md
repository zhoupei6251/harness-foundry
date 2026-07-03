---
name: understand-project
description: "理解项目结构和架构，生成知识图谱。触发：接手新项目、需要了解项目全局、询问架构设计。"
version: 1.0.0
when_to_use: 需要理解项目结构时
status: peripheral
tags:
- intelligence
- code
- strategic
domain: code
category: code.intelligence
---

# /understand-project

使用 Understand-Anything 分析项目结构，生成交互式知识图谱。

## 使用场景

| 场景 | 调用时机 | 价值 |
|------|---------|------|
| 新项目接手 | plan 阶段开始时 | 5 分钟了解项目全貌 |
| 架构评审 | design 阶段 | 提供架构上下文 |
| 大型重构 | implement 前 | 识别影响范围 |
| Bug 定位 | verify 阶段 | 快速定位相关模块 |

## 多智能体协同流程

```
1. [ProjectScanner] 扫描项目结构
2. [FileAnalyzer] 分析每个文件
3. [ArchitectureAnalyzer] 架构分层
4. [GraphBuilder] 构建知识图谱
5. [TourBuilder] 生成导览
```

## 与其他 Skill 的配合

```
/understand-project  →  获取全局理解
        ↓
/analyze-architecture  →  深入分析架构
        ↓
/index-project  →  建立索引
        ↓
/query-symbol  →  快速定位代码
```

## 限制与注意事项

1. **首次分析较慢**: 完整分析可能需要 1-5 分钟
2. **需要增量更新**: 代码变更后建议重新分析
3. **图谱存储**: 知识图谱存储在 `.understand-anything/` 目录
4. **隐私**: 所有分析在本地进行，代码不外传
