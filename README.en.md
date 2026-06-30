# Harness Foundry

> A multi-agent AI workflow framework for orchestrating code development, novel writing, and news reporting across multiple IDE platforms.

Unified driver for **Trae / Claude Code / Cursor / Codex / Mimocode** — one truth source, rebuilt anytime.

[中文](README.md)

---

## What It Does

Harness Foundry provides a structured orchestration layer on top of any AI coding IDE. Instead of a free-form chat loop, it enforces discipline:

```
User Intent → Intent Routing → Domain Leader → Stage Gates → Parallel Workers → Verification
```

Three operational domains share the same orchestration primitives:

| Domain | Stage Gates | Workers |
|--------|-----------|---------|
| **code** | spec → plan → implement → verify | coder, debugger, reviewer, test-engineer, explorer |
| **novel** | outline → chapter → revision → publish | novel-writer, novel-planner, novel-reviewer, humanizer |
| **news** | angle → draft → fact-check → polish → publish | news-writer, fact-checker, news-editor |

Every session starts by reading `core/intent-routing.md` and declaring:

```
Route: <code|novel|news>
```

---

## Intelligence Layer (Smart Code Understanding)

Harness Foundry integrates **Understand-Anything** and **CodeGraph** for intelligent code comprehension:

| Layer | Tool | Capability |
|-------|------|------------|
| **Strategic** | Understand-Anything | Project understanding, architecture analysis, natural language Q&A |
| **Tactical** | CodeGraph | Index queries, symbol location, impact analysis |

**Benefits**:
- Understand unfamiliar projects in 5 minutes
- 57% reduction in Token consumption
- 71% reduction in tool calls

### One-Command Install

```bash
# Linux/macOS
bash scripts/install-intelligence-deps.sh

# Windows PowerShell
.\scripts\install-intelligence-deps.ps1

# Optional: Initialize project index after installation
codegraph init
codegraph index
```

See: [User Guide](docs/intelligence-layer-user-guide.md) | [Usage Manual](docs/intelligence-layer-usage-guide.md) | [Troubleshooting](docs/intelligence-layer-troubleshooting.md)

---

## Quick Start

```bash
# 1. Project adapters to your IDE
bash scripts/bootstrap.sh --target all       # All platforms
bash scripts/bootstrap.sh --target trae     # Trae only
bash scripts/bootstrap.sh --target cursor   # Cursor only
bash scripts/bootstrap.sh --target claude   # Claude Code only

# 2. Sync skills
bash scripts/sync-skills.sh --target all

# 3. Preview first (safe — no writes)
bash scripts/bootstrap.sh --target all --dry-run
bash scripts/sync-skills.sh --target all --dry-run

# 4. Verify
bash scripts/verify.sh
```

**Windows:** Use `bash` from Git Bash or WSL. PowerShell equivalents exist:
```powershell
.\scripts\bootstrap.ps1 -Target all
.\scripts\sync-skills.ps1 -Target all -DryRun
```

---

## Architecture

