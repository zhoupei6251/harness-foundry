# Rust 测试规则

## 单元测试
- 使用 #[cfg(test)] 和 #[test] 属性
- 测试模块放在同一文件的底部
- 测试函数命名：test_<功能>_<场景>
- 使用 assert_eq!、assert_ne!、assert!

## 测试结构
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_positive_numbers() {
        assert_eq!(add(1, 2), 3);
    }

    #[test]
    fn test_add_negative_numbers() {
        assert_eq!(add(-1, -2), -3);
    }
}
```

## 集成测试
- 测试文件放在 tests/ 目录
- 测试公共 API，而非内部实现
- 使用 tempdir 创建临时文件
- 避免测试间依赖

## Mock 和 Stub
- 使用 mockall 或 mockingbird
- 使用 trait 抽象依赖，便于 Mock
- 避免过度 Mock

## 属性测试
- 使用 proptest 进行属性测试
- 测试不变量（invariants）
- 生成随机输入验证行为

## 基准测试
```rust
#[bench]
fn bench_add(b: &mut Bencher) {
    b.iter(|| add(1, 2));
}
```

## 覆盖率
- 使用 tarpaulin 生成覆盖率报告
- 核心逻辑覆盖率 ≥ 80%
