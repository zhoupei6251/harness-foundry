# Rust Hooks

## PreToolUse

### 编译检查
- 触发：Edit/Write *.rs
- 行为：运行 `cargo check`
- 目的：确保编译通过，类型正确

### 代码格式化
- 触发：Edit/Write *.rs
- 行为：运行 `cargo fmt`
- 目的：统一代码风格

## PostToolUse

### Clippy Lint
- 触发：Edit/Write *.rs
- 行为：运行 `cargo clippy -- -D warnings`
- 目的：检查代码质量和惯用写法

### 单元测试
- 触发：Edit/Write 包含 #[test] 的文件
- 行为：运行 `cargo test`
- 目的：确保测试通过

## Stop

### 安全检查
- 触发：每次响应结束
- 行为：运行 `cargo audit`
- 目的：扫描依赖漏洞

### 依赖检查
- 触发：修改 Cargo.toml 后
- 行为：运行 `cargo tree`
- 目的：检查依赖树和版本冲突
