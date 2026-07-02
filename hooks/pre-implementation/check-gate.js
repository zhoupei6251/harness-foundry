#!/usr/bin/env node
/**
 * Design Gate Check Hook
 *
 * 强制设计门禁：任何实现前必须先有批准的设计文档
 *
 * 使用方式：
 *   node hooks/pre-implementation/check-gate.js '<input_json>'
 *
 * 输入格式：
 *   {
 *     "tool": "Edit|Write|Bash",
 *     "toolInput": { ... },
 *     "conversationHistory": [ ... ],
 *     "intent": "code|design|quick-fix"
 *   }
 *
 * 输出格式：
 *   {
 *     "pass": true|false,
 *     "message": "错误消息（如果 pass=false）",
 *     "gateStatus": {
 *       "brainstorming": true|false,
 *       "designDoc": true|false,
 *       "userApproved": true|false,
 *       "inDesignPhase": true|false
 *     }
 *   }
 */

const fs = require('fs');
const path = require('path');

const DESIGN_APPROVED_FILE = '.claude/.design-approved';
const DESIGN_DOC_PATTERN = /docs\/plans\/\d{4}-\d{2}-\d{2}-.+-design\.md/;

const IMPLEMENTATION_TOOLS = ['Edit', 'Write', 'Bash'];
const IMPLEMENTATION_PATTERNS = [
  /implement|实现|写代码|feature|功能|build|编译/,
  /create_file|scaffold|新增|添加/,
  /npm install|pnpm install|yarn add|go get|cargo add/
];

const DESIGN_PATTERNS = [
  /brainstorming|设计|方案|spec/i,
  /writing-plans|计划|任务列表/i,
  /docs\/plans/i
];

const QUICK_FIX_PATTERNS = [
  /quick[- ]?fix|小改动|直接改|简单修复/,
  /bug fix|fix bug|修复.*bug/i,
  /typo|拼写错误/
];

/**
 * 检查是否需要门禁
 */
function needsGate(tool, toolInput, conversationHistory) {
  // 非实现工具不需要门禁
  if (!IMPLEMENTATION_TOOLS.includes(tool)) {
    return false;
  }

  // 检查对话历史是否在设计阶段
  const inDesignPhase = conversationHistory.some(m => {
    const content = m.content || '';
    return DESIGN_PATTERNS.some(p => p.test(content));
  });

  if (inDesignPhase) {
    return false;
  }

  // 检查是否是 quick-fix
  const isQuickFix = conversationHistory.some(m => {
    const content = m.content || '';
    return QUICK_FIX_PATTERNS.some(p => p.test(content));
  });

  if (isQuickFix) {
    return false;
  }

  // 检查工具输入是否包含实现意图
  const inputStr = JSON.stringify(toolInput);
  const hasImplementationIntent = IMPLEMENTATION_PATTERNS.some(p => p.test(inputStr));

  return hasImplementationIntent;
}

/**
 * 检查设计批准状态
 */
function checkApprovalStatus() {
  if (!fs.existsSync(DESIGN_APPROVED_FILE)) {
    return { approved: false, reason: '批准文件不存在' };
  }

  try {
    const content = fs.readFileSync(DESIGN_APPROVED_FILE, 'utf-8');
    const approval = JSON.parse(content);

    if (approval.status !== 'approved') {
      return { approved: false, reason: '设计未批准' };
    }

    // 检查是否过期（24小时）
    const expiresAt = new Date(approval.expires_at || approval.timestamp);
    const hoursSinceApproval = (Date.now() - expiresAt.getTime()) / 3600000;

    if (hoursSinceApproval > 24) {
      return { approved: false, reason: '批准已过期（超过24小时）' };
    }

    return { approved: true, approval };
  } catch (e) {
    return { approved: false, reason: `批准文件读取失败: ${e.message}` };
  }
}

/**
 * 检查设计文档是否存在
 */
function checkDesignDocExists(conversationHistory) {
  // 检查对话中是否提到设计文档路径
  for (const msg of conversationHistory) {
    const content = msg.content || '';
    const match = content.match(DESIGN_DOC_PATTERN);
    if (match) {
      const docPath = match[0];
      if (fs.existsSync(docPath)) {
        return { exists: true, path: docPath };
      }
    }
  }

  // 检查最近的设计文档
  const plansDir = 'docs/plans';
  if (fs.existsSync(plansDir)) {
    const files = fs.readdirSync(plansDir)
      .filter(f => /^\d{4}-\d{2}-\d{2}-.+-design\.md$/.test(f))
      .sort()
      .reverse();

    if (files.length > 0) {
      const latestDoc = path.join(plansDir, files[0]);
      if (fs.existsSync(latestDoc)) {
        return { exists: true, path: latestDoc };
      }
    }
  }

  return { exists: false, path: null };
}

