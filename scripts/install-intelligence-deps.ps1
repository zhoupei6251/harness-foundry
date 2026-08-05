# install-intelligence-deps.ps1
# Intelligence Layer 依赖检查脚本 (Windows PowerShell)
# codebase-memory-mcp 由 MCP 服务器提供（mcp-config/codebase-memory.json）。

param(
    [switch]$InitIndex
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Intelligence Layer 依赖检查" -ForegroundColor Cyan
Write-Host "=============================================="
Write-Host ""

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }

Write-Host ">>> 检查 codebase-memory-mcp..."
if (Test-Path (Join-Path $PSScriptRoot "..\mcp-config\codebase-memory.json")) {
    Write-Info "MCP 配置存在: mcp-config/codebase-memory.json"
} else {
    Write-Warn "MCP 配置未找到: mcp-config/codebase-memory.json"
}
Write-Info "结构化查询使用 index_repository、search_graph、trace_path、detect_changes。"
Write-Host ""

if ($InitIndex) {
    Write-Host ""
    Write-Host ">>> codebase-memory 索引初始化提示"
    Write-Info "请在 AI 会话中调用 codebase-memory 的 index_repository 工具。"
    Write-Info "不要手动删除或操作其内部索引目录。"
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan

Write-Host ">>> 检查 ripgrep (文本搜索)..."
$rgCmd = Get-Command rg -ErrorAction SilentlyContinue
if ($rgCmd) {
    Write-Host "[OK] ripgrep found: $($rgCmd.Source)"
} else {
    Write-Host "[WARN] ripgrep 未安装；ripgrep-search skill 将降级到 grep 兜底"
    Write-Host "       安装: https://github.com/BurntSushi/ripgrep#installation"
}

Write-Host ">>> 检查 LSP (语言服务)..."
$found = $false
foreach ($cmd in @("typescript-language-server","pyright","gopls","rust-analyzer","clangd","jdtls","omnisharp-roslyn")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "[OK] LSP available: $cmd"
        $found = $true
        break
    }
}
if (-not $found) {
    Write-Host "[WARN] 未检测到任何 language server；lsp-query skill 仍可调用（由 IDE 暴露 LSP）"
}
Write-Success "Intelligence Layer 检查完成"
Write-Host "=============================================="
Write-Host ""
Write-Host "下一步:"
Write-Host "  - /code-insight-stack       # 统一入口（codebase-memory + ripgrep + LSP）"
Write-Host "  - /understand-project       # 理解项目（codebase-memory: index_repository + get_architecture）"
Write-Host "  - /analyze-architecture     # 分析架构（codebase-memory: get_architecture）"
Write-Host "  - /query-symbol             # 定位代码（图）"
Write-Host "  - /ripgrep-search           # 定位字符串/正则"
Write-Host "  - /lsp-query                # 权威定义/引用/类型/诊断"
Write-Host "  - /analyze-impact           # 评估影响"
Write-Host ""