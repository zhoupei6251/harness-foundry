#!/usr/bin/env bash
# Route: news
# 新建新闻项目的标准目录结构
# Usage: news-init.sh <集名> [工作目录]
set -euo pipefail

NEWS_NAME="${1:?用法: news-init.sh <集名> [工作目录]}"
WORK_DIR="${2:-.}"

NEWS_DIR="${WORK_DIR}/${NEWS_NAME}"

if [[ -d "$NEWS_DIR" ]]; then
  echo "Error: 目录已存在: ${NEWS_DIR}" >&2
  exit 1
fi

mkdir -p "${NEWS_DIR}/文章"
mkdir -p "${NEWS_DIR}/.harness-news-runtime"/{plans,execution-logs,tracking,memory,articles}

cat > "${NEWS_DIR}/README.md" <<EOF
# ${NEWS_NAME}

## 基本信息
- 领域：
- 定位：
- 更新频率：
- 风格：

## 状态
- 当前进度：初始化
- 文章总数：0
- 最近更新：$(date +%Y-%m-%d)
EOF

cat > "${NEWS_DIR}/文章索引.md" <<EOF
# ${NEWS_NAME} 文章索引

| 编号 | 标题 | 分类 | 字数 | 状态 | 发布日期 |
|------|------|------|------|------|----------|
EOF

cat > "${NEWS_DIR}/MEMORY.md" <<EOF
# ${NEWS_NAME} 记忆文件 — Route: news

## 项目信息
project:
  title: ${NEWS_NAME}
  domain: 待定
  style: 待定
  cadence: 待定

## 进行中
in_progress:
  - current_phase: init
  - last_action: "项目初始化"

## 阻塞项
blockers: []

## 最后更新
last_updated: $(date +%Y-%m-%dT%H:%M:%S%z)
EOF

echo "[ok] 已创建新闻项目: ${NEWS_DIR}"
echo ""
echo "目录结构:"
echo "  ${NEWS_DIR}/"
echo "  ├── README.md          # 项目简介"
echo "  ├── 文章索引.md         # 文章索引"
echo "  ├── MEMORY.md          # 长期记忆"
echo "  └── 文章/              # 文章内容"
echo ""
echo "下一步: 开始创作第一篇文章"
