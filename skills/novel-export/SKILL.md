---
name: novel-export
description: 多格式小说导出系统，支持 EPUB/PDF/HTML/番茄小说/起点中文格式输出，网文创作者必备工具
metadata:
  domain: novel
  priority: P1
  tags:
  - export
  - epub
  - pdf
  - html
  - fanqie
  - qidian
  - publishing
version: 1.0.0
when_to_use: 用户要求导出小说、发布到平台、生成电子书、生成可印刷版本时
status: peripheral
tags:
- novel
- export
- publishing
domain: novel
category: novel.export
---

# Novel Export — 多格式导出系统

> 支持 EPUB、PDF、HTML、番茄小说格式、起点中文格式的智能导出。
> 参考 writing-template-for-ai 多格式输出设计，网文创作者必备工具。

## 激活条件

- 用户说"导出"、"生成 EPUB"、"生成 PDF"、"发布到番茄"、"发布到起点"
- 用户说"制作电子书"、"生成可印刷版本"
- Writer 完成全书后需要打包发布

## 导出格式

### 1. EPUB（电子书）

```python
def export_epub(book_dir, output_path):
    """
    导出 EPUB 格式

    参数:
        book_dir: 小说章节目录（包含 chapters/ 子目录和 metadata.yaml）
        output_path: 输出文件路径

    输出:
        - 封面（cover.jpg/png）
        - 书名页（titlepage.xhtml）
        - 目录（toc.xhtml）
        - 各章节（chapter_*.xhtml）
        - 元数据（metadata.opf）
        - 样式表（style.css）

    依赖:
        - python-epub-builder / epubBuilder
        - Pillow（封面生成）
    """
```

### 2. PDF（印刷/阅读）

```python
def export_pdf(book_dir, output_path):
    """
    导出 PDF 格式

    参数:
        book_dir: 小说章节目录
        output_path: 输出文件路径

    输出:
        - 封面（居中大字标题）
        - 目录页（带页码）
        - 正文分页（每页约 500 字）
        - 页眉（书名）
        - 页脚（页码）
        - 章节分隔页

    依赖:
        - weasyprint / reportlab
        - jinja2（模板）
    """
```

### 3. HTML（网页阅读）

```python
def export_html(book_dir, output_dir):
    """
    导出 HTML 格式

    输出:
        - index.html（目录页）
        - chapters/chapter_*.html（各章节）
        - css/style.css（样式）
        - images/（封面等）
        - search.js（全文搜索）

    特性:
        - 响应式布局
        - 夜间模式
        - 进度保存
        - 章节跳转
    """
```

### 4. 番茄小说格式

```python
def export_fanqie(book_dir, output_dir):
    """
    导出番茄小说平台可用格式

    输出格式:
        单章 JSON:
        {
            "title": "第一章 觉醒",
            "content": "正文内容...",
            "word_count": 3200,
            "chapter_index": 1
        }

        批量上传 JSONL:
        每行一个 JSON 对象，便于批量导入

    平台要求:
        - UTF-8 编码
        - 每章独立文件或 JSONL 格式
        - 标题格式：第X章 标题
    """
```

### 5. 起点中文格式

```python
def export_qidian(book_dir, output_dir):
    """
    导出起点中文网平台可用格式

    输出格式:
        单章 XML（起点标准格式）:
        <?xml version="1.0" encoding="UTF-8"?>
        <chapter>
            <title>第一章 觉醒</title>
            <content><![CDATA[正文内容...]]></content>
            <word_count>3200</word_count>
        </chapter>

        或 CSV 格式（批量导入）:
        chapter_name, content, tags
    """
```

## 目录结构

```
skills/novel-export/
├── SKILL.md              # 本文档
├── scripts/
│   ├── __init__.py
│   ├── novel_export.py   # 主入口（CLI）
│   ├── epub_builder.py   # EPUB 生成器
│   ├── pdf_builder.py    # PDF 生成器
│   ├── html_builder.py   # HTML 生成器
│   ├── fanqie_exporter.py # 番茄格式
│   └── qidian_exporter.py # 起点格式
└── templates/
    ├── cover.html        # 封面模板
    ├── chapter.html      # 章节模板
    └── toc.html          # 目录模板
```

## 命令行接口

```bash
# EPUB 导出
python scripts/novel_export.py epub 章节正文/我的小说 -o output/book.epub

# PDF 导出
python scripts/novel_export.py pdf 章节正文/我的小说 -o output/book.pdf

# HTML 导出
python scripts/novel_export.py html 章节正文/我的小说 -o output/

# 番茄小说格式
python scripts/novel_export.py fanqie 章节正文/我的小说 -o output/

# 起点中文格式
python scripts/novel_export.py qidian 章节正文/我的小说 -o output/

# 查看帮助
python scripts/novel_export.py --help
```

## 输入格式

### 目录结构

```
小说目录/
├── metadata.yaml          # 元数据
├── cover.jpg              # 封面（可选）
└── chapters/
    ├── chapter_001.md     # 第1章
    ├── chapter_002.md     # 第2章
    └── ...
```