```
harness-foundry/
├── core/                              # Platform-agnostic truth source
│   ├── intent-routing.md              # Intent routing table (read first)
│   ├── routing.md                    # Compat alias → intent-routing.md
│   ├── NEVER.md                      # Hard prohibitions (402 trap rules)
│   ├── principles.md                 # 10 core principles
│   ├── capabilities/                 # Capability ID registry
│   │   ├── registry.md
│   │   └── primitives.md
│   ├── intelligence/                 # Intelligence Layer config
│   │   └── README.md
│   ├── memory/                       # Memory management protocol
│   └── orchestration/               # Dispatcher, roles, skill routing
│       ├── domain-config.yaml      # Domain → agent/skill mapping
│       ├── dispatcher-workflow.md   # Parallel dispatch workflow (≤5 workers)
│       ├── skill-preferences.md    # WU-level skill routing
│       └── execution-context/        # Worktree / local provider protocol
│
├── adapters/                         # Platform physical bindings (thin shells)
│   ├── trae/                       # Trae IDE adapter
│   ├── cursor/                     # Cursor adapter
│   ├── claude/                     # Claude Code adapter
│   ├── codex/                      # Codex adapter
│   └── mimocode/                   # Mimocode adapter
│
├── skills/                            # ★ 194 Skills (flat structure)
│   ├── INDEX.md                    # Complete skill index (auto-generated)
│   ├── categories.yaml            # 26 category definitions
│   ├── _layer.yaml                # Skill layer classification
│   └── <slug>/SKILL.md           # Each skill in its own directory
│
├── agents/                             # ★ 30 Agents (flat structure)
│   ├── leader-code.md              # Domain leader (code)
│   ├── leader-novel.md            # Domain leader (novel)
│   ├── leader-news.md             # Domain leader (news)
│   ├── coder.md                   # Code implementation
│   ├── debugger.md                # Debugging expert
│   ├── reviewer.md                # Code review
│   ├── code-reviewer.md           # Dedicated reviewer (with Handoff protocol)
│   ├── test-engineer.md           # Test engineering
│   ├── explorer.md               # Code exploration
│   ├── implementer.md             # Lightweight implementer
│   ├── humanizer.md              # Text humanization
│   ├── memory-keeper.md          # Memory manager
│   └── *.md                      # Other specialized agents
│
├── hooks/                              # Automation hooks + Guardrails
│   ├── hooks.json                 # PreToolUse / PostToolUse / Stop hooks
│   ├── guardrails/               # Double-layer protection rules
│   │   ├── guardrail-config.json
│   │   └── rules/                # Input 5 + Output 5 rules
│   ├── observe.sh / observe.ps1  # Runtime monitoring
│   └── memory-persistence/       # Memory persistence
│
├── scripts/                           # Bootstrap and sync scripts
│   ├── bootstrap.sh / bootstrap.ps1
│   ├── sync-skills.sh / sync-skills.ps1
│   ├── verify.sh                  # CI verification entry
│   ├── gen-skill-index.sh / gen-skill-index.ps1
│   ├── gen-skill-graph.py        # Skill dependency graph generator
│   ├── auto-fill-frontmatter.py  # Frontmatter auto-fill
│   ├── classify-skills.py        # Skill classification
│   └── harness-worktree.sh       # Git worktree sandbox
│
├── traps-archive/                    # Historical trap archive (402 rules)
│   ├── code/00-all.md           # 251 code traps
│   ├── novel/00-all.md         # 82 novel traps
│   └── news/00-all.md          # 69 news traps
│
├── contexts/                       # Domain-specific contexts
├── rules/                          # Tech-stack-specific coding rules
├── references/                     # Context maps, instincts
├── docs/                           # Documentation
│   ├── skill-metadata-spec.md   # Skill metadata spec
│   ├── skill-frontmatter-schema.md
│   ├── skill-dependency-graph.md # Skill dependency graph
│   ├── harness-foundry-knowledge-graph.md # Knowledge graph
│   └── intelligence-layer-*.md   # Intelligence Layer docs
│
└── CLAUDE.md                   # Claude Code context file
```

---

## Intent Routing

`core/intent-routing.md` is the **single mandatory entry point** for every session. It maps natural language triggers to domains and capability IDs:

| Trigger Phrases | Domain | Capability |
|----------------|--------|-----------|
| 写代码 / 实现 / 修 bug / 重构 | code | `roles.coder` |
| 设计 / 架构 / 方案 | code | `roles.architect` |
| 调试 / 排查 | code | `roles.debugger` |
| 审查 / review | code | `roles.reviewer` |
| 写小说 / 章节 / 续写 | novel | `roles.novel-writer` |
| 写新闻 / 报道 / 快讯 | news | `roles.news-writer` |
| 小改动 / quick fix | code | Direct (no dispatch) |

---

## Skill System

**194 Skills** in a flat `skills/<slug>/SKILL.md` structure.

### Category System (26 Categories)

| Category | Count | Description |
|----------|-------|-------------|
| code | 11 | Full code development lifecycle |
| novel | 4 | Novel writing and editing |
| news | 2 | News writing and fact-checking |
| shared | 6 | Cross-domain skills |
| biz | 2 | Business analysis |
| crypto | 1 | Cryptography related |
| science | 1 | Scientific research |

### Skill Layer Classification

```yaml
_layer.yaml:
  must-core:   # Core skills to sync (~50)
  optional:    # Optional skills (~140)
```

### Skill Metadata

Each Skill may contain optional `_meta.json`:
```json
{
  "slug": "skill-name",
  "domain": "code|novel|news|shared",
  "category": "category-id",
  "tags": ["tag1", "tag2"],
  "purpose": "Brief description",
  "requires": ["other-skill"],
  "complements": ["related-skill"],
  "conflicts": ["incompatible-skill"]
}
```

### Loading Path (Cursor example)

1. `.cursor/skills/<slug>/SKILL.md` — projection (generated by `sync-skills.sh`)
2. `skills/<slug>/SKILL.md` — truth source
3. `~/.cursor/skills/<slug>/SKILL.md` — user global

---

## Agent Pool

**30 Agents** across 3 domains. Each agent is a markdown file with YAML frontmatter.

| Domain | Leader | Primary Workers |
|--------|--------|---------------|
| **code** | leader-code | coder, debugger, reviewer, test-engineer, explorer |
| **novel** | leader-novel | novel-writer, novel-planner, novel-reviewer, humanizer, memory-keeper |
| **news** | leader-news | news-writer, fact-checker, news-editor |

