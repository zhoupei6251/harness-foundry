#!/usr/bin/env python3
"""
Novel Mechanical Scorer — 无 LLM 的确定性章节质量评分
========================================================

借鉴 autonovel (NousResearch) 的"机械评分器"概念：
- 纯规则/正则扫描，无 LLM 调用，零 API 成本
- 在 LLM 审稿前先做机械检查，过滤低级问题
- 输出结构化 JSON，可被 LLM 审稿器引用

架构：
  autonovel  evaluate.py  ─→  本脚本 mechanical_scorer.py
  机械评分器 (无LLM)          + 中文网文专属规则

用法：
  python mechanical_scorer.py <章节文件路径> [--checklist]
"""

import re
import sys
import json
import os
from pathlib import Path
from collections import Counter
from typing import List, Dict, Tuple, Optional


# ═══════════════════════════════════════════════════════════════
# 配置 — 借鉴 autonovel evaluate.py 的检查维度
# ═══════════════════════════════════════════════════════════════

# 参考: autonovel 的 BANNED_PATTERNS + 我们 traps-archive 的 82 条陷阱

class CheckResult:
    """单条检查结果"""
    def __init__(self, check_id: str, category: str, severity: str,
                 line: int, context: str, message: str, suggestion: str):
        self.check_id = check_id
        self.category = category
        self.severity = severity  # BLOCK | WARN | INFO
        self.line = line
        self.context = context
        self.message = message
        self.suggestion = suggestion

    def to_dict(self) -> dict:
        return {
            "check_id": self.check_id,
            "category": self.category,
            "severity": self.severity,
            "line": self.line,
            "context": self.context,
            "message": self.message,
            "suggestion": self.suggestion
        }


