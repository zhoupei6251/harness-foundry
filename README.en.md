# Harness Kit

> An AI coding workflow framework for multiple IDEs, integrating intent routing, stage gates, the Skill system, Agent orchestration, and third-party cherry-picking.
>
> Unified driver across **Trae / Claude Code / Cursor / Codex / Mimocode**.

[中文版 README](README.md)

## Features

| Feature | Description |
|---------|-------------|
| **Platform-agnostic core** | Same rules in `harness-kit/core/`, physical bindings in `adapters/` |
| **Stage gates** | spec → plan → implement → verify — forced pause for confirmation |
| **291 Skills + 77 Agents** | Coverage: TDD, debugging, review, UX, security, databases, AI/Agent, frontend, business, parallel dispatch |
| **Full third-party cherry-pick** | 271 ECC skills + 4 Superpowers skills + 70 ECC agents (auto-discovered) — without installing the whole plugin |
| **Idempotent sync** | `bootstrap.sh` / `sync-skills.sh` / `sync-third-party.sh` all support `--dry-run` |
| **Truth source + projection** | git tracks the truth source; IDEs read the projection (rebuildable any time) |
| **Layered indexes** | 3 index files: main entry + by-language + by-purpose, so you don't get lost in 271 skills |

## Quick Start

```bash
# 1. Project adapters to your IDE
bash harness-kit/scripts/bootstrap.sh --target trae       # Trae only
bash harness-kit/scripts/bootstrap.sh --target cursor     # Cursor only
bash harness-kit/scripts/bootstrap.sh --target all        # All platforms

# 2. Project third-party skills/agents
bash harness-kit/scripts/sync-third-party.sh

# 3. Preview first (no writes)
bash harness-kit/scripts/bootstrap.sh --target all --dry-run
bash harness-kit/scripts/sync-skills.sh --target trae --dry-run
```

> **Windows users:** Use `bash` from Git Bash or WSL. PowerShell equivalents:
> `bootstrap.ps1` mirrors `bootstrap.sh`. The other scripts require bash.

## Directory Structure

```
harness-kit/
├── core/                          # Platform-agnostic core rules
│   ├── intent-routing.md         # Intent routing + stage gates (mandatory for all platforms)
│   ├── routing.md                # Compat alias (truth source is intent-routing.md)
│   ├── karpathy-guidelines.md
│   ├── NEVER.md                  # Hard prohibitions
│   ├── capabilities/             # Capability ID registry
│   └── orchestration/            # Dispatch / roles / skill routing
│       ├── roles.md              # 7 roles + on-demand ECC agents
│       └── agents/               # Truth source for 7 roles
├── context-map.md                # Cross-module context map (template)
├── project.verification.md       # Project verification checklist (template)
│
├── adapters/                     # Platform physical bindings (thin shells)
│   ├── trae/                     # Trae IDE adapter
│   ├── cursor/                   # Cursor adapter
│   ├── claude/                   # Claude Code adapter
│   ├── codex/                    # Codex adapter
│   └── mimocode/                 # Mimocode adapter
│
├── skills/                       # ★ Skill collection (distribution entry)
│   ├── README.md
│   ├── INDEX.md                  # Main entry + complete list
│   ├── INDEX-by-language.md      # By language/framework (25+ groups)
│   ├── INDEX-by-category.md      # By purpose (14 categories)
│   ├── harness/                  # 16 harness-owned skills
│   └── third-party/
│       ├── superpowers/          # 4 Superpowers skills
│       └── ecc/                  # 271 ECC skills
│
├── agents/                       # ★ Agent collection (distribution entry)
│   ├── README.md
│   ├── harness/                  # 7 harness roles
│   └── third-party/ecc/          # 70 ECC agents (auto-discovered)
│
├── third-party/                  # Third-party cherry-pick truth source
│   ├── superpowers/skills/       # 4 Superpowers skills
│   └── ecc/
│       ├── skills/               # 271 ECC skills (with SKILL.md)
│       ├── agents/               # 70 ECC agents (md + meta)
│       └── .skill-slugs.txt      # 271 slug manifest
│
├── scripts/                      # Sync and bootstrap scripts
│   ├── bootstrap.sh / bootstrap.ps1
│   ├── sync-skills.sh / sync-skills.ps1
│   ├── sync-third-party.sh
│   ├── harness-worktree.sh
│   └── harness-worktree.test.sh
│
├── docs/                         # Design and plans
│   └── superpowers/
│       ├── specs/
│       └── plans/
│
├── references/                   # Examples and traps
├── artifact-templates/           # Artifact templates
├── traps-archive/                # Historical trap archive
└── universal/CLAUDE.md           # Universal entry
```

## Documentation Index

