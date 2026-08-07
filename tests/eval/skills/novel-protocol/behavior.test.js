/**
 * Novel Protocol Skill Behavior Tests
 *
 * 测试 novel-protocol skill 的关键行为：
 * 1. 是否包含指令路由表（唯一权威源）
 * 2. 是否强制因果链一致性（法典级约束）
 * 3. 是否集成 novel-graph 脚本校验
 * 4. 是否要求执行闭环（五步）
 * 5. 是否禁止捏造设定
 * 6. 是否指向写后自检（novel-checklist 红线）
 * 7. 是否声明路由表为唯一权威（不另设路由）
 */

module.exports = {
  name: 'novel-protocol-behavior',
  description: 'novel-protocol skill 行为测试',
  skill: 'novel-protocol',
  tests: [
    {
      id: 'instruction-routing-table',
      description: '应包含指令路由表（novel 域唯一权威路由）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return (content.includes('指令路由表') || content.includes('routing')) &&
               content.includes('唯一权威');
      },
    },
    {
      id: 'causality-consistency',
      description: '应强制因果链一致性（因果律闭环约束）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return (content.includes('因果链') || content.includes('causality')) &&
               (content.includes('先导') || content.includes('闭环'));
      },
    },
    {
      id: 'novel-graph-integration',
      description: '应集成 novel-graph 脚本自动校验（因果链熔断）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('novel_graph.py') &&
               (content.includes('validate') || content.includes('熔断') || content.includes('causality_chain_broken'));
      },
    },
    {
      id: 'five-step-closure',
      description: '应要求执行闭环（指令识别 → 协议装配 → 知识库绑定 → 前置校验 → 交付收束）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return (content.includes('指令识别') || content.includes('协议装配')) &&
               (content.includes('知识库绑定') || content.includes('知识库')) &&
               (content.includes('前置校验') || content.includes('交付收束'));
      },
    },
    {
      id: 'no-fabrication',
      description: '应禁止捏造设定（知识库缺失时报告绑定失败）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent;
        return content.includes('禁止捏造') &&
               (content.includes('绑定失败') || content.includes('唯一真实世界'));
      },
    },
    {
      id: 'post-write-checklist',
      description: '应指向写后自检（novel-checklist 5 维 + AI 痕迹红线）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent;
        return content.includes('novel-checklist') &&
               (content.includes('红线') || content.includes('5 维') || content.includes('5维'));
      },
    },
    {
      id: 'single-authority-route',
      description: '应声明路由表为唯一权威源（不另设路由）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('唯一权威源') &&
               (content.includes('不另设路由') || content.includes('唯一权威路由'));
      },
    },
  ],
};
