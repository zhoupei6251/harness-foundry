/**
 * Skill Evaluator API Module
 *
 * 提供 Skill 评估的编程接口
 */

const fs = require('fs');
const path = require('path');

class SkillEvaluator {
  constructor(options = {}) {
    this.basePath = options.basePath || process.cwd();
    this.verbose = options.verbose || false;
    this.skillsPath = path.join(this.basePath, 'skills');
    this.testsPath = path.join(this.basePath, 'tests/eval/skills');
  }

  /**
   * 加载 skill 定义
   */
  loadSkill(skillName) {
    const skillPath = path.join(this.skillsPath, skillName, 'SKILL.md');

    if (!fs.existsSync(skillPath)) {
      throw new Error(`Skill not found: ${skillName}`);
    }

    return {
      name: skillName,
      path: skillPath,
      content: fs.readFileSync(skillPath, 'utf-8'),
    };
  }

  /**
   * 检查 skill 定义
   */
  async checkDefinition(skillName) {
    const SkillDefinitionChecker = require('./run-skill-eval.js');
    // 直接使用 run-skill-eval.js 中的检查逻辑
    const runner = require('./run-skill-eval.js');
    const checker = new (require('./run-skill-eval.js')).SkillDefinitionChecker(this.basePath);
    return await checker.checkDefinition(skillName);
  }

  /**
   * 评估单个 skill
   */
  async evaluate(skillName) {
    const runner = {
      evaluate: async () => {
        const SkillDefinitionChecker = require('./run-skill-eval.js').SkillDefinitionChecker;
        const checker = new SkillDefinitionChecker(this.basePath);
        const definition = await checker.checkDefinition(skillName);

        return {
          skill: skillName,
          timestamp: new Date().toISOString(),
          definition,
          tests: [],
          summary: { total: 0, passed: 0, failed: 0, errors: 0 },
          status: definition.passed ? 'PASS' : 'FAIL',
        };
      }
    };

    return await runner.evaluate();
  }

  /**
   * 评估多个 skills
   */
  async evaluateAll(skillNames) {
    const results = [];

    for (const skillName of skillNames) {
      const result = await this.evaluate(skillName);
      results.push(result);
    }

    return {
      timestamp: new Date().toISOString(),
      skills: results,
      summary: {
        total: results.length,
        passed: results.filter(r => r.status === 'PASS').length,
        failed: results.filter(r => r.status === 'FAIL').length,
      },
    };
  }
}

module.exports = {
  SkillEvaluator,
};
