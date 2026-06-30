# Java 编码模式

## 核心原则
- 优先使用不可变对象（final + record）
- 避免 null，使用 Optional 或 @Nullable
- 优先组合而非继承
- 异常处理：要么处理，要么上抛，禁止吞异常

## Spring Boot 模式
- Controller 只做参数校验和路由，业务逻辑在 Service
- 使用 @Transactional 管理事务，避免在 Controller 层开启
- 异步任务使用 @Async + CompletableFuture，注意事务传播
- 配置类使用 @ConfigurationProperties，避免 @Value 散落

## 并发模式
- 优先使用 ConcurrentHashMap、AtomicInteger 等并发集合
- 分布式锁使用 Redisson，避免自己实现
- 线程池使用 ThreadPoolExecutor，禁止 Executors.newFixedThreadPool
- 虚拟线程场景避免 synchronized，改用 ReentrantLock

## 数据访问
- MyBatis 使用 #{param}，禁止 ${param} 防 SQL 注入
- 分页使用 PageHelper 或游标分页，避免深分页 LIMIT offset
- 批量操作使用 batch insert/update，避免循环单条
- 事务内避免 RPC 调用，防止长事务

## 代码组织
- 包结构：controller / service / repository / model / config / util
- Service 类不超过 500 行，超过则拆分
- 工具类使用静态方法，禁止实例化（private constructor）
- 常量使用 enum 或 static final，禁止魔法值
