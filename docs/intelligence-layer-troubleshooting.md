# Intelligence Layer 故障排查手册

> Intelligence Layer 常见问题与解决方案

## 目录

- [CodeGraph 问题](#codegraph-问题)
- [Understand-Anything 问题](#understand-anything-问题)
- [MCP 连接问题](#mcp-连接问题)
- [性能问题](#性能问题)

---

## CodeGraph 问题

### 问题 1: 索引失败

**症状**: `codegraph index` 执行失败

**可能原因**:
1. Node.js 版本不兼容
2. 缺少依赖
3. 项目路径不存在

**排查步骤**:

```bash
# 1. 检查 Node.js 版本
node -v
# 需要 >= 20.0.0

# 2. 检查 codegraph 安装
codegraph --version

# 3. 检查项目路径
ls -la /path/to/project

# 4. 查看错误日志
codegraph index --verbose 2>&1 | tee debug.log
```

**解决方案**:

```bash
# 重新安装 CodeGraph
npm uninstall -g @colbymchenry/codegraph
npm install -g @colbymchenry/codegraph

# 清理并重建索引
rm -rf .codegraph
codegraph init
codegraph index
```

---

### 问题 2: 符号搜索无结果

**症状**: `/query-symbol` 返回空结果

**可能原因**:
1. 索引未建立
2. 符号名称拼写错误
3. 搜索范围不对

**排查步骤**:

```bash
# 1. 检查索引状态
codegraph status

# 2. 尝试模糊搜索
codegraph query "User*" --fuzzy

# 3. 查看索引内容
ls -la .codegraph/
```

**解决方案**:

```bash
# 重建索引
rm -rf .codegraph
codegraph init
codegraph index

# 搜索特定类型
codegraph search --types class,interface "ClassName"
```

---

### 问题 3: 查询超时

**症状**: 符号查询响应时间过长

**可能原因**:
1. 索引文件过大
2. 磁盘 I/O 慢
3. 并发查询过多

**排查步骤**:

```bash
# 1. 检查索引大小
du -sh .codegraph/

# 2. 检查数据库完整性
sqlite3 .codegraph/graph.db "PRAGMA integrity_check;"

# 3. 监控资源使用
htop  # 或 Task Manager
```

**解决方案**:

```bash
# 清理缓存
codegraph clean

# 优化数据库
sqlite3 .codegraph/graph.db "VACUUM;"

# 限制查询范围
codegraph query "symbol" --limit 100
```

---

## Understand-Anything 问题

### 问题 1: MCP 服务器无法启动

**症状**: Understand-Anything MCP 连接失败

**可能原因**:
1. Node.js 版本不兼容
2. 依赖未安装
3. 端口被占用

**排查步骤**:

```bash
# 1. 检查 Node.js 版本
node -v
# 需要 >= 22.0.0

# 2. 检查依赖
cd reference_github/Understand-Anything
npm install

# 3. 检查端口
netstat -an | grep 3000
```

**解决方案**:

```bash
# 完整安装
cd reference_github/Understand-Anything
rm -rf node_modules package-lock.json
npm install

# 构建插件
pnpm --filter @understand-anything/core build
pnpm --filter @understand-anything/skill build

# 启动 MCP 服务器
node dist/index.js --port 3000
```

---

### 问题 2: 项目分析失败

**症状**: `/understand-project` 执行失败

**可能原因**:
1. 项目路径不存在
2. 权限不足
3. 文件系统问题

**排查步骤**:

```bash
# 1. 验证路径
ls -la /path/to/project

# 2. 检查权限
test -r /path/to/project && test -x /path/to/project

# 3. 检查磁盘空间
df -h /path/to/project
```

**解决方案**:

```bash
# 使用绝对路径
codegraph understand --path /absolute/path/to/project

# 限制扫描范围
codegraph understand --path /project --max-depth 5
```

---

## MCP 连接问题

### 问题 1: MCP 服务器无法连接

**症状**: MCP 调用返回连接错误

**可能原因**:
1. MCP 服务器未启动
2. 端口配置错误
3. 防火墙阻止

**排查步骤**:

```bash
# 1. 检查 MCP 服务器状态
curl http://localhost:3000/health

# 2. 检查配置
cat mcp-config/CodeGraph.json
cat mcp-config/Understand-Anything.json

# 3. 检查端口监听
netstat -an | grep 3000
```

**解决方案**:

```bash
# 重启 MCP 服务器
pkill -f codegraph
codegraph serve --mcp &

# 检查防火墙
# Windows
netsh firewall show state

# Linux/Mac
sudo iptables -L -n
```

---

### 问题 2: MCP 超时

**症状**: MCP 调用超时

**可能原因**:
1. 处理时间过长
2. 网络延迟
3. 服务器负载高

**排查步骤**:

```bash
# 1. 检查服务器资源
top
df -h

# 2. 查看超时日志
tail -f logs/mcp.log
```

**解决方案**:

```bash
# 减少并发
echo '{"maxConcurrency": 1}' > mcp-config/local.json

# 增加超时时间
codegraph serve --mcp --timeout 120
```

---

## 性能问题

### 问题 1: 索引很慢

**症状**: `codegraph index` 执行时间过长

**可能原因**:
1. 项目文件太多
2. 硬件性能不足
3. 并行度设置不当

**排查步骤**:

```bash
# 1. 统计文件数
find . -type f \( -name "*.java" -o -name "*.ts" \) | wc -l

# 2. 检查 CPU 使用
top -bn1 | grep "Cpu(s)"

# 3. 检查内存
free -h
```

**解决方案**:

```bash
# 限制索引范围
codegraph index --paths src/main/java

# 减少并行度
CODEGRAPH_PARALLELISM=2 codegraph index

# 跳过测试文件
codegraph index --exclude '**/*Test.java'
```

---

### 问题 2: 内存不足

**症状**: 索引过程 OOM

**可能原因**:
1. 项目过大
2. 内存设置不足
3. 内存泄漏

**排查步骤**:

```bash
# 1. 检查可用内存
free -h

# 2. 监控内存使用
watch -n 1 free -h
```

**解决方案**:

```bash
# 设置内存限制
NODE_OPTIONS="--max-old-space-size=4096" codegraph index

# 分批索引
codegraph index --paths src/module1
codegraph index --paths src/module2

# 清理后重试
rm -rf .codegraph
codegraph init
codegraph index
```

---

## 日志位置

```
# CodeGraph
./.codegraph/logs/
./.codegraph/debug.log

# Understand-Anything
./.understand-anything/logs/
./node_modules/.cache/
```

## 获取帮助

如果以上方案无法解决问题：

1. 收集诊断信息:
```bash
codegraph debug --output diagnostic.json
```

2. 查看完整日志:
```bash
tail -n 1000 .codegraph/debug.log > debug_output.txt
```

3. 提交 Issue:
   - CodeGraph: https://github.com/colbymchenry/codegraph/issues
   - Understand-Anything: https://github.com/Understand-Anything/understand-anything/issues