/**
 * 检查 brainstorming 是否已完成
 */
function checkBrainstormingComplete(conversationHistory) {
  // 检查对话中是否有设计讨论的迹象
  const hasDesignDiscussion = conversationHistory.some(m => {
    const content = m.content || '';
    return /设计|方案|approach|trade[- ]?off|recommend/i.test(content);
  });

  const hasMultipleMessages = conversationHistory.length >= 3;

  return hasDesignDiscussion && hasMultipleMessages;
}

/**
 * 获取门禁状态
 */
function getGateStatus(conversationHistory) {
  const designDoc = checkDesignDocExists(conversationHistory);
  const approval = checkApprovalStatus();
  const brainstorming = checkBrainstormingComplete(conversationHistory);

  return {
    brainstorming,
    designDoc: designDoc.exists,
    designDocPath: designDoc.path,
    userApproved: approval.approved,
    inDesignPhase: conversationHistory.some(m => {
      const content = m.content || '';
      return DESIGN_PATTERNS.some(p => p.test(content));
    })
  };
}

/**
 * 生成错误消息
 */
function generateErrorMessage(gateStatus) {
  const lines = [
    '[HARD-GATE] 设计门禁未通过',
    '',
    '检测到：您在设计被批准前尝试执行实现操作。',
    '',
    '当前状态：',
    `  - brainstorming: ${gateStatus.brainstorming ? '✓ 完成' : '✗ 未开始/未充分'}`,
    `  - 设计文档: ${gateStatus.designDoc ? `✓ 已写 (${gateStatus.designDocPath})` : '✗ 不存在'}`,
    `  - 用户批准: ${gateStatus.userApproved ? '✓ 已批准' : '✗ 未批准'}`,
    '',
    '下一步：',
    '1. 完成 brainstorming（如果未开始）',
    '2. 编写设计文档到 docs/plans/',
    '3. 提交给用户审查并获得批准',
    '4. 创建 .claude/.design-approved 文件',
    '',
    '当前设计阶段请使用 brainstorming skill。'
  ];

  return lines.join('\n');
}

/**
 * 主检查函数
 */
function checkGate(input) {
  const { tool, toolInput, conversationHistory = [], intent } = input;

  // 如果是 quick-fix 或用户明确授权，跳过门禁
  const isQuickFix = conversationHistory.some(m => {
    const content = m.content || '';
    return QUICK_FIX_PATTERNS.some(p => p.test(content));
  });

  if (isQuickFix || intent === 'quick-fix') {
    return {
      pass: true,
      message: null,
      exemption: 'quick-fix'
    };
  }

  // 如果在设计阶段，跳过门禁
  const inDesignPhase = conversationHistory.some(m => {
    const content = m.content || '';
    return DESIGN_PATTERNS.some(p => p.test(content));
  });

  if (inDesignPhase) {
    return {
      pass: true,
      message: null,
      exemption: 'design-phase'
    };
  }

  // 如果不需要门禁
  if (!needsGate(tool, toolInput, conversationHistory)) {
    return {
      pass: true,
      message: null
    };
  }

  // 检查门禁状态
  const gateStatus = getGateStatus(conversationHistory);

  // 检查是否有有效批准
  if (gateStatus.userApproved && gateStatus.designDoc) {
    return {
      pass: true,
      message: null,
      gateStatus
    };
  }

  // 门禁未通过
  return {
    pass: false,
    message: generateErrorMessage(gateStatus),
    gateStatus
  };
}

/**
 * 创建批准文件
 */
function createApprovalFile(designPath, scope = {}) {
  const timestamp = new Date().toISOString();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const approval = {
    status: 'approved',
    timestamp,
    approved_by: 'user',
    design_path: designPath,
    expires_at: expiresAt,
    scope
  };

  // 确保目录存在
  const dir = path.dirname(DESIGN_APPROVED_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(DESIGN_APPROVED_FILE, JSON.stringify(approval, null, 2));

  return approval;
}

/**
 * 清除批准文件
 */
function clearApproval() {
  if (fs.existsSync(DESIGN_APPROVED_FILE)) {
    fs.unlinkSync(DESIGN_APPROVED_FILE);
    return true;
  }
  return false;
}

// CLI 入口
if (require.main === module) {
  const input = process.argv[2];

  if (!input) {
    console.error('Usage: node check-gate.js <input_json>');
    process.exit(1);
  }

  try {
    const parsed = JSON.parse(input);
    const result = checkGate(parsed);
    console.log(JSON.stringify(result, null, 2));

    if (!result.pass) {
      process.exit(1);
    }
  } catch (e) {
    console.error(`Error: ${e.message}`);
    process.exit(1);
  }
}

module.exports = {
  checkGate,
  createApprovalFile,
  clearApproval,
  getGateStatus,
  checkDesignDocExists,
  checkApprovalStatus
};