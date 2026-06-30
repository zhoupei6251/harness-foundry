# 小说域命令

## /novel
进入小说创作模式

**触发**: `/novel`
**执行**:
1. 加载 `contexts/novel.md`
2. 加载 `rules/novel/`
3. 启动 `novel-orchestrator` 编排器
4. 进入小说创作流程

## /write
写章节

**触发**: `/write`
**执行**:
1. 加载 `contexts/novel.md`
2. 调用 `junli-ai-novel` skill
3. 读取大纲和人物设定
4. 写章节正文
5. 自检 AI 痕迹

## /outline
写大纲

**触发**: `/outline`
**执行**:
1. 调用 `brainstorming` skill
2. 分析题材和核心卖点
3. 输出故事大纲
4. 等待用户确认

## /evaluate
审稿评分

**触发**: `/evaluate`
**执行**:
1. 加载 `contexts/review.md`
2. 调用 `novel-evaluator` skill
3. 按 6 维度评分（情节/人物/文笔/世界观/情感/创新）
4. 输出审稿报告

## /polish
润色去 AI 味

**触发**: `/polish`
**执行**:
1. 加载 `contexts/novel.md`
2. 调用 `humanizer-zh` 或 `novel-ai-wash` skill
3. 扫描 AI 高频词汇
4. 重写套路化表达
5. 输出润色版本

## /research
查资料

**触发**: `/research`
**执行**:
1. 调用 `web-tools-guide` skill
2. 搜索相关资料
3. 整理素材
4. 存入素材库
