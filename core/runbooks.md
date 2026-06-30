# Runbooks — 常用操作手册

> 以"项目/书/新闻集"为单位，三域共用。

## 代码域

### Git 协作
详见 `harness-foundry/project.git.md`。Leader 不自动 push；git 操作由 Leader 调用 `git-xywh` skill 执行。

### 派兵
1. 用户批准 plan → 进入实现阶段
2. Leader 拆 WU → 按 `core/orchestration/dispatcher-workflow.md` 并行派兵
3. GROUP 全部返回 → 尾盘 collective-test + code-review
4. 产物落盘 `.ai-runtime-artifacts/`

阶段门禁见 `core/intent-routing.md` § 阶段门禁。

### 修复
- Tier 1 (小改动)：Leader 直改，不改业务代码
- Tier 2+ (多文件)：先 explore 定位 → 再 debugger 修复 → reviewer 审查

## 小说域

### 开书
1. brainstorming → 确认需求
2. planner 产出大纲 → 确认大纲
3. 逐章产出 → 逐章确认（或用户授权连续写）

### 审稿
`novel-evaluator` 6 维评分：情节 / 人物 / 文笔 / 世界观 / 情感 / 创新
不及格（<70）→ 返修，最多 2 次

### 润色
`humanizer-zh` 去 AI 味；`novel-ai-wash` 批量深度清洗

## 新闻域

### 写稿
`news-generator` → `fact-check` → 确认发布

### 日报
`news-generator` 生成日报 → 确认格式 → 发布

## 通用

### 持续学习
`continuous-learning` skill → 提取 instinct → 衰减管理 → 定期清理
