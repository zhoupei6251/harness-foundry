# instinct-status

查看 instinct 系统统计信息。

## 用法

```bash
node scripts/instinct-cli.js stats
```

## 输出信息

- 项目 instinct 数量
- 全局 instinct 数量
- 按 domain 分类统计
- 置信度分布（0.0-0.3 / 0.3-0.6 / 0.6-0.8 / 0.8-1.0）

## 示例

```bash
$ node scripts/instinct-cli.js stats

=== Instinct 统计 ===

项目 instinct: 15
全局 instinct: 8
总计: 23

按 domain 统计:
  code-style: 10
  architecture: 5
  testing: 4
  workflow: 4

置信度分布:
  0.0-0.3: 2
  0.3-0.6: 8
  0.6-0.8: 9
  0.8-1.0: 4
```

## 用途

- 了解 instinct 库整体状况
- 识别需要清理的低置信度 instinct
- 评估哪些 domain 积累较多经验
- 判断是否达到进化条件（某 domain ≥5 个且平均置信度 ≥0.7）
