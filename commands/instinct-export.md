# instinct-export

导出 instinct 到文件。

## 用法

```bash
node scripts/instinct-cli.js export <id> <output-file>
```

## 参数

- `id`: 要导出的 instinct ID
- `output-file`: 输出文件路径

## 示例

```bash
# 导出单个 instinct
node scripts/instinct-cli.js export prefer-early-return ./exported.yaml

# 导出所有项目 instinct
node scripts/instinct-cli.js export-all ./all-instincts.yaml --scope=project
```

## 用途

- 备份重要 instinct
- 跨项目共享 instinct
- 版本控制 instinct 库
- 迁移到其他系统

## 注意事项

- 导出的文件包含完整的 YAML frontmatter 和 body
- 可直接用于 import 命令
- 敏感信息请手动清理后再分享
