#!/usr/bin/env python3
"""
code-trap-scanner — Java/Spring Boot 代码陷阱扫描器

把 traps-archive/code/00-all.md 中可机器检查的禁令子集做成可执行引擎，
对齐 novel 域引擎模式（novel_memory_health 等）：argparse CLI + --json 输出。

当前检测 11 类禁令（对应 00-all.md 条目）：
  EMPTY_CATCH           空 catch 吞异常            #9  / 规则7
  SELECT_STAR           SELECT * 拉全字段          #48
  N_PLUS_ONE            for 循环内查库/发 SQL       #13 / #51
  HTTP_IN_LOOP          循环内发 HTTP 请求          #57
  SQL_CONCAT           ${xxx} / 字符串拼接 SQL      #60 / #61
  HARDCODED_SECRET      硬编码密码/JWT/API Key      #66(日志) / #73 / #160
  SETNX_LOCK            手写 setnx+expire 分布式锁  #82
  LOG_SENSITIVE         日志打印敏感信息            #66 / #121
  SYSTEM_OUT            System.out.println 直出     #日志规范
  MAGIC_NUMBER          裸数字魔法数                #编码标准
  VIRTUAL_THREAD_SYNC   虚拟线程内 synchronized     #26 / #35

用法：
    python code_trap_scanner.py <文件或目录>          # 扫描，可读报告
    python code_trap_scanner.py <文件或目录> --json   # JSON 输出
    python code_trap_scanner.py <文件或目录> --alert  # 只输出问题
    python code_trap_scanner.py <文件或目录> --fail-on-error  # 有问题则退出码 1

说明：
    - 语义级禁令（事务边界、AOP 自调用、缓存一致性等）无法纯静态检测，
      不在本扫描器范围——由 ecc:java-reviewer / silent-failure-hunter 覆盖。
"""

import re
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Dict

# ─────────────────────────────────────────────
# 常量
# ─────────────────────────────────────────────

# 硬编码密钥的最小长度（避免误报 test 里的占位符）
SECRET_MIN_LEN = 6

# 日志敏感字段
SENSITIVE_FIELDS = r"(password|passwd|pwd|token|secret|credential|apiKey|accessKey|privateKey|idCard|mobile|phone)"

# 虚拟线程构造名
VIRTUAL_THREAD_NAMES = r"(Thread\.ofVirtual|newVirtualThreadPerTaskExecutor|Executors\.newVirtualThread)"

# 扫描的源码后缀
JAVA_SUFFIXES = {".java", ".kt", ".scala"}

# 跳过目录
SKIP_DIRS = {"target", "node_modules", ".git", "build", ".venv", "venv", "__pycache__"}


@dataclass
class Finding:
    """单条命中"""
    rule_id: str
    message: str
    file: str
    line: int = 0
    severity: str = "ERROR"  # ERROR | WARN


@dataclass
class ScanResult:
    """扫描结果"""
    files_scanned: int = 0
    findings: List[Finding] = field(default_factory=list)

    def add(self, rule_id: str, message: str, file: str, line: int = 0, severity: str = "ERROR"):
        self.findings.append(Finding(rule_id=rule_id, message=message, file=file, line=line, severity=severity))

    @property
    def error_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == "ERROR")

    @property
    def warn_count(self) -> int:
        return sum(1 for f in self.findings if f.severity == "WARN")

    @property
    def rule_hits(self) -> Dict[str, int]:
        hits: Dict[str, int] = {}
        for f in self.findings:
            hits[f.rule_id] = hits.get(f.rule_id, 0) + 1
        return hits


# ─────────────────────────────────────────────
# 扫描原语
# ─────────────────────────────────────────────

def _line_of(content: str, pos: int) -> int:
    """把字符位置换算成 1-based 行号"""
    return content.count("\n", 0, pos) + 1


def _is_in_comment(content: str, pos: int) -> bool:
    """粗略判断位置是否在 /* */ 块注释内（去掉已闭合的块注释后仍有未闭合的 /*）"""
    before = content[:pos]
    stripped = re.sub(r"/\*.*?\*/", "", before, flags=re.DOTALL)
    return "/*" in stripped


def _find_empty_catches(content: str) -> List[int]:
    """空 catch 块（块内无语句）→ 行号列表。兼容跨行块。"""
    lines: List[int] = []
    for m in re.finditer(r"catch[^{]*\{([^{}]*)\}", content, re.DOTALL):
        body = m.group(1)
        if not re.search(r";|return|throw|log\.|continue|break", body):
            lines.append(_line_of(content, m.start()))
    return lines


