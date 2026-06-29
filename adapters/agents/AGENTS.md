---
name: harness-foundry
description: "Harness Foundry 统一入口：所有平台共用的行为准则 R1-R8 + 禁止清单 + 操作手册。"
tags: [Rules, Runbook, Memory]
---

# AGENTS.md — Harness Foundry 统一入口

> 一个文件，所有平台。Cursor / Trae / Claude Code / Codex / MimoCode 共用的唯一真相源。

## 规范优先级

1. **本文件** — 行为准则（所有平台强制）
2. `harness-foundry/core/intent-routing.md` — 意图路由 + 阶段门禁（所有平台强制）
3. `harness-foundry/core/NEVER.md` — 禁止清单（所有平台强制）
4. 平台入口规则（按当前平台自动选一个加载）：
   - Cursor: `harness-foundry/adapters/cursor/.cursor/rules/ENTRY.mdc`
   - Trae: `harness-foundry/adapters/trae/.trae/rules/ENTRY.md`
   - Claude Code: `harness-foundry/adapters/claude/.claude/rules/ENTRY.md`
   - Codex: 本文件直接作为 `AGENTS.md`
   - MimoCode: `harness-foundry/adapters/mimocode/bindings.md`

## 每任务必做

1. 首句输出 `「Route: <code|novel|news>」` 或 `「Route: 小改动，直接处理」`
2. 按意图路由表判定加载（不要会话开始预读所有文件）
3. 对用户用**中文**回复
4. 所有文件写入用 `Write` / `Edit` 工具——**禁止** shell 写文本文件

---

## 行为准则（Rules）

### R1. 先读后写

没读过的代码不要改。没见过的模式不要发明。

- 改 Controller → 先读本项目的参考 Controller
- 加 Service → 先读同类 Service，对齐事务边界和异常处理
- 写测试 → 先读已有测试，用同样的框架和断言风格
- 参考范例在 `harness-foundry/references/README.md`

### R2. 保持简单

最少的代码解决问题。不写没要的东西。

- 不写没要求的功能
- 不只为一次用就建抽象层
- 不写"以后可能会用"的配置
- 写了 200 行能压到 50 行，就重写

### R3. 精准修改

只碰要改的。改了哪就清理哪。

- 不"顺带优化"旁边的代码、注释、格式
- 匹配已有风格，哪怕你觉得你的写法更好
- 删掉你的改动产生的无用 import / 变量 / 函数
- 每行改动都能追溯到任务目标

### R4. 目标驱动

先定怎么算通过，再写代码。循环迭代直到验证通过。

- "加校验" → 先写无效输入测试，再让测试通过
- "修 bug" → 先写复现测试，再修代码
- 多步骤任务 → 每步带验证检查点

### R5. 工具优先

用工具做事，别用 shell 绕路。**禁止 shell 写文本文件。**

- 读文件 → `Read`（不 `cat`）
- 搜索内容 → `Grep`（不 `grep`）
- 写文件 → `Write` / `Edit`（不 `echo >` / `Set-Content`）
- 找文件 → `Glob`（不 `find` / `ls -R`）
- Shell 仅用于：测试、lint、构建、git、只读查询

### R6. 禁止静默失败

出错了就报出来。不要吞异常，不要退化成"差不多就行"。

- catch 了异常 → 要么处理，要么转译后往上抛。**禁止空 catch**
- 没找到文件 → 报错。不要假设它"可能在别的地方"
- 测试没过 → 说实话。不要改测试让它过
- 外部 API 超时 → 记录。不要假装调用成功

### R7. 冲突显式化

发现矛盾立刻说出来。不要让不确定性积累到最后。

- plan 说改 A，实际需改 B → 说出来，不要自己悄悄改
- 两个需求互相矛盾 → 列出来问
- 现有代码和 plan 对不上 → 报告
- 自己的实现和前人冲突 → 标记出来，不要覆盖

### R8. 不要过度设计

第二次出现相同模式时才抽象。先 naive 正确，再重构。

- 1 个策略 → 直接写。不要建抽象类
- 2 个策略 → 可以抽接口。不要建工厂
- 3 个以上 → 策略模式 + 工厂。不要建 DSL
- 问自己："一个资深工程师看了会说'过度设计了'吗？"

---

## 标签体系（Token 节流）