### metadata.yaml 格式

```yaml
title: 我的小说
author: 作者名
description: 小说简介
genre: 玄幻
tags:
  - 玄幻
  - 热血
  - 成长
cover: cover.jpg
chapters:
  - title: 第一章 觉醒
    file: chapters/chapter_001.md
  - title: 第二章 修炼
    file: chapters/chapter_002.md
```

### 章节文件格式

```markdown
---
title: 第一章 觉醒
word_count: 3200
---

# 第一章 觉醒

正文内容...
```

## 工作流程

```
┌─────────────────────────────────────────────────────────┐
│  📖 小说导出流程                                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Step 1: 扫描目录                                        │
│  ├─ 读取 metadata.yaml                                  │
│  ├─ 检查封面是否存在                                    │
│  └─ 扫描 chapters/ 目录                                 │
│                                                          │
│  Step 2: 解析章节                                        │
│  ├─ 读取每个章节文件                                    │
│  ├─ 提取标题、正文、字数                                │
│  └─ 检查格式规范                                        │
│                                                          │
│  Step 3: 生成导出                                        │
│  ├─ 选择格式（EPUB/PDF/HTML/番茄/起点）               │
│  ├─ 渲染模板                                            │
│  └─ 生成输出文件                                        │
│                                                          │
│  Step 4: 验证输出                                        │
│  ├─ 检查文件完整性                                      │
│  ├─ 验证格式规范                                        │
│  └─ 输出摘要                                            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 输出格式

### 番茄小说单章 JSON

```json
{
  "title": "第一章 觉醒",
  "content": "清晨的阳光透过破旧的窗户洒进房间...",
  "word_count": 3200,
  "chapter_index": 1,
  "tags": ["玄幻", "热血"],
  "created_at": "2024-01-01T00:00:00Z"
}
```

### 番茄小说批量 JSONL

```jsonl
{"title": "第一章 觉醒", "content": "...", "word_count": 3200, "chapter_index": 1}
{"title": "第二章 修炼", "content": "...", "word_count": 3100, "chapter_index": 2}
{"title": "第三章 突破", "content": "...", "word_count": 3400, "chapter_index": 3}
```

### 起点中文 CSV

```csv
chapter_name,content,tags,word_count
第一章 觉醒,"清晨的阳光...",玄幻|热血,3200
第二章 修炼,"经过一夜的...",玄幻,3100
第三章 突破,"第三天清晨...",玄幻|成长,3400
```

## 前端界面

```markdown
┌─────────────────────────────────────────────────────────┐
│  📖 小说导出                                            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  当前小说: 我的小说                                      │
│  章节数: 50章 | 总字数: 160,000字                       │
│                                                          │
│  导出格式                                               │
│  ┌──────────────────────────────────────────────────┐ │
│  │ [EPUB]  电子书格式，支持 Kindle/多看阅读器       │ │
│  │ [PDF]   印刷/打印格式，带目录和页码              │ │
│  │ [HTML]  网页格式，支持全文搜索                   │ │
│  │ [番茄]  番茄小说平台格式                         │ │
│  │ [起点]  起点中文网格式                           │ │
│  └──────────────────────────────────────────────────┘ │
│                                                          │
│  高级选项                                               │
│  □ 包含封面          □ 添加水印                        │
│  □ 压缩图片          □ 生成目录索引                    │
│                                                          │
│  [开始导出]                                             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 依赖库

| 格式 | 依赖库 | 安装命令 |
|------|--------|----------|
| EPUB | epubBuilder | `pip install epubBuilder` |
| PDF | weasyprint | `pip install weasyprint` |
| PDF | reportlab | `pip install reportlab` |
| HTML | jinja2 | `pip install jinja2` |
| All | pyyaml | `pip install pyyaml` |
| All | markdown | `pip install markdown` |

## 异常处理

### 缺少 metadata.yaml

```markdown
⚠️ 缺少 metadata.yaml 文件

请在小说目录下创建 metadata.yaml，包含：
- title: 书名
- author: 作者
- description: 简介
- chapters: 章节列表

是否自动生成？ [Y/n]:
```

### 章节文件缺失

```markdown
⚠️ 章节文件缺失

检测到: chapter_005.md 不存在
可用章节: chapter_001-004, chapter_006-010

选项：
1. 跳过缺失章节继续导出
2. 暂停并提示用户补充
3. 终止导出

请选择 [1/2/3]:
```

### 输出目录不存在

```markdown
⚠️ 输出目录不存在: output/

将自动创建目录: output/

继续导出... [Enter]
```

## 禁止事项

- ❌ 不检查输入目录就尝试导出
- ❌ 跳过 metadata.yaml 验证
- ❌ 不处理编码问题（统一使用 UTF-8）
- ❌ 导出后不验证文件完整性
- ❌ 覆盖用户已有文件而不提示

## 依赖

- `skills/novel-quick-write/` — 章节写作
- `skills/novel-init/` — 项目初始化
- `skills/novel-checkpoint/` — 状态保存
- `skills/novel-metrics/` — 字数统计