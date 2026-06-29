---
name: novel-ai-wash
description: 深度文风清洗，四层清洗体系：词级替换→句式重构→叙事重写→人物声音分化
metadata:
  origin: harness-ink
  priority: P0
  tags:
  - polish
  - deep-wash
  - chinese
version: 1.0.0
when_to_use: 调用 novel-ai-wash 时
status: peripheral
tags:
- shared
domain: novel
category: novel.creation
---
# 深度文风清洗

## 激活条件

- 用户要求深度清洗（"深度润色"、"彻底去AI味"）
- humanizer-zh 轻量润色后仍不满意
- 整章 AI 味严重

## 核心能力

### 四层清洗体系

#### 第一层：词级替换
- 替换 AI 高频词汇
- 删除无意义修饰词
- 替换俗套过渡词

#### 第二层：句式重构
- 长短句交错
- 避免均匀分段
- 增加节奏感
- 删除机械罗列

#### 第三层：叙事重写
- 重构段落结构
- 增加细节描写
- 强化情感层次
- 避免情绪扁平化

#### 第四层：人物声音分化
- 不同角色对话风格差异化
- 口语化调整
- 符合人物身份和性格
- 避免套路对话

## 工作流程

1. **诊断 AI 味**
   - 扫描高频 AI 词汇
   - 识别套路句式
   - 评估 AI 味严重程度

2. **分层清洗**
   - 第一层：词级替换
   - 第二层：句式重构
   - 第三层：叙事重写
   - 第四层：人物声音分化

3. **质量验证**
   - 朗读检查
   - 对比检查
   - 剥离检查

## 禁止事项

- ❌ 改变情节走向
- ❌ 增删情节内容
- ❌ 润色后更不自然
- ❌ 跳过轻量润色直接使用

## 产物

- 深度清洗后的章节正文
- AI 味诊断报告（可选）

## 依赖

- `core/NEVER.md`：AI 写作禁忌清单
- `skills/humanizer-zh/SKILL.md`：轻量润色技能
