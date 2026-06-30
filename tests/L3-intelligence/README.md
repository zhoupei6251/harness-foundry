# Intelligence Layer - Level 3 Integration Tests

> 端到端集成测试

## 测试目录结构

```
tests/L3-intelligence/
├── test-skill-routing.sh          # Skill 路由测试
├── test-agent-integration.sh      # Agent 集成测试
├── test-mcp-config.sh            # MCP 配置测试
└── README.md                     # 本文件
```

## 测试用例

### 1. Skill 路由测试 (test-skill-routing.sh)

测试 Intelligence Skills 在各阶段的路由配置。

### 2. Agent 集成测试 (test-agent-integration.sh)

测试 Agent 是否正确加载 Intelligence Layer 指南。

### 3. MCP 配置测试 (test-mcp-config.sh)

测试 MCP 配置文件格式和内容。

## 运行测试

```bash
# 运行所有 L3 测试
bash tests/L3-intelligence/run-all.sh

# 运行单个测试
bash tests/L3-intelligence/test-skill-routing.sh
```
