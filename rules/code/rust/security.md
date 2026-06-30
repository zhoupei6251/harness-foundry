# Rust 安全规则

## 内存安全
- 禁止使用 unsafe 块，除非绝对必要
- unsafe 块必须有详细注释说明安全性保证
- 优先使用安全抽象（Vec、String、Box）
- 避免裸指针（*const T、*mut T）

## 输入验证
- 使用 serde 进行反序列化时验证数据
- 所有外部输入必须检查边界
- 字符串处理使用 UTF-8 安全方法
- 文件路径使用 std::path::Path，防止路径遍历

## 依赖安全
- 使用 cargo audit 扫描依赖漏洞
- 锁定依赖版本（Cargo.lock 必须提交）
- 避免使用不维护的 crate
- 定期运行 cargo update 更新依赖

## 并发安全
- 使用 Arc<Mutex<T>> 确保线程安全
- 避免使用 Rc<RefCell<T>> 在多线程环境
- 使用 Send 和 Sync trait 标记
- 避免死锁，使用 try_lock 或超时机制

## 敏感信息
- 环境变量存储密钥（使用 dotenv）
- 禁止在代码中硬编码密码
- 日志脱敏处理
- 使用 zeroize 清理敏感内存