class MechanicalScorer:
    """机械评分器 — 纯规则，无 LLM"""

    def __init__(self, filepath: str):
        self.filepath = filepath
        self.text = ""
        self.lines = []
        self.findings: List[CheckResult] = []
        self.stats = {}

        # 加载章节
        if os.path.exists(filepath):
            with open(filepath, "r", encoding="utf-8") as f:
                raw_text = f.read()

            # 剥离 Markdown 格式，提取纯文本
            self.text = self._strip_markdown(raw_text)
            self.lines = [l for l in self.text.split("\n") if l.strip()]

    def _strip_markdown(self, raw: str) -> str:
        """剥离 Markdown 标记，提取纯文本内容"""
        text = raw
        # 移除 YAML frontmatter (--- ... ---)
        text = re.sub(r'^---\s*\n.*?\n---\s*\n', '', text, flags=re.DOTALL)
        # 移除标题标记 (# ## ###)
        text = re.sub(r'^#{1,6}\s+', '', text, flags=re.MULTILINE)
        # 移除粗体/斜体 (**text**, *text*, __text__, _text_)
        text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
        text = re.sub(r'__(.+?)__', r'\1', text)
        text = re.sub(r'\*(.+?)\*', r'\1', text)
        text = re.sub(r'_(.+?)_', r'\1', text)
        # 移除行内代码 (`code`)
        text = re.sub(r'`([^`]+)`', r'\1', text)
        # 移除链接 [text](url) 保留 text
        text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
        # 移除图片 ![alt](url)
        text = re.sub(r'!\[([^\]]*)\]\([^)]+\)', r'\1', text)
        # 移除引用标记 (> )
        text = re.sub(r'^>\s?', '', text, flags=re.MULTILINE)
        # 移除水平分割线 (---, ***, ___)
        text = re.sub(r'^[-*_]{3,}\s*$', '', text, flags=re.MULTILINE)
        # 移除 HTML 标签
        text = re.sub(r'<[^>]+>', '', text)
        # 移除多余空行
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text

    # ═════════════════════════════════════════════════════════
    # 字数检查 (参考 autonovel BANNED_PATTERNS → 字数基准)
    # ═════════════════════════════════════════════════════════

    def check_word_count(self) -> None:
        """检查字数是否达标"""
        # 中文：统计纯文本字符数（排除空行和纯英文空格）
        clean_text = self.text.replace("\n", "").replace(" ", "").replace("\t", "")
        # 排除英文标点和常见英文单词
        clean_text = re.sub(r'[a-zA-Z0-9\[\]{}()<>&#@$%^*/\\|~`\'"]+', '', clean_text)
        count = len(clean_text)
        self.stats["char_count"] = count
        self.stats["line_count"] = len(self.lines)

        if count < 500:
            self.findings.append(CheckResult(
                "WC-001", "字数", "BLOCK",
                0, "",
                f"字数严重不足：{count} 字（要求 ≥2000 字）",
                "继续扩写至达标"
            ))
        elif count < 1800:
            self.findings.append(CheckResult(
                "WC-002", "字数", "WARN",
                0, "",
                f"字数不足：{count} 字（要求 ≥2000 字, 差距较大）",
                "建议扩写至2000字以上"
            ))
        elif count < 2000:
            self.findings.append(CheckResult(
                "WC-002b", "字数", "INFO",
                0, "",
                f"字数略少：{count} 字（距2000字目标差{2000 - count}字）",
                "可稍微扩写"
            ))
        elif count < 5000:
            self.findings.append(CheckResult(
                "WC-003", "字数", "INFO",
                0, "",
                f"字数正常：{count} 字",
                ""
            ))
        else:
            self.findings.append(CheckResult(
                "WC-004", "字数", "WARN",
                0, "",
                f"字数偏多：{count} 字（建议控制在 5000 字以内）",
                "考虑分段或拆分"
            ))

    # ═════════════════════════════════════════════════════════
    # AI 高频词汇扫描 (参考 autonovel BANNED_PATTERNS)
    # ═════════════════════════════════════════════════════════

    AI_PATTERNS = [
        # (检查ID, 正则模式, 说明, 替换建议)
        ("AI-001", r"眼中闪过一丝", "AI 高频表情描写 #8",
         "改为具体肢体语言，如'攥紧拳头' '后退半步'"),
        ("AI-002", r"嘴角勾起一抹", "AI 高频微笑描写 #9",
         "改为更自然的表情变化，如'笑了一下' '嘴角动了动'"),
        ("AI-003", r"深吸一口气", "AI 高频情绪前奏 #10",
         "直接写人物行动或心理"),
        ("AI-004", r"首先.*其次|首先.*然后.*最后", "滥用列举式连接词 #1",
         "用自然叙事过渡替代"),
        ("AI-005", r"就在这时|突然之间[^，]", "俗套过渡 #4",
         "用动作/环境变化自然过渡"),
        ("AI-006", r"只见[^，]{0,10}，", "俗套叙述视角 #4",
         "直接描述场景，不用'只见'"),
        ("AI-007", r"预知后事如何|且听下回分解", "万能结尾 #5",
         "用具体悬念钩子替代"),
        ("AI-008", r"仿佛[^，]{0,20}，|似乎[^，]{0,20}，", "'仿佛/似乎'过度使用 #15",
         "直接陈述，减少模糊化"),
        ("AI-009", r"不仅[^，]+，[^，]+，[^，]+而且", "三段式法则 #11",
         "打破固定句式节奏"),
        ("AI-010", r"不是[^，]+，不是[^，]+，而是", "否定式排比 #13",
         "直接说'是C'"),
        ("AI-011", r"不仅如此|更令人惊讶的是|值得注意的是", "连接性短语泛滥 #14",
         "删除，让内容自然衔接"),
        ("AI-012", r"今天就这样|本章完|今天就到这里", "万能结尾标志",
         "改为具体悬念或转折"),
        ("AI-013", r"微微一笑|淡淡一笑|苦笑一声|轻轻一笑", "AI 高频笑容组合",
         "用更个性化的表情替代"),
        ("AI-014", r"心中[一不]?[由暗]?[得觉]?[感]?[想思]", "AI 高频心理描写",
         "通过行为或对话间接表达内心"),
        ("AI-015", r"不由得|情不自禁|不由自主", "AI 高频情感表达",
         "通过具体动作展现情感"),
    ]

    def check_ai_patterns(self) -> None:
        """扫描 AI 高频词汇和套路化表达"""
        for check_id, pattern, desc, suggestion in self.AI_PATTERNS:
            for i, line in enumerate(self.lines, 1):
                if not line.strip() or line.strip().startswith("#"):
                    continue
                matches = re.findall(pattern, line)
                for match in matches:
                    self.findings.append(CheckResult(
                        check_id, "AI痕迹", "WARN",
                        i, match.strip()[:30], f"{desc}: 发现 '{match.strip()[:20]}'",
                        suggestion
                    ))

    # ═════════════════════════════════════════════════════════
    # 标点检查
    # ═════════════════════════════════════════════════════════

    def check_punctuation(self) -> None:
        """检查标点符号规范"""
        has_halfwidth = False
        halfwidth_lines = []

        for i, line in enumerate(self.lines, 1):
            # 跳过空行和标题行
            if not line.strip() or line.strip().startswith("#"):
                continue

            # 检测英文标点
            english_commas = len(re.findall(r"(?<![a-zA-Z0-9]),", line))
            english_periods = len(re.findall(r"(?<![a-zA-Z0-9])\.", line))

            if english_commas > 0 or english_periods > 0:
                has_halfwidth = True
                halfwidth_lines.append(i)

        self.stats["halfwidth_punctuation_lines"] = len(halfwidth_lines)

        if has_halfwidth:
            self.findings.append(CheckResult(
                "PUN-001", "标点", "WARN",
                halfwidth_lines[0] if halfwidth_lines else 0,
                f"共 {len(halfwidth_lines)} 行",
                f"发现 {len(halfwidth_lines)} 行使用了英文标点（半角逗号/句号）",
                "全文替换为全角中文标点：，，。。 ！! ？？"
            ))

    # ═════════════════════════════════════════════════════════
    # 句长均匀度检查 (参考 autonovel sentence-length uniformity)
    # ═════════════════════════════════════════════════════════

    def check_sentence_variety(self) -> None:
        """检查句长是否变化多样"""
        sentence_lengths = []
        for line in self.lines:
            # 按中文标点分句
            parts = re.split(r"[，。！？；：、]", line)
            for part in parts:
                length = len(part.strip())
                if 3 <= length <= 100:  # 过滤太短和太长的
                    sentence_lengths.append(length)

        if not sentence_lengths:
            return

        avg_len = sum(sentence_lengths) / len(sentence_lengths)
        # 计算句长标准差
        variance = sum((l - avg_len) ** 2 for l in sentence_lengths) / len(sentence_lengths)
        std_dev = variance ** 0.5

        self.stats["avg_sentence_length"] = round(avg_len, 1)
        self.stats["sentence_count"] = len(sentence_lengths)
        self.stats["sentence_std_dev"] = round(std_dev, 1)

        # autonovel 的核心发现：句长太均匀是 AI 特征
        if std_dev < 5.0:
            self.findings.append(CheckResult(
                "STY-001", "句式", "WARN",
                0, f"句长标准差 = {std_dev:.1f}",
                f"句长过于均匀（标准差 {std_dev:.1f}），疑似 AI 写作特征",
                "增加长短句交替：短句加速节奏，长句放慢展开"
            ))

        # 连续短句检查
        short_runs = 0
        max_short_run = 0
        for l in sentence_lengths:
            if l < 8:
                short_runs += 1
                max_short_run = max(max_short_run, short_runs)
            else:
                short_runs = 0

        if max_short_run > 8:
            self.findings.append(CheckResult(
                "STY-002", "句式", "WARN",
                0, f"连续 {max_short_run} 个短句",
                f"发现连续 {max_short_run} 个短句，可能节奏过碎",
                "在短句间插入 1-2 句中等长度的描述或心理活动"
            ))

        # 连续长句检查
        long_runs = 0
        max_long_run = 0
        for l in sentence_lengths:
            if l > 25:
                long_runs += 1
                max_long_run = max(max_long_run, long_runs)
            else:
                long_runs = 0

        if max_long_run > 5:
            self.findings.append(CheckResult(
                "STY-003", "句式", "INFO",
                0, f"连续 {max_long_run} 个长句",
                f"发现连续 {max_long_run} 个长句，可能阅读负担重",
                "用短句或对话打断长句序列"
            ))

    # ═════════════════════════════════════════════════════════
    # Show-Don't-Tell 检查 (参考 autonovel show-don't-tell violations)
    # ═════════════════════════════════════════════════════════

    TELL_PATTERNS = [
        (r"他很[^，]{0,5}", "直接说'他很X'，应改为通过行为展现"),
        (r"她觉得很[^，]{0,5}", "直接说'她觉得X'，应改为通过行为展现"),
        (r".{0,5}心里很不", "直接描述内心状态，应通过外在行为展现"),
        (r"感到一阵.{0,8}", "'感到一阵X'是典型的 Telling"),
        (r"非常[^，]{1,4}地", "'非常X地'是形容词堆砌"),
    ]

    def check_show_dont_tell(self) -> None:
        """检查 Show-Don't-Tell 违规"""
        total_tells = 0
        for i, line in enumerate(self.lines, 1):
            for pattern, desc in self.TELL_PATTERNS:
                matches = re.findall(pattern, line)
                if matches:
                    total_tells += len(matches)

        self.stats["tell_violations"] = total_tells

        if total_tells > 10:
            self.findings.append(CheckResult(
                "SDT-001", "叙事", "WARN",
                0, f"发现 {total_tells} 处",
                f"Show-Don't-Tell 违规偏多（{total_tells} 处），存在大量告知而非展示",
                "改为通过人物行为、对话、环境细节间接展现情感和状态"
            ))
        elif total_tells > 5:
            self.findings.append(CheckResult(
                "SDT-002", "叙事", "INFO",
                0, f"发现 {total_tells} 处",
                f"存在 {total_tells} 处 Show-Don't-Tell 可优化",
                "检查是否有可以改为'展示'的'告知'"
            ))

    # ═════════════════════════════════════════════════════════
    # 对话占比检查
    # ═════════════════════════════════════════════════════════

    def check_dialogue_ratio(self) -> None:
        """检查对话在章节中的占比"""
        dialogue_chars = 0
        total_chars = len(self.text.replace("\n", "").replace(" ", ""))

        for line in self.lines:
            # 统计引号内的文字
            dialogue_in_line = len(re.findall(r'"([^"]*)"', line))
            dialogue_in_line += len(re.findall(r"'([^']*)'", line))
            dialogue_in_line += len(re.findall(r"「([^」]*)」", line))
            dialogue_in_line += len(re.findall(r"『([^』]*)』", line))
            dialogue_chars += dialogue_in_line

        ratio = dialogue_chars / total_chars * 100 if total_chars > 0 else 0
        self.stats["dialogue_ratio"] = round(ratio, 1)

        if ratio > 60:
            self.findings.append(CheckResult(
                "DLG-001", "对话", "WARN",
                0, f"对话占比 {ratio:.1f}%",
                "对话占比过高（>60%），可能缺乏动作和场景描写",
                "增加动作描写、环境描写、内心独白"
            ))
        elif ratio < 10:
            self.findings.append(CheckResult(
                "DLG-002", "对话", "INFO",
                0, f"对话占比 {ratio:.1f}%",
                "对话占比过低（<10%），可能过于静态",
                "增加人物互动和对话"
            ))

    # ═════════════════════════════════════════════════════════
    # 段落长度检查
    # ═════════════════════════════════════════════════════════

    def check_paragraph_length(self) -> None:
        """检查段落长度是否合理"""
        paragraphs = []
        current = ""

        for line in self.lines:
            stripped = line.strip()
            if stripped == "":
                if current:
                    paragraphs.append(current)
                    current = ""
            else:
                current += stripped

        if current:
            paragraphs.append(current)

        long_paras = [p for p in paragraphs if len(p) > 500]
        self.stats["paragraph_count"] = len(paragraphs)
        self.stats["long_paragraph_count"] = len(long_paras)

        if long_paras:
            self.findings.append(CheckResult(
                "PAR-001", "段落", "INFO",
                0, f"{len(long_paras)} 个段落",
                f"发现 {len(long_paras)} 个超过 500 字的长段落，可能阅读疲劳",
                "在适当位置分段或用对话打断"
            ))

    # ═════════════════════════════════════════════════════════
    # 钩子检查
    # ═════════════════════════════════════════════════════════

    HOOK_INDICATORS = [
        (r"预知后事|下回分解|下章再见|下回再续|今天就到|未完待续", "万能结尾 — 无具体钩子"),
        (r"心里暗暗.{0,10}决定", "内心决定型钩子 — 偏弱"),
        (r"不知道.{0,15}会发生什么", "概括性钩子 — 不够具体"),
    ]

    def check_hook(self) -> None:
        """检查章节结尾钩子"""
        # 取最后 20 行作为结尾
        end_lines = self.lines[-20:] if len(self.lines) > 20 else self.lines
        end_text = "\n".join(end_lines)

        has_bad_hook = False
        for pattern, desc in self.HOOK_INDICATORS:
            if re.search(pattern, end_text):
                self.findings.append(CheckResult(
                    "HOK-001", "钩子", "WARN",
                    len(self.lines) - 20,
                    re.search(pattern, end_text).group()[:30] if re.search(pattern, end_text) else "",
                    f"章节结尾使用了 {desc}",
                    "改为具体的悬念：信息差悬念、反转型钩子、冲突未解决"
                ))
                has_bad_hook = True

        # 检查结尾是否太短或太平淡
        end_line_count = 0
        for line in reversed(self.lines):
            if line.strip():
                end_line_count += 1
            if end_line_count >= 3:
                break

        # 最后 3 行是否包含冲突、悬念、问题
        last_3_lines = [l for l in self.lines[-3:] if l.strip()]
        has_tension = any(
            re.search(pattern, "\n".join(last_3_lines))
            for pattern in [r"\?", r"！", r"危险", r"暗", r"秘密", r"诡异", r"不对劲"]
        )

        if not has_tension and not has_bad_hook:
            self.findings.append(CheckResult(
                "HOK-002", "钩子", "WARN",
                len(self.lines) - 3,
                "\n".join(last_3_lines)[:40],
                "章节结尾过于平淡，缺乏悬念或张力",
                "在结尾加上悬念钩子：新的威胁、未解的疑问、意外的发现"
            ))

    # ═════════════════════════════════════════════════════════
    # OVER-EXPLAIN 检查 (参考 autonovel #1 发现)
    # ═════════════════════════════════════════════════════════

    OVER_EXPLAIN_PATTERNS = [
        (r"这意味[着]?[^，。！？]{0,15}", "旁白解释（narrator explains）— OVER-EXPLAIN"),
        (r"也就是说[^，。！？]{0,15}", "重复解释 — REDUNDANT"),
        (r"换句话[说]?[^，。！？]{0,15}", "重复表述 — REDUNDANT"),
        (r"简单[来]?[说][^，。！？]{0,15}", "过度简化解释 — OVER-EXPLAIN"),
    ]

    def check_over_explain(self) -> None:
        """检查 OVER-EXPLAIN 和 REDUNDANT (autonovel 最重要的 2 个发现)"""
        total = 0
        for i, line in enumerate(self.lines, 1):
            for pattern, desc in self.OVER_EXPLAIN_PATTERNS:
                if re.search(pattern, line):
                    total += 1

        self.stats["over_explain_count"] = total

        if total > 5:
            self.findings.append(CheckResult(
                "OEX-001", "冗余", "WARN",
                0, f"发现 {total} 处",
                f"OVER-EXPLAIN / REDUNDANT 过多（{total} 处）— 旁白解释了场景已经展示的内容",
                "删除解释性句子，相信读者能从场景和对话中理解"
            ))

    # ═════════════════════════════════════════════════════════
    # 主流程：运行所有检查
    # ═════════════════════════════════════════════════════════

    def run_all(self) -> dict:
        """运行所有检查，返回评分报告"""
        checks = [
            self.check_word_count,
            self.check_ai_patterns,
            self.check_punctuation,
            self.check_sentence_variety,
            self.check_show_dont_tell,
            self.check_dialogue_ratio,
            self.check_paragraph_length,
            self.check_hook,
            self.check_over_explain,
        ]

        for check_fn in checks:
            try:
                check_fn()
            except Exception as e:
                self.findings.append(CheckResult(
                    "ERR-001", "系统", "INFO",
                    0, "", f"检查 '{check_fn.__name__}' 执行失败: {e}", ""
                ))

        return self.build_report()

    def build_report(self) -> dict:
        """构建结构化报告"""

        # 按严重程度分组
        blocks = [f for f in self.findings if f.severity == "BLOCK"]
        warns = [f for f in self.findings if f.severity == "WARN"]
        infos = [f for f in self.findings if f.severity == "INFO"]

        # 计算机械评分 (100 分制)
        score = 100
        score -= len(blocks) * 20  # 每个 BLOCK 扣 20 分
        score -= len(warns) * 5     # 每个 WARN 扣 5 分
        score -= len(infos) * 1     # 每个 INFO 扣 1 分
        score = max(0, min(100, score))

        # 计算各维度得分
        categories = {}
        for f in self.findings:
            cat = f.category
            if cat not in categories:
                categories[cat] = {"total": 0, "blocks": 0, "warns": 0, "infos": 0}
            categories[cat]["total"] += 1
            if f.severity == "BLOCK":
                categories[cat]["blocks"] += 1
            elif f.severity == "WARN":
                categories[cat]["warns"] += 1
            else:
                categories[cat]["infos"] += 1

        # autonovel 风格的处理建议
        processing = self._get_processing_decision(blocks, warns)

        return {
            "meta": {
                "tool": "novel-mechanical-scorer",
                "version": "1.0.0",
                "file": self.filepath,
                "inspiration": "autonovel evaluate.py (NousResearch)"
            },
            "score": score,
            "max_score": 100,
            "findings_count": {
                "total": len(self.findings),
                "block": len(blocks),
                "warn": len(warns),
                "info": len(infos)
            },
            "categories": categories,
            "findings": [f.to_dict() for f in self.findings],
            "stats": self.stats,
            "processing": processing,
            "comparative": {
                "autonovel_mechanical_score": score,
                "note": "机械评分仅供参考，不代表文学质量，需要 LLM 审稿器补充判断"
            }
        }

    def _get_processing_decision(self, blocks, warns) -> dict:
        """决定处理方式 — 借鉴 autonovel 的 modify-evaluate-keep/discard 循环"""
        if len(blocks) > 0:
            return {
                "decision": "BLOCK",
                "action": "拒绝交付 — 存在严重机械问题，必须先修复再提交 LLM 审稿",
                "next": "修复所有 BLOCK 级别的发现，重新运行机械评分器"
            }
        elif len(warns) > 10:
            return {
                "decision": "WARN",
                "action": "可以提交 LLM 审稿，但建议先修复 WARN 级别的发现",
                "next": "修复主要 WARN 后提交，或直接提交但标注已知问题"
            }
        else:
            return {
                "decision": "PASS",
                "action": "机械评分通过，可以提交 LLM 审稿",
                "next": "提交给 novel-evaluator 进行 7 维 LLM 审稿"
            }


