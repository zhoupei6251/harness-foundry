# instinct-import

导入 instinct 文件到系统。

## 用法

```bash
node scripts/instinct-cli.js import <file> [--scope=project|global]
```

## 参数

- `file`: 要导入的 YAML 文件路径
- `--scope`: 导入目标（默认 project）

## 示例

```bash
# 导入到项目作用域
node scripts/instinct-cli.js import ./my-instinct.yaml

# 导入到全局作用域
node scripts/instinct-cli.js import ./shared-instinct.yaml --scope=global
```

## 文件格式

导入文件必须符合 instinct YAML 格式：

```yaml
---
id: prefer-early-return
trigger: "when writing conditional logic"
confidence: 0.7
domain: "code-style"
scope: project
source: session
project_id: "harness-foundry"
created: 2026-06-26
last_used: 2026-06-26
usage_count: 3
---

# Prefer Early Return

描述内容...
```

## 注意事项

- 如果 instinct id 已存在，导入将失败
- 导入前会验证 YAML 格式
- scope 字段会被自动修正为导入目标
