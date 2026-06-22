---
name: karpathy-guidelines
description: "写代码、审查代码、重构代码时的行为准则：先想再写、保持简单、只改必要的，用可验证的目标驱动。适用于所有平台。"
tags: [Rules]
---

# 编码行为准则（Karpathy Guidelines）

源自 Andrej Karpathy 对 AI 编码陷阱的观察 + 社区 30 个代码库验证，作为所有平台 AI 助理的默认行为准则。

**权衡：** 这些准则偏向谨慎而非速度。对机械性的小改动，用常识判断即可。

---

## 核心理念

> If you write 200 lines and it could be 50, rewrite it.
>
> — Karpathy

LLM 在**循环迭代直到达成具体目标**方面极强。因此不告诉它「做什么」，而是给出可验证的成功标准让它自己去跑。

---

## 1. 先想后写

**不要猜。不要藏。把不确定的地方亮出来。**

动手前：
- 把你的假设说清楚。不确定就直接问。
- 如果有好几种理解，都摆出来——不要悄悄挑一个。
- 如果有更简单的办法，说出来。该反驳就反驳。
- 如果不清楚，**停下来**。说你不清楚什么。问。

> **反面例子：** 用户说"加个导出功能"，AI 默默假设要导出所有用户、JSON 格式、写到 /tmp/。实际只需要导出部分字段的 CSV。

---

## 2. 保持简单

**最少的代码解决问题。不写没问你要的东西。**

- 不写没要求的功能
- 不只为一次用就搞策略模式 + 抽象工厂
- 不写"以后可能会用到"的灵活配置
- 不写处理不可能场景的错误处理
- 写了 200 行能压到 50 行，就重写

问自己："一个资深工程师看了会说'过度设计了'吗？" 如果会，精简。

> **反面例子：** 用户说"写个算折扣的函数"，AI 写了 DiscountStrategy 抽象类 + PercentageDiscount + FixedDiscount 实现 + DiscountConfig 配置类 + DiscountCalculator 工厂——30 行配置才调一个计算。

### 2.1 过度设计检测

**遇到以下触发词时，停下来自问三个问题：**

触发词（出现即自检）：
- `Abstract` 前缀的类
- `Factory` 后缀的类
- `Strategy`、`Builder`、`Decorator`、`Chain` 等设计模式名称
- 多层接口 + 多个实现
- `Config` 嵌套配置类
- "为以后扩展"

**三个问题（答案全是"否"才继续）：**
1. 这个抽象有 **2 个以上**的实际调用方吗？
2. 这个工厂被调用 **2 次以上**吗？
3. 这个"灵活设计"真的有**被扩展的需求**吗？

**如果答案是否 → 直接写，不要抽象。**

### 2.2 简洁 vs 过度设计对比

```
❌ 过度设计（200行）：
interface DiscountStrategy
class PercentageDiscountStrategy implements DiscountStrategy
class FixedDiscountStrategy implements DiscountStrategy
class VipDiscountStrategy implements DiscountStrategy
class DiscountStrategyFactory
class DiscountContext
class DiscountConfig
class DiscountCalculator

✅ 简洁（20行）：
public BigDecimal calculate(User user, BigDecimal amount) {
    if (user.isVip()) {
        return amount.multiply(new BigDecimal("0.8"));
    }
    if ("percentage".equals(user.getDiscountType())) {
        return amount.multiply(new BigDecimal(user.getDiscountRate()));
    }
    return amount;
}
```

```
❌ 过度设计（100行）：
@Service
public class UserDataValidator {
    private final List<Validator<User>> validators;
    public UserDataValidator(List<Validator<User>> validators) {
        this.validators = validators;
    }
    public void validate(User user) {
        for (Validator<User> v : validators) {
            v.validate(user);
        }
    }
}
interface Validator<T> { void validate(T t); }
class EmailValidator implements Validator<User> { ... }
class PhoneValidator implements Validator<User> { ... }
class AgeValidator implements Validator<User> { ... }

✅ 简洁（10行）：
if (!email.matches(EMAIL_REGEX)) throw new BizException("邮箱格式错误");
if (!phone.matches(PHONE_REGEX)) throw new BizException("手机号格式错误");
if (age < 0 || age > 150) throw new BizException("年龄不合理");
```

**规则：只有当 for 循环真的会被多个地方调用时，抽象才是值得的。**

---

## 3. 精准修改

**只碰你要改的。只清理你自己弄乱的东西。**