所有文件按 `tags: [Rules|Runbook|Memory|Standard|Never]` 分类。

- **Rules** → 会话开始必读（声明式行为准则）
- **Runbook** → 触发时才读（过程式指南）
- **Memory** → 按需读（经验积累）
- **Standard** → 角色/技能按需读（规范）
- **Never** → 所有任务必读（禁止项）

**加载策略：** 不要每次全读所有文件。按当前意图只读需要的。

## 操作手册（Runbooks）

| 触发词 | 看什么 | 做什么 |
|--------|--------|--------|
| 设计/方案/怎么搞/架构 | `harness-foundry/core/intent-routing.md` § design | brainstorming → 写 spec → 暂停等确认 |
| 计划/拆分/WBS | `harness-foundry/core/intent-routing.md` § plan | writing-plans → 写 plan → 暂停等确认 |
| OK/开始/执行/做吧 | `harness-foundry/core/intent-routing.md` § implement | 拆 WU → 并行派兵 |
| 修 bug/报错/改一下 | Leader 直做 或 debugger | 排查修复 |
| 审查/code review | `harness-foundry/agents/reviewer.md` | 五轴审查 |
| 测试/单测/补测试 | `harness-foundry/agents/test-engineer.md` | 先写测试再实现 |
| commit/merge/push/MR | git-xywh skill | git-xywh 工作流 |
| 搜/查/调研 | WebSearch → WebFetch | 信息收集 |
| 后端开发 | Read `.cursor/rules/Backend-Develop-Rule.mdc` 或对应 adapter 的后端规范 | Java 后端通用规范 |
| 多 WU/写到第N个 | `harness-foundry/core/orchestration/dispatcher-workflow.md` | 拆 WU → 并行派兵 |

---

## 7 角色体系

| 角色 | 定义位置 | 用途 |
|------|---------|------|
| coder | `harness-foundry/agents/coder.md` | 代码实现 |
| implementer | `harness-foundry/agents/implementer.md` | 轻量执行（文档/配置） |
| reviewer | `harness-foundry/agents/reviewer.md` | 代码审查 |
| test-engineer | `harness-foundry/agents/test-engineer.md` | 测试/E2E |
| explorer | `harness-foundry/agents/explorer.md` | 只读探索 |
| debugger | `harness-foundry/agents/debugger.md` | 缺陷调查 |
| web-investigator | `harness-foundry/agents/web-investigator.md` | 调研取证 |

---

## 禁止项（所有平台全局）

| 禁止 | 说明 |
|------|------|
| shell 写文本文件 | `Set-Content`、`Out-File`、`echo >`、`cat >`、Python/Node 一行写文件 |
| 空 catch | 异常要么处理，要么转译后上抛 |
| Controller 写业务 | Controller 只做参数校验+路由 |
| 循环 SQL | foreach 里发 SQL → N+1 |
| 静默吞数据 | JSON 反序列化失败不报错 |
| 事务外缓存 | 缓存更新必须在事务确认提交后 |
| 自动 push | 永远不自动 git push |
| 实现=审查 | 实现者和审查者必须不同 Agent 实例 |
| 未读就改 | 没读过的文件不输出代码 |
| 过度抽象 | 一次调用不建工厂/策略/DSL |

---

## 各平台配置文件映射

| 平台 | 配置文件 | 格式 |
|------|---------|------|
| **Claude Code** | `harness-foundry/adapters/claude/.claude/rules/ENTRY.md` | Markdown |
| **Cursor** | `harness-foundry/adapters/cursor/.cursor/rules/ENTRY.mdc` | Markdown + YAML frontmatter |
| **Trae** | `harness-foundry/adapters/trae/.trae/rules/ENTRY.md` | Markdown |
| **Codex** | `AGENTS.md` (直接读取) | Markdown |
| **MimoCode** | `harness-foundry/adapters/mimocode/bindings.md` | Markdown |

## Bootstrap

```bash
bash harness-foundry/scripts/bootstrap.sh          # 投影所有适配器
bash harness-foundry/scripts/bootstrap.sh --target trae     # 仅 Trae
bash harness-foundry/scripts/bootstrap.sh --target cursor   # 仅 Cursor
bash harness-foundry/scripts/bootstrap.sh --target claude   # 仅 Claude Code
```
