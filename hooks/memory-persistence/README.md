# 记忆持久化钩子

> 自动管理项目记忆，确保跨会话连续性
> 
> **状态**：钩子脚本尚未实现，当前 hooks.json 使用内嵌 prompt 类型钩子。以下为设计文档，待后续实施。

## 钩子脚本（规划中）

| 脚本 | 触发时机 | 用途 |
|------|---------|------|
| `session-start.sh` | 会话开始 | 加载项目记忆摘要 |
| `session-end.sh` | 会话结束 | 保存本次会话经验 |
| `extract-patterns.sh` | 手动触发 | 从日志提取模式 |

## 配置方式

在 `hooks/hooks.json` 中添加：

```json
{
  "PreToolUse": [
    {
      "matcher": "Read|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "bash hooks/memory-persistence/session-start.sh"
        }
      ]
    }
  ],
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "bash hooks/memory-persistence/session-end.sh"
        }
      ]
    }
  ]
}
```

## 工作流程

### 会话开始
1. 检查 `MEMORY.md` 是否存在
2. 显示记忆摘要（前 20 行）
3. 提示记忆文件年龄
4. 建议运行 `/evolve` 刷新（如果超过 7 天）

### 会话结束
1. 提取本次会话关键信息
2. 保存到会话日志（`.ai-runtime-artifacts/execution-logs/`）
3. 追加到 `MEMORY.md`
4. 创建备份文件（`MEMORY.md.bak`）
5. 提示后续操作

### 模式提取
1. 扫描所有会话日志
2. 统计高频关键词
3. 提取错误模式
4. 建议更新 `references/learned-patterns.md`

## 最佳实践

### 记忆文件结构

```markdown
# 项目记忆

## 项目概述
- 项目名称：xxx
- 技术栈：xxx
- 核心功能：xxx

## 关键决策
- [日期] 决策内容
- [日期] 决策内容

## 已完成任务
- [日期] 任务描述

## 待办事项
- [ ] 任务 1
- [ ] 任务 2

## 经验教训
- [日期] 学到的经验
```

### 定期维护

1. **每周运行 `/evolve`**：自动提取会话经验
2. **每月清理记忆**：删除过时信息
3. **每季度归档**：将旧记忆移到 `MEMORY-ARCHIVE.md`

### 注意事项

- 不要在记忆中存储敏感信息（密码、API Key）
- 保持记忆简洁，避免冗余
- 重要决策必须记录日期
- 定期备份 `MEMORY.md`
