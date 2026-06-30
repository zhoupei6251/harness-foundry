# Go 编码模式

## 核心原则
- 遵循 Go 官方风格指南（Effective Go）
- 错误处理：显式检查，禁止忽略 error
- 优先使用组合而非继承
- 接口越小越好（1-3 个方法）

## 项目结构
```
project/
├── cmd/
│   └── app/
│       └── main.go
├── internal/
│   ├── handler/
│   ├── service/
│   ├── repository/
│   └── model/
├── pkg/          # 可导出的公共库
├── api/          # API 定义（proto/openapi）
└── go.mod
```

## 错误处理
```go
// 正确
result, err := doSomething()
if err != nil {
    return fmt.Errorf("do something failed: %w", err)
}

// 错误：忽略 error
result, _ := doSomething()
```

## 并发模式
- 使用 goroutine + channel 进行并发编程
- 使用 sync.WaitGroup 等待多个 goroutine
- 使用 context 控制超时和取消
- 避免 goroutine 泄漏，确保退出通道

## 接口设计
```go
// 小接口原则
type Reader interface {
    Read(p []byte) (n int, err error)
}

// 避免大接口
type UserService interface {
    GetUser(id int) (*User, error)
    CreateUser(user *User) error
    UpdateUser(user *User) error
    DeleteUser(id int) error
}
```

## 性能优化
- 避免在循环中分配内存
- 使用 sync.Pool 复用对象
- 字符串拼接使用 strings.Builder
- 预分配 slice 容量：make([]T, 0, cap)