def _find_magic_numbers(content: str) -> List[int]:
    """裸数字魔法数 → 行号列表。

    启发式：只抓**无上下文的孤立数字常量**，保守策略——宁可漏报不误报：
      - 排除: 任何带名字的数字（枚举名、注解参数、赋值、超时、HTTP 状态码、return 0/1/-1、年份）
      - 命中: 无参数名的孤立数字结尾（如 `result = x * 299;` 中的 299、`return 65;`）
    行号在**原文本**上计算（删注释保留换行符，避免行号漂移）。
    """
    hits: List[int] = []
    # 删注释但保留换行符（避免多行块注释删除后行号上移）
    stripped = re.sub(
        r"/\*.*?\*/",
        lambda m: "\n" * m.group(0).count("\n"),
        content, flags=re.DOTALL
    )
    stripped = re.sub(r"//[^\n]*", "", stripped)
    for i, line in enumerate(stripped.split("\n"), 1):
        s = line.strip()
        if not s or s.startswith(("import ", "package ")):
            continue
        # 任何带名字的数字（字母紧邻数字=标识符/枚举名；赋值、注解参数、超时、HTTP 状态码）→ 排除
        if re.search(
            r"[a-zA-Z_]\d|\d[a-zA-Z_]|=\s*[0-9]+|sleep\s*\(|setTimeout\s*\(|setConnectionTimeout\s*\(|"
            r"setReadTimeout\s*\(|Duration\.of|\.timeout\s*\(|HTTP_[A-Z_]+|SC_\w+|fixedDelay|initialDelay|"
            r"acquireTimeout|expire\s*[=:]|return\s+(0|1|-1)\s*;", s
        ):
            continue
        # 命中：孤立 3-4 位数字结尾（排除年份 19xx/20xx 和 return 2/3 等小数字约定）
        m = re.search(r"([5-9][0-9]{2,}|[1-9][0-9]{3,})\s*[;),]?\s*$", s)
        if m and not re.match(r"(19|20)\d{2}", m.group(1)):
            hits.append(i)
    return hits


def _find_http_in_loop(content: str) -> List[int]:
    """for/while 循环体内有同步 HTTP 调用 → 行号列表（启发式，取循环体前 400 字符）。

    排除两类合法模式：
      - 重试循环（for retry.../for i < maxRetries）——重试本身就该在循环里
      - 异步提交（循环体里 execute(() -> /submit(() ->）——非串行等待
    """
    hits: List[int] = []
    http_call = re.compile(
        r"(restTemplate|restClient|okHttp|httpClient|webClient|feignClient|"
        r"\.postForEntity|\.getForObject|\.exchange\(|\.execute\(|"
        r"\b(RpcClient|HttpUtil|HttpRequest|HttpClient|ApiClient)\w*)"
    )
    async_call = re.compile(r"(execute|submit|submitAsync)\s*\(\s*[()\w\s,]*?->|\.execute\s*\([^)]*\.run\b")
    for m in re.finditer(r"(for\s*\([^)]*\)|while\s*\([^)]*\))\s*\{", content):
        loop_header = content[m.start() : m.end()]
        # 重试循环（for (int retry = 0; retry < maxRetries...）不报
        if re.search(r"retry|maxRetries|attempt", loop_header, re.IGNORECASE):
            continue
        body = content[m.end() : m.end() + 400]
        if http_call.search(body):
            # 循环体只含异步提交 → 不报
            if async_call.search(body) and not re.search(r"\.send\(|\.execute\(\s*(Http|Request|url)|postFor|getForObject|restTemplate", body):
                continue
            hits.append(_line_of(content, m.start()))
    return hits


# ─────────────────────────────────────────────
# 单文件扫描
# ─────────────────────────────────────────────

