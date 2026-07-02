/**
 * Brainstorming Skill Output Tests
 *
 * 测试 brainstorming skill 的输出格式和质量
 */

module.exports = {
  name: 'brainstorming-output',
  description: 'Brainstorming skill 输出测试',
  skill: 'brainstorming',
  tests: [
    {
      id: 'design-document-format',
      description: '设计文档格式正确（包含 Markdown 标题）',
      type: 'output',
      assert: (ctx) => {
        const content = ctx.output || ctx.skillContent;
        // 检查是否包含 Markdown 标题
        return content.includes('##') || content.includes('###');
      },
    },
    {
      id: 'tradeoffs-presented',
      description: '包含权衡分析（pros/cons/tradeoff）',
      type: 'output',
      assert: (ctx) => {
        const content = (ctx.output || ctx.skillContent).toLowerCase();
        return /pros?|cons?|trade-?off|优势|劣势|权衡/i.test(content);
      },
    },
    {
      id: 'sections-200-300-words',
      description: '每个章节应简洁（小于1500字符）',
      type: 'output',
      assert: (ctx) => {
        const content = ctx.output || ctx.skillContent;
        // 简单检查：内容不应过于冗长
        // 注意：这是简化版本，真实测试需要分割章节
        const lines = content.split('\n');
        let inSection = false;
        let sectionLength = 0;
        let maxSectionLength = 0;

        for (const line of lines) {
          if (/^##\s+\w/.test(line)) {
            if (sectionLength > maxSectionLength) maxSectionLength = sectionLength;
            sectionLength = 0;
            inSection = true;
          } else if (inSection) {
            sectionLength += line.length;
          }
        }

        // 检查是否有过长的章节
        return maxSectionLength < 1500 || content.length < 3000;
      },
    },
    {
      id: 'has-sections',
      description: '包含多个章节（架构、组件、数据流等）',
      type: 'output',
      assert: (ctx) => {
        const content = (ctx.output || ctx.skillContent).toLowerCase();
        // 检查是否提到需要包含的章节类型
        const sections = ['architecture', 'component', 'data flow', 'error handling',
                          'testing', '架构', '组件', '数据流'];
        const found = sections.filter(s => content.includes(s));
        return found.length >= 2;
      },
    },
    {
      id: 'recommendation-given',
      description: '应提供推荐方案',
      type: 'output',
      assert: (ctx) => {
        const content = (ctx.output || ctx.skillContent).toLowerCase();
        return content.includes('recommend') ||
               content.includes('suggest') ||
               content.includes('建议') ||
               content.includes('推荐');
      },
    },
  ],
};