### Specialized Reviewers (ECC cherry-pick)

- `ecc-java-reviewer` — Java specialized review
- `ecc-security-reviewer` — Security review
- `ecc-database-reviewer` — Database review

Invoked only during the review phase, not in the main flow.

### Handoff Protocol

All agent files include built-in Handoff protocol entries to ensure context transfer during multi-agent collaboration.

---

## Hooks & Guardrails

**PreToolUse / PostToolUse / Stop** hooks per domain, defined in `hooks/hooks.json`.

### Double-Layer Protection (P0-2)

| Layer | Type | Rules |
|-------|------|-------|
| **Input** (parallel, any-fail-block) | prompt injection | SQL injection | command injection | prompt override | path traversal |
| **Output** (sequential, any-block) | secret leak | canary token leak | NEVER violation | AI writing markers | syntax check |

**Config**: `hooks/guardrails/guardrail-config.json`
**Audit log**: `.ai-runtime-artifacts/guardrail-audit.jsonl`

### Canary Token

Generated at runtime by `scripts/canary-rotate.sh` and injected into agent prompts to detect prompt leakage. Token file (`core/security/canary-tokens.yaml`) is gitignored — never committed.

---

## Memory Management

| Layer | Path | Description |
|-------|------|-------------|
| **Global** | `~/.claude/GLOBAL-MEMORY.md` | Cross-project shared |
| **Project** | `MEMORY.md` (root) | Project-specific |
| **Session** | `memory/` | Runtime temporary |

See: [hooks/memory-persistence/README.md](hooks/memory-persistence/README.md)

---

## Testing & Verification

```bash
# Full CI verification
bash scripts/verify.sh

# L1 static checks
bash tests/L1-static/validate-agent-format.sh
bash tests/L1-static/validate-skill-meta.sh
bash tests/L1-static/validate-never.sh

# L2 integration checks
bash tests/L2-integration/validate-routing.sh
bash tests/L2-integration/validate-domain-config.sh

# Skill quality check
bash scripts/skill-quality-check.sh

# Shell script syntax
shellcheck scripts/*.sh
```

---

## Key Files Reference

| What you need | File |
|---------------|------|
| How this project works | [`CLAUDE.md`](CLAUDE.md) |
| Intent routing rules | [`core/intent-routing.md`](core/intent-routing.md) |
| Stage gates | [`core/intent-routing.md` § 阶段门禁](core/intent-routing.md) |
| Skill routing table | [`core/orchestration/skill-preferences.md`](core/orchestration/skill-preferences.md) |
| Dispatcher workflow | [`core/orchestration/dispatcher-workflow.md`](core/orchestration/dispatcher-workflow.md) |
| Domain config | [`core/orchestration/domain-config.yaml`](core/orchestration/domain-config.yaml) |
| All skills | [`skills/INDEX.md`](skills/INDEX.md) |
| Skill categories | [`skills/categories.yaml`](skills/categories.yaml) |
| Skill metadata spec | [`docs/skill-metadata-spec.md`](docs/skill-metadata-spec.md) |
| Skill dependency graph | [`docs/skill-dependency-graph.md`](docs/skill-dependency-graph.md) |
| All agents | [`agents/README.md`](agents/README.md) |
| Hooks & guardrails | [`hooks/README.md`](hooks/README.md) |
| **Intelligence Layer** | [`docs/intelligence-layer-user-guide.md`](docs/intelligence-layer-user-guide.md) |
| Knowledge graph | [`docs/harness-foundry-knowledge-graph.md`](docs/harness-foundry-knowledge-graph.md) |
| Trae quick ref | [`adapters/trae/trae-quick-ref.md`](adapters/trae/trae-quick-ref.md) |

---

## Known Limitations

- Canary tokens are generated at runtime — not available for offline use
- Execution context providers (worktree/local) are defined but not yet fully wired
- Three planned domains (essay/math/academic) are stubbed out in `domain-config.yaml`
- CI only runs on Linux (shell scripts); Windows uses PowerShell equivalents

---

## License

MIT — see [`LICENSE`](LICENSE).

## Credits

Inspired by and cherry-picks from:

- [obra/superpowers](https://github.com/obra/superpowers) — skill-triggered workflow methodology
- [affaan-m/ECC](https://github.com/affaan-m/ECC) — 60+ agents, 230+ skills, multi-harness ecosystem
- [Understand-Anything](https://github.com/ollama/ollama) — Strategic code understanding
- [CodeGraph](https://github.com/salesforce/codegraph) — Tactical code indexing
