#!/usr/bin/env bash
# Route: novel
# 新建小说项目的标准目录结构
# Usage: novel-init.sh <小说名> [工作目录]
set -euo pipefail

BOOK_NAME="${1:?用法: novel-init.sh <小说名> [工作目录]}"
WORK_DIR="${2:-.}"

BOOK_DIR="${WORK_DIR}/${BOOK_NAME}"

if [[ -d "$BOOK_DIR" ]]; then
  echo "Error: 目录已存在: ${BOOK_DIR}" >&2
  exit 1
fi

mkdir -p "${BOOK_DIR}/人物设定"
mkdir -p "${BOOK_DIR}/章节正文"
mkdir -p "${BOOK_DIR}/素材库"
mkdir -p "${BOOK_DIR}/.harness-novel-runtime"/{plans,execution-logs,tracking,memory}

cat > "${BOOK_DIR}/README.md" <<EOF
# 《${BOOK_NAME}》

## 基本信息
- 题材：
- 核心卖点：
- 目标字数：
- 更新频率：

## 状态
- 当前进度：规划中
- 总章节数：待定
- 最近更新：$(date +%Y-%m-%d)
EOF

cat > "${BOOK_DIR}/大纲.md" <<EOF
# 《${BOOK_NAME}》大纲

## 故事梗概

## 主线

## 分卷规划

### 第一卷
- 核心冲突：
- 章节数：
- 关键事件：

EOF

cat > "${BOOK_DIR}/章节目录.md" <<EOF
# 《${BOOK_NAME}》章节目录

| 章节 | 标题 | 字数 | 状态 | 备注 |
|------|------|------|------|------|
EOF

cat > "${BOOK_DIR}/人物设定/主角.md" <<EOF
# 主角

## 基本信息
- 姓名：
- 年龄：
- 身份：
- 性格：

## 人物弧线
- 初始状态：
- 转折点：
- 最终状态：

## 关系网
EOF

cat > "${BOOK_DIR}/素材库/情节灵感.md" <<EOF
# 情节灵感

EOF

cat > "${BOOK_DIR}/素材库/环境描写.md" <<EOF
# 环境描写素材

EOF

cat > "${BOOK_DIR}/MEMORY.md" <<EOF
# 《${BOOK_NAME}》记忆文件 — Route: novel

## 本书基础设定
project:
  title: 《${BOOK_NAME}》
  genre: 待定
  timeline: 待定
  pov: 待定

## 人物状态追踪
characters: []

## 伏笔追踪
foreshadowing: []

## 章节索引+一句话摘要
chapter_index: []

## 进行中工作
in_progress:
  - current_phase: init
  - last_action: "项目初始化"

## 阻塞项
blockers: []

## 最后更新
last_updated: $(date +%Y-%m-%dT%H:%M:%S%z)
EOF

echo "[ok] 已创建小说项目: ${BOOK_DIR}"
echo ""
echo "目录结构:"
echo "  ${BOOK_DIR}/"
echo "  ├── README.md          # 小说简介"
echo "  ├── 大纲.md             # 故事大纲"
echo "  ├── 章节目录.md         # 章节索引"
echo "  ├── MEMORY.md          # 长期记忆"
echo "  ├── 人物设定/           # 角色设定"
echo "  ├── 章节正文/           # 章节内容"
echo "  └── 素材库/             # 参考资料"
echo ""
echo "下一步: 开始规划大纲"
