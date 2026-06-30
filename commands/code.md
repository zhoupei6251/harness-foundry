# 代码域命令

## /code
进入代码开发模式

**触发**: `/code`
**执行**:
1. 加载 `contexts/code.md`
2. 加载 `rules/code/<tech>/` 和 `rules/common/`
3. 启动 `harness-orchestration` 编排器
4. 进入代码开发流程

## /review
代码审查

**触发**: `/review`
**执行**:
1. 加载 `contexts/review.md`
2. 调用 `requesting-code-review` skill
3. 按审查清单检查代码
4. 输出审查报告

## /debug
调试模式

**触发**: `/debug`
**执行**:
1. 加载 `contexts/code.md`
2. 调用 `systematic-debugging` skill
3. 按调试流程排查问题
4. 输出调试报告

## /test
TDD 模式

**触发**: `/test`
**执行**:
1. 加载 `contexts/code.md`
2. 调用 `test-driven-development` skill
3. 按红-绿-重构循环开发
4. 确保测试覆盖率 ≥ 80%

## /plan
写实现计划

**触发**: `/plan`
**执行**:
1. 调用 `writing-plans` skill
2. 分析需求和现有代码
3. 输出实现计划（spec/plan）
4. 等待用户确认

## /verify
尾盘验证

**触发**: `/verify`
**执行**:
1. 调用 `verification-before-completion` skill
2. 运行所有测试
3. 检查代码质量
4. 输出验证报告
