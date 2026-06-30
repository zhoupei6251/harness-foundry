# Harness Foundry — 完整知识图谱

> 生成时间: 2026-06-30
> 数据来源: CodeGraph + 源码分析

---

## 1. 整体架构图

```mermaid
flowchart TB
    subgraph IDE["🖥️ IDE 层（用户交互）"]
        Trae["Trae IDE"]
        ClaudeCode["Claude Code"]
        Cursor["Cursor"]
        Codex["Codex"]
        MimoCode["MimoCode"]
    end

    subgraph Adapters["📦 Adapters 层（平台适配）"]
        TraeAdapter["trae/ .trae/"]
        ClaudeAdapter["claude/ .claude/"]
        CursorAdapter["cursor/ .cursor/"]
        CodexAdapter["codex/"]
        MimoAdapter["mimocode/"]
    end

    subgraph Core["⚙️ Core 层（真相源）"]
        Routing["intent-routing.md<br/>路由入口"]
        Never["NEVER.md<br/>硬性禁止规则"]
        Principles["principles.md<br/>10条核心原则"]
        Orchestration["orchestration/<br/>编排系统"]
        Security["security/<br/>安全机制"]
        Capabilities["capabilities/<br/>能力注册"]
        Intelligence["intelligence/<br/>智能层"]
        Memory["memory/<br/>记忆系统"]
    end

    subgraph Execution["🚀 执行层"]
        Skills["📚 Skills (336)"]
        Agents["🤖 Agents (33)"]
        Hooks["🪝 Hooks<br/>Pre/Post Tool"]
        Traps["⚠️ Traps Archive<br/>(241规则)"]
    end

    subgraph IntelligenceLayer["🧠 Intelligence Layer"]
        CodeGraph["CodeGraph<br/>战术层"]
        UAPlugin["Understand-Anything<br/>战略层"]
    end

    IDE --> Adapters
    Adapters -->|"bootstrap.sh"| Core
    Core --> Orchestration
    Core --> Security
    Orchestration --> Skills
    Orchestration --> Agents
    Hooks --> Traps
    Intelligence --> IntelligenceLayer
    IntelligenceLayer --> CodeGraph
    IntelligenceLayer --> UAPlugin
```

---

## 2. 路由决策流程

```mermaid
flowchart TD
    Start["用户请求"] --> ReadRouting["读取 core/intent-routing.md"]
    ReadRouting --> Match["匹配路由规则"]
    
    Match --> Code{域?}
    Code -->|code| CodePath["✅ Code 域"]
    Code -->|novel| NovelPath["✅ Novel 域"]
    Code -->|news| NewsPath["✅ News 域"]
    Code -->|multiple| Ask["❓ 多域匹配<br/>询问用户确认"]
    Code -->|low| Clarify["❓ 置信度<0.7<br/>询问澄清"]
    
    CodePath --> StageGate["Stage Gate 流程"]
    NovelPath --> StageGate
    NewsPath --> StageGate
    
    StageGate --> Plan["1. Plan → 写规格"]
    Plan --> Pause["⏸️ PAUSE 等待确认"]
    Pause --> Approve{用户确认?}
    Approve -->|No| Revise["修改规格"]
    Revise --> Plan
    Approve -->|Yes| Implement["2. Implement"]
    
    Implement --> Split["拆分为 WU"]
    Split --> Dispatch["并行派发 ≤5 Worker"]
    Dispatch --> Workers["Worker 执行"]
    Workers --> Verify["3. Verify"]
    Verify --> Report["整合汇报"]
```

---

## 3. Code 域编排

