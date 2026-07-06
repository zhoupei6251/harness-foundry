#!/usr/bin/env python3
"""
novel-mcp-server — Model Context Protocol 服务器

为外部编辑器/IDE 提供 novel 域 AI 能力接口。

基于 FastMCP 框架，支持：
- 章节写作
- 审稿评分
- 记忆管理
- 大纲查询
- 伏笔检查

用法：
    python -m novel_mcp.server                    # 启动服务器
    npx @modelcontextprotocol/inspector python -m novel_mcp.server  # 测试
"""

import json
import re
import sys
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, asdict

# 导入本地模块
sys.path.insert(0, str(Path(__file__).parent.parent))
from novel.mechanical_scorer import MechanicalScorer
from novel.novel_metrics import scan_book_directory, BookMetrics


# ═══════════════════════════════════════════════════════════════════════════
# MCP 工具定义
# ═══════════════════════════════════════════════════════════════════════════

@dataclass
class ToolResult:
    """工具执行结果"""
    success: bool
    data: Any = None
    error: str = ""


def count_words(text: str) -> int:
    """统计字数"""
    chinese = len(re.findall(r'[一-鿿]', text))
    return chinese


def parse_chapter(file_path: Path) -> Optional[Dict]:
    """解析章节文件"""
    try:
        content = file_path.read_text(encoding="utf-8")
    except:
        return None

    name = file_path.stem
    match = re.match(r'第(\d+)章[_：](.+)', name)
    if not match:
        return None

    return {
        "num": int(match.group(1)),
        "title": match.group(2),
        "path": str(file_path),
        "word_count": count_words(content),
        "content": content
    }


def find_books(workspace_root: Path = Path(".")) -> List[Dict]:
    """查找所有书籍"""
    books = []

    # 搜索可能的小说目录
    patterns = [
        "examples/novel-*",
        "章节正文/*",
        "novels/*",
        "*"
    ]

    for pattern in patterns:
        for book_dir in workspace_root.glob(pattern):
            if book_dir.is_dir():
                # 检查是否有章节文件
                chapters = list(book_dir.glob("第*章*.md")) or \
                          list(book_dir.glob("章节正文/第*章*.md"))
                if chapters:
                    books.append({
                        "name": book_dir.name,
                        "path": str(book_dir),
                        "chapter_count": len(chapters)
                    })

    return books


def find_chapters(book_path: str) -> List[Dict]:
    """查找书籍的所有章节"""
    book_dir = Path(book_path)
    chapters = []

    for pattern in ["第*章*.md", "章节正文/第*章*.md"]:
        for file_path in book_dir.glob(pattern):
            chapter = parse_chapter(file_path)
            if chapter:
                chapters.append(chapter)

    return sorted(chapters, key=lambda x: x["num"])


def load_memory(book_path: str) -> Optional[str]:
    """加载记忆文件"""
    book_dir = Path(book_path)
    memory_paths = [
        book_dir / "MEMORY.md",
        book_dir / "记忆.md",
        book_dir / ".memory.md"
    ]

    for memory_path in memory_paths:
        if memory_path.exists():
            return memory_path.read_text(encoding="utf-8")

    return None


def update_memory(book_path: str, updates: Dict) -> ToolResult:
    """更新记忆文件"""
    book_dir = Path(book_path)
    memory_path = book_dir / "MEMORY.md"

    if not memory_path.exists():
        return ToolResult(success=False, error="MEMORY.md 不存在")

    try:
        content = memory_path.read_text(encoding="utf-8")

        # 简单的文本替换更新
        for key, value in updates.items():
            # 查找并替换对应字段
            pattern = rf"(\| {key} \| )[^|]+"
            replacement = rf"\1 {value}"
            content = re.sub(pattern, replacement, content)

        memory_path.write_text(content, encoding="utf-8")
        return ToolResult(success=True, data={"updated": list(updates.keys())})

    except Exception as e:
        return ToolResult(success=False, error=str(e))


def run_mechanical_scorer(chapter_path: str) -> ToolResult:
    """运行机械评分"""
    try:
        scorer = MechanicalScorer(chapter_path)
        scorer.check_all()

        findings = [f.to_dict() for f in scorer.findings]
        total_score = scorer.get_total_score()

        return ToolResult(
            success=True,
            data={
                "score": total_score,
                "findings": findings,
                "stats": scorer.stats,
                "decision": "BLOCK" if any(f.severity == "BLOCK" for f in scorer.findings) else "PASS"
            }
        )
    except Exception as e:
        return ToolResult(success=False, error=str(e))


def get_book_metrics(book_path: str) -> ToolResult:
    """获取书籍指标"""
    try:
        metrics = scan_book_directory(Path(book_path))

        return ToolResult(
            success=True,
            data={
                "book_name": metrics.book_name,
                "completed_chapters": metrics.completed_chapters,
                "total_words_written": metrics.total_words_written,
                "avg_score": metrics.avg_score,
                "first_pass_rate": metrics.first_pass_rate
            }
        )
    except Exception as e:
        return ToolResult(success=False, error=str(e))


