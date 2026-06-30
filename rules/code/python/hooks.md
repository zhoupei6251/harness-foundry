# Python Hooks

## PreToolUse

### 语法检查
- 触发：Edit/Write *.py
- 行为：运行 `ruff check` 或 `flake8`
- 目的：确保语法正确，符合 PEP 8

### 类型检查
- 触发：Edit/Write *.py
- 行为：运行 `mypy` 或 `pyright`
- 目的：验证类型注解正确性

## PostToolUse

### 格式化
- 触发：Edit/Write *.py
- 行为：运行 `black` 或 `ruff format`
- 目的：统一代码风格

### 单元测试
- 触发：Edit/Write test_*.py
- 行为：运行 `pytest path/to/test_file.py`
- 目的：确保测试通过

## Stop

### 代码质量
- 触发：每次响应结束
- 行为：运行 `pylint` 或 `ruff check --select ALL`
- 目的：检查代码复杂度、重复代码

### 安全检查
- 触发：修改依赖文件后
- 行为：运行 `safety check` 或 `bandit`
- 目的：扫描依赖漏洞和代码安全问题
