# Go Hooks

## PreToolUse

### 编译检查
- 触发：Edit/Write *.go
- 行为：运行 `go build ./...`
- 目的：确保编译通过

### 代码格式化
- 触发：Edit/Write *.go
- 行为：运行 `gofmt -w` 或 `goimports -w`
- 目的：统一代码风格

## PostToolUse

### Lint 检查
- 触发：Edit/Write *.go
- 行为：运行 `golangci-lint run`
- 目的：检查代码质量问题

### 单元测试
- 触发：Edit/Write *_test.go
- 行为：运行 `go test ./...`
- 目的：确保测试通过

## Stop

### 安全检查
- 触发：每次响应结束
- 行为：运行 `gosec ./...`
- 目的：扫描安全漏洞

### 依赖检查
- 触发：修改 go.mod 后
- 行为：运行 `go mod verify`
- 目的：验证依赖完整性
