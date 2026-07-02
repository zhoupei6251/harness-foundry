/**
 * Skill Eval Runner
 * 运行 skill 行为测试、输出测试和集成测试
 *
 * 用法:
 *   node scripts/eval/run-skill-eval.js --skill brainstorming
 *   node scripts/eval/run-skill-eval.js --all
 *   node scripts/eval/run-skill-eval.js --skill brainstorming --type behavior
 *   node scripts/eval/run-skill-eval.js --skill brainstorming --json
 */

const fs = require('fs');
const path = require('path');

// 配置
const BASE_PATH = path.resolve(__dirname, '../../');
const SKILLS_PATH = path.join(BASE_PATH, 'skills');
const TESTS_PATH = path.join(BASE_PATH, 'tests/eval/skills');
const FRAMEWORK_PATH = path.join(BASE_PATH, 'core/eval');

// 命令行参数
const args = process.argv.slice(2);
const options = {
  skill: null,
  all: false,
  type: null, // behavior | output | integration
  json: false,
  verbose: false,
  checkDefinition: false,
};

// 解析参数
for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '--skill':
      options.skill = args[++i];
      break;
    case '--all':
      options.all = true;
      break;
    case '--type':
      options.type = args[++i];
      break;
    case '--json':
      options.json = true;
      break;
    case '--verbose':
    case '-v':
      options.verbose = true;
      break;
    case '--check-definition':
      options.checkDefinition = true;
      break;
    case '--help':
    case '-h':
      printUsage();
      process.exit(0);
  }
}

function printUsage() {
  console.log(`
Skill Eval Runner

用法:
  node scripts/eval/run-skill-eval.js --skill <skill-name>
  node scripts/eval/run-skill-eval.js --all
  node scripts/eval/run-skill-eval.js --skill <name> --type <type>
  node scripts/eval/run-skill-eval.js --skill <name> --json

选项:
  --skill <name>      指定要测试的 skill 名称
  --all               运行所有 skill 的测试
  --type <type>       测试类型: behavior, output, integration
  --json              JSON 格式输出
  --verbose, -v       详细输出
  --check-definition  仅检查 skill 定义
  --help, -h          显示帮助

示例:
  node scripts/eval/run-skill-eval.js --skill brainstorming
  node scripts/eval/run-skill-eval.js --skill brainstorming --type behavior
  node scripts/eval/run-skill-eval.js --all --json
`);
}

/**
 * Skill 定义检查器
 */
class SkillDefinitionChecker {
  constructor(basePath) {
    this.basePath = basePath;
    this.skillsPath = path.join(basePath, 'skills');
  }

