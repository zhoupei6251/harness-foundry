/**
 * Brainstorming Skill Behavior Tests
 *
 * 测试 brainstorming skill 的关键行为：
 * 1. 是否在实现前触发
 * 2. 是否强制提问
 * 3. 是否提供选项对比
 * 4. 是否在设计批准后停止
 */

module.exports = {
  name: 'brainstorming-behavior',
  description: 'Brainstorming skill 行为测试',
  skill: 'brainstorming',
  tests: [
    {
      id: 'trigger-before-implementation',
      description: '应在实现前触发 brainstorming（检查是否包含触发条件关键词）',
      type: 'behavior',
      assert: (ctx) => {
        // 检查 skill 定义中是否包含触发条件的说明
        const content = ctx.skillContent.toLowerCase();
        return content.includes('before') ||
               content.includes('implementation') ||
               content.includes('creative work') ||
               content.includes('design');
      },
    },
    {
      id: 'force-questioning',
      description: '应强制提问而非直接执行（检查是否包含提问机制）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        // 检查是否有提问相关的描述
        const hasQuestions = content.includes('question') ||
                             content.includes('ask') ||
                             content.includes('clarify');
        // 检查是否有每次只问一个问题
        const hasOneQuestion = content.includes('one question') ||
                               content.includes('single question') ||
                               content.includes('每次') ||
                               content.includes('one at a time');
        return hasQuestions && hasOneQuestion;
      },
    },
    {
      id: 'option-comparison',
      description: '应提供选项对比（检查是否有方案比较）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('option') ||
               content.includes('approach') ||
               content.includes('alternative') ||
               content.includes('方案') ||
               content.includes('trade-off') ||
               content.includes('权衡');
      },
    },
    {
      id: 'stop-after-design-approved',
      description: '设计批准后应停止 brainstorming，转入实现',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        // 检查是否有"设计后"或"实现"的描述
        return (content.includes('design') || content.includes('approved')) &&
               (content.includes('implementation') ||
                content.includes('ready to') ||
                content.includes('ready-to'));
      },
    },
    {
      id: 'yagni-ruthlessly',
      description: '应包含 YAGNI 原则（不要过度设计）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('yagni') ||
               content.includes('unnecessary') ||
               content.includes('keep it simple') ||
               content.includes('simplicity') ||
               content.includes('简洁');
      },
    },
    {
      id: 'incremental-validation',
      description: '应支持增量验证（分块展示设计）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('section') ||
               content.includes('incremental') ||
               content.includes('分段') ||
               content.includes('块');
      },
    },
  ],
};
