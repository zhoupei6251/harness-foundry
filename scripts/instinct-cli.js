#!/usr/bin/env node

/**
 * Instinct CLI - 持续学习系统管理工具
 * 零依赖版本，使用原生 YAML frontmatter 解析
 *
 * G-4 升级: 增加 export/import/promote 命令
 */

const fs = require('fs');
const path = require('path');

const INSTINCTS_DIR = path.join(__dirname, '..', 'references', 'instincts');
const PROJECT_DIR = path.join(INSTINCTS_DIR, 'project');
const GLOBAL_DIR = path.join(INSTINCTS_DIR, 'global', 'instincts');

// 简易 YAML 解析（仅支持 frontmatter 中的简单键值对）
function parseYamlFrontmatter(content) {
  const match = content.match(/---\n([\s\S]+?)\n---/);
  if (!match) return null;

  const yaml = {};
  match[1].split('\n').forEach(line => {
    const colonIdx = line.indexOf(':');
    if (colonIdx === -1) return;
    const key = line.slice(0, colonIdx).trim();
    let value = line.slice(colonIdx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (!isNaN(value) && value !== '') {
      value = parseFloat(value);
    }
    yaml[key] = value;
  });
  return yaml;
}

// 简易 YAML 生成
function generateYamlFrontmatter(obj) {
  const lines = ['---'];
  Object.entries(obj).forEach(([key, value]) => {
    if (typeof value === 'string' && value.includes(' ')) {
      lines.push(`${key}: "${value}"`);
    } else {
      lines.push(`${key}: ${value}`);
    }
  });
  lines.push('---');
  return lines.join('\n') + '\n';
}

function createInstinct(id, trigger, domain, scope = 'project') {
  const instinct = {
    id,
    trigger,
    confidence: 0.5,
    domain,
    scope,
    source: 'session',
    project_id: getProjectId(),
    created: new Date().toISOString().split('T')[0],
    last_used: new Date().toISOString().split('T')[0],
    usage_count: 0
  };

  const targetDir = scope === 'global' ? GLOBAL_DIR : path.join(PROJECT_DIR, getProjectId(), 'instincts');
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  const filePath = path.join(targetDir, `${id}.yaml`);
  const content = generateYamlFrontmatter(instinct);
  fs.writeFileSync(filePath, content, 'utf8');
  console.log(`✓ 创建 instinct: ${id}`);
  console.log(`  路径: ${filePath}`);
}

function listInstincts(scope = 'all') {
  const results = [];

  const scanDir = (dir, scopeType) => {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.yaml'));
    files.forEach(file => {
      const content = fs.readFileSync(path.join(dir, file), 'utf8');
      const instinct = parseYamlFrontmatter(content);
      if (instinct) {
        instinct.scope = scopeType;
        instinct.file = file;
        instinct.fullPath = path.join(dir, file);
        results.push(instinct);
      }
    });
  };

  if (scope === 'project' || scope === 'all') {
    const projectDir = path.join(PROJECT_DIR, getProjectId(), 'instincts');
    scanDir(projectDir, 'project');
  }
  if (scope === 'global' || scope === 'all') {
    scanDir(GLOBAL_DIR, 'global');
  }

  return results;
}

function updateScore(id, delta) {
  const instincts = listInstincts('all');
  const instinct = instincts.find(i => i.id === id);
  if (!instinct) {
    console.error(`✗ 未找到 instinct: ${id}`);
    return;
  }

  const newConfidence = Math.max(0, Math.min(1, parseFloat(instinct.confidence) + delta));
  instinct.confidence = newConfidence.toFixed(2);
  instinct.last_used = new Date().toISOString().split('T')[0];
  instinct.usage_count = (instinct.usage_count || 0) + 1;

  const filePath = instinct.fullPath || path.join(
    instinct.scope === 'global' ? GLOBAL_DIR : path.join(PROJECT_DIR, getProjectId(), 'instincts'),
    instinct.file
  );
  const content = generateYamlFrontmatter(instinct);
  fs.writeFileSync(filePath, content, 'utf8');

  console.log(`✓ 更新 ${id}: ${instinct.confidence} (${delta > 0 ? '+' : ''}${delta})`);
}

function pruneInstincts(threshold = 0.3) {
  const instincts = listInstincts('all');
  const toPrune = instincts.filter(i => parseFloat(i.confidence) < threshold);

  if (toPrune.length === 0) {
    console.log('✓ 无需修剪，所有 instinct 置信度 >= ' + threshold);
    return;
  }

  console.log(`将修剪 ${toPrune.length} 个 instinct (置信度 < ${threshold}):\n`);
  toPrune.forEach(instinct => {
    console.log(`  - ${instinct.id}: ${instinct.confidence}`);
    const fp = instinct.fullPath || path.join(
      instinct.scope === 'global' ? GLOBAL_DIR : path.join(PROJECT_DIR, getProjectId(), 'instincts'),
      instinct.file
    );
    fs.unlinkSync(fp);
  });

  console.log(`\n✓ 已修剪 ${toPrune.length} 个 instinct`);
}

function evolveInstincts(minCount = 5, minConfidence = 0.7) {
  const all = listInstincts('all');

  const clusters = {};
  all.forEach(instinct => {
    if (!clusters[instinct.domain]) {
      clusters[instinct.domain] = [];
    }
    clusters[instinct.domain].push(instinct);
  });

  const proposals = [];
  Object.entries(clusters).forEach(([domain, instincts]) => {
    const avgConfidence = instincts.reduce((sum, i) => sum + parseFloat(i.confidence), 0) / instincts.length;

    if (instincts.length >= minCount && avgConfidence >= minConfidence) {
      proposals.push({
        domain,
        count: instincts.length,
        avgConfidence: avgConfidence.toFixed(2),
        instincts: instincts.map(i => i.id)
      });
    }
  });

  if (proposals.length === 0) {
    console.log('无符合条件的 cluster，无法进化');
    console.log(`条件: count >= ${minCount} && avgConfidence >= ${minConfidence}`);
    return;
  }

  console.log('=== 进化提案 ===\n');
  proposals.forEach((proposal, idx) => {
    console.log(`${idx + 1}. Domain: ${proposal.domain}`);
    console.log(`   Count: ${proposal.count}, Avg Confidence: ${proposal.avgConfidence}`);
    console.log(`   Instincts: ${proposal.instincts.join(', ')}`);
    console.log(`   建议进化为: ${getEvolutionTarget(proposal.domain)}`);
    console.log();
  });
}

function showStats() {
  const instincts = listInstincts('all');
  const projectCount = instincts.filter(i => i.scope === 'project').length;
  const globalCount = instincts.filter(i => i.scope === 'global').length;
  const avgConfidence = instincts.length > 0
    ? (instincts.reduce((sum, i) => sum + parseFloat(i.confidence), 0) / instincts.length).toFixed(2)
    : 0;

  console.log('=== Instinct 统计 ===\n');
  console.log(`总数: ${instincts.length}`);
  console.log(`  Project: ${projectCount}`);
  console.log(`  Global: ${globalCount}`);
  console.log(`平均置信度: ${avgConfidence}`);

  const domains = {};
  instincts.forEach(i => {
    domains[i.domain] = (domains[i.domain] || 0) + 1;
  });

  if (Object.keys(domains).length > 0) {
    console.log('\n按 domain 统计:');
    Object.entries(domains).forEach(([domain, count]) => {
      console.log(`  ${domain}: ${count}`);
    });
  }
}

// ============ G-4: 新增命令 ============

function exportInstinct(id, outputFile) {
  const instincts = listInstincts('all');
  const instinct = instincts.find(i => i.id === id);
  if (!instinct) {
    console.error(`✗ 未找到 instinct: ${id}`);
    process.exit(1);
  }

  const fp = instinct.fullPath || path.join(
    instinct.scope === 'global' ? GLOBAL_DIR : path.join(PROJECT_DIR, getProjectId(), 'instincts'),
    instinct.file
  );

  if (!fs.existsSync(fp)) {
    console.error(`✗ 文件不存在: ${fp}`);
    process.exit(1);
  }

  const content = fs.readFileSync(fp, 'utf8');
  const outputPath = path.resolve(outputFile);
  fs.writeFileSync(outputPath, content, 'utf8');
  console.log(`✓ 导出 ${id} → ${outputPath}`);
}

function importInstinct(filePath, scopeArg = '--scope=project') {
  const inputPath = path.resolve(filePath);
  if (!fs.existsSync(inputPath)) {
    console.error(`✗ 文件不存在: ${inputPath}`);
    process.exit(1);
  }

  const scope = scopeArg.includes('global') ? 'global' : 'project';
  const content = fs.readFileSync(inputPath, 'utf8');
  const instinct = parseYamlFrontmatter(content);
  if (!instinct || !instinct.id) {
    console.error('✗ 无效的 instinct YAML 文件');
    process.exit(1);
  }

  const targetDir = scope === 'global' ? GLOBAL_DIR : path.join(PROJECT_DIR, getProjectId(), 'instincts');
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  const outputPath = path.join(targetDir, `${instinct.id}.yaml`);
  if (fs.existsSync(outputPath)) {
    console.log(`⚠  已存在 instinct: ${instinct.id}，跳过导入`);
    return;
  }

  instinct.source = instinct.source || 'imported';
  instinct.scope = scope;
  const newContent = generateYamlFrontmatter(instinct);
  fs.writeFileSync(outputPath, newContent, 'utf8');
  console.log(`✓ 导入 ${instinct.id} (scope: ${scope})`);
  console.log(`  路径: ${outputPath}`);
}

function promoteInstinct(id) {
  const instincts = listInstincts('all');
  const instinct = instincts.find(i => i.id === id && i.scope === 'project');
  if (!instinct) {
    console.error(`✗ 未找到 project 级 instinct: ${id}（只能提升 project 级 instinct）`);
    process.exit(1);
  }

  const srcPath = instinct.fullPath || path.join(PROJECT_DIR, getProjectId(), 'instincts', instinct.file);

  if (!fs.existsSync(GLOBAL_DIR)) {
    fs.mkdirSync(GLOBAL_DIR, { recursive: true });
  }

  const dstPath = path.join(GLOBAL_DIR, instinct.file);

  if (fs.existsSync(dstPath)) {
    console.log(`⚠  全局 instinct 已存在: ${id}, 跳过`);
    return;
  }

  instinct.scope = 'global';
  const content = generateYamlFrontmatter(instinct);
  fs.writeFileSync(dstPath, content, 'utf8');
  fs.unlinkSync(srcPath);

  console.log(`✓ 提升 ${id}: project → global`);
}

// ============ 辅助函数 ============

function getProjectId() {
  return path.basename(process.cwd());
}

function getEvolutionTarget(domain) {
  const mapping = {
    'code-style': 'skill',
    'architecture': 'skill',
    'testing': 'skill',
    'workflow': 'command',
    'debugging': 'command',
    'review': 'agent',
    'code': 'skill',
    'novel': 'skill',
    'news': 'skill'
  };
  return mapping[domain] || 'skill';
}

// ============ 主入口 ============

const [,, command, ...args] = process.argv;

switch (command) {
  case 'create':
    if (args.length < 3) {
      console.error('用法: instinct-cli.js create <id> <trigger> <domain> [scope]');
      process.exit(1);
    }
    createInstinct(args[0], args[1], args[2], args[3] || 'project');
    break;

  case 'list':
    const list = listInstincts(args[0] || 'all');
    if (list.length === 0) {
      console.log('无 instinct');
    } else {
      list.forEach(i => {
        console.log(`${i.id} [${i.scope}] ${i.domain} ${i.confidence}`);
      });
    }
    break;

  case 'score':
    if (args.length < 2) {
      console.error('用法: instinct-cli.js score <id> <delta>');
      process.exit(1);
    }
    updateScore(args[0], parseFloat(args[1]));
    break;

  case 'prune':
    pruneInstincts(parseFloat(args[0]) || 0.3);
    break;

  case 'evolve':
    evolveInstincts(parseInt(args[0]) || 5, parseFloat(args[1]) || 0.7);
    break;

  case 'stats':
    showStats();
    break;

  case 'export':
    if (args.length < 2) {
      console.error('用法: instinct-cli.js export <id> <output-file>');
      process.exit(1);
    }
    exportInstinct(args[0], args[1]);
    break;

  case 'import':
    if (args.length < 1) {
      console.error('用法: instinct-cli.js import <file> [--scope=project|global]');
      process.exit(1);
    }
    importInstinct(args[0], args[1] || '--scope=project');
    break;

  case 'promote':
    if (args.length < 1) {
      console.error('用法: instinct-cli.js promote <id>');
      process.exit(1);
    }
    promoteInstinct(args[0]);
    break;

  default:
    console.log('Instinct CLI - 持续学习系统');
    console.log('\n命令:');
    console.log('  create <id> <trigger> <domain> [scope]  创建 instinct');
    console.log('  list [scope]                            列出 instinct');
    console.log('  score <id> <delta>                      更新置信度');
    console.log('  prune [threshold]                       修剪低置信度 instinct');
    console.log('  evolve [minCount] [minConfidence]       进化为 skill/command');
    console.log('  stats                                   统计信息');
    console.log('  export <id> <output-file>              导出 instinct 为 YAML (G-4)');
    console.log('  import <file> [--scope=project|global]  导入外部 instinct (G-4)');
    console.log('  promote <id>                            提升 project → global (G-4)');
}