def scan_text(content: str, file_path: str) -> List[Finding]:
    """扫描单文件文本，返回命中列表"""
    result: List[Finding] = []
    f = file_path

    # 1. 空 catch
    for ln in _find_empty_catches(content):
        result.append(Finding("EMPTY_CATCH", "空 catch 吞异常——静默失败，处理或转译后抛出", f, ln))

    # 2. SELECT *
    for m in re.finditer(r"SELECT[ \t\r\n]+\*", content, re.IGNORECASE):
        if not _is_in_comment(content, m.start()):
            result.append(Finding("SELECT_STAR", "SELECT * 拉取不需要的字段——明确列出列名", f, _line_of(content, m.start())))

    # 3. N+1：循环内逐条查库
    n1_pattern = re.compile(
        r"(for\s*\([^)]*\)|while\s*\([^)]*\))\s*\{[^}]{0,600}?"
        r"(selectById|selectOne|selectList\s*\(\s*[^)]*Ids?|queryForObject|queryForList|findById|findOne|"
        r"getOne\s*\(\s*new\s+\w+QueryWrapper)"
    )
    for m in n1_pattern.finditer(content):
        if not _is_in_comment(content, m.start()):
            result.append(Finding("N_PLUS_ONE", "循环内逐条查库（N+1）——批量查询代替", f, _line_of(content, m.start())))

    # 4. 循环内 HTTP
    for ln in _find_http_in_loop(content):
        result.append(Finding("HTTP_IN_LOOP", "循环内发 HTTP 请求（串行等待）——批量接口或并发", f, ln))

    # 5. ${} 拼接 SQL（仅 MyBatis XML 中才是注入风险；Java 里 ${} 是配置注入，不算）
    if file_path.endswith(".xml"):
        for m in re.finditer(r"\$\{[^}]*\}", content):
            if not _is_in_comment(content, m.start()):
                result.append(Finding("SQL_CONCAT", "${xxx} 直接拼接用户输入——有 SQL 注入风险，改用 #{}", f, _line_of(content, m.start()), "WARN"))
    # 字符串拼接 SQL（仅 .java 源码；只匹配拼接**变量**——字面量+字面量是合法常量拼接）
    elif file_path.endswith(".java"):
        for m in re.finditer(
            r'"[^"]*(SELECT|WHERE|FROM|INSERT|UPDATE|DELETE)[^"]*"\s*\+'
            r'\s*(?![^"\n]*"[^"\n]*["\n])\w+\s*;',
            content, re.IGNORECASE
        ):
            if not _is_in_comment(content, m.start()):
                result.append(Finding("SQL_CONCAT", "字符串拼接 SQL 变量——注入风险且无法复用执行计划", f, _line_of(content, m.start())))

    # 6. 硬编码密钥（排除 DICT_/字典 key 名字符串——那是配置引用不是密钥）
    for m in re.finditer(
        r"(?<![A-Za-z_])(password|passwd|jwtSecret|jwt_secret|apiKey|api_key|accessKey|secretKey|privateKey)\s*[:=]\s*"
        r"['\"]([^'\"]{%d,})['\"]" % SECRET_MIN_LEN,
        content,
        re.IGNORECASE,
    ):
        if not _is_in_comment(content, m.start()):
            # 排除 DICT_TYPE_/DICT_KEY_ 等字典引用名
            prefix = content[max(0, m.start() - 40) : m.start()]
            if re.search(r"DICT_[A-Z_]*KEY|DICT_KEY_", prefix, re.IGNORECASE):
                continue
            result.append(Finding("HARDCODED_SECRET", f"硬编码密钥（{m.group(1)}）——应放配置/环境变量", f, _line_of(content, m.start())))

    # 7. setnx + expire 手写分布式锁
    for m in re.finditer(
        r"(setIfAbsent\s*\([^)]*\)\s*[^;\n]*(?:expire|setExpire)|expire\s*\([^)]*\)\s*[^;\n]*(?:setIfAbsent|setnx))|setnx\s*\(",
        content, re.IGNORECASE
    ):
        if not _is_in_comment(content, m.start()):
            result.append(Finding("SETNX_LOCK", "手写 setnx+expire 分布式锁非原子——用 Redisson tryLock", f, _line_of(content, m.start())))

    # 8. 日志打敏感信息（排除 {} 占位符的日志——那是参数名不是泄露值）
    for m in re.finditer(r'log\.(info|error|warn|debug)\([^)]*' + SENSITIVE_FIELDS, content, re.IGNORECASE):
        if not _is_in_comment(content, m.start()):
            log_call = content[m.start() : m.end()]
            # log.info("token={}", token) → token 是占位符参数名，不报
            if re.search(SENSITIVE_FIELDS + r"[^)\n]*=\{\}", log_call, re.IGNORECASE):
                continue
            result.append(Finding("LOG_SENSITIVE", "日志打印敏感信息——脱敏后再记", f, _line_of(content, m.start())))

    # 9. System.out
    for m in re.finditer(r"System\.out\.(println|print|printf)", content):
        if not _is_in_comment(content, m.start()):
            result.append(Finding("SYSTEM_OUT", "System.out.println 直出——用日志框架", f, _line_of(content, m.start())))

    # 10. 魔法数
    for ln in _find_magic_numbers(content):
        result.append(Finding("MAGIC_NUMBER", "裸数字魔法数——提取常量/枚举", f, ln, "WARN"))

    # 11. 虚拟线程内 synchronized
    for m in re.finditer(VIRTUAL_THREAD_NAMES + r".{0,300}?(synchronized\s*\()", content, re.DOTALL):
        if not _is_in_comment(content, m.start()):
            result.append(Finding("VIRTUAL_THREAD_SYNC", "虚拟线程内 synchronized 会挂起平台线程——用 ReentrantLock", f, _line_of(content, m.start())))

    return result


