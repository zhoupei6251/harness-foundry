# Intelligence Layer 故障排除

> 本文只描述 Harness Foundry 当前的 Intelligence Layer：战略层使用 Understand-Anything，战术层使用 `codebase-memory` skill。

## 1. codebase-memory skill 不可用

**症状**：无法调用 `search_graph`、`trace_path` 或 `index_repository`。

**排查**：

1. 确认当前 AI 会话已加载 `codebase-memory` skill。
2. 用 `index_status` 检查项目是否已登记。
3. 如果项目未建立索引，调用 `index_repository`。
4. 如果仍然失败，记录工具返回的完整错误，不要改用全库 grep 假装完成结构分析。

## 2. 建立索引失败

**建议顺序**：

```text
list_projects
  ↓
index_status
  ↓
index_repository(project_path="<project>")
```

检查项目路径、语言支持和当前会话的工具权限。大型项目可以先索引核心目录，再逐步扩大范围。

## 3. 符号搜索没有结果

**可能原因**：

- 索引尚未建立或已经过期；
- 符号名不准确；
- 目标代码被排除在索引范围之外；
- 使用了错误的节点类型或查询条件。

**建议**：

```text
index_status
search_graph(name_pattern=".*UserService.*")
get_code_snippet(qualified_name="<exact-qualified-name>")
```

先用 `search_graph` 找到精确名称，再用 `get_code_snippet` 读取源码，不要猜路径。

## 4. 调用链或影响分析不完整

按以下顺序查询：

```text
trace_path(function_name="<function>", direction="both", depth=3)
detect_changes()
query_graph(<按需使用 Cypher 查询>)
```

- `direction="inbound"`：查找调用方；
- `direction="outbound"`：查找被调用方；
- `direction="both"`：同时查看两侧关系。

如果结构关系仍不完整，应先确认索引状态和项目是否已重新索引。

## 5. Understand-Anything 与 codebase-memory 如何分工

| 需求 | 工具 |
|------|------|
| 了解陌生项目整体架构 | `/understand-project`、`/understand-chat` |
| 询问架构和模块关系 | Understand-Anything |
| 查找函数、类和调用链 | `search_graph`、`trace_path` |
| 评估本次代码变更影响 | `detect_changes` |
| 读取精确源码 | `get_code_snippet` |

战略层和战术层可以组合使用：先用 Understand-Anything 建立整体理解，再用 codebase-memory 做精确定位。

## 6. 性能问题

不要设置旧版索引工具的环境变量，也不要手动删除未知的索引目录。优先采用以下方式：

1. 缩小 `index_repository` 的项目路径或文件范围；
2. 排除测试、构建产物和生成目录；
3. 分模块建立索引；
4. 检查 `index_status` 返回的项目规模和耗时；
5. 将工具返回的错误和耗时记录到 Harness 审计日志。

## 7. 诊断信息

出现问题时请收集：

- 调用的工具名称和完整参数；
- 工具返回的完整错误；
- `index_status` 结果；
- 项目语言和路径；
- 是否在索引后修改过大量文件。

codebase-memory 的索引由技能运行时管理，Harness 不假设或操作某个固定的本地数据库目录。

## 8. 检查 Harness 配置

```bash
bash scripts/validate-intelligence-layer.sh
bash tests/L3-intelligence/test-agent-integration.sh
bash tests/L3-intelligence/test-mcp-config.sh
```

如果脚本失败，优先修复配置或 Skill 引用，不要通过跳过测试来隐藏问题。