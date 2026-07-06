#!/usr/bin/env python3
"""
novel-checkpoint — 写作检查点管理

创建、验证写作进度检查点，确保批量写作不丢失上下文。

用法：
    python novel_checkpoint.py create <name>           # 创建检查点
    python novel_checkpoint.py verify <name>           # 验证检查点
    python novel_checkpoint.py list                    # 列出检查点
    python novel_checkpoint.py restore <name>         # 恢复检查点
"""

import re
import json
import argparse
import subprocess
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, field, asdict
from typing import Optional


@dataclass
class Checkpoint:
    """检查点"""
    name: str
    timestamp: str
    chapter: str = ""
    status: str = ""
    commit: str = ""
    notes: str = ""


class CheckpointManager:
    """检查点管理器"""

    def __init__(self, book_dir: Path):
        self.book_dir = book_dir
        self.checkpoint_dir = book_dir / ".checkpoints"
        self.checkpoint_dir.mkdir(exist_ok=True)

        self.checkpoint_file = self.checkpoint_dir / "checkpoints.json"
        self.checkpoints = self._load_checkpoints()

    def _load_checkpoints(self) -> dict:
        """加载检查点数据"""
        if self.checkpoint_file.exists():
            try:
                return json.loads(self.checkpoint_file.read_text(encoding="utf-8"))
            except:
                pass
        return {"checkpoints": []}

    def _save_checkpoints(self):
        """保存检查点数据"""
        self.checkpoint_file.write_text(
            json.dumps(self.checkpoints, ensure_ascii=False, indent=2),
            encoding="utf-8"
        )

    def create(self, name: str, chapter: str = "", status: str = "", notes: str = "") -> Checkpoint:
        """创建检查点"""
        # 获取 git commit
        commit = ""
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--short", "HEAD"],
                cwd=self.book_dir,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                commit = result.stdout.strip()
        except:
            pass

        # 创建检查点
        checkpoint = Checkpoint(
            name=name,
            timestamp=datetime.now().isoformat(),
            chapter=chapter,
            status=status,
            commit=commit,
            notes=notes
        )

        self.checkpoints["checkpoints"].append(asdict(checkpoint))
        self.checkpoints["last_checkpoint"] = name
        self._save_checkpoints()

        return checkpoint

    def verify(self, name: str) -> dict:
        """验证检查点"""
        # 查找检查点
        target = None
        for cp in self.checkpoints.get("checkpoints", []):
            if cp["name"] == name:
                target = cp
                break

        if not target:
            return {"found": False, "error": f"检查点 '{name}' 不存在"}

        # 验证各项
        results = {
            "found": True,
            "checkpoint": target,
            "checks": []
        }

        # 检查章节文件
        if target.get("chapter"):
            chapter_match = re.search(r'第(\d+)章', target["chapter"])
            if chapter_match:
                chapter_num = int(chapter_match.group(1))
                chapter_pattern = f"第{chapter_num:03d}章*.md"

                found = list(self.book_dir.glob(f"**/{chapter_pattern}"))
                results["checks"].append({
                    "name": "章节文件",
                    "status": "✓" if found else "✗",
                    "detail": f"找到 {len(found)} 个匹配文件" if found else "未找到文件"
                })

        # 检查 git commit
        if target.get("commit"):
            try:
                result = subprocess.run(
                    ["git", "rev-parse", "--short", "HEAD"],
                    cwd=self.book_dir,
                    capture_output=True,
                    text=True
                )
                current_commit = result.stdout.strip() if result.returncode == 0 else ""
                is_same = current_commit == target["commit"]
                results["checks"].append({
                    "name": "Git 状态",
                    "status": "✓" if is_same else "⚠",
                    "detail": f"当前: {current_commit}, 检查点: {target['commit']}"
                })
            except:
                pass

        # 检查 MEMORY.md
        memory_file = self.book_dir / "MEMORY.md"
        results["checks"].append({
            "name": "MEMORY.md",
            "status": "✓" if memory_file.exists() else "✗",
            "detail": str(memory_file) if memory_file.exists() else "文件不存在"
        })

        return results

    def list_all(self) -> list:
        """列出所有检查点"""
        checkpoints = self.checkpoints.get("checkpoints", [])
        last = self.checkpoints.get("last_checkpoint", "")

        result = []
        for cp in checkpoints:
            result.append({
                **cp,
                "is_current": cp["name"] == last
            })

        return sorted(result, key=lambda x: x["timestamp"], reverse=True)

    def restore(self, name: str) -> bool:
        """恢复检查点（需要 git）"""
        # 查找检查点
        target = None
        for cp in self.checkpoints.get("checkpoints", []):
            if cp["name"] == name:
                target = cp
                break

        if not target:
            print(f"❌ 检查点 '{name}' 不存在")
            return False

        if not target.get("commit"):
            print(f"❌ 检查点 '{name}' 没有关联的 git commit")
            return False

        try:
            # git checkout
            result = subprocess.run(
                ["git", "checkout", target["commit"]],
                cwd=self.book_dir,
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print(f"✅ 已恢复到检查点 '{name}'")
                print(f"   Commit: {target['commit']}")
                print(f"   时间: {target['timestamp']}")
                return True
            else:
                print(f"❌ 恢复失败: {result.stderr}")
                return False
        except Exception as e:
            print(f"❌ 恢复失败: {e}")
            return False


def print_checkpoint_table(checkpoints: list):
    """打印检查点表格"""
    print("""
╔══════════════════════════════════════════════════════════════════════════╗
║                          📍 检查点列表                                ║
╠══════════════════════════════════════════════════════════════════════════╣
║  名称              │ 时间                    │ 章节      │ Commit    │ 当前  ║
╠══════════════════════════════════════════════════════════════════════════╣""")

    for cp in checkpoints:
        name = cp["name"][:16].ljust(16)
        ts = cp["timestamp"][:19]
        chapter = (cp.get("chapter") or "")[:8].ljust(8)
        commit = (cp.get("commit") or "")[:9].ljust(9)
        current = "◀" if cp.get("is_current") else " "

        print(f"║  {name} │ {ts} │ {chapter} │ {commit} │ {current}  ║")

    print("╚══════════════════════════════════════════════════════════════════════════╝")


def print_checkpoint_detail(result: dict):
    """打印检查点详情"""
    if not result.get("found"):
        print(f"❌ {result.get('error')}")
        return

    cp = result["checkpoint"]
    print(f"""
╔══════════════════════════════════════════════════════════════════════════╗
║                          📍 检查点详情                                ║
╠══════════════════════════════════════════════════════════════════════════╣
║  名称: {cp['name']}
║  时间: {cp['timestamp']}
║  章节: {cp.get('chapter') or '-'}
║  状态: {cp.get('status') or '-'}
║  Commit: {cp.get('commit') or '-'}
║  备注: {cp.get('notes') or '-'}
╠══════════════════════════════════════════════════════════════════════════╣
║                          验证结果                                    ║
╠══════════════════════════════════════════════════════════════════════════╣""")

    for check in result.get("checks", []):
        print(f"║  {check['status']} {check['name']}: {check['detail']}")

    print("╚══════════════════════════════════════════════════════════════════════════╝")


def main():
    parser = argparse.ArgumentParser(description="novel-checkpoint — 写作检查点管理")
    subparsers = parser.add_subparsers(dest="command", help="命令")

    # create 命令
    create_parser = subparsers.add_parser("create", help="创建检查点")
    create_parser.add_argument("name", help="检查点名称")
    create_parser.add_argument("--chapter", "-c", help="章节信息")
    create_parser.add_argument("--status", "-s", help="状态")
    create_parser.add_argument("--notes", "-n", help="备注")

    # verify 命令
    verify_parser = subparsers.add_parser("verify", help="验证检查点")
    verify_parser.add_argument("name", help="检查点名称")

    # list 命令
    subparsers.add_parser("list", help="列出检查点")

    # restore 命令
    restore_parser = subparsers.add_parser("restore", help="恢复检查点")
    restore_parser.add_argument("name", help="检查点名称")

    args = parser.parse_args()

    # 默认查找书籍目录
    book_dir = Path("examples/novel-demo")
    if not book_dir.exists():
        book_dir = Path("章节正文")
        if not book_dir.exists():
            book_dir = Path(".")

    if not book_dir.exists():
        print("❌ 未找到书籍目录")
        return

    manager = CheckpointManager(book_dir)

    if args.command == "create":
        checkpoint = manager.create(
            name=args.name,
            chapter=args.chapter or "",
            status=args.status or "",
            notes=args.notes or ""
        )
        print(f"""
✅ 检查点已创建

  名称: {checkpoint.name}
  时间: {checkpoint.timestamp}
  章节: {checkpoint.chapter or '-'}
  状态: {checkpoint.status or '-'}
  Commit: {checkpoint.commit or '-'}
""")

    elif args.command == "verify":
        result = manager.verify(args.name)
        print_checkpoint_detail(result)

    elif args.command == "list":
        checkpoints = manager.list_all()
        if checkpoints:
            print_checkpoint_table(checkpoints)
        else:
            print("❌ 暂无检查点")

    elif args.command == "restore":
        manager.restore(args.name)

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
