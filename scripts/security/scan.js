#!/usr/bin/env node
/**
 * AgentShield Security Scanner
 *
 * 扫描 Harness Foundry 配置中的安全漏洞：
 * - Secrets 检测 (API keys, tokens, passwords)
 * - 注入风险检测 (shell, path traversal)
 * - Hook 安全审计
 * - MCP 配置检查
 */

const fs = require('fs');
const path = require('path');

// ============================================================================
// 扫描模式定义
// ============================================================================

const SCAN_PATTERNS = {
  // Secrets 检测 - CRITICAL
  secrets: [
    {
      name: 'OpenAI API Key',
      pattern: /sk-[a-zA-Z0-9]{48}/g,
      severity: 'CRITICAL',
      description: '检测到疑似 OpenAI API Key'
    },
    {
      name: 'GitHub Personal Access Token',
      pattern: /ghp_[a-zA-Z0-9]{36}/g,
      severity: 'CRITICAL',
      description: '检测到疑似 GitHub Token'
    },
    {
      name: 'GitHub OAuth Token',
      pattern: /gho_[a-zA-Z0-9]{36}/g,
      severity: 'CRITICAL',
      description: '检测到疑似 GitHub OAuth Token'
    },
    {
      name: 'GitHub User-to-Server Token',
      pattern: /ghu_[a-zA-Z0-9]{36}/g,
      severity: 'CRITICAL',
      description: '检测到疑似 GitHub User-to-Server Token'
    },
    {
      name: 'AWS Access Key',
      pattern: /AKIA[0-9A-Z]{16}/g,
      severity: 'CRITICAL',
      description: '检测到疑似 AWS Access Key'
    },
    {
      name: 'Email with Password',
      pattern: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\s*[:=]\s*[a-zA-Z0-9!@#$%^&*()_+=-]+/g,
      severity: 'CRITICAL',
      description: '检测到 Email:Password 格式'
    },
    {
      name: 'Generic API Key',
      pattern: /api[_-]?key['"]?\s*[:=]\s*['"][a-zA-Z0-9_\-]{20,}['"]/gi,
      severity: 'HIGH',
      description: '检测到疑似 API Key'
    },
    {
      name: 'Generic Secret',
      pattern: /secret['"]?\s*[:=]\s*['"][^'"]{8,}['"]/gi,
      severity: 'HIGH',
      description: '检测到疑似 Secret'
    },
    {
      name: 'Generic Token',
      pattern: /token['"]?\s*[:=]\s*['"][a-zA-Z0-9_\-]{20,}['"]/gi,
      severity: 'HIGH',
      description: '检测到疑似 Token'
    },
    {
      name: 'Private Key Header',
      pattern: /-----BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY-----/g,
      severity: 'CRITICAL',
      description: '检测到私钥文件内容'
    },
    {
      name: 'Password Assignment',
      pattern: /password['"]?\s*[:=]\s*['"][^'"]{4,}['"]/gi,
      severity: 'HIGH',
      description: '检测到疑似密码'
    }
  ],

  // 注入风险 - HIGH
  injection: [
    {
      name: 'Shell Command Injection',
      pattern: /;\s*rm\s+-rf/gi,
      severity: 'HIGH',
      description: '检测到危险的 rm -rf 命令'
    },
    {
      name: 'Shell Variable Injection',
      pattern: /\$\([^\)]+\)/g,
      severity: 'MEDIUM',
      description: '检测到 Shell 命令替换'
    },
    {
      name: 'Backtick Command Injection',
      pattern: /`[^`]*\$\{[^}]+\}[^`]*`/g,
      severity: 'MEDIUM',
      description: '检测到反引号命令注入'
    },
    {
      name: 'Curl with Pipe',
      pattern: /curl[^\|]*\|\s*bash/gi,
      severity: 'HIGH',
      description: '检测到 curl | bash 危险模式'
    },
    {
      name: 'Wget with Pipe',
      pattern: /wget[^\|]*\|\s*bash/gi,
      severity: 'HIGH',
      description: '检测到 wget | bash 危险模式'
    },
    {
      name: 'Eval with Variable',
      pattern: /eval\s+\$/g,
      severity: 'HIGH',
      description: '检测到 eval 命令注入风险'
    },
    {
      name: 'Python Import OS',
      pattern: /__import__\s*\(\s*['"]os['"]\s*\)/g,
      severity: 'HIGH',
      description: '检测到 Python OS 模块导入'
    },
    {
      name: 'Python OS System',
      pattern: /os\.system\s*\(/g,
      severity: 'HIGH',
      description: '检测到 OS system 调用'
    }
  ],

  // 路径遍历 - HIGH
  pathTraversal: [
    {
      name: 'Unix Path Traversal',
      pattern: /\.\.\/[\.\.\/]+/g,
      severity: 'HIGH',
      description: '检测到 Unix 路径遍历'
    },
    {
      name: 'Windows Path Traversal',
      pattern: /\.\.\\[\.\.\\]+/g,
      severity: 'HIGH',
      description: '检测到 Windows 路径遍历'
    },
    {
      name: 'Sensitive Path Access',
      pattern: /\/etc\/passwd|\/etc\/shadow|C:\\Windows\\System32/gi,
      severity: 'MEDIUM',
      description: '检测到敏感系统路径'
    }
  ],

  // Prompt 注入 - HIGH
  promptInjection: [
    {
      name: 'Ignore Previous Instructions',
      pattern: /ignore\s+(all\s+)?(previous|above)\s+(instructions|rules|constraints)/gi,
      severity: 'HIGH',
      description: '检测到忽略指令尝试'
    },
    {
      name: 'Role Override',
      pattern: /you\s+are\s+now|your\s+new\s+(role|identity|name)\s+is/gi,
      severity: 'HIGH',
      description: '检测到角色劫持尝试'
    },
    {
      name: 'Forget Rules',
      pattern: /forget\s+(everything|all\s+rules)|disregard\s+(your\s+)?(system\s+)?prompt/gi,
      severity: 'HIGH',
      description: '检测到忘记规则尝试'
    },
    {
      name: 'Pretend Mode',
      pattern: /you\s+are\s+(no\s+longer|not)\s+an\s+AI|pretend\s+(you\s+are|to\s+be)|act\s+as\s+if/gi,
      severity: 'MEDIUM',
      description: '检测到伪装模式尝试'
    }
  ]
};

// ============================================================================
// Hook 安全检查
// ============================================================================

const HOOK_SECURITY_CHECKS = [
  {
    name: 'enableAllProjectMcpServers',
    pattern: /enableAllProjectMcpServers/,
    severity: 'HIGH',
    description: '检测到自动启用所有项目 MCP 服务器的配置'
  },
  {
    name: 'ANTHROPIC_BASE_URL Override',
    pattern: /ANTHROPIC_BASE_URL/,
    severity: 'CRITICAL',
    description: '检测到可被覆盖的 ANTHROPIC_BASE_URL'
  },
  {
    name: 'Dangerous Bash Commands',
    pattern: /rm\s+-rf|nc\s+|netcat/i,
    severity: 'HIGH',
    description: 'Hook 中包含危险命令'
  },
  {
    name: 'External Network Call',
    pattern: /curl\s+|wget\s+http/gi,
    severity: 'MEDIUM',
    description: 'Hook 包含外部网络调用'
  }
];

// ============================================================================
// MCP 安全检查
// ============================================================================

const MCP_SECURITY_CHECKS = [
  {
    name: 'Auto-approve MCP',
    check: (config) => config.autoApprove === true || config.trust === true,
    severity: 'HIGH',
    description: 'MCP 配置为自动批准'
  },
  {
    name: 'Overly Broad File Access',
    check: (config) => {
      if (!config.permissions) return false;
      const perms = JSON.stringify(config.permissions);
      return perms.includes('**/*') || perms.includes('~/**');
    },
    severity: 'MEDIUM',
    description: 'MCP 权限过于宽松'
  },
  {
    name: 'Unconstrained Shell',
    check: (config) => {
      if (!config.permissions) return false;
      const perms = JSON.stringify(config.permissions);
      return perms.includes('Bash(*)') || perms.includes('Bash(.*)');
    },
    severity: 'HIGH',
    description: 'Shell 权限未限制'
  }
];

// ============================================================================
// 辅助函数
// ============================================================================

/**
 * 获取文件扩展名
 */
function getExtension(filepath) {
  return path.extname(filepath).toLowerCase();
}

/**
 * 判断文件是否应被扫描
 */
function shouldScan(filepath) {
  const ext = getExtension(filepath);
  const skipPatterns = [
    /node_modules/,
    /\.git/,
    /\.test\.js$/,
    /spec\.js$/,
    /\.min\.(js|css)$/,
    /dist\//,
    /build\//
  ];

  for (const pattern of skipPatterns) {
    if (pattern.test(filepath)) return false;
  }

  // 可扫描的文件类型
  const scannableExts = ['.js', '.json', '.yaml', '.yml', '.md', '.ts', '.tsx', '.py', '.sh', '.ps1'];
  return scannableExts.includes(ext);
}

/**
 * 扫描单个文件
 */
function scanFile(filepath, content) {
  const issues = [];
  const lines = content.split('\n');

  // 扫描 Secrets
  for (const rule of SCAN_PATTERNS.secrets) {
    const matches = content.match(rule.pattern);
    if (matches) {
      matches.forEach(match => {
        // 找到匹配的行号
        const lineNum = lines.findIndex(line => line.includes(match));
        issues.push({
          type: 'SECRET',
          severity: rule.severity,
          file: filepath,
          line: lineNum + 1,
          pattern: rule.name,
          match: match.substring(0, 20) + (match.length > 20 ? '...' : ''),
          description: rule.description
        });
      });
    }
  }

  // 扫描注入风险
  for (const rule of SCAN_PATTERNS.injection) {
    const matches = content.match(rule.pattern);
    if (matches) {
      matches.forEach(match => {
        const lineNum = lines.findIndex(line => line.includes(match));
        issues.push({
          type: 'INJECTION',
          severity: rule.severity,
          file: filepath,
          line: lineNum + 1,
          pattern: rule.name,
          match: match.substring(0, 30) + (match.length > 30 ? '...' : ''),
          description: rule.description
        });
      });
    }
  }

  // 扫描路径遍历
  for (const rule of SCAN_PATTERNS.pathTraversal) {
    if (typeof rule.pattern === 'string') continue;
    const matches = content.match(rule.pattern);
    if (matches) {
      const lineNum = lines.findIndex(line => rule.pattern.test(line));
      if (lineNum >= 0) {
        issues.push({
          type: 'PATH_TRAVERSAL',
          severity: rule.severity,
          file: filepath,
          line: lineNum + 1,
          pattern: rule.name,
          description: rule.description
        });
      }
    }
  }

  // 扫描 Prompt 注入
  for (const rule of SCAN_PATTERNS.promptInjection) {
    const matches = content.match(rule.pattern);
    if (matches) {
      const lineNum = lines.findIndex(line => rule.pattern.test(line));
      if (lineNum >= 0) {
        issues.push({
          type: 'PROMPT_INJECTION',
          severity: rule.severity,
          file: filepath,
          line: lineNum + 1,
          pattern: rule.name,
          description: rule.description
        });
      }
    }
  }

  return issues;
}

/**
 * 扫描 Hook 配置
 */
function scanHookConfig(filepath, content) {
  const issues = [];

  try {
    const config = JSON.parse(content);

    for (const hook of config.hooks || []) {
      if (hook.command) {
        // 检查命令注入
        for (const check of HOOK_SECURITY_CHECKS) {
          if (check.pattern.test(hook.command)) {
            issues.push({
              type: 'HOOK_INJECTION',
              severity: check.severity,
              file: filepath,
              line: 0,
              pattern: check.name,
              description: check.description
            });
          }
        }
      }

      if (hook.trust === true || hook.autoApprove === true) {
        issues.push({
          type: 'HOOK_PERMISSION',
          severity: 'HIGH',
          file: filepath,
          line: 0,
          pattern: 'Auto-approved Hook',
          description: 'Hook 配置为自动批准，可能执行未验证的代码'
        });
      }
    }
  } catch (e) {
    // JSON 解析失败，忽略
  }

  return issues;
}

/**
 * 递归扫描目录
 */
function scanDirectory(dirPath, scanType) {
  const issues = [];
  let fileCount = 0;

  function walk(currentPath) {
    try {
      const entries = fs.readdirSync(currentPath, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(currentPath, entry.name);

        if (entry.isDirectory()) {
          // 跳过特定目录
          if (/node_modules|\.git|\.test|spec|dist|build/.test(entry.name)) continue;
          walk(fullPath);
        } else if (entry.isFile() && shouldScan(fullPath)) {
          fileCount++;
          const content = fs.readFileSync(fullPath, 'utf-8');

          // 根据文件类型选择扫描
          if (entry.name === 'hooks.json' || entry.name === 'hooks.js') {
            if (!scanType || scanType === 'hooks' || scanType === 'all') {
              issues.push(...scanHookConfig(fullPath, content));
            }
          }

          if (!scanType || scanType === 'secrets' || scanType === 'all') {
            issues.push(...scanFile(fullPath, content));
          }
        }
      }
    } catch (e) {
      // 权限错误，忽略
    }
  }

  walk(dirPath);
  return { issues, fileCount };
}

/**
 * 计算安全评分
 */
function calculateScore(issues) {
  if (issues.length === 0) return 'A';

  const severityCounts = { CRITICAL: 0, HIGH: 0, MEDIUM: 0, LOW: 0 };

  for (const issue of issues) {
    severityCounts[issue.severity] = (severityCounts[issue.severity] || 0) + 1;
  }

  if (severityCounts.CRITICAL > 0) return 'F';
  if (severityCounts.HIGH >= 3) return 'D';
  if (severityCounts.HIGH > 0) return 'C';
  if (severityCounts.MEDIUM >= 3) return 'C';
  if (severityCounts.MEDIUM > 0) return 'B';
  return 'B';
}

/**
 * 格式化输出
 */
function formatOutput(result, format = 'text') {
  if (format === 'json') {
    return JSON.stringify(result, null, 2);
  }

  // 人类可读格式
  let output = '';
  output += '\n';
  output += '═══════════════════════════════════════════════════════════════\n';
  output += '                    AgentShield Security Report                \n';
  output += '═══════════════════════════════════════════════════════════════\n';
  output += '\n';
  output += `  Scan Time:  ${result.timestamp}\n`;
  output += `  Files:      ${result.files}\n`;
  output += `  Issues:     ${result.issues.length}\n`;
  output += `  Score:      ${result.score}\n`;
  output += '\n';

  // 按严重级别分组
  const bySeverity = { CRITICAL: [], HIGH: [], MEDIUM: [], LOW: [] };
  for (const issue of result.issues) {
    bySeverity[issue.severity] = bySeverity[issue.severity] || [];
    bySeverity[issue.severity].push(issue);
  }

  if (result.issues.length > 0) {
    output += '───────────────────────────────────────────────────────────────\n';

    // CRITICAL
    if (bySeverity.CRITICAL.length > 0) {
      output += '\n  [CRITICAL] 严重 - 必须立即修复\n';
      output += '  ─────────────────────────────────\n';
      for (const issue of bySeverity.CRITICAL) {
        output += `    ${issue.type}: ${issue.description}\n`;
        output += `    Location: ${issue.file}:${issue.line}\n`;
        output += '\n';
      }
    }

    // HIGH
    if (bySeverity.HIGH.length > 0) {
      output += '\n  [HIGH] 重要 - 建议立即修复\n';
      output += '  ─────────────────────────────────\n';
      for (const issue of bySeverity.HIGH) {
        output += `    ${issue.type}: ${issue.description}\n`;
        output += `    Location: ${issue.file}:${issue.line}\n`;
        output += '\n';
      }
    }

    // MEDIUM
    if (bySeverity.MEDIUM.length > 0) {
      output += '\n  [MEDIUM] 中等 - 应该修复\n';
      output += '  ─────────────────────────────────\n';
      for (const issue of bySeverity.MEDIUM) {
        output += `    ${issue.type}: ${issue.description}\n`;
        output += `    Location: ${issue.file}:${issue.line}\n`;
        output += '\n';
      }
    }

    // LOW
    if (bySeverity.LOW && bySeverity.LOW.length > 0) {
      output += '\n  [LOW] 轻微 - 可选修复\n';
      output += '  ─────────────────────────────────\n';
      for (const issue of bySeverity.LOW) {
        output += `    ${issue.type}: ${issue.description}\n`;
        output += '\n';
      }
    }

    output += '───────────────────────────────────────────────────────────────\n';
    output += '\n  Recommendations:\n';
    output += '  1. 立即移除所有硬编码的 secrets\n';
    output += '  2. 限制 hooks 中的 shell 执行权限\n';
    output += '  3. 审查 MCP 权限配置\n';
    output += '  4. 避免在注释中包含敏感信息\n';
  } else {
    output += '  ✓ 未发现安全问题\n';
  }

  output += '\n';
  output += '═══════════════════════════════════════════════════════════════\n';
  output += '\n';

  return output;
}

// ============================================================================
// 主程序
// ============================================================================

function main() {
  const args = process.argv.slice(2);

  let scanPath = process.cwd();
  let scanType = 'all';
  let outputFormat = 'text';

  // 解析参数
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--path' && args[i + 1]) {
      scanPath = path.resolve(args[i + 1]);
      i++;
    } else if (args[i] === '--type' && args[i + 1]) {
      scanType = args[i + 1];
      i++;
    } else if (args[i] === '--format' && args[i + 1]) {
      outputFormat = args[i + 1];
      i++;
    } else if (args[i] === '--help') {
      console.log(`
AgentShield Security Scanner
Usage: node scan.js [options]

Options:
  --path <path>      扫描指定路径 (默认: 当前目录)
  --type <type>      扫描类型: secrets|hooks|all (默认: all)
  --format <format> 输出格式: text|json (默认: text)
  --help            显示帮助

Examples:
  node scan.js                           # 完整扫描
  node scan.js --path ./hooks            # 扫描 hooks 目录
  node scan.js --type secrets            # 仅扫描 secrets
  node scan.js --format json            # JSON 格式输出
`);
      process.exit(0);
    }
  }

  // 执行扫描
  const { issues, fileCount } = scanDirectory(scanPath, scanType);

  // 构建结果
  const result = {
    timestamp: new Date().toISOString(),
    files: fileCount,
    issues: issues,
    score: calculateScore(issues),
    summary: {
      critical: issues.filter(i => i.severity === 'CRITICAL').length,
      high: issues.filter(i => i.severity === 'HIGH').length,
      medium: issues.filter(i => i.severity === 'MEDIUM').length,
      low: issues.filter(i => i.severity === 'LOW').length
    }
  };

  // 输出结果
  console.log(formatOutput(result, outputFormat));

  // 返回退出码
  process.exit(result.score === 'F' ? 2 : result.score === 'D' ? 1 : 0);
}

// 导出函数供测试
module.exports = { scanFile, scanHookConfig, scanDirectory, calculateScore };

// 运行主程序
if (require.main === module) {
  main();
}
