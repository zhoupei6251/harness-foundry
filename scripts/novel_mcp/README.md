# novel-mcp-server 配置

## Claude Code 配置

在 `settings.json` 中添加：

```json
{
  "mcpServers": {
    "novel": {
      "command": "python",
      "args": ["-m", "scripts.novel_mcp.server"],
      "cwd": "D:\\work\\zhoupei\\harness-foundry"
    }
  }
}
```

## Cursor 配置

在 `.cursor/mcp.json` 中添加：

```json
{
  "mcpServers": {
    "novel": {
      "command": "python",
      "args": ["-m", "scripts.novel_mcp.server"],
      "cwd": "D:\\work\\zhoupei\\harness-foundry"
    }
  }
}
```

## 使用方式

配置后，在 Claude Code 或 Cursor 中可以直接调用：

```
/novel-write 第3章
/novel-review 第2章
/novel-status
```

## 可用工具

| 工具名 | 说明 |
|--------|------|
| list_books | 列出所有书籍 |
| get_chapters | 获取章节列表 |
| get_memory | 获取记忆文件 |
| update_memory | 更新记忆 |
| score_chapter | 机械评分 |
| get_metrics | 获取写作指标 |
| check_foreshadowing | 检查伏笔 |

## 测试

```bash
# 列出工具
echo '{"method":"tools/list"}' | python -m scripts.novel_mcp.server

# 调用工具
echo '{"method":"tools/call","params":{"name":"list_books"}}' | python -m scripts.novel_mcp.server
```
