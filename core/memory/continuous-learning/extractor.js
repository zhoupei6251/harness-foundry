#!/usr/bin/env node
/**
 * Continuous Learning - Session Extractor
 *
 * 从会话文件中提取模式、陷阱和经验。
 * 用于 Stop Hook 或手动触发。
 */

const fs = require('fs');
const path = require('path');

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

const MEMORY_DIR = path.join(process.env.HOME || process.env.USERPROFILE, '.claude', 'memory');
const LEARNED_DIR = path.join(MEMORY_DIR, 'learned');
const LEARNED_FILE = path.join(MEMORY_DIR, 'learned.json');

// 确保目录存在
function ensureDirs() {
  const dirs = [
    LEARNED_DIR,
    path.join(LEARNED_DIR, 'debugging'),
    path.join(LEARNED_DIR, 'project-patterns'),
    path.join(LEARNED_DIR, 'tool-tips'),
    path.join(LEARNED_DIR, 'error-handling'),
    path.join(LEARNED_DIR, 'security'),
  ];
  dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });
}

// ─────────────────────────────────────────────
// Pattern Detection
// ─────────────────────────────────────────────

const PATTERNS = {
  debugging: {
    keywords: [/调试|debug|定位|root cause|根因|排查|bug|缺陷/gi, /console\.log|print\(|logger|trace|step through/gi],
    confidence: 0.7,
    description: '调试技术'
  },
  'project-pattern': {
    keywords: [/项目特定|规范|约定|convention|architecture|架构|模式|最佳实践/gi, /read before edit|grep before|read first/gi],
    confidence: 0.6,
    description: '项目模式'
  },
  'tool-tip': {
    keywords: [/高效|efficient|快捷|shortcut|组合|combo|tips|技巧/gi, /glob|grep|find|xargs|pipe/gi],
    confidence: 0.5,
    description: '工具技巧'
  },
  'error-handling': {
    keywords: [/错误处理|error handling|异常|catch|try.*catch|finally|容错/gi, /throw|raise|except|panic/gi],
    confidence: 0.6,
    description: '错误处理'
  },
  security: {
    keywords: [/安全|security|注入|injection|验证|validation|敏感|sensitive|加密|encrypt/gi, /sanitize|escape|auth|permission|credential/gi],
    confidence: 0.7,
    description: '安全实践'
  }
};

// ─────────────────────────────────────────────
// Extractors
// ─────────────────────────────────────────────

/**
 * 从内容中提取调试模式
 */
function extractDebugPatterns(content) {
  const patterns = [];
  const lines = content.split('\n');

  // 检测调试方法
  const debugMethods = [
    { pattern: /console\.log|logger\.|print\(/g, method: '日志输出' },
    { pattern: /breakpoint|debugger/g, method: '断点调试' },
    { pattern: /git blame|git log/g, method: 'Git 历史追踪' },
    { pattern: /grep|find|rg/g, method: '代码搜索' },
    { pattern: /console\.table|json\.stringify/g, method: '对象检查' }
  ];

  debugMethods.forEach(({ pattern, method }) => {
    if (pattern.test(content)) {
      patterns.push({
        type: 'debugging',
        trigger: `when debugging ${method.toLowerCase()}`,
        action: method,
        confidence: 0.6
      });
    }
  });

  return patterns;
}

/**
 * 从内容中提取错误处理模式
 */
function extractErrorPatterns(content) {
  const patterns = [];
  const errorPatterns = [
    { pattern: /try\s*\{[\s\S]*?\}\s*catch/gs, method: 'try-catch 块' },
    { pattern: /if\s*\(\s*err/g, method: '错误检查' },
    { pattern: /\.catch\(/g, method: 'Promise 错误处理' },
    { pattern: /throw\s+new\s+Error/g, method: '抛出错误' },
    { pattern: /finally\s*\{/g, method: 'finally 清理' }
  ];

  errorPatterns.forEach(({ pattern, method }) => {
    if (pattern.test(content)) {
      patterns.push({
        type: 'error-handling',
        trigger: `when handling errors in ${method.toLowerCase()}`,
        action: method,
        confidence: 0.5
      });
    }
  });

  return patterns;
}

/**
 * 从内容中提取安全模式
 */
function extractSecurityPatterns(content) {
  const patterns = [];
  const securityPatterns = [
    { pattern: /sanitize|escape|input validation/g, method: '输入验证' },
    { pattern: /password|secret|api[_-]?key|token/gi, method: '敏感数据处理' },
    { pattern: /sql injection|xss|csrf/gi, method: '注入攻击防护' },
    { pattern: /https?|ssl|tls/gi, method: '传输安全' },
    { pattern: /authorization|permission|auth/gi, method: '权限检查' }
  ];

  securityPatterns.forEach(({ pattern, method }) => {
    if (pattern.test(content)) {
      patterns.push({
        type: 'security',
        trigger: `when dealing with ${method.toLowerCase()}`,
        action: method,
        confidence: 0.7
      });
    }
  });

  return patterns;
}

/**
 * 从内容中提取工具技巧
 */
function extractToolPatterns(content) {
  const patterns = [];
  const toolPatterns = [
    { pattern: /git add -p|git add --patch/g, method: 'Git 部分暂存' },
    { pattern: /git rebase -i|git interactive rebase/g, method: 'Git 交互式变基' },
    { pattern: /grep -r --include|rg/g, method: '递归搜索' },
    { pattern: /find.*-exec|find.*\;|xargs/g, method: '批量处理' },
    { pattern: /glob\(|path\.join|path\.resolve/g, method: '路径处理' }
  ];

  toolPatterns.forEach(({ pattern, method }) => {
    if (pattern.test(content)) {
      patterns.push({
        type: 'tool-tip',
        trigger: `when using ${method.toLowerCase()}`,
        action: method,
        confidence: 0.5
      });
    }
  });

  return patterns;
}

/**
 * 从内容中提取项目模式
 */
function extractProjectPatterns(content) {
  const patterns = [];
  const projectPatterns = [
    { pattern: /read before write|先读后写/gi, method: 'Read before Write' },
    { pattern: /test first|测试先行/gi, method: '测试驱动开发' },
    { pattern: /small commit|小步提交/gi, method: '小步提交' },
    { pattern: /convention|约定|规范/gi, method: '遵循项目规范' }
  ];

  projectPatterns.forEach(({ pattern, method }) => {
    if (pattern.test(content)) {
      patterns.push({
        type: 'project-pattern',
        trigger: `when ${method.toLowerCase()}`,
        action: method,
        confidence: 0.6
      });
    }
  });

  return patterns;
}

// ─────────────────────────────────────────────
// Main Extraction
// ─────────────────────────────────────────────

/**
 * 从会话内容提取所有模式
 */
function extractPatterns(sessionContent) {
  const allPatterns = [];

  allPatterns.push(...extractDebugPatterns(sessionContent));
  allPatterns.push(...extractErrorPatterns(sessionContent));
  allPatterns.push(...extractSecurityPatterns(sessionContent));
  allPatterns.push(...extractToolPatterns(sessionContent));
  allPatterns.push(...extractProjectPatterns(sessionContent));

  // 去重
  const seen = new Set();
  return allPatterns.filter(p => {
    const key = `${p.type}:${p.action}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

/**
 * 分类模式
 */
function categorizePattern(pattern) {
  switch (pattern.type) {
    case 'debugging': return 'debugging';
    case 'project-pattern': return 'project-patterns';
    case 'tool-tip': return 'tool-tips';
    case 'error-handling': return 'error-handling';
    case 'security': return 'security';
    default: return 'general';
  }
}

// ─────────────────────────────────────────────
// Storage
// ─────────────────────────────────────────────

/**
 * 生成唯一 ID
 */
function generateId(type, action) {
  const timestamp = Date.now().toString(36);
  const actionSlug = action
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .substring(0, 30);
  return `${type}-${actionSlug}-${timestamp}`;
}

/**
 * 保存模式到文件
 */
function savePattern(pattern) {
  ensureDirs();

  const id = pattern.id || generateId(pattern.type, pattern.action);
  const category = categorizePattern(pattern);
  const filename = `${id}.yaml`;
  const filepath = path.join(LEARNED_DIR, category, filename);

  const content = `---
id: ${id}
type: ${pattern.type}
trigger: "${pattern.trigger}"
action: "${pattern.action}"
confidence: ${pattern.confidence}
scope: ${pattern.scope || 'global'}
source: ${pattern.source || 'session-observation'}
created: ${pattern.created || new Date().toISOString()}
last_seen: ${new Date().toISOString()}
count: ${pattern.count || 1}
---

# ${pattern.action}

## 触发条件
${pattern.trigger}

## 执行动作
${pattern.action}

## 证据
${(pattern.evidence || []).map(e => `- ${e}`).join('\n')}
`;

  fs.writeFileSync(filepath, content, 'utf-8');
  return filepath;
}

/**
 * 加载已学习的模式
 */
function loadLearnedPatterns() {
  if (!fs.existsSync(LEARNED_FILE)) {
    return [];
  }
  try {
    return JSON.parse(fs.readFileSync(LEARNED_FILE, 'utf-8'));
  } catch (e) {
    return [];
  }
}

/**
 * 保存已学习模式统计
 */
function saveLearnedStats(patterns) {
  const stats = {
    last_extract: new Date().toISOString(),
    total_patterns: patterns.length,
    by_type: {}
  };

  patterns.forEach(p => {
    stats.by_type[p.type] = (stats.by_type[p.type] || 0) + 1;
  });

  fs.writeFileSync(LEARNED_FILE, JSON.stringify(stats, null, 2), 'utf-8');
}

// ─────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────

/**
 * 从会话文件提取模式
 */
function extractFromSession(sessionFile) {
  if (!fs.existsSync(sessionFile)) {
    console.error(`[Extractor] Session file not found: ${sessionFile}`);
    return [];
  }

  const content = fs.readFileSync(sessionFile, 'utf-8');
  const patterns = extractPatterns(content);

  // 保存每个模式
  const savedPaths = patterns.map(p => savePattern(p));

  // 更新统计
  const allPatterns = loadLearnedPatterns();
  saveLearnedStats([...allPatterns, ...patterns]);

  return savedPaths;
}

/**
 * 处理原始输入（从 stdin 或参数）
 */
function processInput(input) {
  try {
    const data = typeof input === 'string' ? JSON.parse(input) : input;
    const sessionFile = data.session_file || data.sessionPath || data.path;

    if (!sessionFile) {
      console.error('[Extractor] No session file provided');
      return { success: false, error: 'No session file' };
    }

    const saved = extractFromSession(sessionFile);
    return {
      success: true,
      patterns_count: saved.length,
      saved_files: saved
    };
  } catch (e) {
    console.error(`[Extractor] Error: ${e.message}`);
    return { success: false, error: e.message };
  }
}

// ─────────────────────────────────────────────
// CLI
// ─────────────────────────────────────────────

if (require.main === module) {
  // 确保目录存在
  ensureDirs();

  // 从 stdin 读取输入
  let input = '';
  process.stdin.on('data', chunk => input += chunk);
  process.stdin.on('end', () => {
    const result = processInput(input);
    console.log(JSON.stringify(result, null, 2));
  });

  // 如果没有 stdin，从参数读取
  if (process.argv.length > 2) {
    const result = processInput(process.argv[2]);
    console.log(JSON.stringify(result, null, 2));
  }
}

module.exports = {
  extractPatterns,
  extractDebugPatterns,
  extractErrorPatterns,
  extractSecurityPatterns,
  extractToolPatterns,
  extractProjectPatterns,
  savePattern,
  loadLearnedPatterns,
  extractFromSession,
  processInput,
  ensureDirs
};