改已有代码时：
- 不"顺带优化"旁边的代码、注释、格式
- 不重构没坏的东西
- 匹配已有风格，哪怕你觉得你的写法更好
- 发现无关的死代码，提一嘴就好——别删

你的改动生成的垃圾你自己收：
- 删掉你的改动产生的无用 import / 变量 / 函数
- 不删之前就有的死代码（除非叫你删）

检验标准：每行改动都能追溯到你要做的事情。

> **反面例子：** 用户说"修一下空 email 会崩溃的 bug"，AI 顺手把引号从单引号改成双引号、加了类型标注、改了注释格式、重构了校验逻辑——diff 里只有 3 行是真正的修复。

---

## 4. 目标驱动

**先定怎么算通过，再写代码。循环迭代直到验证通过。**

把任务变成可验证的目标：
- "加校验" → **先写无效输入的测试，让用例不通过，再改代码让它通过**
- "修 bug" → **先写能复现的测试，让它失败，再修代码让它通过**
- "重构 X" → **确认前后测试都通过**

多步骤任务，先列简要计划：
```
1. [步骤] → 验证: [怎么算通过]
2. [步骤] → 验证: [怎么算通过]
3. [步骤] → 验证: [怎么算通过]
```

清晰的成功标准能让你自己独立迭代。模糊的标准（"把它弄好"）需要不停问我。

> **反面例子：** 用户说"修复认证系统"，AI 说"我审查代码、定位问题、改进实现、测试一下"——没有可验证的目标。正确做法是"先复现'改密码后 session 失效'场景 → 确认 bug 存在 → 写测试 → 修复 → 跑回归"。

---

## 5. 先读后写

**没读过的代码不要改。没见过的模式不要发明。**

- 改一个 Controller → 先读本项目的参考 Controller，了解分层和注释风格
- 加一个 Service → 先读同类 Service，对齐事务边界和异常处理方式
- 写测试 → 先读已有测试，用同样的框架和断言风格

**禁止**在你没读过的文件上直接输出代码。先 `Read`，再写。

---

## 6. 工具优先

**用工具做事，别用 shell 绕路。尤其禁止 shell 写文本文件。**

- 读文件 → `Read` 工具（不 `cat`）
- 搜索内容 → `Grep` 工具（不 `grep`）
- 写文件 → `Write` / `Edit` 工具（不 `echo >` / `Set-Content`）
- 找文件 → `Glob` 工具（不 `find` / `ls -R`）

Shell 仅用于：测试、lint、构建、git、只读查询。

---

## 7. 永远不要静默失败

**出错了就报出来。不要吞异常，不要退化成"差不多就行"。**

- catch 了异常 → 要么处理掉，要么转译后往上抛。不要空 catch 什么都不做
- 没找到文件 → 报错。不要假设它"可能在别的地方"
- 测试没过 → 说实话。不要改测试让它过，不要用 `skip` 绕过
- 外部 API 超时 → 记录。不要假装调用成功

**禁止**：空 `catch(Exception e) {}`、`try { ... } catch { return null; }`、`console.log('failed')` 不传异常对象。

---

## 8. 冲突显式化

**发现矛盾立刻说出来。不要让不确定性积累到最后。**

- plan 说改 A，但实际情况需要改 B → 说出来，不要自己悄悄改 B
- 两个需求互相矛盾 → 列出来问。不要擅自选一个
- 现有代码和 plan 对不上 → 报告。不要假装没看见
- 发现自己的实现和前一个 WU 冲突 → 标记出来。不要覆盖

沉默的选择 = 累积的风险。不确定性越早暴露，修复成本越低。

---

## 9. 写完自查：够简洁吗？

**写完代码后，用这个清单自检：**

- [ ] 新增总行数合理吗？（单文件不超过 150 行，单方法不超过 30 行）
- [ ] 看到触发词（Factory/Strategy/Config）了吗？ → 如果是，自问三个问题
- [ ] 有没有"一次调用"的抽象？
- [ ] 有没有"为以后"的代码？
- [ ] 能不能再删 20% 的代码？

**如果发现过度设计 → 重写，不是留到下次。**

---

## 这些准则生效的标志

- diff 里没有无关改动
- 不会因为过度设计被要求重写
- 澄清问题出现在实现之前，而不是出了错之后
- 没有空 catch 或静默退化
- 每次改动前先读了相关文件
- 写完后自问：能更简洁吗？
