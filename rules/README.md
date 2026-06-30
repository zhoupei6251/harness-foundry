# 规则库（rules/）

按技术栈和领域分类的编码规范、安全规则、测试策略和自动化 Hooks。

## 目录结构

```
rules/
├── code/              # 代码域
│   ├── java/          # Java + Spring Boot
│   │   ├── patterns.md    # 编码模式
│   │   ├── security.md    # 安全规则
│   │   ├── testing.md     # 测试策略
│   │   └── hooks.md       # 自动化 Hooks
│   ├── python/        # Python
│   ├── go/            # Go
│   ├── rust/          # Rust
│   ├── vue/           # Vue 3
│   ├── react/         # React
│   └── typescript/    # TypeScript
├── novel/             # 小说域
│   ├── patterns.md    # 创作模式
│   ├── security.md    # 内容安全
│   ├── testing.md     # 审稿规则
│   └── hooks.md       # 自动化 Hooks
├── news/              # 新闻域
│   ├── patterns.md    # 采编模式
│   ├── security.md    # 合规规则
│   ├── testing.md     # 审稿规则
│   └── hooks.md       # 自动化 Hooks
└── common/            # 通用规则
    ├── patterns.md    # 通用编码规范
    ├── security.md    # 通用安全规则
    ├── testing.md     # 通用测试规则
    └── hooks.md       # 通用 Hooks 设计
```

## 使用方式

| 场景 | 加载规则 |
|------|----------|
| 写 Java 代码 | `rules/code/java/` + `rules/common/` |
| 写 Python 代码 | `rules/code/python/` + `rules/common/` |
| 写 Vue 组件 | `rules/code/vue/` + `rules/code/typescript/` + `rules/common/` |
| 写 React 组件 | `rules/code/react/` + `rules/code/typescript/` + `rules/common/` |
| 写小说 | `rules/novel/` |
| 写新闻 | `rules/news/` |

## 规则类型

| 文件 | 内容 |
|------|------|
| `patterns.md` | 编码模式、最佳实践、代码组织 |
| `security.md` | 安全规则、输入验证、依赖安全 |
| `testing.md` | 测试策略、覆盖率、Mock 使用 |
| `hooks.md` | 自动化 Hooks（PreToolUse/PostToolUse/Stop） |

## 设计原则

- **按需加载**：只加载当前技术栈的规则，避免上下文污染
- **分层结构**：通用规则 + 技术栈特定规则
- **可执行性**：每条规则都可验证，避免模糊表述
- **持续更新**：根据项目实践不断优化
