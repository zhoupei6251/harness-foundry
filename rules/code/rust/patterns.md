# Rust 编码模式

## 核心原则
- 所有权和借用规则必须严格遵守
- 优先使用不可变绑定（let 而非 let mut）
- 错误处理使用 Result 和 Option，禁止 unwrap
- 类型系统要充分利用（enum、trait）

## 项目结构
```
project/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   ├── models/
│   ├── services/
│   └── utils/
├── tests/
├── Cargo.toml
└── Cargo.lock
```

## 错误处理
```rust
// 正确：使用 ? 操作符
fn read_file(path: &str) -> Result<String, io::Error> {
    let mut file = File::open(path)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}

// 错误：使用 unwrap
let file = File::open(path).unwrap();
```

## 并发模式
- 使用 Arc<Mutex<T>> 进行线程间共享
- 使用 channel（mpsc）进行线程间通信
- 使用 tokio 进行异步编程
- 避免数据竞争，使用 Send 和 Sync trait

## 生命周期
- 明确标注生命周期注解
- 避免过长的生命周期
- 使用 'static 生命周期时要谨慎
- 借用检查器报错时，优先调整数据结构而非添加 clone

## 性能优化
- 避免不必要的 clone
- 使用迭代器而非循环
- 预分配集合容量：Vec::with_capacity
- 使用 &str 而非 String 作为函数参数
