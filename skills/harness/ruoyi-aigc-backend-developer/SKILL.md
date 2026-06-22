---
name: ruoyi-aigc-backend-developer
description: 【项目级别】为RuoYi-Vue-Plus AIGC平台提供后端开发指导，包括代码规范、模板生成、最佳实践。在开发该项目后端功能时调用。
---

# AIGC平台项目规则

## 技术栈
- 后端：JDK21、SpringBoot 3.5.6、RuoYi-Vue-Plus 5.5.0
- 存储：MySQL 8.0、Redis
- 部署：Docker、Ubuntu 22.04

## 项目结构
- ruoyi-admin：主应用入口
- ruoyi-common：公共模块
- ruoyi-modules：业务模块（核心为 ruoyi-aigc）

## 核心规范
1. 分层架构：controller→service→domain→mapper
2. 命名规范：XxxController、IXxxService、XxxServiceImpl
3. 优先使用 Hutool、框架原生工具
4. 后端 IO 使用 JDK21 虚拟线程池
5. 关键的地方需要加上日志输出
6.一定要在对应的地方写好注释信息

## 开发准则
- 业务优先，拒绝过度设计
- 可读优先，拒绝过度封装
- 规范优先，遵循阿里 Java+RuoYi 规范
- 落地优先，代码可直接编译运行

## 绝对禁令
- Controller 写业务逻辑
- 循环 SQL
- 空 catch 块
- 泄露敏感信息