# ─────────────────────────────────────────────
# 目录扫描
# ─────────────────────────────────────────────

def scan_path(path: Path, result: ScanResult) -> None:
    """递归扫描路径（文件或目录）"""
    if path.is_file():
        if path.suffix not in JAVA_SUFFIXES:
            return
        result.files_scanned += 1
        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            try:
                content = path.read_text(encoding="gbk")
            except (UnicodeDecodeError, OSError):
                return
        for f in scan_text(content, str(path)):
            result.add(f.rule_id, f.message, f.file, f.line, f.severity)
        return

    if path.is_dir():
        for child in sorted(path.iterdir()):
            if child.name.startswith(".") or child.name in SKIP_DIRS:
                continue
            scan_path(child, result)


# ─────────────────────────────────────────────
# 输出
# ─────────────────────────────────────────────

RULE_INFO = {
    "EMPTY_CATCH": ("空 catch 吞异常", "00-all.md #9"),
    "SELECT_STAR": ("SELECT * 全字段", "00-all.md #48"),
    "N_PLUS_ONE": ("循环内查库 N+1", "00-all.md #13/#51"),
    "HTTP_IN_LOOP": ("循环内 HTTP 请求", "00-all.md #57"),
    "SQL_CONCAT": ("${} 拼接 SQL", "00-all.md #60/#61"),
    "HARDCODED_SECRET": ("硬编码密钥", "00-all.md #73/#160"),
    "SETNX_LOCK": ("手写 setnx 锁", "00-all.md #82"),
    "LOG_SENSITIVE": ("日志泄敏感", "00-all.md #66/#121"),
    "SYSTEM_OUT": ("System.out 直出", "日志规范"),
    "MAGIC_NUMBER": ("裸数字魔法数", "编码标准"),
    "VIRTUAL_THREAD_SYNC": ("虚拟线程内 synchronized", "00-all.md #26/#35"),
}


def print_report(result: ScanResult):
    """可读报告"""
    print(f"═══ code-trap-scanner ═══")
    print(f"扫描文件: {result.files_scanned}  |  命中: {len(result.findings)} "
          f"(ERROR {result.error_count} / WARN {result.warn_count})")
    print()

    if not result.findings:
        print("✅ 未发现陷阱")
        return

    by_rule: Dict[str, List[Finding]] = {}
    for f in result.findings:
        by_rule.setdefault(f.rule_id, []).append(f)

    for rule_id in sorted(by_rule, key=lambda r: -len(by_rule[r])):
        info = RULE_INFO.get(rule_id, (rule_id, ""))
        findings = by_rule[rule_id]
        print(f"❌ {info[0]} ({info[1]}) — {len(findings)} 处")
        for f in findings[:10]:
            print(f"   {f.file}:{f.line}  {f.message}")
        if len(findings) > 10:
            print(f"   … 还有 {len(findings) - 10} 处")
        print()


def main():
    parser = argparse.ArgumentParser(description="code-trap-scanner — Java/Spring Boot 代码陷阱扫描")
    parser.add_argument("path", help="文件或目录")
    parser.add_argument("--json", "-j", action="store_true", help="JSON 输出")
    parser.add_argument("--alert", "-a", action="store_true", help="只输出问题")
    parser.add_argument("--fail-on-error", "-f", action="store_true", help="有 ERROR 级命中则退出码 1")
    args = parser.parse_args()

    target = Path(args.path)
    if not target.exists():
        print(f"❌ 路径不存在: {target}")
        sys.exit(2)

    result = ScanResult()
    scan_path(target, result)

    if args.json:
        output = {
            "files_scanned": result.files_scanned,
            "total_findings": len(result.findings),
            "errors": result.error_count,
            "warns": result.warn_count,
            "rules": result.rule_hits,
            "findings": [
                {"rule": f.rule_id, "severity": f.severity, "file": f.file, "line": f.line, "message": f.message}
                for f in result.findings
            ],
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    elif args.alert:
        for f in result.findings:
            print(f"[{f.severity}] {f.rule_id} {f.file}:{f.line} {f.message}")
        if not result.findings:
            print("✅ 无问题")
    else:
        print_report(result)

    if args.fail_on_error and result.error_count > 0:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