def check_foreshadowing(book_path: str, current_chapter: int = 0) -> ToolResult:
    """检查伏笔状态"""
    book_dir = Path(book_path)

    # 尝试读取伏笔配置
    fs_paths = [
        book_dir / ".foreshadowing.json",
        book_dir / "伏笔.json",
        book_dir / ".novel" / "foreshadowing.json"
    ]

    foreshadows = []
    for fs_path in fs_paths:
        if fs_path.exists():
            try:
                data = json.loads(fs_path.read_text(encoding="utf-8"))
                foreshadows = data.get("foreshadows", [])
                break
            except:
                pass

    # 如果没有配置文件，从 MEMORY.md 解析
    if not foreshadows:
        memory = load_memory(book_path)
        if memory:
            # 简单解析伏笔表格
            for line in memory.split('\n'):
                if 'FP' in line and 'buried' in line:
                    foreshadows.append({
                        "status": "buried",
                        "detail": line
                    })

    # 分类伏笔
    buried = [f for f in foreshadows if f.get("status") == "buried"]
    triggered = [f for f in foreshadows if f.get("status") == "triggered"]
    resolved = [f for f in foreshadows if f.get("status") == "resolved"]

    return ToolResult(
        success=True,
        data={
            "total": len(foreshadows),
            "buried": len(buried),
            "triggered": len(triggered),
            "resolved": len(resolved),
            "foreshadows": foreshadows
        }
    )


# ═══════════════════════════════════════════════════════════════════════════
# MCP 协议处理
# ═══════════════════════════════════════════════════════════════════════════

class MCPServer:
    """简化版 MCP 服务器"""

    def __init__(self):
        self.tools = self._register_tools()

    def _register_tools(self) -> Dict[str, Dict]:
        """注册所有工具"""
        return {
            "list_books": {
                "name": "list_books",
                "description": "列出所有书籍项目",
                "input_schema": {
                    "type": "object",
                    "properties": {},
                    "required": []
                },
                "handler": lambda _: ToolResult(success=True, data={"books": find_books()})
            },
            "get_chapters": {
                "name": "get_chapters",
                "description": "获取书籍的所有章节",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "book_path": {"type": "string", "description": "书籍目录路径"}
                    },
                    "required": ["book_path"]
                },
                "handler": lambda args: ToolResult(
                    success=True,
                    data={"chapters": find_chapters(args["book_path"])}
                )
            },
            "get_memory": {
                "name": "get_memory",
                "description": "获取书籍记忆文件",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "book_path": {"type": "string", "description": "书籍目录路径"}
                    },
                    "required": ["book_path"]
                },
                "handler": lambda args: ToolResult(
                    success=True,
                    data={"memory": load_memory(args["book_path"])}
                )
            },
            "update_memory": {
                "name": "update_memory",
                "description": "更新书籍记忆",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "book_path": {"type": "string"},
                        "updates": {"type": "object"}
                    },
                    "required": ["book_path", "updates"]
                },
                "handler": lambda args: update_memory(args["book_path"], args["updates"])
            },
            "score_chapter": {
                "name": "score_chapter",
                "description": "对章节进行机械评分",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "chapter_path": {"type": "string"}
                    },
                    "required": ["chapter_path"]
                },
                "handler": lambda args: run_mechanical_scorer(args["chapter_path"])
            },
            "get_metrics": {
                "name": "get_metrics",
                "description": "获取书籍写作指标",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "book_path": {"type": "string"}
                    },
                    "required": ["book_path"]
                },
                "handler": lambda args: get_book_metrics(args["book_path"])
            },
            "check_foreshadowing": {
                "name": "check_foreshadowing",
                "description": "检查伏笔状态",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "book_path": {"type": "string"},
                        "current_chapter": {"type": "integer", "default": 0}
                    },
                    "required": ["book_path"]
                },
                "handler": lambda args: check_foreshadowing(
                    args["book_path"],
                    args.get("current_chapter", 0)
                )
            }
        }

    def handle_request(self, request: Dict) -> Dict:
        """处理 MCP 请求"""
        method = request.get("method")
        params = request.get("params", {})

        if method == "tools/list":
            # 返回工具列表
            tools = []
            for tool_id, tool in self.tools.items():
                tools.append({
                    "name": tool["name"],
                    "description": tool["description"],
                    "inputSchema": tool["input_schema"]
                })
            return {"result": {"tools": tools}}

        elif method == "tools/call":
            # 调用工具
            tool_name = params.get("name")
            arguments = params.get("arguments", {})

            tool = self.tools.get(tool_name)
            if not tool:
                return {"error": {"code": -32601, "message": f"Tool not found: {tool_name}"}}

            try:
                result = tool["handler"](arguments)
                if result.success:
                    return {"result": {"content": [{"type": "text", "text": json.dumps(result.data, ensure_ascii=False)}]}}
                else:
                    return {"error": {"code": -32603, "message": result.error}}
            except Exception as e:
                return {"error": {"code": -32603, "message": str(e)}}

        elif method == "resources/list":
            # 返回资源列表
            return {"result": {"resources": []}}

        else:
            return {"error": {"code": -32601, "message": f"Method not found: {method}"}}

    def run(self):
        """运行服务器（简化版：处理单次请求）"""
        # 从 stdin 读取请求
        request = json.load(sys.stdin)
        response = self.handle_request(request)
        print(json.dumps(response, ensure_ascii=False))


def main():
    """主入口"""
    server = MCPServer()
    server.run()


if __name__ == "__main__":
    main()
