# Vue 安全规则

## XSS 防护
- 避免使用 v-html，必须使用时先消毒（DOMPurify）
- 用户输入必须转义
- 避免在模板中直接拼接 HTML

## 依赖安全
- 定期运行 npm audit
- 锁定依赖版本（package-lock.json）
- 避免使用不维护的 Vue 插件

## API 安全
- 敏感操作使用 POST/PUT/DELETE
- CSRF Token 必须携带
- API Key 不暴露在前端代码
- 使用环境变量管理配置

## 认证授权
- Token 存储在 httpOnly cookie 或 localStorage（配合加密）
- 路由守卫检查权限
- 敏感操作二次确认
- 登出时清除所有认证信息

## 数据验证
- 表单验证使用 VeeValidate 或 FormKit
- 前端验证仅作为辅助，后端必须验证
- 文件上传验证类型和大小
- 避免直接拼接 SQL 或命令
