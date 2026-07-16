# install-intelligence-deps.ps1
# Intelligence Layer 依赖检查脚本 (Windows PowerShell)
# codebase-memory 由 Codex skill 提供，不需要 npm 全局安装。

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

Write-Host ">>> 检查 codebase-memory..."
Write-Info "codebase-memory 由 Codex skill 提供，无需 npm 全局安装。"
Write-Info "结构化查询使用 index_repository、search_graph、trace_path、detect_changes。"
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$uaPath = Join-Path $rootDir "reference_github\Understand-Anything"

Write-Host ">>> 检查 Understand-Anything..."
if (Test-Path $uaPath) {
    Write-Info "Understand-Anything 源码已存在: $uaPath"
} else {
    Write-Warn "Understand-Anything 源码未找到（可选）"
    Write-Host "       如需使用，请按 mcp-config/Understand-Anything.json 配置。"
}

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
Write-Host "  - /code-insight-stack       # 战术层统一入口（codebase-memory + ripgrep + LSP）"
Write-Host "  - /understand-project       # 战略层：理解项目"
Write-Host "  - /analyze-architecture     # 战略层：分析架构"
Write-Host "  - /query-symbol             # 战术层：定位代码（图）"
Write-Host "  - /ripgrep-search           # 战术层：定位字符串/正则"
Write-Host "  - /lsp-query                # 战术层：权威定义/引用/类型/诊断"
Write-Host "  - /analyze-impact           # 战术层：评估影响"
Write-Host ""