```mermaid
flowchart LR
    subgraph Leaders["Leader"]
        LC["leader-code"]
    end
    
    subgraph Primary["Primary Agents (必加载)"]
        Coder["coder"]
        Debugger["debugger"]
        CodeReviewer["code-reviewer"]
        Reviewer["reviewer"]
        TestEngineer["test-engineer"]
    end
    
    subgraph Secondary["Secondary Agents (按需)"]
        Architect["architect"]
        Implementer["implementer"]
        Planner["planner"]
        CodeSimplifier["code-simplifier"]
        TechWriter["tech-writer"]
        Explorer["explorer"]
        WebInvestigator["web-investigator"]
    end
    
    subgraph PrimarySkills["Primary Skills"]
        Brainstorming["brainstorming"]
        ArchPatterns["architecture-patterns"]
        TDD["test-driven-development"]
        CodeReview["code-review"]
        Refactor["refactor-safely"]
    end
    
    subgraph IntelligenceSkills["Intelligence Skills"]
        UnderstandProject["understand-project"]
        AnalyzeArchitecture["analyze-architecture"]
        QueryGraph["query-knowledge-graph"]
        IndexProject["index-project"]
        QuerySymbol["query-symbol"]
        GetCallers["get-callers"]
        AnalyzeImpact["analyze-impact"]
    end
    
    Leaders --> Primary
    Leaders --> Secondary
    Primary --> PrimarySkills
    Primary --> IntelligenceSkills
```

---

## 4. Novel 域编排

```mermaid
flowchart LR
    subgraph Leaders["Leader"]
        LN["leader-novel"]
    end
    
    subgraph Primary["Primary Agents"]
        NovelWriter["novel-writer"]
        NovelPlanner["novel-planner"]
        NovelReviewer["novel-reviewer"]
        Humanizer["humanizer"]
    end
    
    subgraph Secondary["Secondary Agents"]
        SharedResearcher["shared-researcher"]
        Editor["editor"]
        MemoryKeeper["memory-keeper"]
    end
    
    subgraph PrimarySkills["Primary Skills"]
        Brainstorming["brainstorming"]
        JunliNovel["junli-ai-novel"]
        NovelOrchestrator["novel-orchestrator"]
        NovelEvaluator["novel-evaluator"]
        HumanizerZH["humanizer-zh"]
    end
    
    subgraph SecondarySkills["Secondary Skills"]
        NovelAIWash["novel-ai-wash"]
        WebTools["web-tools-guide"]
        Summarize["summarize"]
        MemoryManager["memory-manager"]
    end
    
    Leaders --> Primary
    Leaders --> Secondary
    Primary --> PrimarySkills
    PrimarySkills --> SecondarySkills
```

---

## 5. News 域编排

```mermaid
flowchart LR
    subgraph Leaders["Leader"]
        LNews["leader-news"]
    end
    
    subgraph Primary["Primary Agents"]
        NewsWriter["news-writer"]
        FactChecker["fact-checker"]
    end
    
    subgraph Secondary["Secondary Agents"]
        NewsEditor["news-editor"]
        SharedResearcher["shared-researcher"]
    end
    
    subgraph Skills["Skills"]
        NewsGenerator["news-generator"]
        FactCheck["fact-check"]
        NewsPolish["news-polish"]
        HotTopic["hot-topic-research"]
        WebTools["web-tools-guide"]
        Summarize["summarize"]
        HumanizerZH["humanizer-zh"]
    end
    
    Leaders --> Primary
    Leaders --> Secondary
    Primary --> Skills
```

---

## 6. Skill 系统架构

```mermaid
flowchart TB
    subgraph SkillLayer["Skill 分层"]
        direction TB
        Core["⭐ Core Layer<br/>(80个, 稳定)"]
        Peripheral["🔸 Peripheral Layer<br/>(120个, 辅助)"]
        Archived["📦 Archived Layer<br/>(归档)"]
    end
    
    subgraph LoadingPriority["加载优先级（按 IDE）"]
        direction TB
        CursorP1[".cursor/skills/"]
        CursorP2["~/.cursor/skills/"]
        CursorP3["~/.agents/skills/"]
        
        ClaudeP1[".claude/skills/"]
        ClaudeP2["~/.claude/skills/"]
        
        TraeP1[".trae/skills/"]
        TraeP2["~/.trae/skills/"]
    end
    
    subgraph Routing["Skill 路由"]
        Auto["wu_skills: auto"]
        AgentRole["agent_role"]
        WuType["wu_type"]
        Overrides["overrides / exclude"]
        Exclude["全局禁止列表"]
    end
    
    Core --> Auto
    Peripheral --> Auto
    AgentRole --> Routing
    WuType --> Routing
    Overrides --> Routing
    Exclude -.->|"剔除"| Routing
```