# ═════════════════════════════════════════════════════════
# CLI
# ═════════════════════════════════════════════════════════

def print_checklist(findings: List[CheckResult]) -> None:
    """打印人类可读的检查清单"""
    print("\n" + "=" * 60)
    print("  📋 Novel Mechanical Scorer — 检查清单")
    print("  借鉴 autonovel (NousResearch) 机械评分器")
    print("=" * 60)

    blocks = [f for f in findings if f.severity == "BLOCK"]
    warns = [f for f in findings if f.severity == "WARN"]
    infos = [f for f in findings if f.severity == "INFO"]

    def print_group(title, items):
        if not items:
            return
        print(f"\n{'─' * 50}")
        print(f"  {title}（{len(items)} 项）")
        print(f"{'─' * 50}")
        for f in items:
            print(f"  [{f.severity:5s}] {f.check_id}: {f.message}")
            if f.line > 0:
                print(f"           行 {f.line}: {f.context}")
            print(f"           建议: {f.suggestion}")
            print()

    print_group("🔴 BLOCK — 必须修复", blocks)
    print_group("🟡 WARN — 建议修复", warns)
    print_group("🔵 INFO — 参考信息", infos)

    if not findings:
        print("\n  ✅ 无发现问题！机械评分通过。")

    print("\n" + "=" * 60)
    print("  ⚠ 机械评分仅供参考，不代表文学质量")
    print("  完整审稿请使用 novel-evaluator（7 维 LLM 审稿）")
    print("=" * 60 + "\n")