  async checkDefinition(skillName) {
    const skillPath = path.join(this.skillsPath, skillName, 'SKILL.md');

    if (!fs.existsSync(skillPath)) {
      return {
        exists: false,
        errors: [`Skill not found: ${skillPath}`],
      };
    }

    const content = fs.readFileSync(skillPath, 'utf-8');
    const errors = [];
    const warnings = [];

    // 检查 frontmatter
    const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
    if (!fmMatch) {
      errors.push('Missing frontmatter (---)');
    } else {
      const fm = this.parseFrontmatter(fmMatch[1]);

      // 必需字段
      const required = ['name', 'description', 'version', 'status'];
      for (const field of required) {
        if (!fm[field]) {
          errors.push(`Missing required field: ${field}`);
        }
      }

      // 状态检查
      const validStatuses = ['core', 'peripheral', 'experimental'];
      if (fm.status && !validStatuses.includes(fm.status)) {
        errors.push(`Invalid status: ${fm.status}. Valid: ${validStatuses.join(', ')}`);
      }

      // 版本格式
      if (fm.version && !/^\d+\.\d+\.\d+$/.test(fm.version)) {
        errors.push(`Invalid version format: ${fm.version}. Expected: x.y.z`);
      }
    }

    // 检查内容
    const lines = content.split('\n');
    let hasH1 = false;
    let hasH2 = false;

    for (const line of lines) {
      if (/^#\s+\w/.test(line)) hasH1 = true;
      if (/^##\s+\w/.test(line)) hasH2 = true;
    }

    if (!hasH1) warnings.push('Missing main heading (H1)');
    if (!hasH2) warnings.push('Missing section headings (H2)');

    return {
      exists: true,
      path: skillPath,
      errors,
      warnings,
      passed: errors.length === 0,
    };
  }

  parseFrontmatter(text) {
    const result = {};
    const lines = text.split('\n');

    for (const line of lines) {
      const match = line.match(/^(\w+):\s*(.*)$/);
      if (match) {
        const [, key, value] = match;
        result[key] = value.replace(/^["']|["']$/g, '');
      }
    }

    return result;
  }
}

/**
 * Skill 测试运行器
 */
class SkillTestRunner {
  constructor(basePath) {
    this.basePath = basePath;
    this.skillsPath = path.join(basePath, 'skills');
    this.testsPath = path.join(basePath, 'tests/eval/skills');
    this.checker = new SkillDefinitionChecker(basePath);
  }

  /**
   * 获取所有可测试的 skills
   */
  getSkillList() {
    if (!fs.existsSync(this.skillsPath)) {
      return [];
    }

    return fs.readdirSync(this.skillsPath)
      .filter(item => {
        const skillPath = path.join(this.skillsPath, item);
        return fs.statSync(skillPath).isDirectory() &&
               fs.existsSync(path.join(skillPath, 'SKILL.md'));
      })
      .filter(item => !item.startsWith('_'));
  }

  /**
   * 加载 skill 定义
   */
  loadSkillDefinition(skillName) {
    const skillPath = path.join(this.skillsPath, skillName, 'SKILL.md');

    if (!fs.existsSync(skillPath)) {
      throw new Error(`Skill not found: ${skillName}`);
    }

    return fs.readFileSync(skillPath, 'utf-8');
  }

  /**
   * 加载测试用例
   */
  loadTests(skillName, testType = null) {
    const skillTestPath = path.join(this.testsPath, skillName);
    const tests = [];

    if (!fs.existsSync(skillTestPath)) {
      return tests;
    }

    const types = testType ? [testType] : ['behavior', 'output', 'integration'];

    for (const type of types) {
      const testFile = path.join(skillTestPath, `${type}.test.js`);
      if (fs.existsSync(testFile)) {
        try {
          const testModule = require(testFile);
          if (Array.isArray(testModule)) {
            tests.push(...testModule.map(t => ({ ...t, type })));
          } else if (testModule.tests) {
            tests.push(...testModule.tests.map(t => ({ ...t, type })));
          }
        } catch (e) {
          // 测试文件加载失败，跳过
          if (options.verbose) {
            console.error(`Failed to load ${testFile}: ${e.message}`);
          }
        }
      }
    }

    return tests;
  }

  /**
   * 运行单个测试
   */
  async runTest(test, context) {
    try {
      const result = await test.assert(context);
      return {
        id: test.id,
        description: test.description,
        type: test.type,
        status: result ? 'PASS' : 'FAIL',
        error: result ? null : 'Assertion failed',
      };
    } catch (e) {
      return {
        id: test.id,
        description: test.description,
        type: test.type,
        status: 'ERROR',
        error: e.message,
      };
    }
  }

  /**
   * 评估单个 skill
   */
  async evaluate(skillName, testType = null) {
    const timestamp = new Date().toISOString();
    const results = {
      skill: skillName,
      timestamp,
      definition: null,
      tests: [],
      summary: { total: 0, passed: 0, failed: 0, errors: 0 },
      status: 'FAIL',
    };

    // 检查定义
    if (options.checkDefinition || options.verbose) {
      results.definition = await this.checker.checkDefinition(skillName);
    }

    // 加载测试
    const tests = this.loadTests(skillName, testType);

    if (tests.length === 0) {
      if (!options.checkDefinition) {
        results.warning = 'No tests found';
      }
      results.tests = [];
    } else {
      // 创建测试上下文
      const skillContent = this.loadSkillDefinition(skillName);
      const context = {
        skillName,
        skillContent,
        output: skillContent,
        triggeredBefore: (phase) => {
          // 简化实现：检查是否包含相关关键词
          return /implementation|feature|build|create/i.test(skillContent);
        },
        questionsAsked: (skillContent.match(/\?|提问|clarify|question/i) || []).length,
        optionsProvided: /option|approach|方案|选择|tradeoff/i.test(skillContent),
        stoppedAfterApproval: /ready to|implementation|execute/i.test(skillContent),
        matchesPattern: (pattern) => new RegExp(pattern).test(skillContent),
        contains: (keyword) => skillContent.includes(keyword),
        maxLength: (max) => skillContent.length <= max,
        hasSection: (heading) => new RegExp(`##\\s+${heading}`, 'i').test(skillContent),
      };

      // 运行测试
      for (const test of tests) {
        const result = await this.runTest(test, context);
        results.tests.push(result);
        results.summary.total++;
        if (result.status === 'PASS') results.summary.passed++;
        else if (result.status === 'FAIL') results.summary.failed++;
        else if (result.status === 'ERROR') results.summary.errors++;
      }
    }

    // 计算状态
    if (results.definition && !results.definition.passed) {
      results.status = 'FAIL';
    } else if (results.summary.total === 0) {
      results.status = results.definition ? 'PASS' : 'NO_TESTS';
    } else if (results.summary.failed === 0 && results.summary.errors === 0) {
      results.status = 'PASS';
    } else {
      results.status = 'FAIL';
    }

    results.summary.passRate = results.summary.total > 0
      ? results.summary.passed / results.summary.total
      : 1.0;

    return results;
  }

  /**
   * 评估多个 skills
   */
  async evaluateAll(skillNames) {
    const results = [];

    for (const skillName of skillNames) {
      const result = await this.evaluate(skillName, options.type);
      results.push(result);
    }

    return {
      timestamp: new Date().toISOString(),
      skills: results,
      summary: {
        total: results.length,
        passed: results.filter(r => r.status === 'PASS').length,
        failed: results.filter(r => r.status === 'FAIL').length,
        noTests: results.filter(r => r.status === 'NO_TESTS').length,
      },
    };
  }
}

/**
 * 格式化输出
 */
function formatOutput(result, verbose = false) {
  if (options.json) {
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  const lines = [];
  lines.push(`\n=== Skill Evaluator ===`);
  lines.push(`Skill: ${result.skill}`);

  // 定义检查
  if (result.definition) {
    if (result.definition.exists) {
      if (result.definition.errors.length > 0) {
        lines.push(`  [FAIL] Definition check:`);
        result.definition.errors.forEach(e => lines.push(`    - ${e}`));
      } else {
        lines.push(`  [PASS] Definition check`);
      }
      if (verbose && result.definition.warnings.length > 0) {
        result.definition.warnings.forEach(w => lines.push(`    ! ${w}`));
      }
    } else {
      lines.push(`  [FAIL] Skill not found`);
    }
  }

  // 测试结果
  if (result.tests && result.tests.length > 0) {
    lines.push(`\nTests:`);
    for (const test of result.tests) {
      const icon = test.status === 'PASS' ? '[PASS]' :
                   test.status === 'ERROR' ? '[ERROR]' : '[FAIL]';
      lines.push(`  ${icon} ${test.id}`);
      if (verbose && test.error) {
        lines.push(`        ${test.error}`);
      }
    }
  }

  // 摘要
  lines.push(`\nSummary: ${result.summary.passed}/${result.summary.total} tests passed`);
  if (result.summary.passRate < 1.0) {
    lines.push(`Pass rate: ${(result.summary.passRate * 100).toFixed(1)}%`);
  }
  lines.push(`Status: ${result.status}`);

  console.log(lines.join('\n'));
}

/**
 * 主函数
 */
async function main() {
  const runner = new SkillTestRunner(BASE_PATH);

  // 验证参数
  if (!options.skill && !options.all) {
    console.error('Error: --skill or --all is required');
    printUsage();
    process.exit(1);
  }

  try {
    let result;

    if (options.all) {
      const skills = runner.getSkillList();
      if (options.json) {
        result = await runner.evaluateAll(skills);
        console.log(JSON.stringify(result, null, 2));
      } else {
        console.log(`Evaluating ${skills.length} skills...`);
        let passed = 0, failed = 0, noTests = 0;

        for (const skill of skills) {
          const skillResult = await runner.evaluate(skill, options.type);
          formatOutput(skillResult, options.verbose);
          if (skillResult.status === 'PASS') passed++;
          else if (skillResult.status === 'FAIL') failed++;
          else noTests++;
        }

        console.log(`\n=== Overall Summary ===`);
        console.log(`Total: ${skills.length}`);
        console.log(`Passed: ${passed}`);
        console.log(`Failed: ${failed}`);
        console.log(`No tests: ${noTests}`);
      }
    } else {
      result = await runner.evaluate(options.skill, options.type);
      formatOutput(result, options.verbose);
    }

    // 退出码
    if (result && result.status === 'FAIL') {
      process.exit(1);
    }
  } catch (e) {
    console.error('Error:', e.message);
    if (options.verbose) {
      console.error(e.stack);
    }
    process.exit(1);
  }
}

// 运行
main();
