# Skill 依赖图谱

> 自动生成的 Skill 关系图（Mermaid）。基于 `_meta.json` 中的 `requires / conflicts / complements` 字段。
> 最后更新：2026-06-25
> 生成方式：`bash scripts/gen-skill-graph.sh`

## 图例

| 关系 | 含义 | Mermaid 语法 |
|------|------|--------------|
| `requires` | 强依赖 | `A --> B` |
| `complements` | 互补 | `A -.-> B` |
| `conflicts` | 互斥 | `A ==x B` |

## 全局依赖图

```mermaid
flowchart LR
  brainstorming[brainstorming] --> writing-plans[writing-plans]
  brainstorming[brainstorming] -. complements .-> planning-with-files[planning-with-files]
  brainstorming[brainstorming] -. complements .-> project-planner[project-planner]
  code-review[code-review] -. complements .-> refactor-safely[refactor-safely]
  code-review[code-review] -. complements .-> requesting-code-review[requesting-code-review]
  dispatching-parallel-agents[dispatching-parallel-agents] --> subagent-driven-development[subagent-driven-development]
  dispatching-parallel-agents[dispatching-parallel-agents] -. complements .-> cursor-orchestration[cursor-orchestration]
  executing-plans[executing-plans] --> writing-plans[writing-plans]
  executing-plans[executing-plans] -. complements .-> subagent-driven-development[subagent-driven-development]
  fanqie-novel-auto-publish[fanqie-novel-auto-publish] --> fanqie[fanqie]
  fanqie-novel-auto-publish[fanqie-novel-auto-publish] -. complements .-> web-novel-publishing-readiness-and-quality-check-skill[web-novel-publishing-readiness-and-quality-check-skill]
  find-skills[find-skills] -. complements .-> skill-vetter[skill-vetter]
  find-skills[find-skills] -. complements .-> skill-stocktake[skill-stocktake]
  humanizer[humanizer] -. complements .-> humanizer-zh[humanizer-zh]
  humanizer[humanizer] -. complements .-> humanize-ai-text[humanize-ai-text]
  inkos[inkos] -. complements .-> novel-orchestrator[novel-orchestrator]
  novel-orchestrator[novel-orchestrator] -. complements .-> junli-ai-novel[junli-ai-novel]
  novel-orchestrator[novel-orchestrator] -. complements .-> novel-evaluator[novel-evaluator]
  novel-orchestrator[novel-orchestrator] -. complements .-> humanizer[humanizer]
  planning-with-files[planning-with-files] -. complements .-> brainstorming[brainstorming]
  planning-with-files[planning-with-files] -. complements .-> project-planner[project-planner]
  playwright[playwright] -. complements .-> agent-browser[agent-browser]
  project-planner[project-planner] -. complements .-> brainstorming[brainstorming]
  project-planner[project-planner] -. complements .-> planning-with-files[planning-with-files]
  refactor-safely[refactor-safely] --> test-driven-development[test-driven-development]
  refactor-safely[refactor-safely] -. complements .-> code-review[code-review]
  refactor-safely[refactor-safely] -. complements .-> simplify[simplify]
  requesting-code-review[requesting-code-review] -. complements .-> code-review[code-review]
  requesting-code-review[requesting-code-review] -. complements .-> verification-before-completion[verification-before-completion]
  security-auditor[security-auditor] -. complements .-> code-review[code-review]
  skill-vetter[skill-vetter] -. complements .-> find-skills[find-skills]
  skill-vetter[skill-vetter] -. complements .-> skill-comply[skill-comply]
  subagent-driven-development[subagent-driven-development] -. complements .-> dispatching-parallel-agents[dispatching-parallel-agents]
  subagent-driven-development[subagent-driven-development] -. complements .-> executing-plans[executing-plans]
  ui-ux-pro-max[ui-ux-pro-max] -. complements .-> superdesign[superdesign]
  ui-ux-pro-max[ui-ux-pro-max] ==x frontend-design[frontend-design]
  verification-before-completion[verification-before-completion] -. complements .-> test-driven-development[test-driven-development]
  writing-plans[writing-plans] --> brainstorming[brainstorming]
  writing-plans[writing-plans] -. complements .-> executing-plans[executing-plans]
  writing-plans[writing-plans] -. complements .-> planning-with-files[planning-with-files]
```

## 按域分组

### code 域

