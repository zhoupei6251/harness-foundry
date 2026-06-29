#!/usr/bin/env python3
# ============================================================
#  _must_core_skills.py
#  强制 core 层的 Skill 白名单（人工审核兜底）
#
#  来源：
#  1. core/orchestration/skill-preferences.md 路由表实际路由的 skill
#  2. scripts/_skill_meta.py SKILL_META 中标记为 workflow 工具的核心 skill
#  3. 用户在主任务里点名要求保护的核心 skill
#
#  设计原则：
#  - 保守策略，宁可漏不可错：漏了最多进 peripheral/archived 而非 core；
#    错了会污染 core 层（≤80 限制）。
#  - 分类器最优先使用此名单，确保核心 skill 不会因 P1 路由正则缺陷
#    被降级到 archived。
# ============================================================

MUST_CORE = {
    # === TDD 核心（路由表 + _skill_meta 双重标注） ===
    "test-driven-development",
    "systematic-debugging",
    "requesting-code-review",
    "receiving-code-review",
    "verification-before-completion",
    "verification-loop",

    # === 规划 / 设计 / 流程（Leader 阶段必用 skill） ===
    "brainstorming",
    "writing-plans",
    "executing-plans",
    "planning-with-files",
    "project-planner",

    # === 审查 / 重构（review 流程核心） ===
    "code-review",
    "security-review",
    "refactor-safely",
    "simplify",

    # === Agent / 编排（路由表显式路由） ===
    "dispatching-parallel-agents",
    "subagent-driven-development",
    "using-git-worktrees",
    "cursor-orchestration",
    "agent-browser",

    # === 研究 / 工具型工作流 ===
    "deep-research",
    "playwright",
    "find-skills",
    "skill-vetter",
    "summarize",
    "self-improving",

    # === Prompt / 设计系统 ===
    "prompt-engineering-expert",
    "architecture-patterns",
    "superdesign",
    "ui-ux-pro-max",
    "frontend-design",

    # === 安全 / 测试 ===
    "security-auditor",
    "security-bounty-hunter",
    "tdd-workflow",
}


def must_core() -> set:
    """返回 MUST_CORE 集合的副本（防止外部修改）"""
    return set(MUST_CORE)