---

## 7. Hooks 与安全机制

```mermaid
flowchart TB
    subgraph PreHooks["PreToolUse Hooks（并行，任一失败阻止）"]
        P1["Prompt Injection 检测"]
        P2["SQL Injection 检测"]
        P3["Command Injection 检测"]
        P4["Prompt Override 检测"]
        P5["Path Traversal 检测"]
    end
    
    subgraph PostHooks["PostToolUse Hooks（顺序，阻塞）"]
        O1["Secret/Key 泄露检测"]
        O2["Canary Token 检测"]
        O3["NEVER.md 违规检测"]
        O4["AI Writing 标记检测"]
        O5["Syntax 验证"]
    end
    
    subgraph Config["配置"]
        HookConfig["hooks/hooks.json"]
        GuardrailConfig["hooks/guardrails/<br/>guardrail-config.json"]
        CanaryTokens["canary-rotate.sh"]
    end
    
    subgraph Audit["审计"]
        AuditLog[".ai-runtime-artifacts/<br/>guardrail-audit.jsonl"]
    end
    
    PreHooks --> PostHooks
    Config --> PreHooks
    Config --> PostHooks
    PostHooks --> AuditLog
```

---

## 8. Dispatcher 工作流

```mermaid
flowchart TB
    subgraph Trigger["触发条件"]
        T1["Plan 包含 ≥2 WU"]
        T2["用户说「开始实现」"]
        T3["用户说「并行实现」"]
        T4["连续执行: ≥2章节/小说/功能"]
    end
    
    subgraph Execution["执行"]
        Split["拆分 WU"]
        Parallel["≤5 Worker 并行"]
        
        subgraph Workers["Worker 类型"]
            W1["harness-coder"]
            W2["harness-debugger"]
            W3["harness-reviewer"]
            W4["harness-test-engineer"]
            W5["harness-explorer"]
        end
        
        subgraph Context["执行上下文"]
            Worktree["worktree (隔离)"]
            Local["local"]
        end
    end
    
    subgraph Isolation["隔离级别"]
        Full["full: 代码 WU"]
        Partial["partial: reviewer/explorer"]
        None["none: novel/news"]
    end
    
    Trigger --> Split
    Split --> Parallel
    Parallel --> Workers
    Workers --> Context
    Context --> Isolation
```

---

## 9. 目录结构

```mermaid
graph TD
    Root["harness-foundry/"]
    
    Root --> Core["core/"]
    Root --> Adapters["adapters/"]
    Root --> Skills["skills/"]
    Root --> Agents["agents/"]
    Root --> Hooks["hooks/"]
    Root --> Scripts["scripts/"]
    Root --> Tests["tests/"]
    
    Core --> Routing["intent-routing.md"]
    Core --> Never["NEVER.md"]
    Core --> Principles["principles.md"]
    Core --> Orchestration["orchestration/"]
    Core --> Security["security/"]
    Core --> Capabilities["capabilities/"]
    Core --> Intelligence["intelligence/"]
    
    Orchestration --> Domain["domain-config.yaml"]
    Orchestration --> Dispatcher["dispatcher-workflow.md"]
    Orchestration --> SkillPref["skill-preferences.md"]
    
    Intelligence --> Strategic["strategic/"]
    Intelligence --> Tactical["tactical/"]
    
    Strategic --> Understand["understand-project.md"]
    Strategic --> Analyze["analyze-architecture.md"]
    
    Tactical --> CodeGraph["CodeGraph (MCP)"]
    
    Adapters --> Trae["trae/ .trae/"]
    Adapters --> Claude["claude/ .claude/"]
    Adapters --> Cursor["cursor/ .cursor/"]
    Adapters --> Codex["codex/"]
    Adapters --> Mimo["mimocode/"]
```

---

## 10. Skill 分类（部分）

### 10.1 Code 域 Skills

