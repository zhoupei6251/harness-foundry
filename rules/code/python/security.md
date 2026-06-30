# Python 安全规则

## 输入验证
- 使用 pydantic 进行数据验证和序列化
- 所有外部输入必须验证类型和范围
- SQL 查询使用参数化查询，禁止字符串拼接
- 文件路径使用 os.path 或 pathlib，防止路径遍历

## 依赖安全
- 使用 requirements.txt 或 pyproject.toml 锁定版本
- 定期运行 safety check 扫描漏洞
- 避免使用已废弃的库（如 Python 2 兼容库）
- 生产环境使用虚拟环境（venv 或 conda）

## 敏感信息
- 环境变量存储密钥（使用 python-dotenv）
- 禁止在代码中硬编码密码、API Key
- 日志中脱敏处理（使用 logging.Filter）
- 配置文件使用 .env，加入 .gitignore

## Web 安全
- Flask/Django 启用 CSRF 保护
- 使用 HTTPS，禁止 HTTP 明文传输
- 密码哈希使用 bcrypt 或 argon2-cffi
- Session 设置安全标志（secure, httponly, samesite）

## 代码执行
- 避免使用 eval()、exec()
- 反序列化使用安全的 JSON，避免 pickle
- 子进程调用使用 subprocess.run，避免 shell=True
- 动态导入使用 importlib，验证模块来源