def main():
    if len(sys.argv) < 2:
        print("用法: python mechanical_scorer.py <章节文件路径> [--checklist] [--json]")
        print()
        print("示例:")
        print("  python mechanical_scorer.py 章节正文/第1章_xxx.md")
        print("  python mechanical_scorer.py 章节正文/第1章_xxx.md --checklist")
        print("  python mechanical_scorer.py 章节正文/第1章_xxx.md --json")
        sys.exit(1)

    filepath = sys.argv[1]
    use_checklist = "--checklist" in sys.argv
    use_json = "--json" in sys.argv

    if not os.path.exists(filepath):
        print(f"错误: 文件不存在 — {filepath}")
        sys.exit(1)

    scorer = MechanicalScorer(filepath)
    report = scorer.run_all()

    if use_json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    elif use_checklist:
        print_checklist(scorer.findings)
        print(f"\n机械评分: {report['score']}/100")
        print(f"处理决定: {report['processing']['decision']}")
        print(f"            {report['processing']['action']}")
    else:
        # 默认输出: 简短摘要
        blocks = report['findings_count']['block']
        warns = report['findings_count']['warn']
        infos = report['findings_count']['info']
        print(f"机械评分: {report['score']}/100")
        print(f"发现: {blocks} BLOCK, {warns} WARN, {infos} INFO")
        print(f"处理: {report['processing']['decision']}")
        print(f"统计: 字数={report['stats'].get('char_count', '?')}, "
              f"句长标准差={report['stats'].get('sentence_std_dev', '?')}, "
              f"对话占比={report['stats'].get('dialogue_ratio', '?')}%")
        print()
        print("详细报告: python mechanical_scorer.py <文件> --checklist")
        print("JSON 输出: python mechanical_scorer.py <文件> --json")


if __name__ == "__main__":
    main()
