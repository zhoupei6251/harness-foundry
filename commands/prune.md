# prune

清理低置信度 instinct，释放存储空间。

## 用法

```bash
node scripts/instinct-cli.js prune [--threshold=0.3]
```

## 参数

- `--threshold`: 置信度阈值，低于此值的 instinct 将被删除（默认 0.3）

## 示例

```bash
# 删除置信度 < 0.3 的 instinct
node scripts/instinct-cli.js prune

# 删除置信度 < 0.5 的 instinct
node scripts/instinct-cli.js prune --threshold=0.5
```

## 工作原理

1. 扫描所有 instinct（项目 + 全局）
2. 筛选置信度 < threshold 的 instinct
3. 删除符合条件的文件
4. 输出清理统计

## 注意事项

- 此操作不可逆，删除前请确认
- 建议定期执行，保持 instinct 库质量
- 置信度衰减规则：30 天未使用 -0.05
