# Python 编码模式

## 核心原则
- 遵循 PEP 8 风格指南
- 使用类型注解（Type Hints）提高可读性
- 优先使用不可变数据结构（tuple, frozenset, NamedTuple）
- 避免全局变量，使用依赖注入

## 项目结构
```
project/
├── src/
│   └── package_name/
│       ├── __init__.py
│       ├── main.py
│       ├── models/
│       ├── services/
│       └── utils/
├── tests/
├── requirements.txt
└── pyproject.toml
```

## 函数设计
- 函数长度不超过 50 行
- 参数不超过 5 个，超过则使用 dataclass 或 dict
- 使用 *args 和 **kwargs 时要谨慎，优先明确参数
- 返回值类型必须注解

## 类设计
- 使用 dataclass 或 pydantic 定义数据模型
- 避免过深的继承层次（最多 3 层）
- 使用 @property 封装属性访问
- 魔术方法（__str__, __repr__）必须实现

## 异常处理
- 捕获具体异常，避免 bare except
- 使用自定义异常类继承 Exception
- 异常信息要包含上下文（使用 f-string）
- 资源清理使用 with 语句或 try-finally

## 异步编程
- 使用 asyncio 处理 I/O 密集型任务
- 避免在 async 函数中调用阻塞操作
- 使用 async/await 语法，避免回调地狱
- 并发请求使用 asyncio.gather
