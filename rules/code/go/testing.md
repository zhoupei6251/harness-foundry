# Go 测试规则

## 单元测试
- 使用标准库 testing 包
- 测试文件命名：*_test.go
- 测试函数命名：TestFunctionName_Scenario
- 表驱动测试（Table-Driven Tests）

## 测试结构
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

## Mock 和 Stub
- 使用 github.com/golang/mock（gomock）
- 使用 github.com/stretchr/testify/mock
- 接口注入依赖，便于 Mock
- 避免过度 Mock

## 覆盖率
- 使用 go test -cover 生成覆盖率
- 核心业务逻辑覆盖率 ≥ 80%
- 使用 coveralls 或 codecov 跟踪

## 基准测试
```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(1, 2)
    }
}
```

## 集成测试
- 使用 testcontainers-go 管理测试数据库
- 使用 httptest 测试 HTTP 处理器
- 避免依赖外部服务
