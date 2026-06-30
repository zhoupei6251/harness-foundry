# Go 安全规则

## 输入验证
- 使用 go-playground/validator 进行结构体验证
- HTTP 请求参数必须验证类型和范围
- SQL 查询使用参数化，禁止字符串拼接
- 文件上传验证 MIME 类型和大小

## SQL 注入防护
```go
// 正确：使用参数化查询
db.Query("SELECT * FROM users WHERE id = ?", id)

// 错误：字符串拼接
db.Query(fmt.Sprintf("SELECT * FROM users WHERE id = %d", id))
```

## 权限控制
- 使用中间件进行身份认证（JWT/OAuth）
- 敏感接口必须检查权限
- 数据访问必须验证用户归属
- 使用 RBAC 或 ABAC 模型

## 敏感信息
- 环境变量存储密钥（使用 godotenv）
- 禁止在代码中硬编码密码
- 日志脱敏处理
- 使用 gosec 扫描安全问题

## 依赖安全
- 使用 go mod tidy 管理依赖
- 定期运行 govulncheck 扫描漏洞
- 锁定依赖版本（go.sum）
- 避免使用不维护的第三方库
