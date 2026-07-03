#!/usr/bin/env node
/**
 * Continuous Learning - Session Extractor
 *
 * 三域通用。从会话文件中提取模式、陷阱和经验。
 * 用于 Stop Hook 或手动触发。
 *
 * Usage:
 *   node extractor.js --domain code    # Code 域提取
 *   node extractor.js --domain novel   # Novel 域提取
 *   node extractor.js --domain news    # News 域提取
 */

const fs = require('fs');
const path = require('path');

const MEMORY_DIR = path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'memory');

function getLearnedDir(domain) {
  return path.join(MEMORY_DIR, 'learned', domain || 'general');
}

function getLearnedFile(domain) {
  return path.join(MEMORY_DIR, 'learned', `${domain || 'general'}.json`);
}

function ensureDirs(domain) {
  const base = getLearnedDir(domain);
  ['debugging', 'project-patterns', 'tool-tips', 'error-handling', 'security']
    .map(d => path.join(base, d))
    .forEach(dir => { if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true }); });
}

// ─────────────────────────────────────────────
// Extractors (domain-aware)
// ─────────────────────────────────────────────

function extractPatterns(content, domain) {
  const allPatterns = [];

  const debugMethods = [
    { pattern: /console\.log|logger\.|print\(/g, method: '日志输出' },
    { pattern: /breakpoint|debugger/g, method: '断点调试' },
    { pattern: /git blame|git log/g, method: 'Git 历史追踪' },
    { pattern: /grep|find|rg/g, method: '代码搜索' }
  ];

  debugMethods.forEach(({ pattern, method }) => {
    if (pattern.test(content)) allPatterns.push({ type: 'debugging', trigger: `when debugging ${method}`, action: method, confidence: 0.6 });
  });

  const errorPatterns = [
    { pattern: /try\s*\{[\s\S]*?\}\s*catch/gs, method: 'try-catch 块' },
    { pattern: /throw\s+new\s+Error/g, method: '抛出错误' }
  ];

  errorPatterns.forEach(({ pattern, method }) => {
    if (pattern.test(content)) allPatterns.push({ type: 'error-handling', trigger: 'when handling errors', action: method, confidence: 0.5 });
  });

  // Novel-specific: AI writing markers
  if (domain === 'novel') {
    [/眼中闪过/g, /嘴角勾起/g, /深吸一口气/g, /总而言之/g].forEach(marker => {
      if (marker.test(content)) allPatterns.push({ type: 'error-handling', trigger: 'AI 写作痕迹', action: 'AI marker detected', confidence: 0.8 });
    });
  }

  // News-specific: fact check patterns
  if (domain === 'news') {
    [/fact.check|事实核查|verify|source/gi].forEach(p => {
      if (p.test(content)) allPatterns.push({ type: 'project-pattern', trigger: '事实核查', action: '事实核查', confidence: 0.7 });
    });
  }

  const seen = new Set();
  return allPatterns.filter(p => {
    const key = `${p.type}:${p.action}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

// ─────────────────────────────────────────────
// Storage (domain-scoped)
// ─────────────────────────────────────────────

function categorizePattern(pattern) {
  const map = { 'debugging': 'debugging', 'project-pattern': 'project-patterns', 'tool-tip': 'tool-tips', 'error-handling': 'error-handling', 'security': 'security' };
  return map[pattern.type] || 'general';
}

function generateId(type, action) {
  const ts = Date.now().toString(36);
  const slug = action.toLowerCase().replace(/[^a-z0-9]+/g, '-').substring(0, 30);
  return `${type}-${slug}-${ts}`;
}

function savePattern(pattern, domain) {
  ensureDirs(domain);
  const id = pattern.id || generateId(pattern.type, pattern.action);
  const cat = categorizePattern(pattern);
  const filepath = path.join(getLearnedDir(domain), cat, `${id}.yaml`);
  const content = `---
id: ${id}
type: ${pattern.type}
domain: ${domain}
trigger: "${pattern.trigger}"
action: "${pattern.action}"
confidence: ${pattern.confidence}
scope: ${pattern.scope || 'global'}
source: ${pattern.source || 'session-observation'}
created: ${pattern.created || new Date().toISOString()}
last_seen: ${new Date().toISOString()}
count: ${pattern.count || 1}
---
`;
  fs.writeFileSync(filepath, content, 'utf-8');
  return filepath;
}

function loadLearnedPatterns(domain) {
  const f = getLearnedFile(domain);
  if (!fs.existsSync(f)) return [];
  try { return JSON.parse(fs.readFileSync(f, 'utf-8')); } catch (e) { return []; }
}

function saveLearnedStats(patterns, domain) {
  const stats = { last_extract: new Date().toISOString(), domain, total_patterns: patterns.length, by_type: {} };
  patterns.forEach(p => { stats.by_type[p.type] = (stats.by_type[p.type] || 0) + 1; });
  fs.writeFileSync(getLearnedFile(domain), JSON.stringify(stats, null, 2), 'utf-8');
}

function extractFromSession(sessionFile, domain) {
  if (!fs.existsSync(sessionFile)) { console.error(`[Extractor] No session file: ${sessionFile}`); return []; }
  const content = fs.readFileSync(sessionFile, 'utf-8');
  const patterns = extractPatterns(content, domain);
  const savedPaths = patterns.map(p => savePattern(p, domain));
  const all = loadLearnedPatterns(domain);
  saveLearnedStats([...all, ...patterns], domain);
  return savedPaths;
}

function processInput(input) {
  try {
    const data = typeof input === 'string' ? JSON.parse(input) : input;
    const sessionFile = data.session_file || data.sessionPath || data.path;
    const domain = data.domain || 'code';
    if (!sessionFile) return { success: false, error: 'No session file' };
    const saved = extractFromSession(sessionFile, domain);
    return { success: true, domain, patterns_count: saved.length, saved_files: saved };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

// ─────────────────────────────────────────────
// CLI
// ─────────────────────────────────────────────

function parseArgs(argv) {
  const args = { domain: 'code' };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--domain' && argv[i + 1]) { args.domain = argv[i + 1]; i++; }
    else if (argv[i].startsWith('--domain=')) { args.domain = argv[i].split('=')[1]; }
    else if (!argv[i].startsWith('--')) { args.input = argv[i]; }
  }
  return args;
}

if (require.main === module) {
  const args = parseArgs(process.argv);
  ensureDirs(args.domain);
  if (args.input) {
    const result = processInput(args.input);
    console.log(JSON.stringify(result, null, 2));
  } else {
    let input = '';
    process.stdin.on('data', chunk => input += chunk);
    process.stdin.on('end', () => {
      const data = JSON.parse(input || '{}');
      data.domain = data.domain || args.domain;
      console.log(JSON.stringify(processInput(JSON.stringify(data)), null, 2));
    });
  }
}

module.exports = { extractPatterns, extractFromSession, processInput, savePattern, loadLearnedPatterns, ensureDirs };
