# 登录功能设计

## 概述

设计一个基于 React 的用户登录页面，包含邮箱密码验证和登录状态管理。

## 方案对比

### 方案 A：传统 Session + Cookie
- 优点：成熟稳定，浏览器原生支持
- 缺点：需要服务端存储 session

### 方案 B：JWT + LocalStorage
- 优点：无状态，服务端可扩展
- 缺点：需要手动处理 token 刷新

**推荐：方案 B**，更适合前后端分离架构。

## 组件设计

### LoginForm
- 状态：email, password, error, loading
- 行为：表单验证 → 调用 API → 存储 token

### RememberMeToggle
- 决定 token 有效期

## 数据流

1. 用户输入邮箱密码
2. 前端验证格式
3. 调用 `/api/login`
4. 存储 JWT
5. 跳转首页

## 错误处理

- 格式错误：实时校验提示
- 网络错误：重试按钮
- 认证失败：显示错误信息

## 测试

- 单元测试：组件渲染、表单验证
- E2E：完整登录流程
