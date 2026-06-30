import yaml
with open('skills/_layer.yaml') as f:
    d = yaml.safe_load(f)
core = set(d.get('core', []))
peri = set(d.get('peripheral', []))
arch = set(d.get('archived', []))
must_have = [
    'test-driven-development', 'systematic-debugging', 'requesting-code-review',
    'verification-before-completion', 'brainstorming', 'writing-plans',
    'executing-plans', 'planning-with-files', 'code-review', 'security-review',
    'refactor-safely', 'playwright', 'deep-research',
    'verification-loop', 'dispatching-parallel-agents', 'subagent-driven-development',
    'cursor-orchestration', 'claude-orchestration',
    'receiving-code-review', 'simplify', 'find-skills', 'skill-vetter',
    'superdesign', 'ui-ux-pro-max', 'frontend-design', 'architecture-patterns',
    'security-auditor', 'prompt-engineering-expert', 'self-improving',
    'using-git-worktrees', 'tdd-workflow', 'security-bounty-hunter',
    'project-planner', 'summarize', 'agent-browser',
]
print(f'total: core={len(core)} peri={len(peri)} arch={len(arch)}')
missing = []
for s in must_have:
    if s in core:
        loc = 'CORE'
    elif s in peri:
        loc = 'PERIPHERAL'
        missing.append((s, loc))
    elif s in arch:
        loc = 'ARCHIVED'
        missing.append((s, loc))
    else:
        loc = 'MISSING'
        missing.append((s, loc))
    print(f'  {s}: {loc}')
print(f'\nMissing from core: {len(missing)}')
for s, loc in missing:
    print(f'  {s} ({loc})')