#!/usr/bin/env node
/**
 * Continuous Learning - Evaluate Session Hook
 *
 * Stop Hook 实现：会话结束时自动评估并提取模式。
 * 非阻塞模式：exit 0 即使出错也不影响主流程。
 */

const fs = require('fs');
const path = require('path');

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

const CLAUDE_DIR = path.join(process.env.HOME || process.env.USERPROFILE, '.claude');
const MEMORY_DIR = path.join(CLAUDE_DIR, 'memory');
const LEARNED_DIR = path.join(MEMORY_DIR, 'learned');
const LEARNED_FILE = path.join(MEMORY_DIR, 'learned.json');

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

function log(level, ...args) {
  // 只在 DEBUG 模式下输出
  if (process.env.DEBUG) {
    console.error(`[EvaluateSession][${level}]`, ...args);
  }
}

function ensureDirs() {
  const dirs = [
    MEMORY_DIR,
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
    keywords: [/调试|debug|定位|root cause|根因|排查|bug|缺陷/gi, /console\.log|print\(|logger|trace/gi],
    confidence: 0.7
  },
  'project-pattern': {
    keywords: [/项目特定|规范|约定|convention|architecture|架构/gi, /read before edit|先读后写/gi],
    confidence: 0.6
  },
  'tool-tip': {
    keywords: [/高效|efficient|快捷|shortcut|技巧/gi, /glob|grep|find|xargs/gi],
    confidence: 0.5
  },
  'error-handling': {
    keywords: [/错误处理|error handling|异常|catch|try.*catch/gi, /throw|raise|except/gi],
    confidence: 0.6
  },
  security: {
    keywords: [/安全|security|注入|injection|验证|validation/gi, /sanitize|escape|auth/gi],
    confidence: 0.7
  }
};

/**
 * 简单模式检测
 */
function detectSimplePatterns(content) {
  const results = [];

  for (const [type, config] of Object.entries(PATTERNS)) {
    for (const keyword of config.keywords) {
      if (keyword.test(content)) {
        results.push({
          type,
          confidence: config.confidence,
          matched_keyword: keyword.toString()
        });
        break; // 每种类型只取一个
      }
    }
  }

  return results;
}

// ─────────────────────────────────────────────
// Storage
// ─────────────────────────────────────────────

function generateId(type, timestamp) {
  const slug = `instinct-${Date.now().toString(36)}`;
  return slug;
}

function savePattern(pattern) {
  ensureDirs();

  const id = pattern.id || generateId(pattern.type);
  const categoryDir = path.join(LEARNED_DIR, pattern.type === 'project-pattern' ? 'project-patterns' : pattern.type);

  if (!fs.existsSync(categoryDir)) {
    fs.mkdirSync(categoryDir, { recursive: true });
  }

  const filename = `${id}.md`;
  const filepath = path.join(categoryDir, filename);

  const content = `---
id: ${id}
type: ${pattern.type}
confidence: ${pattern.confidence}
trigger: "${pattern.trigger || 'auto-detected'}"
scope: ${pattern.scope || 'global'}
source: session-observation
created: ${pattern.created || new Date().toISOString()}
---

# ${pattern.type}: ${id}

## 触发条件
${pattern.trigger || '从会话中自动检测'}

## 置信度
${(pattern.confidence * 100).toFixed(0)}%

${pattern.evidence ? `\n## 证据\n${pattern.evidence.map(e => `- ${e}`).join('\n')}` : ''}
`;

  fs.writeFileSync(filepath, content, 'utf-8');
  return filepath;
}

/**
 * 更新学习统计
 */
function updateStats(newCount) {
  let stats = { total_patterns: 0, by_type: {}, last_extract: null };

  if (fs.existsSync(LEARNED_FILE)) {
    try {
      stats = JSON.parse(fs.readFileSync(LEARNED_FILE, 'utf-8'));
    } catch (e) {
      // 忽略解析错误
    }
  }

  stats.total_patterns += newCount;
  stats.last_extract = new Date().toISOString();

  fs.writeFileSync(LEARNED_FILE, JSON.stringify(stats, null, 2), 'utf-8');
  return stats;
}

// ─────────────────────────────────────────────
// Main Processing
// ─────────────────────────────────────────────

/**
 * 处理会话输入
 */
function processSession(rawInput) {
  try {
    // 解析输入
    let input;
    try {
      input = JSON.parse(rawInput);
    } catch (e) {
      // 如果不是 JSON，可能只是普通文本
      input = { content: rawInput };
    }

    const sessionFile = input.session_file || input.sessionPath || input.path;
    const content = input.content || input.session_content;

    log('info', 'Processing session', { sessionFile: sessionFile ? 'provided' : 'none' });

    // 如果没有内容，尝试读取文件
    let sessionContent = content;
    if (!sessionContent && sessionFile && fs.existsSync(sessionFile)) {
      sessionContent = fs.readFileSync(sessionFile, 'utf-8');
    }

    if (!sessionContent) {
      log('warn', 'No session content available');
      return { success: true, patterns_count: 0, reason: 'no_content' };
    }

    // 确保目录存在
    ensureDirs();

    // 检测模式
    const patterns = detectSimplePatterns(sessionContent);

    if (patterns.length === 0) {
      log('info', 'No patterns detected');
      return { success: true, patterns_count: 0 };
    }

    // 保存模式
    const savedFiles = [];
    for (const pattern of patterns) {
      try {
        const saved = savePattern({
          id: generateId(pattern.type),
          type: pattern.type,
          confidence: pattern.confidence,
          trigger: `detected: ${pattern.matched_keyword}`,
          scope: input.project_id ? 'project' : 'global',
          created: new Date().toISOString()
        });
        savedFiles.push(saved);
      } catch (e) {
        log('error', `Failed to save pattern: ${e.message}`);
      }
    }

    // 更新统计
    const stats = updateStats(savedFiles.length);

    log('info', `Saved ${savedFiles.length} patterns`, stats);

    return {
      success: true,
      patterns_count: savedFiles.length,
      saved_files: savedFiles,
      stats
    };

  } catch (e) {
    log('error', `Error processing session: ${e.message}`);
    // 始终返回成功，确保 hook 不阻塞
    return { success: true, error: e.message };
  }
}

/**
 * CLI 入口
 */
function main() {
  // 从 stdin 读取输入
  let rawInput = '';

  if (process.stdin.isTTY) {
    // 没有 stdin，使用参数或默认值
    const result = processSession(JSON.stringify({}));
    console.log(JSON.stringify(result));
    return;
  }

  process.stdin.setEncoding('utf-8');
  process.stdin.on('data', chunk => rawInput += chunk);
  process.stdin.on('end', () => {
    const result = processSession(rawInput);
    console.log(JSON.stringify(result));
  });
}

// 导出供测试
module.exports = {
  processSession,
  detectSimplePatterns,
  savePattern,
  updateStats,
  ensureDirs
};

// 直接运行
if (require.main === module) {
  main();
}

// 非阻塞退出（即使有错误）
process.on('uncaughtException', (e) => {
  console.error('[EvaluateSession] Uncaught exception:', e.message);
  process.exit(0);
});

process.on('unhandledRejection', (e) => {
  console.error('[EvaluateSession] Unhandled rejection:', e.message);
  process.exit(0);
});
