# 新闻域命令

## /news
进入新闻采编模式

**触发**: `/news`
**执行**:
1. 加载 `contexts/news.md`
2. 加载 `rules/news/`
3. 进入新闻采编流程

## /hot
热点追踪

**触发**: `/hot`
**执行**:
1. 调用 `hot-topic-research` skill
2. 搜索最新热点
3. 分析新闻价值
4. 输出选题建议

## /fact
事实核查

**触发**: `/fact`
**执行**:
1. 调用 `fact-check` skill
2. 验证核心事实
3. 交叉验证信源
4. 输出核查报告

## /brief
生成日报

**触发**: `/brief`
**执行**:
1. 调用 `daily-brief` skill
2. 汇总当日新闻
3. 按重要性排序
4. 输出日报格式
