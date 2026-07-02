# 连续学习协议

> 会话结束时自动从交互中提取模式、陷阱和经验，持续优化 agent 行为。

## 触发时机

| 触发方式 | 时机 | 说明 |
|---------|------|------|
| **Stop Hook** | 会话结束 | 自动触发，非阻塞（exit 0） |
| **用户触发** | 用户说"记住这个"、"学习这个" | 主动提取 |
| **手动触发** | `/learn-status`, `/learn-evolve`, `/learn-prune` | 命令行操作 |

## 学习内容类型

### 1. 调试技术（Debugging）
- 有效的 bug 定位方法
- 调试命令和工具组合
- 根因分析方法
- 断言和验证技巧

### 2. 项目模式（Project Patterns）
- 架构决策（ADR）
- 命名规范和约定
- 代码组织方式
- 配置文件结构

### 3. 工具技巧（Tool Tips）
- 高效的命令组合
- 工具使用诀窍
- 快捷键和技巧
- 脚本自动化

### 4. 错误处理（Error Handling）
- 异常捕获方式
- 错误恢复策略
- 日志最佳实践
- 容错机制

### 5. 安全实践（Security）
- 输入验证方法
- 认证授权模式
- 敏感数据处理
- 安全编码规范

## 输出位置

```
~/.claude/memory/
├── learned/                    # 学习到的技能（通用）
│   ├── debugging/
│   ├── project-patterns/
│   ├── tool-tips/
│   └── error-handling/
├── patterns/                   # 通用模式（跨项目）
└── learned.json                # 学习统计
```

## 提取格式

```yaml
---
id: <唯一ID>
type: debugging | project-pattern | tool-tip | error-handling | security
trigger: "<何时触发>"
action: "<做什么>"
confidence: <0.0-1.0>
scope: global | project
source: session-observation | user-correction | error-resolution
evidence:
  - "<证据1>"
  - "<证据2>"
created: <ISO日期>
last_seen: <ISO日期>
count: <出现次数>
---
```

## 置信度评估

| 分数 | 含义 | 行为 |
|------|------|------|
| 0.3 | 试探性 | 建议但不强制的 |
| 0.5 | 中等 | 相关时应用 |
| 0.7 | 强 | 自动批准应用 |
| 0.9 | 几乎确定 | 核心行为 |

**置信度增加条件**：
- 模式被反复观察到
- 用户没有纠正建议的行为
- 相似来源的本能一致

**置信度减少条件**：
- 用户明确纠正了该行为
- 长时间未观察到该模式
- 出现矛盾证据

## 去重规则

1. **相似度检查**
   - 标题相似度 > 80% → 跳过（不添加）
   - 内容相似度 > 60% → 合并（更新已有）

2. **时效性检查**
   - 发现日期 > 6 个月 → 降级到 archive
   - 被引用 ≥5 次 → 升级为核心规则

3. **可信度检查**
   - 仅出现一次 → 标记为"待验证"
   - 反复触发 ≥2 次 → 标记为"已验证"

## 演化机制

### 自动演化（每 30 天或积累 ≥10 条）

1. 扫描 `learned/` 目录
2. 识别重复模式（≥3 次）
3. 提取为核心规则
4. 标记旧条目为"已演化"

### 手动演化（用户触发 /evolve）

1. 显示当前积累统计
2. 识别可演化模式
3. 建议升级到：
   - 核心规则（rules/）
   - 新的 Skill
   - 新的 Agent

## 与现有系统集成

### 与 hooks.json 集成

```json
{
  "Stop": [{
    "matcher": "",
    "filePattern": "",
    "hooks": [{
      "type": "command",
      "command": "node hooks/continuous-learning/evaluate-session.js",
      "description": "会话学习评估"
    }]
  }]
}
```

### 与 ECC Instinct 对比

| 特性 | 本协议 | ECC Instinct |
|------|--------|--------------|
| 存储位置 | `~/.claude/memory/` | `${XDG_DATA_HOME}/ecc-homunculus/` |
| 作用域 | global / project | global / project |
| 演化目标 | rules / skills | skills / commands / agents |
| 置信度 | 0.3-0.9 | 0.3-0.9 |
| 触发方式 | Stop hook | PreToolUse + PostToolUse |

## 禁止事项

- ❌ 提取不完整内容（缺少关键字段）
- ❌ 存储重复内容（必须先去重）
- ❌ 不验证就保存
- ❌ 保存敏感信息到学习文件
- ❌ 过期内容不归档（>6 个月）
- ❌ Hook 中阻塞（必须 exit 0）

## 相关文件

- `core/memory/continuous-learning/extractor.js` - 会话提取器
- `hooks/continuous-learning/evaluate-session.js` - Stop Hook 实现
- `skills/continuous-learning/SKILL.md` - Skill 定义