| I want to see… | Look at |
|----------------|---------|
| **Skill main index** | [`skills/INDEX.md`](skills/INDEX.md) |
| Skills by language | [`skills/INDEX-by-language.md`](skills/INDEX-by-language.md) |
| Skills by purpose | [`skills/INDEX-by-category.md`](skills/INDEX-by-category.md) |
| Skill collection details | [`skills/README.md`](skills/README.md) |
| Agent collection details | [`agents/README.md`](agents/README.md) |
| Intent routing | [`core/intent-routing.md`](core/intent-routing.md) |
| Role definitions | [`core/orchestration/roles.md`](core/orchestration/roles.md) |
| Three-layer integration design | [`docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md`](docs/superpowers/specs/2026-06-22-three-layer-harness-integration-design.md) |
| Trae adapter | [`adapters/trae/README.md`](adapters/trae/README.md) |
| Cursor adapter | [`adapters/cursor/bindings.md`](adapters/cursor/bindings.md) |
| Claude Code adapter | [`adapters/claude/README.md`](adapters/claude/README.md) |

## Multi-Platform Support Matrix

| Platform | Entry | Physical dir | Skills | Agents |
|----------|-------|--------------|--------|--------|
| **Trae** | `.trae/rules/harness-entry.md` | `.trae/` | 289 | 11 |
| **Cursor** | `.cursor/rules/ai-entry.mdc` | `.cursor/` | 291 | 11 |
| **Claude Code** | `CLAUDE.md` | `.claude/` | 289 | 11 |
| **Codex** | `AGENTS.md` | (no projection) | direct read | direct read |
| **Mimocode** | `.mimocode/` | `.mimocode/` | — | — |

> **Skill / Agent counts = post-projection** (16 harness-owned + 4 Superpowers + 271 ECC = 291; agents 7 + 70 = 77)

## Sync Mechanism

```
Truth source (git tracked)             Projection (IDE reads)
harness-kit/core/            ───┐
harness-kit/third-party/     ───┼──→  bootstrap.sh
harness-kit/adapters/        ───┤      sync-skills.sh
.agents/skills/              ───┘      sync-third-party.sh
                                         │
                                         ↓
                                .trae/  .cursor/  .claude/
```

**Key principles:**
- IDEs actually read the **projection directories** (`.trae/`, `.cursor/`, `.claude/`) — rebuildable any time
- After changing the truth source, run `bootstrap.sh` to re-project
- All sync scripts support `--dry-run` for safe preview

## Conflict-Prevention Mechanism

1. **Physical isolation** — Trae / Cursor / Claude each read their own dir; no direct conflicts
2. **Single truth source** — Only modify `harness-kit/core/` or `adapters/`
3. **Idempotent sync** — `rm -rf` + `cp -a` pattern; repeated runs are consistent
4. **Dry-run support** — All sync scripts can preview without writing
5. **Git-tracked truth, projection-only at runtime** — `.trae/` and similar are gitignored, recoverable

## Upgrading Upstream Skills (Third-Party)

```bash
# 1. Temporary upstream clone
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/sp
git clone --depth 1 https://github.com/affaan-m/ECC.git /tmp/ecc

# 2. Diff comparison
diff -r /tmp/ecc/skills/springboot-patterns \
        harness-kit/third-party/ecc/skills/springboot-patterns

# 3. Manually sync changes to third-party/ecc/skills/
# 4. Update third-party/ecc/.skill-slugs.txt (add new slugs)
# 5. Run sync projection (--dry-run first)
bash harness-kit/scripts/sync-third-party.sh --dry-run
bash harness-kit/scripts/sync-third-party.sh

# 6. Cleanup
rm -rf /tmp/sp /tmp/ecc
```

See [`skills/README.md` § 重新同步](skills/README.md).

## Full ECC Cherry-Pick Upgrade Strategy

> This project adopts **full cherry-pick** rather than selection, meaning ECC upgrade = sync the entire catalog.

```bash
# ECC upgrade script (recommended quarterly)
bash harness-kit/scripts/upgrade-ecc.sh   # See following sections

# Or manually:
git clone --depth 1 https://github.com/affaan-m/ECC.git /tmp/ecc
diff -rq /tmp/ecc/skills harness-kit/third-party/ecc/skills
# Manual merge
bash harness-kit/scripts/sync-third-party.sh --dry-run
```

## Testing

```bash
bash harness-kit/scripts/verify.sh
# ==> All checks passed.
```

## License

MIT — see [LICENSE](LICENSE).

Before first use, follow the instructions in:
- [`third-party/ecc/LICENSE`](third-party/ecc/LICENSE)
- [`third-party/superpowers/LICENSE`](third-party/superpowers/LICENSE)

to fetch upstream LICENSE copies (required for MIT/Apache compliance).

## Credits

This framework is inspired by and cherry-picks from these open-source projects:

- [obra/superpowers](https://github.com/obra/superpowers) — Skill-triggered workflow methodology
- [affaan-m/ECC](https://github.com/affaan-m/ECC) — 60 agents + 232 skills + 75 commands, multi-language ecosystem

**Special note**: This project uses **full cherry-pick** of all 271 ECC skills and 70 ECC agents, complying with their MIT License / project-specific licenses. If you want a curated subset, you can pick from [`skills/INDEX-by-category.md`](skills/INDEX-by-category.md) and adjust the `ECC_SKILLS` array in `sync-third-party.sh` (`ECC_AGENTS` is already auto-discovered, no manual maintenance needed).