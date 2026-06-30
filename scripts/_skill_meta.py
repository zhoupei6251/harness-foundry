#!/usr/bin/env python3
# ============================================================
#  _skill_meta.py
#  共享模块：Skill 元数据映射表（单一真相源）
#  被 rebuild-skill-metas.py 和 apply-skill-categories.py 共用
#
#  slug → (category, domain, tags)
# ============================================================

SKILL_META = {
    # code 域
    "architecture-patterns": ("code.architecture", "code", ["architecture", "backend", "DDD", "clean"]),
    "code-review": ("code.review", "code", ["review", "quality"]),
    "refactor-safely": ("code.review", "code", ["refactor", "safe"]),
    "requesting-code-review": ("code.review", "code", ["review", "workflow"]),
    "simplify": ("code.review", "code", ["simplify", "quality"]),
    "verification-before-completion": ("code.testing", "code", ["verify", "completion"]),
    "security-auditor": ("code.security", "code", ["security", "audit"]),
    "dispatching-parallel-agents": ("code.ai-agent", "code", ["parallel", "agent", "dispatch"]),
    "subagent-driven-development": ("code.ai-agent", "code", ["SDD", "agent", "subagent"]),
    "prompt-engineering-expert": ("code.ai-agent", "code", ["prompt", "LLM"]),
    "self-improving": ("code.ai-agent", "code", ["self-improve", "learning"]),
    "superdesign": ("code.frontend", "code", ["design", "UI"]),
    "ui-ux-pro-max": ("code.frontend", "code", ["UI", "UX"]),
    "using-git-worktrees": ("code.tooling", "code", ["git", "worktree"]),

    # novel 域
    "inkos": ("novel.creation", "novel", ["创作", "系统"]),
    "novel-generator": ("novel.creation", "novel", ["爽文", "生成"]),
    "story-cog": ("novel.creation", "novel", ["creative", "writing"]),
    "humanizer": ("novel.polish", "novel", ["humanizer", "AI痕迹"]),
    "fanqie": ("novel.publish", "novel", ["番茄", "平台"]),
    "fanqie-novel-auto-publish": ("novel.publish", "novel", ["番茄", "自动发布"]),
    "web-novel-publishing-readiness-and-quality-check-skill": ("novel.publish", "novel", ["发布", "质检"]),
    "novel-to-drama-script": ("novel.transform", "novel", ["短剧", "剧本"]),

    # shared 域
    "brainstorming": ("shared.planning", "shared", ["头脑风暴", "设计"]),
    "writing-plans": ("shared.planning", "shared", ["plan", "writing"]),
    "executing-plans": ("shared.planning", "shared", ["plan", "execute"]),
    "planning-with-files": ("shared.planning", "shared", ["plan", "files"]),
    "project-planner": ("shared.planning", "shared", ["plan", "project"]),
    "deep-research": ("shared.research", "shared", ["研究", "搜索"]),
    "playwright": ("shared.workflow", "shared", ["browser", "automation"]),
    "find-skills": ("shared.workflow", "shared", ["skill", "discover"]),
    "skill-vetter": ("shared.workflow", "shared", ["skill", "vet", "security"]),
    "auto-updater": ("shared.workflow", "shared", ["update", "cron"]),
    "free-ride": ("shared.workflow", "shared", ["model", "free"]),
    "summarize": ("shared.workflow", "shared", ["summarize"]),
    "edge-tts": ("shared.media", "shared", ["TTS", "voice"]),
    "pdf": ("shared.docs", "shared", ["pdf", "document"]),
    "word-docx": ("shared.docs", "shared", ["word", "document"]),
    "excel-xlsx": ("shared.docs", "shared", ["excel", "spreadsheet"]),
    "human-writing": ("shared.docs", "shared", ["writing", "human"]),
}