```mermaid
flowchart LR
  code-review[code-review] -. complements .-> refactor-safely[refactor-safely]
  code-review[code-review] -. complements .-> requesting-code-review[requesting-code-review]
  dispatching-parallel-agents[dispatching-parallel-agents] --> subagent-driven-development[subagent-driven-development]
  dispatching-parallel-agents[dispatching-parallel-agents] -. complements .-> cursor-orchestration[cursor-orchestration]
  refactor-safely[refactor-safely] --> test-driven-development[test-driven-development]
  refactor-safely[refactor-safely] -. complements .-> code-review[code-review]
  refactor-safely[refactor-safely] -. complements .-> simplify[simplify]
  requesting-code-review[requesting-code-review] -. complements .-> code-review[code-review]
  requesting-code-review[requesting-code-review] -. complements .-> verification-before-completion[verification-before-completion]
  security-auditor[security-auditor] -. complements .-> code-review[code-review]
  subagent-driven-development[subagent-driven-development] -. complements .-> dispatching-parallel-agents[dispatching-parallel-agents]
  subagent-driven-development[subagent-driven-development] -. complements .-> executing-plans[executing-plans]
  ui-ux-pro-max[ui-ux-pro-max] -. complements .-> superdesign[superdesign]
  ui-ux-pro-max[ui-ux-pro-max] ==x frontend-design[frontend-design]
  verification-before-completion[verification-before-completion] -. complements .-> test-driven-development[test-driven-development]
```

### novel 域

```mermaid
flowchart LR
  fanqie-novel-auto-publish[fanqie-novel-auto-publish] --> fanqie[fanqie]
  fanqie-novel-auto-publish[fanqie-novel-auto-publish] -. complements .-> web-novel-publishing-readiness-and-quality-check-skill[web-novel-publishing-readiness-and-quality-check-skill]
  humanizer[humanizer] -. complements .-> humanizer-zh[humanizer-zh]
  inkos[inkos] -. complements .-> novel-orchestrator[novel-orchestrator]
  novel-orchestrator[novel-orchestrator] -. complements .-> junli-ai-novel[junli-ai-novel]
  novel-orchestrator[novel-orchestrator] -. complements .-> novel-evaluator[novel-evaluator]
  novel-orchestrator[novel-orchestrator] -. complements .-> humanizer[humanizer]
```

### news 域

```mermaid
flowchart LR
```

### shared 域

```mermaid
flowchart LR
  brainstorming[brainstorming] --> writing-plans[writing-plans]
  brainstorming[brainstorming] -. complements .-> planning-with-files[planning-with-files]
  brainstorming[brainstorming] -. complements .-> project-planner[project-planner]
  executing-plans[executing-plans] --> writing-plans[writing-plans]
  executing-plans[executing-plans] -. complements .-> subagent-driven-development[subagent-driven-development]
  find-skills[find-skills] -. complements .-> skill-vetter[skill-vetter]
  find-skills[find-skills] -. complements .-> skill-stocktake[skill-stocktake]
  planning-with-files[planning-with-files] -. complements .-> brainstorming[brainstorming]
  planning-with-files[planning-with-files] -. complements .-> project-planner[project-planner]
  playwright[playwright] -. complements .-> agent-browser[agent-browser]
  project-planner[project-planner] -. complements .-> brainstorming[brainstorming]
  project-planner[project-planner] -. complements .-> planning-with-files[planning-with-files]
  skill-vetter[skill-vetter] -. complements .-> find-skills[find-skills]
  skill-vetter[skill-vetter] -. complements .-> skill-comply[skill-comply]
  writing-plans[writing-plans] --> brainstorming[brainstorming]
  writing-plans[writing-plans] -. complements .-> executing-plans[executing-plans]
  writing-plans[writing-plans] -. complements .-> planning-with-files[planning-with-files]
```

### biz 域

```mermaid
flowchart LR
```

## 添加新依赖

在 `skills/<slug>/_meta.json` 中声明：

```json
{
  "slug": "my-skill",
  "requires": ["other-skill-1", "other-skill-2"],
  "complements": ["another-skill"],
  "conflicts": ["rival-skill"]
}
```

然后重新跑：

```bash
bash scripts/gen-skill-graph.sh
```

## 维护说明

- 所有字段均为**可选**
- `requires`：本 skill 的核心流程**必须**先加载该 skill
- `complements`：建议**同时**加载以获得完整体验
- `conflicts`：与本 skill 同时加载会**互相覆盖意图路由或资源**
