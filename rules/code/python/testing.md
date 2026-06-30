# Python 测试规则

## 单元测试
- 使用 pytest 作为测试框架
- 测试文件命名：test_*.py 或 *_test.py
- 测试函数命名：test_<功能>_<场景>
- 使用 fixture 管理测试数据

## 测试结构
```python
def test_user_creation_with_valid_data():
    # Arrange
    user_data = {"name": "Alice", "age": 30}
    
    # Act
    user = User(**user_data)
    
    # Assert
    assert user.name == "Alice"
    assert user.age == 30
```

## Mock 和 Stub
- 使用 unittest.mock 或 pytest-mock
- Mock 外部服务（数据库、API、文件系统）
- 使用 patch 装饰器隔离依赖
- 避免过度 Mock，保持测试真实性

## 覆盖率
- 使用 pytest-cov 生成覆盖率报告
- 核心业务逻辑覆盖率 ≥ 80%
- 工具函数覆盖率 ≥ 90%
- 排除测试代码和配置代码

## 集成测试
- 使用 pytest-django 或 pytest-flask
- 数据库测试使用事务回滚或 SQLite 内存库
- API 测试使用 TestClient
- 避免依赖外部服务，使用 docker-compose

## 参数化测试
```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input, expected):
    assert double(input) == expected
```