| 类别 | Skills |
|------|--------|
| **架构设计** | architecture-patterns, architecture-decision-records, api-design, backend-patterns |
| **代码审查** | code-review, requesting-code-review, receiving-code-review, simplify |
| **测试** | test-driven-development, playwright, agent-browser, tdd-workflow |
| **调试** | systematic-debugging |
| **重构** | refactor-safely |
| **安全** | security-auditor, security-review |
| **前端** | ui-ux-pro-max, frontend-design, superdesign |
| **Agent** | agentic-engineering, agent-self-evaluation, agent-sort |
| **工具链** | using-git-worktrees, docker-patterns, kubernetes-patterns |

### 10.2 Novel 域 Skills

| 类别 | Skills |
|------|--------|
| **创作** | junli-ai-novel, novel-orchestrator, novel-generator (archived third-party), inkos |
| **润色** | humanizer-zh, novel-ai-wash, humanizer |
| **发布** | fanqie-novel-auto-publish, web-novel-publishing-readiness-and-quality-check-skill |
| **短剧** | novel-to-drama-script, story-cog |

### 10.3 通用 Skills

| 类别 | Skills |
|------|--------|
| **规划** | brainstorming, writing-plans, planning-with-files, project-planner |
| **执行** | executing-plans, subagent-driven-development, dispatching-parallel-agents |
| **研究** | deep-research, web-tools-guide, summarize |
| **文档** | backend-doc-generator, technical-writer |
| **媒体** | edge-tts, video-editing |

---

## 11. Intelligence Layer

```mermaid
flowchart LR
    subgraph Intelligence["🧠 Intelligence Layer"]
        direction TB
        
        Strategic["🎯 战略层"]
        Tactical["⚡ 战术层"]
        
        Strategic --> UA["Understand-Anything"]
        Tactical --> CG["CodeGraph"]
        
        UA --> Dashboard["📊 可视化仪表盘"]
        UA --> Tours["🧭 引导学习"]
        UA --> Chat["💬 自然语言问答"]
        
        CG --> Query["🔍 符号查询"]
        CG --> Callers["📞 调用链分析"]
        CG --> Impact["💥 影响评估"]
        CG --> Index["📇 索引管理"]
    end
    
    subgraph Usage["使用场景"]
        NewProject["新项目接手"]
        BugFix["Bug 定位"]
        Refactor["重构评估"]
        Review["代码审查"]
    end
    
    Strategic --> Usage
    Tactical --> Usage
```

---

## 12. 文件统计

| 类别 | 数量 |
|------|------|
| Skills | 336 |
| Agents | 33 |
| Core 文件 | 15+ |
| Adapters | 6 |
| Hooks | 多层 |
| Traps | 241 |
| 总文件 | ~5,294 |

---

## 13. 关键配置文件

| 文件 | 作用 |
|------|------|
| `core/intent-routing.md` | 路由入口，必读 |
| `core/NEVER.md` | 硬性禁止规则 |
| `core/orchestration/domain-config.yaml` | 域配置 |
| `core/orchestration/skill-preferences.md` | Skill 路由表 |
| `core/orchestration/dispatcher-workflow.md` | 派发流程 |
| `hooks/hooks.json` | Hook 配置 |
| `skills/_layer.yaml` | Skill 分层配置 |

---

## 14. 命令速查

```bash
# Bootstrap IDE 适配器
bash scripts/bootstrap.sh --target all --dry-run  # 预览
bash scripts/bootstrap.sh --target all            # 执行

# 同步 Skills
bash scripts/sync-skills.sh --target all --dry-run  # 预览
bash scripts/sync-skills.sh --target all            # 执行

# CI 验证
bash scripts/verify.sh

# 单独测试
bash tests/L1-static/validate-agent-format.sh
bash tests/L1-static/validate-skill-meta.sh
bash tests/L2-integration/validate-routing.sh

# Intelligence Layer
cd reference_github/Understand-Anything
pnpm --filter @understand-anything/core build
pnpm --filter @understand-anything/dashboard build
```

---

*此图谱基于源码分析生成，如有更新请运行 `/understand --full` 重新生成*
