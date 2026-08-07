/**
 * Code Review Skill Behavior Tests
 *
 * 测试 code-review skill 的关键行为：
 * 1. 是否覆盖安全维度
 * 2. 是否覆盖性能维度（N+1 / 分页）
 * 3. 是否覆盖正确性维度
 * 4. 是否要求严重度分级（Critical/Major/Minor/Nitpick）
 * 5. 是否要求三遍审阅流程
 * 6. 是否有反模式清单（rubber-stamping 等）
 */

module.exports = {
  name: 'code-review-behavior',
  description: 'code-review skill 行为测试',
  skill: 'code-review',
  tests: [
    {
      id: 'security-dimension',
      description: '应包含安全审查维度（SQL 注入 / XSS / 密钥管理等）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('security') &&
               (content.includes('sql injection') || content.includes('xss')) &&
               (content.includes('secrets') || content.includes('credentials') || content.includes('token'));
      },
    },
    {
      id: 'performance-dimension',
      description: '应包含性能审查维度（N+1 / 索引 / 分页）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('performance') &&
               (content.includes('n+1') || content.includes('queries')) &&
               (content.includes('pagination') || content.includes('indexing'));
      },
    },
    {
      id: 'severity-levels',
      description: '应要求按严重度分级（Critical/Major/Minor/Nitpick）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('critical') &&
               content.includes('major') &&
               content.includes('minor') &&
               content.includes('nitpick');
      },
    },
    {
      id: 'blocks-merge-clarification',
      description: '应明确哪些严重度阻塞合并',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        // Critical/Major 阻塞合并（表格"Blocks Merge? Yes"）
        return (content.includes('blocks merge') || content.includes('block merge')) &&
               content.includes('yes');
      },
    },
    {
      id: 'three-pass-process',
      description: '应要求三遍审阅流程（结构 → 细节 → 边界）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return content.includes('three passes') ||
               (content.includes('first pass') &&
                content.includes('second pass') &&
                content.includes('third pass'));
      },
    },
    {
      id: 'anti-patterns',
      description: '应包含审阅反模式（rubber-stamping / bikeshedding 等）',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent.toLowerCase();
        return (content.includes('rubber-stamping') || content.includes('rubber stamping')) &&
               (content.includes('bikeshedding') || content.includes('bikeshed'));
      },
    },
    {
      id: 'never-do',
      description: '应有明确的 NEVER Do 禁区',
      type: 'behavior',
      assert: (ctx) => {
        const content = ctx.skillContent;
        return content.includes('NEVER') && content.includes('never');
      },
    },
  ],
};
