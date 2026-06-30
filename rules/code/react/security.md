# React 安全规则

## XSS 防护
- 避免使用 dangerouslySetInnerHTML
- 用户输入必须转义
- URL 参数使用 URLSearchParams
- 避免直接拼接 HTML 字符串

## 依赖安全
- 定期运行 npm audit
- 锁定依赖版本（package-lock.json）
- 避免使用不维护的 React 库
- 使用 dependabot 自动更新

## API 安全
- 敏感操作使用 POST/PUT/DELETE
- CSRF Token 必须携带
- API Key 不暴露在前端代码
- 使用环境变量管理配置

## 认证授权
- Token 存储在 httpOnly cookie
- 路由守卫检查权限
- 敏感操作二次确认
- 登出时清除所有认证信息

## 数据验证
- 表单验证使用 React Hook Form + Zod
- 前端验证仅作为辅助，后端必须验证
- 文件上传验证类型和大小
- 避免直接拼接 SQL 或命令
