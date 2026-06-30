# install-intelligence-deps.ps1
# Intelligence Layer 一键安装脚本 (Windows PowerShell)
# 用法: .\scripts\install-intelligence-deps.ps1 [-InitIndex]

param(
    [switch]$InitIndex
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Intelligence Layer 依赖安装" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }

# === 1. 检查 Node.js ===
Write-Host ">>> 检查 Node.js..."

try {
    $nodeVersion = (node --version).Trim()
    $nodeMajor = [int]($nodeVersion -replace 'v', '' -split '\.')[0]
} catch {
    Write-Err "Node.js 未安装或未在 PATH 中"
    Write-Host "   请从 https://nodejs.org/ 安装 Node.js >= 20"
    exit 1
}

if ($nodeMajor -lt 20) {
    Write-Err "Node.js 版本过低: $nodeVersion"
    Write-Host "   CodeGraph 需要 Node.js >= 20"
    Write-Host "   请从 https://nodejs.org/ 升级"
    exit 1
}

Write-Info "Node.js 版本检查通过: $nodeVersion"
Write-Host ""

# === 2. 安装 CodeGraph ===
Write-Host ">>> 安装 CodeGraph..."

if (Get-Command codegraph -ErrorAction SilentlyContinue) {
    $cgVersion = codegraph --version 2>$null || "unknown"
    Write-Info "CodeGraph 已安装: $cgVersion"
} else {
    Write-Info "正在安装 CodeGraph..."

    try {
        npm install -g @colbymchenry/codegraph
        Write-Success "CodeGraph 安装成功"
    } catch {
        Write-Err "CodeGraph 安装失败"
        exit 1
    }
}
Write-Host ""

# === 3. 检查 Understand-Anything ===
Write-Host ">>> 检查 Understand-Anything..."

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$uaPath = Join-Path $rootDir "reference_github\Understand-Anything"

if (Test-Path $uaPath) {
    Write-Info "Understand-Anything 源码已存在: $uaPath"
} else {
    Write-Warn "Understand-Anything 源码未找到"
    Write-Host ""
    Write-Host "   Understand-Anything 是可选的智能代码理解工具"
    Write-Host "   如需使用，请手动安装:"
    Write-Host ""
    Write-Host "   # 克隆源码"
    Write-Host "   git clone https://github.com/Understand-Anything/understand-anything.git"
    Write-Host "   cd understand-anything"
    Write-Host ""
    Write-Host "   # 安装依赖"
    Write-Host "   pnpm install"
    Write-Host ""
    Write-Host "   # 构建"
    Write-Host "   pnpm --filter @understand-anything/core build"
    Write-Host "   pnpm --filter @understand-anything/skill build"
    Write-Host ""
    Write-Host "   详见: https://github.com/Understand-Anything/understand-anything"
}
Write-Host ""

# === 4. 初始化项目索引（可选）===
if ($InitIndex) {
    Write-Host ">>> 初始化项目索引..."

    if (Test-Path ".git") {
        Write-Info "检测到 Git 项目: $rootDir"

        if (Test-Path ".codegraph") {
            Write-Warn ".codegraph 目录已存在，将重新初始化"
            Remove-Item -Recurse -Force ".codegraph"
        }

        Write-Info "初始化 CodeGraph..."
        codegraph init

        Write-Info "建立代码索引..."
        codegraph index

        Write-Success "项目索引初始化完成"
        Write-Host ""
        Write-Host "   索引数据存储在: .codegraph\"
        Write-Host "   如需更新索引: codegraph sync"
    } else {
        Write-Warn "当前目录不是 Git 项目，跳过索引初始化"
    }
}

# === 完成 ===
Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Success "Intelligence Layer 安装完成!"
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:"
Write-Host ""
Write-Host "  1. 在 Harness Foundry 中使用 Skills:"
Write-Host "     - /understand-project   # 理解项目"
Write-Host "     - /analyze-architecture # 分析架构"
Write-Host "     - /query-symbol         # 定位代码"
Write-Host "     - /analyze-impact       # 评估影响"
Write-Host ""
Write-Host "  2. 如需初始化项目索引:"
Write-Host "     cd your-project"
Write-Host "     codegraph init"
Write-Host "     codegraph index"
Write-Host ""
Write-Host "  3. 查看文档:"
Write-Host "     cat docs/intelligence-layer-user-guide.md"
Write-Host ""