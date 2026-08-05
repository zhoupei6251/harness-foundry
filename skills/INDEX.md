# Skill 索引

> 自动生成的 Skill 索引 — 共 141 个 Skill，采用扁平目录结构。
> 最后更新：2026-08-05
> 生成方式：`bash scripts/gen-skill-index.sh`

## 按字母顺序索引

| 序号 | Skill 目录 | 说明 |
|------|-----------|------|
| 1 | `accessibility` | Design, implement, and audit inclusive digital products using WCAG 2.2 Level AA |
| 2 | `agent-browser` | Browser automation for AI agents via inference.sh. Navigate web pages, interact with elements using @e refs, take screenshots, record video. Capabilities: web scraping, form filling, clicking, typing, |
| 3 | `agent-shield` | 安全审计：扫描配置漏洞、注入风险、MCP 安全问题。保护 Harness Foundry 免受提示注入、权限过度、Hook 注入等攻击。 |
| 4 | `agentic-engineering` | Operate as an agentic engineer using eval-first execution, decomposition, and cost-aware model routing. |
| 5 | `ai-first-engineering` | Engineering operating model for teams where AI agents generate a large share of implementation output. |
| 6 | `ai-regression-testing` | Regression testing strategies for AI-assisted development. Sandbox-mode API testing without database dependencies, automated bug-check workflows, and patterns to catch AI blind spots where the same mo |
| 7 | `analyze-architecture` | 深入分析项目架构，回答架构相关问题。触发：询问设计原因、技术选型、模块职责、架构决策。 |
| 8 | `analyze-impact` | 评估代码变更的影响范围。触发：重构前、修改核心方法、批量修改前。 |
| 9 | `api-connector-builder` | Build a new API connector or provider by matching the target repo's existing integration pattern exactly. Use when adding one more integration without inventing a second architecture. |
| 10 | `api-design` | REST API design patterns including resource naming, status codes, pagination, filtering, error responses, versioning, and rate limiting for production APIs. |
| 11 | `architecture-decision-records` | Capture architectural decisions made during Claude Code sessions as structured ADRs. Auto-detects decision moments, records context, alternatives considered, and rationale. Maintains an ADR log so fut |
| 12 | `architecture-patterns` | ## WHAT |
| 13 | `article-writing` | Write articles, guides, blog posts, tutorials, newsletter issues, and other long-form content in a distinctive voice derived from supplied examples or brand guidance. Use when the user wants polished  |
| 14 | `auto-compact` | 智能上下文压缩：在最佳时机触发压缩，保留关键状态，清理冗余上下文。 |
| 15 | `auto-updater` | Automatically update Clawdbot and all installed skills once daily. Runs |
| 16 | `automation-audit-ops` | Evidence-first automation inventory and overlap audit workflow for ECC. Use when the user wants to know which jobs, hooks, connectors, MCP servers, or wrappers are live, broken, redundant, or missing  |
| 17 | `autonomous-agent-harness` | Transform Claude Code into a fully autonomous agent system with persistent memory, scheduled operations, computer use, and task queuing. Replaces standalone agent frameworks (Hermes, AutoGPT) by lever |
| 18 | `backend-doc-generator` | 生成标准后端技术文档，包含Mermaid流程图、时序图、类图、状态图。Invoke when user needs to create backend technical documentation or draw system architecture diagrams. |
| 19 | `backend-patterns` | Backend architecture patterns, API design, database optimization, and server-side best practices for Node.js, Express, and Next.js API routes. |
| 20 | `benchmark` | Use this skill to measure performance baselines, detect regressions before/after PRs, and compare stack alternatives. |
| 21 | `benchmark-methodology` | Use after competitive-platform-analysis has produced a tiered competitor set. Scores each competitor across nine weighted dimensions (positioning, voice, visual craft, offer packaging, evidence, enter |
| 22 | `benchmark-optimization-loop` | Use when the user asks to make something faster, try many variants, run recursive optimization, benchmark latency/throughput/cost, or choose the best implementation by repeated measured tests. |
| 23 | `blueprint` | Turn a one-line objective into a step-by-step construction plan for multi-session, multi-agent engineering projects. Each step has a self-contained context brief so a fresh agent can execute it cold.  |
| 24 | `brainstorming` | You MUST use this before any creative work - creating features, building |
| 25 | `brand-discovery` | Use when a brand needs to discover or articulate its identity through structured multi-session interviews. Covers purpose, positioning, audience, personality, voice, narrative, and founder-brand tensi |
| 26 | `brand-voice` | Build a source-derived writing style profile from real posts, essays, launch notes, docs, or site copy, then reuse that profile across content, outreach, and social workflows. Use when the user wants  |
| 27 | `ceo-orchestration` | CEO 角色主 Skill — 跨域协调入口，调用子 Skill 完成各项职责 |
| 28 | `ck` | Persistent per-project memory for Claude Code. Auto-loads project context on session start, tracks sessions with git activity, and writes to native memory. Commands run deterministic Node.js scripts — |
| 29 | `code-insight-stack` | 编排 codebase-memory + ripgrep + LSP 三层查询栈，按场景选择最便宜的工具组合。触发：探索陌生代码库、定位修改点、调查 bug、准备 refactor、计划实现、跨文件影响分析。 |
| 30 | `code-review` | Systematic code review patterns covering security, performance, maintainability, |
| 31 | `code-tour` | Create CodeTour `.tour` files — persona-targeted, step-by-step walkthroughs with real file and line anchors. Use for onboarding tours, architecture walkthroughs, PR tours, RCA tours, and structured \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ |
| 32 | `codebase-onboarding` | Analyze an unfamiliar codebase and generate a structured onboarding guide with architecture map, key entry points, conventions, and a starter CLAUDE.md. Use when joining a new project or setting up Cl |
| 33 | `coding-standards` | Baseline cross-project coding conventions for naming, readability, immutability, and code-quality review. Use detailed frontend or backend skills for framework-specific patterns. |
| 34 | `context-budget` | Audits Claude Code context window consumption across agents, skills, MCP servers, and rules. Identifies bloat, redundant components, and produces prioritized token-savings recommendations. |
| 35 | `continuous-agent-loop` | Patterns for continuous autonomous agent loops with quality gates, evals, and recovery controls. |
| 36 | `continuous-learning` | 持续学习系统 — Session → instinct → cluster → Skill 进化闭环。P1-3 升级：confidence |
| 37 | `cost-aware-llm-pipeline` | Cost optimization patterns for LLM API usage — model routing by task complexity, budget tracking, retry logic, and prompt caching. |
| 38 | `cost-tracking` | Track and report Claude Code token usage, spending, and budgets from the local ECC cost-tracker metrics log. Use when the user asks about costs, spending, usage, tokens, budgets, or cost breakdowns by |
| 39 | `cpp-coding-standards` | C++ coding standards based on the C++ Core Guidelines (isocpp.github.io). Use when writing, reviewing, or refactoring C++ code to enforce modern, safe, and idiomatic practices. |
| 40 | `cursor-orchestration` | Cursor 多 subagent 并行编排，等价于 omx ultrawork。在用户已批准 plan 并说「开始实现」后，通过 harness-coder（代码）、harness-implementer（轻量）、harness-test-engineer、harness-web-investigator（research）等并行派发 WU。触发词：并行实现、多 task、开始实现、cursor |
| 41 | `database-migrations` | Database migration best practices for schema changes, data migrations, rollbacks, and zero-downtime deployments across PostgreSQL, MySQL, and common ORMs (Prisma, Drizzle, Kysely, Django, TypeORM, gol |
| 42 | `deep-research` | Multi-source deep research using firecrawl and exa MCPs. Searches the |
| 43 | `deployment-patterns` | Deployment workflows, CI/CD pipeline patterns, Docker containerization, health checks, rollback strategies, and production readiness checklists for web applications. |
| 44 | `design-system` | Use this skill to generate or audit design systems, check visual consistency, and review PRs that touch styling. |
| 45 | `docker-patterns` | Docker and Docker Compose patterns for local development, container security, networking, volume strategies, and multi-service orchestration. |
| 46 | `document-review` | Use when reviewing any document (spec, design, plan) for completeness, clarity, and quality — especially environment preparation completeness. Triggers: review document, check document, audit spec, au |
| 47 | `documentation-lookup` | Use up-to-date library and framework docs via Context7 MCP instead of training data. Activates for setup questions, API references, code examples, or when the user names a framework (e.g. React, Next. |
| 48 | `dotnet-patterns` | Idiomatic C# and .NET patterns, conventions, dependency injection, async/await, and best practices for building robust, maintainable .NET applications. |
| 49 | `e2e-testing` | Playwright E2E testing patterns, Page Object Model, configuration, CI/CD integration, artifact management, and flaky test strategies. |
| 50 | `ecc-guide` | Guide users through ECC's current agents, skills, commands, hooks, rules, install profiles, and project onboarding by reading the live repository surface before answering. |
| 51 | `ecc-tools-cost-audit` | Evidence-first ECC Tools burn and billing audit workflow. Use when investigating runaway PR creation, quota bypass, premium-model leakage, duplicate jobs, or GitHub App cost spikes in the ECC Tools re |
| 52 | `error-handling` | Patterns for robust error handling across TypeScript, Python, and Go. Covers typed errors, error boundaries, retries, circuit breakers, and user-facing error messages. |
| 53 | `exa-search` | Neural search via Exa MCP for web, code, and company research. Use when the user needs web search, code examples, company intel, people lookup, or AI-powered deep research with Exa's neural search eng |
| 54 | `excel-xlsx` | Create, inspect, and edit Microsoft Excel workbooks and XLSX files with |
| 55 | `fact-check` | 事实核查 skill，对新闻内容进行多源交叉验证 |
| 56 | `fal-ai-media` | Unified media generation via fal.ai MCP — image, video, and audio. Covers text-to-image (Nano Banana), text/image-to-video (Seedance, Kling, Veo 3), text-to-speech (CSM-1B), and video-to-audio (ThinkS |
| 57 | `fanqie` | 用途与边界 |
| 58 | `fanqie-novel-auto-publish` | 番茄小说创作发布一条龙技能，整合 AI 创作与番茄发布，支持全自动批量上传、断点续传、错误重试、发布报告生成 |
| 59 | `fastapi-patterns` | FastAPI best practices covering project structure, Pydantic v2 schemas, dependency injection, async handlers, authentication, authorization, transactional service layers, and testing with httpx and py |
| 60 | `find-skills` | Helps users discover and install agent skills when they ask questions |
| 61 | `free-ride` | Manages free AI models from OpenRouter for OpenClaw. Automatically ranks |
| 62 | `frontend-a11y` | Accessibility patterns for React and Next.js — semantic HTML, ARIA attributes, form labeling, keyboard navigation, focus management, and screen reader support. Use when building any interactive UI com |
| 63 | `frontend-design` | Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples inclu |
| 64 | `frontend-design-direction` | Set an ECC-specific frontend design direction for production UI work. Use when building or improving websites, dashboards, applications, components, landing pages, visual tools, or any web UI that nee |
| 65 | `frontend-patterns` | Frontend development patterns for React, Next.js, state management, performance optimization, and UI best practices. |
| 66 | `frontend-slides` | Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build a presentation, convert a PPT/PPTX to web, or create slides for a ta |
| 67 | `get-callees` | 获取指定符号调用的所有代码。触发：想知道某个方法内部调用了什么、分析实现细节。 |
| 68 | `get-callers` | 获取调用指定符号的所有代码。触发：想知道谁在调用某个方法、分析依赖、评估影响。 |
| 69 | `git-workflow` | Git workflow patterns including branching strategies, commit conventions, merge vs rebase, conflict resolution, and collaborative development best practices for teams of all sizes. |
| 70 | `git-xywh` | 组织级 Git 工作流：三主干（main / test / develop）、五类临时分支、多环境隔离、Angular 提交与 MR 流程；涵盖合并、变基、冲突、恢复。任务涉及分支、提测、热修、版本标签、提交规范或 MR 时使用。 |
| 71 | `golang-patterns` | Idiomatic Go patterns, best practices, and conventions for building robust, efficient, and maintainable Go applications. |
| 72 | `harness-health` | 系统健康度检查 Skill — 一键输出所有子系统的健康状态 |
| 73 | `human-writing` | Write content that reads as naturally human — no AI tells, no corporate |
| 74 | `humanizer` | Remove signs of AI-generated writing from text. Use when editing or reviewing |
| 75 | `humanizer-zh` | 中文 AI 文风清洗，消除 AI 生成特征，去套路化，句式重构，人物声音分化 |
| 76 | `index-project` | 为项目建立代码索引。触发：大型项目、需要精准定位符号、快速查找调用关系。 |
| 77 | `inkos` | Autonomous novel writing CLI agent with web workbench (InkOS Studio) |
| 78 | `java-coding-standards` | Java coding standards for Spring Boot and Quarkus services: naming, immutability, Optional usage, streams, exceptions, generics, CDI, reactive patterns, and project layout. Automatically applies frame |
| 79 | `jpa-patterns` | JPA/Hibernate patterns for entity design, relationships, query optimization, transactions, auditing, indexing, pagination, and pooling in Spring Boot. |
| 80 | `junli-ai-novel` | 长篇网文核心写作引擎，支持章节续写、扩写、重写，维护人物状态和伏笔追踪 |
| 81 | `karpathy-guidelines` | 写代码、审查代码、重构代码时的行为准则：先想再写、保持简单、只改必要的，目标驱动。code 域默认基线，P0 优先级。 |
| 82 | `kubernetes-patterns` | Kubernetes workload patterns, resource management, RBAC, probes, autoscaling, ConfigMap/Secret handling, and kubectl debugging for production-grade deployments. |
| 83 | `lsp-query` | 通过 Language Server Protocol（typescript-language-server / pyright / gopls 等）做结构化代码查询：定义、引用、悬停信息、符号、代码诊断。触发：找定义、找引用、找类型、看类型签名、go to definition、find references、hover、diagnostics、rename、检查类型错误。 |
| 84 | `memory-manager` | 小说项目记忆管理引擎，双轨架构+Mem0增强模式，伏笔状态机，Agent交接压缩协议 |
| 85 | `news-generator` | 新闻写作技能包：根据热点/素材生成新闻稿件 |
| 86 | `news-polish` | 新闻稿件润色技能：去AI味、提升可读性、专业化表达 |
| 87 | `novel-36-beats` | 结构化节拍写作框架，基于 36-beat 三幕式结构，为长篇网文提供完整的情节骨架与节奏控制指南 |
| 88 | `novel-ai-wash` | 深度文风清洗引擎，四层清洗体系（词级→句式→叙事→人物声音），用于批量深度去AI味 |
| 89 | `novel-batch-write` | 批量写作模式，当用户说写到第N章时触发，自动并行/串行写作 |
| 90 | `novel-checkpoint` | 创建、验证写作进度检查点，确保批量写作不丢失上下文 |
| 91 | `novel-contexts` | 小说上下文管理，维护角色设定、世界观、时间线的全局一致性 |
| 92 | `novel-dashboard` | 小说进度仪表板，显示当前书籍状态、章节进度、人物和伏笔状态 |
| 93 | `novel-debug` | 情节矛盾/角色冲突/伏笔遗漏排查与修复 |
| 94 | `novel-evaluator` | 7维量化小说评分系统，基于情节/人物/文笔/世界观/情感/创新/钩子进行质量审查，联动47条陷阱检测，逐条引用原文举证 |
| 95 | `novel-foreshadowing-dag` | 伏笔有向无环图管理，结构化管理和追踪所有伏笔的埋设、触发和回收 |
| 96 | `novel-generator` | 根据用户提供的内容方向自动生成提示词并创作爽文小说 |
| 97 | `novel-guardian` | 法医式事实核查 Agent，专门检查角色/时间线/世界观/情节的连续性 |
| 98 | `novel-guidelines` | 小说写作前思维基线：AI 陷阱 + 简洁原则。写章节/大纲/续写前必须加载 |
| 99 | `novel-init` | 新书创作向导，帮助用户从零开始创建小说项目 |
| 100 | `novel-mcp-server` | Model Context Protocol 服务器，为写作工具提供 AI 写作能力接口 |
| 101 | `novel-mechanical-scorer` | 无LLM的确定性章节质量评分器，在LLM审稿前做纯规则检查 |
| 102 | `novel-metrics` | 写作指标追踪，统计字数、速度、质量趋势 |
| 103 | `novel-orchestrator` | 小说创作总控调度器，协调 writer→planner→reviewer→humanizer→editor→memory-keeper 全链路，管理阶段门禁和返修闭环 |
| 104 | `novel-quick-write` | 快速单章写作，无需完整编排流程，适用于写第X章类型的简单写作任务 |
| 105 | `novel-receiving-review` | 接收审稿反馈，正确处理修改建议，不是盲目接受或机械执行 |
| 106 | `novel-recovery` | 会话恢复工具，恢复中断的写作任务和上下文 |
| 107 | `novel-safe-revision` | 安全返修流程：小步返修、逐次确认、保留历史版本 |
| 108 | `novel-simplify` | 章节自查简洁度检查，识别冗余、重复、堆砌问题 |
| 109 | `novel-voice-profile` | 人物声音档案，为每个角色建立独特的语言指纹和说话风格 |
| 110 | `novel-writer-cn` | 创建小说创作框架，包括人物设定、人物关系、剧情发展和多版本结局 |
| 111 | `planning-with-files` | Implements Manus-style file-based planning to organize and track progress |
| 112 | `playwright` | Browser automation via Playwright MCP. Navigate websites, click elements, |
| 113 | `project-planner` | Triage ideas, problems, and feature requests into the right format: |
| 114 | `prompt-engineering-expert` | Advanced expert in prompt engineering, custom instructions design, and |
| 115 | `query-knowledge-graph` | 查询已生成的知识图谱，获取结构化信息。触发：需要查询项目结构、模块关系、依赖关系。 |
| 116 | `query-symbol` | 快速定位代码符号（类/函数/变量）。触发：需要找某个符号、不知道在哪里、查询定义。 |
| 117 | `ralph` | Ralph Loop — 自指循环开发，Stop Hook 拦截会话退出，强制 AI 循环生成直到 Completion Promise 满足或达到最大迭代次数。防 AI 偷懒神器。 |
| 118 | `receiving-code-review` | 根据独立审查者的反馈修改代码。 |
| 119 | `refactor-safely` | Plans and executes safe refactors with small steps, tests, and rollback |
| 120 | `requesting-code-review` | Use when completing tasks, implementing major features, or before merging |
| 121 | `ripgrep-search` | 使用 ripgrep（rg）做高速文本搜索，定位引用、字符串、关键字。触发：grep、find、搜索文本、定位字符串、查找引用、查找 TODO/FIXME、查找实现、查找日志、搜索代码。 |
| 122 | `security-auditor` | Use when reviewing code for security vulnerabilities, implementing authentication |
| 123 | `security-bounty-hunter` | Hunt for exploitable, bounty-worthy security issues in repositories. Focuses on remotely reachable vulnerabilities that qualify for real reports instead of noisy local-only findings. |
| 124 | `security-review` | Use this skill when adding authentication, handling user input, working with secrets, creating API endpoints, or implementing payment/sensitive features. Provides comprehensive security checklist and  |
| 125 | `self-improving` | Self-reflection + Self-criticism + Self-learning + Self-organizing memory. |
| 126 | `simplify` | Refactor code for clarity, consistency, and maintainability without changing |
| 127 | `skill-vetter` | Security-first skill vetting for AI agents. Use before installing any |
| 128 | `summarize` | Summarize URLs or files with the summarize CLI (web, PDFs, images, audio, |
| 129 | `superdesign` | Expert frontend design guidelines for creating beautiful, modern UIs. |
| 130 | `systematic-debugging` | Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes |
| 131 | `tdd-workflow` | Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests. |
| 132 | `test-driven-development` | Use when implementing any feature or bugfix, before writing implementation code |
| 133 | `two-stage-review` | 两阶段审查：先验证 Spec 合规，再检查代码质量。code 域实现完成后使用。 |
| 134 | `ui-ux-pro-max` | UI/UX design intelligence and implementation guidance for building polished |
| 135 | `understand-project` | 理解项目结构和架构，生成知识图谱。触发：接手新项目、需要了解项目全局、询问架构设计。 |
| 136 | `verification-before-completion` | Use when about to claim work is complete, fixed, or passing, before committing |
| 137 | `verification-loop` | A comprehensive verification system for Claude Code sessions. |
| 138 | `web-design-guidelines` | 网页设计规范和最佳实践指南 |
| 139 | `web-novel-publishing-readiness-and-quality-check-skill` | 小说质量检查技能。触发关键词：检查正文、质量报告、违禁词、套路句、章节衔接、逻辑漏洞、自检、人写感、大纲、人设。执行最大算力深度推理五步链，每章必须跑freq_check.py词频扫描+逐行违禁词扫描双轨制，复核自检通过方可出报告。 |
| 140 | `web-tools-guide` | Web 工具使用指南：搜索、网页抓取、浏览器自动化。触发：查资料、上网、搜索、打开网站。 |
| 141 | `writing-plans` | Use when you have a spec or requirements for a multi-step task, before |

## 按功能分类

> 分类定义见 [categories.yaml](./categories.yaml)。新 skill 请在 `_meta.json` 中声明 `category` 字段。

### 架构与设计

_后端架构、API 设计、ADR、DDD_

- `ai-regression-testing` - Regression testing strategies for AI-assisted development. Sandbox-mode API testing without database dependencies, automated bug-check workflows, and patterns to catch AI blind spots where the same mo
- `api-connector-builder` - Build a new API connector or provider by matching the target repo's existing integration pattern exactly. Use when adding one more integration without inventing a second architecture.
- `api-design` - REST API design patterns including resource naming, status codes, pagination, filtering, error responses, versioning, and rate limiting for production APIs.
- `architecture-decision-records` - Capture architectural decisions made during Claude Code sessions as structured ADRs. Auto-detects decision moments, records context, alternatives considered, and rationale. Maintains an ADR log so fut
- `architecture-patterns` - ## WHAT
- `backend-doc-generator` - 生成标准后端技术文档，包含Mermaid流程图、时序图、类图、状态图。Invoke when user needs to create backend technical documentation or draw system architecture diagrams.
- `backend-patterns` - Backend architecture patterns, API design, database optimization, and server-side best practices for Node.js, Express, and Next.js API routes.
- `blueprint` - Turn a one-line objective into a step-by-step construction plan for multi-session, multi-agent engineering projects. Each step has a self-contained context brief so a fresh agent can execute it cold. 
- `code-tour` - Create CodeTour `.tour` files — persona-targeted, step-by-step walkthroughs with real file and line anchors. Use for onboarding tours, architecture walkthroughs, PR tours, RCA tours, and structured \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
- `codebase-onboarding` - Analyze an unfamiliar codebase and generate a structured onboarding guide with architecture map, key entry points, conventions, and a starter CLAUDE.md. Use when joining a new project or setting up Cl
- `coding-standards` - Baseline cross-project coding conventions for naming, readability, immutability, and code-quality review. Use detailed frontend or backend skills for framework-specific patterns.
- `continuous-agent-loop` - Patterns for continuous autonomous agent loops with quality gates, evals, and recovery controls.
- `cost-aware-llm-pipeline` - Cost optimization patterns for LLM API usage — model routing by task complexity, budget tracking, retry logic, and prompt caching.
- `deployment-patterns` - Deployment workflows, CI/CD pipeline patterns, Docker containerization, health checks, rollback strategies, and production readiness checklists for web applications.
- `design-system` - Use this skill to generate or audit design systems, check visual consistency, and review PRs that touch styling.
- `docker-patterns` - Docker and Docker Compose patterns for local development, container security, networking, volume strategies, and multi-service orchestration.
- `dotnet-patterns` - Idiomatic C# and .NET patterns, conventions, dependency injection, async/await, and best practices for building robust, maintainable .NET applications.
- `e2e-testing` - Playwright E2E testing patterns, Page Object Model, configuration, CI/CD integration, artifact management, and flaky test strategies.
- `error-handling` - Patterns for robust error handling across TypeScript, Python, and Go. Covers typed errors, error boundaries, retries, circuit breakers, and user-facing error messages.
- `fastapi-patterns` - FastAPI best practices covering project structure, Pydantic v2 schemas, dependency injection, async handlers, authentication, authorization, transactional service layers, and testing with httpx and py
- `frontend-a11y` - Accessibility patterns for React and Next.js — semantic HTML, ARIA attributes, form labeling, keyboard navigation, focus management, and screen reader support. Use when building any interactive UI com
- `frontend-patterns` - Frontend development patterns for React, Next.js, state management, performance optimization, and UI best practices.
- `git-workflow` - Git workflow patterns including branching strategies, commit conventions, merge vs rebase, conflict resolution, and collaborative development best practices for teams of all sizes.
- `golang-patterns` - Idiomatic Go patterns, best practices, and conventions for building robust, efficient, and maintainable Go applications.
- `java-coding-standards` - Java coding standards for Spring Boot and Quarkus services: naming, immutability, Optional usage, streams, exceptions, generics, CDI, reactive patterns, and project layout. Automatically applies frame
- `jpa-patterns` - JPA/Hibernate patterns for entity design, relationships, query optimization, transactions, auditing, indexing, pagination, and pooling in Spring Boot.
- `kubernetes-patterns` - Kubernetes workload patterns, resource management, RBAC, probes, autoscaling, ConfigMap/Secret handling, and kubectl debugging for production-grade deployments.
- `ralph` - Ralph Loop — 自指循环开发，Stop Hook 拦截会话退出，强制 AI 循环生成直到 Completion Promise 满足或达到最大迭代次数。防 AI 偷懒神器。
- `security-review` - Use this skill when adding authentication, handling user input, working with secrets, creating API endpoints, or implementing payment/sensitive features. Provides comprehensive security checklist and 

### 代码审查与重构

_Code review、安全重构、simplify_

- `code-review` - Systematic code review patterns covering security, performance, maintainability,
- `document-review` - Use when reviewing any document (spec, design, plan) for completeness, clarity, and quality — especially environment preparation completeness. Triggers: review document, check document, audit spec, au
- `frontend-design` - Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples inclu
- `receiving-code-review` - 根据独立审查者的反馈修改代码。
- `refactor-safely` - Plans and executes safe refactors with small steps, tests, and rollback
- `requesting-code-review` - Use when completing tasks, implementing major features, or before merging
- `simplify` - Refactor code for clarity, consistency, and maintainability without changing

### 测试与 TDD

_TDD、E2E、benchmark、验证_

- `agent-browser` - Browser automation for AI agents via inference.sh. Navigate web pages, interact with elements using @e refs, take screenshots, record video. Capabilities: web scraping, form filling, clicking, typing,
- `benchmark` - Use this skill to measure performance baselines, detect regressions before/after PRs, and compare stack alternatives.
- `benchmark-methodology` - Use after competitive-platform-analysis has produced a tiered competitor set. Scores each competitor across nine weighted dimensions (positioning, voice, visual craft, offer packaging, evidence, enter
- `benchmark-optimization-loop` - Use when the user asks to make something faster, try many variants, run recursive optimization, benchmark latency/throughput/cost, or choose the best implementation by repeated measured tests.
- `cursor-orchestration` - Cursor 多 subagent 并行编排，等价于 omx ultrawork。在用户已批准 plan 并说「开始实现」后，通过 harness-coder（代码）、harness-implementer（轻量）、harness-test-engineer、harness-web-investigator（research）等并行派发 WU。触发词：并行实现、多 task、开始实现、cursor
- `frontend-design-direction` - Set an ECC-specific frontend design direction for production UI work. Use when building or improving websites, dashboards, applications, components, landing pages, visual tools, or any web UI that nee
- `systematic-debugging` - Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
- `verification-before-completion` - Use when about to claim work is complete, fixed, or passing, before committing
- `verification-loop` - A comprehensive verification system for Claude Code sessions.

### 安全与合规

_安全审计、漏洞扫描、合规检查_

- `security-auditor` - Use when reviewing code for security vulnerabilities, implementing authentication
- `security-bounty-hunter` - Hunt for exploitable, bounty-worthy security issues in repositories. Focuses on remotely reachable vulnerabilities that qualify for real reports instead of noisy local-only findings.

### 语言 / 框架生态

_各语言/框架的模式、TDD、安全_

- `ck` - Persistent per-project memory for Claude Code. Auto-loads project context on session start, tracks sessions with git activity, and writes to native memory. Commands run deterministic Node.js scripts —
- `database-migrations` - Database migration best practices for schema changes, data migrations, rollbacks, and zero-downtime deployments across PostgreSQL, MySQL, and common ORMs (Prisma, Drizzle, Kysely, Django, TypeORM, gol
- `documentation-lookup` - Use up-to-date library and framework docs via Context7 MCP instead of training data. Activates for setup questions, API references, code examples, or when the user names a framework (e.g. React, Next.
- `frontend-slides` - Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint files. Use when the user wants to build a presentation, convert a PPT/PPTX to web, or create slides for a ta

### 前端开发

_UI/UX 设计、动画、演示_

- `accessibility` - Design, implement, and audit inclusive digital products using WCAG 2.2 Level AA
- `superdesign` - Expert frontend design guidelines for creating beautiful, modern UIs.
- `ui-ux-pro-max` - UI/UX design intelligence and implementation guidance for building polished

### AI / Agent 系统

_Agent 编排、LLM、Prompt、MCP、推荐_

- `agentic-engineering` - Operate as an agentic engineer using eval-first execution, decomposition, and cost-aware model routing.
- `ai-first-engineering` - Engineering operating model for teams where AI agents generate a large share of implementation output.
- `automation-audit-ops` - Evidence-first automation inventory and overlap audit workflow for ECC. Use when the user wants to know which jobs, hooks, connectors, MCP servers, or wrappers are live, broken, redundant, or missing 
- `autonomous-agent-harness` - Transform Claude Code into a fully autonomous agent system with persistent memory, scheduled operations, computer use, and task queuing. Replaces standalone agent frameworks (Hermes, AutoGPT) by lever
- `context-budget` - Audits Claude Code context window consumption across agents, skills, MCP servers, and rules. Identifies bloat, redundant components, and produces prioritized token-savings recommendations.
- `cost-tracking` - Track and report Claude Code token usage, spending, and budgets from the local ECC cost-tracker metrics log. Use when the user asks about costs, spending, usage, tokens, budgets, or cost breakdowns by
- `ecc-guide` - Guide users through ECC's current agents, skills, commands, hooks, rules, install profiles, and project onboarding by reading the live repository surface before answering.
- `ecc-tools-cost-audit` - Evidence-first ECC Tools burn and billing audit workflow. Use when investigating runaway PR creation, quota bypass, premium-model leakage, duplicate jobs, or GitHub App cost spikes in the ECC Tools re
- `exa-search` - Neural search via Exa MCP for web, code, and company research. Use when the user needs web search, code examples, company intel, people lookup, or AI-powered deep research with Exa's neural search eng
- `fal-ai-media` - Unified media generation via fal.ai MCP — image, video, and audio. Covers text-to-image (Nano Banana), text/image-to-video (Seedance, Kling, Veo 3), text-to-speech (CSM-1B), and video-to-audio (ThinkS
- `prompt-engineering-expert` - Advanced expert in prompt engineering, custom instructions design, and
- `self-improving` - Self-reflection + Self-criticism + Self-learning + Self-organizing memory.

### 小说创作

_生成、编排、写作、评估_

- `inkos` - Autonomous novel writing CLI agent with web workbench (InkOS Studio)
- `junli-ai-novel` - 长篇网文核心写作引擎，支持章节续写、扩写、重写，维护人物状态和伏笔追踪
- `novel-generator` - 根据用户提供的内容方向自动生成提示词并创作爽文小说
- `novel-writer-cn` - 创建小说创作框架，包括人物设定、人物关系、剧情发展和多版本结局

### 小说结构

_大纲、节拍、伏笔、节奏_

- `novel-36-beats` - 结构化节拍写作框架，基于 36-beat 三幕式结构，为长篇网文提供完整的情节骨架与节奏控制指南

### AI 文风处理

_humanizer、文风清洗_

- `humanizer` - Remove signs of AI-generated writing from text. Use when editing or reviewing
- `humanizer-zh` - 中文 AI 文风清洗，消除 AI 生成特征，去套路化，句式重构，人物声音分化
- `novel-ai-wash` - 深度文风清洗引擎，四层清洗体系（词级→句式→叙事→人物声音），用于批量深度去AI味

### 小说发布与平台

_番茄、发布质检_

- `fanqie` - 用途与边界
- `fanqie-novel-auto-publish` - 番茄小说创作发布一条龙技能，整合 AI 创作与番茄发布，支持全自动批量上传、断点续传、错误重试、发布报告生成
- `web-novel-publishing-readiness-and-quality-check-skill` - 小说质量检查技能。触发关键词：检查正文、质量报告、违禁词、套路句、章节衔接、逻辑漏洞、自检、人写感、大纲、人设。执行最大算力深度推理五步链，每章必须跑freq_check.py词频扫描+逐行违禁词扫描双轨制，复核自检通过方可出报告。

### 新闻生成与润色

_自动生成、润色_

- `fact-check` - 事实核查 skill，对新闻内容进行多源交叉验证

### 规划与编排

_brainstorming、计划、SDD、并行_

- `brainstorming` - You MUST use this before any creative work - creating features, building
- `planning-with-files` - Implements Manus-style file-based planning to organize and track progress
- `project-planner` - Triage ideas, problems, and feature requests into the right format:
- `writing-plans` - Use when you have a spec or requirements for a multi-step task, before

### 记忆与上下文

_记忆管理、上下文预算_

- `memory-manager` - 小说项目记忆管理引擎，双轨架构+Mem0增强模式，伏笔状态机，Agent交接压缩协议

### 文档与写作

_Word、Excel、PDF、写作_

- `article-writing` - Write articles, guides, blog posts, tutorials, newsletter issues, and other long-form content in a distinctive voice derived from supplied examples or brand guidance. Use when the user wants polished 
- `brand-discovery` - Use when a brand needs to discover or articulate its identity through structured multi-session interviews. Covers purpose, positioning, audience, personality, voice, narrative, and founder-brand tensi
- `brand-voice` - Build a source-derived writing style profile from real posts, essays, launch notes, docs, or site copy, then reuse that profile across content, outreach, and social workflows. Use when the user wants 
- `cpp-coding-standards` - C++ coding standards based on the C++ Core Guidelines (isocpp.github.io). Use when writing, reviewing, or refactoring C++ code to enforce modern, safe, and idiomatic practices.
- `excel-xlsx` - Create, inspect, and edit Microsoft Excel workbooks and XLSX files with
- `human-writing` - Write content that reads as naturally human — no AI tells, no corporate
- `tdd-workflow` - Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.
- `test-driven-development` - Use when implementing any feature or bugfix, before writing implementation code

### 搜索与研究

_深度研究、Exa、查找_

- `deep-research` - Multi-source deep research using firecrawl and exa MCPs. Searches the
- `web-tools-guide` - Web 工具使用指南：搜索、网页抓取、浏览器自动化。触发：查资料、上网、搜索、打开网站。

### 技能管理与自检

_find-skills、vetter、stocktake、verify_

- `agent-shield` - 安全审计：扫描配置漏洞、注入风险、MCP 安全问题。保护 Harness Foundry 免受提示注入、权限过度、Hook 注入等攻击。
- `auto-updater` - Automatically update Clawdbot and all installed skills once daily. Runs
- `ceo-orchestration` - CEO 角色主 Skill — 跨域协调入口，调用子 Skill 完成各项职责
- `continuous-learning` - 持续学习系统 — Session → instinct → cluster → Skill 进化闭环。P1-3 升级：confidence
- `find-skills` - Helps users discover and install agent skills when they ask questions
- `free-ride` - Manages free AI models from OpenRouter for OpenClaw. Automatically ranks
- `git-xywh` - 组织级 Git 工作流：三主干（main / test / develop）、五类临时分支、多环境隔离、Angular 提交与 MR 流程；涵盖合并、变基、冲突、恢复。任务涉及分支、提测、热修、版本标签、提交规范或 MR 时使用。
- `harness-health` - 系统健康度检查 Skill — 一键输出所有子系统的健康状态
- `playwright` - Browser automation via Playwright MCP. Navigate websites, click elements,
- `skill-vetter` - Security-first skill vetting for AI agents. Use before installing any
- `summarize` - Summarize URLs or files with the summarize CLI (web, PDFs, images, audio,
- `two-stage-review` - 两阶段审查：先验证 Spec 合规，再检查代码质量。code 域实现完成后使用。

### 代码基线

_Karpathy 准则、编码基线_

- `karpathy-guidelines` - 写代码、审查代码、重构代码时的行为准则：先想再写、保持简单、只改必要的，目标驱动。code 域默认基线，P0 优先级。

### 前端/UI 设计

_网页设计规范、设计指南_

- `web-design-guidelines` - 网页设计规范和最佳实践指南

### 代码智能

_图谱查询、LSP、ripgrep、影响分析_

- `analyze-architecture` - 深入分析项目架构，回答架构相关问题。触发：询问设计原因、技术选型、模块职责、架构决策。
- `analyze-impact` - 评估代码变更的影响范围。触发：重构前、修改核心方法、批量修改前。
- `code-insight-stack` - 编排 codebase-memory + ripgrep + LSP 三层查询栈，按场景选择最便宜的工具组合。触发：探索陌生代码库、定位修改点、调查 bug、准备 refactor、计划实现、跨文件影响分析。
- `get-callees` - 获取指定符号调用的所有代码。触发：想知道某个方法内部调用了什么、分析实现细节。
- `get-callers` - 获取调用指定符号的所有代码。触发：想知道谁在调用某个方法、分析依赖、评估影响。
- `index-project` - 为项目建立代码索引。触发：大型项目、需要精准定位符号、快速查找调用关系。
- `query-knowledge-graph` - 查询已生成的知识图谱，获取结构化信息。触发：需要查询项目结构、模块关系、依赖关系。
- `query-symbol` - 快速定位代码符号（类/函数/变量）。触发：需要找某个符号、不知道在哪里、查询定义。
- `understand-project` - 理解项目结构和架构，生成知识图谱。触发：接手新项目、需要了解项目全局、询问架构设计。

### 语言服务器

_LSP 查询、定义引用_

- `lsp-query` - 通过 Language Server Protocol（typescript-language-server / pyright / gopls 等）做结构化代码查询：定义、引用、悬停信息、符号、代码诊断。触发：找定义、找引用、找类型、看类型签名、go to definition、find references、hover、diagnostics、rename、检查类型错误。

### 性能优化

_上下文压缩、Token 优化_

- `auto-compact` - 智能上下文压缩：在最佳时机触发压缩，保留关键状态，清理冗余上下文。

### 代码搜索

_ripgrep 搜索、定位_

- `ripgrep-search` - 使用 ripgrep（rg）做高速文本搜索，定位引用、字符串、关键字。触发：grep、find、搜索文本、定位字符串、查找引用、查找 TODO/FIXME、查找实现、查找日志、搜索代码。

### 新闻生产

_生成、润色、发布_

- `news-generator` - 新闻写作技能包：根据热点/素材生成新闻稿件
- `news-polish` - 新闻稿件润色技能：去AI味、提升可读性、专业化表达

### 小说分析

_写作指标、进度追踪_

- `novel-metrics` - 写作指标追踪，统计字数、速度、质量趋势

### 小说基线

_写作前准则、自查、返修_

- `novel-debug` - 情节矛盾/角色冲突/伏笔遗漏排查与修复
- `novel-guidelines` - 小说写作前思维基线：AI 陷阱 + 简洁原则。写章节/大纲/续写前必须加载
- `novel-safe-revision` - 安全返修流程：小步返修、逐次确认、保留历史版本
- `novel-simplify` - 章节自查简洁度检查，识别冗余、重复、堆砌问题

### 批量写作

_批量章节写作_

- `novel-batch-write` - 批量写作模式，当用户说写到第N章时触发，自动并行/串行写作

### 小说上下文

_角色/世界观/时间线一致性_

- `novel-contexts` - 小说上下文管理，维护角色设定、世界观、时间线的全局一致性

### 小说仪表板

_进度仪表板_

- `novel-dashboard` - 小说进度仪表板，显示当前书籍状态、章节进度、人物和伏笔状态

### 一致性核查

_法医式连续性检查_

- `novel-guardian` - 法医式事实核查 Agent，专门检查角色/时间线/世界观/情节的连续性

### 小说初始化

_新书创建向导_

- `novel-init` - 新书创作向导，帮助用户从零开始创建小说项目

### 小说集成

_MCP 服务、外部工具_

- `novel-mcp-server` - Model Context Protocol 服务器，为写作工具提供 AI 写作能力接口

### 小说编排

_全链路调度、阶段门禁_

- `novel-orchestrator` - 小说创作总控调度器，协调 writer→planner→reviewer→humanizer→editor→memory-keeper 全链路，管理阶段门禁和返修闭环

### 情节结构

_伏笔 DAG、节拍_

- `novel-foreshadowing-dag` - 伏笔有向无环图管理，结构化管理和追踪所有伏笔的埋设、触发和回收

### 写作进度

_检查点、进度管理_

- `novel-checkpoint` - 创建、验证写作进度检查点，确保批量写作不丢失上下文

### 质量评分

_确定性评分、机械评分_

- `novel-mechanical-scorer` - 无LLM的确定性章节质量评分器，在LLM审稿前做纯规则检查

### 快速写作

_单章快速写作_

- `novel-quick-write` - 快速单章写作，无需完整编排流程，适用于写第X章类型的简单写作任务

### 会话恢复

_中断恢复、上下文恢复_

- `novel-recovery` - 会话恢复工具，恢复中断的写作任务和上下文

### 小说审稿

_评估、接收反馈_

- `novel-evaluator` - 7维量化小说评分系统，基于情节/人物/文笔/世界观/情感/创新/钩子进行质量审查，联动47条陷阱检测，逐条引用原文举证
- `novel-receiving-review` - 接收审稿反馈，正确处理修改建议，不是盲目接受或机械执行

### 人物声音

_角色语言指纹_

- `novel-voice-profile` - 人物声音档案，为每个角色建立独特的语言指纹和说话风格

---

_本文件由脚本自动生成，请勿手改。如需修改分类，请编辑 `skills/categories.yaml`；如需修改 skill 描述，请编辑 `SKILL.md` 的 frontmatter 或 `_meta.json` 的 `purpose` 字段。_
