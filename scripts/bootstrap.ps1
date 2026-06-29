# Harness bootstrap (Windows PowerShell)
# 功能与 bootstrap.sh 对齐：多平台投影 + 运行时目录 + MEMORY.md 生成
param(
    [ValidateSet('all','cursor','trae','claude','codex','mimocode')]
    [string]$Target = 'all',
    [ValidateSet('code','novel','news')]
    [string]$Route = 'code',
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Kit = Join-Path $Root 'harness-foundry'

function Write-DryRun([string]$Msg) {
    Write-Host "[dry] $Msg"
}

function Copy-Tree([string]$Src, [string]$Dst, [string]$Label) {
    if (-not (Test-Path $Src)) {
        Write-Warning "Missing $Label source: $Src"
        return
    }
    if ($DryRun) {
        Write-DryRun "$Label : would copy $Src -> $Dst"
        return
    }
    New-Item -ItemType Directory -Force -Path $Dst | Out-Null
    Get-ChildItem $Src -Force | ForEach-Object {
        $destPath = Join-Path $Dst $_.Name
        if ($_.PSIsContainer) {
            if (Test-Path $destPath) { Remove-Item $destPath -Recurse -Force }
            Copy-Item $_.FullName $destPath -Recurse -Force
        } else {
            Copy-Item $_.FullName $destPath -Force
        }
    }
    Write-Host "[ok] $Label : $Src -> $Dst"
}

function Sync-SkillsPlatform([string]$Platform) {
    $dryArg = if ($DryRun) { @('-DryRun') } else { @() }
    & (Join-Path $PSScriptRoot 'sync-skills.ps1') -Target $Platform @dryArg
}

# === 运行时目录（按域） ===
function Create-RuntimeDirs {
    if ($DryRun) {
        Write-DryRun "would create runtime dirs for route=$Route"
        return
    }
    switch ($Route) {
        'code' {
            $dirs = @(
                '.ai-runtime-artifacts/specs',
                '.ai-runtime-artifacts/plans',
                '.ai-runtime-artifacts/decisions',
                '.ai-runtime-artifacts/execution-logs/tracking',
                '.ai-runtime-artifacts/verifications',
                '.ai-runtime-artifacts/reviews',
                '.ai-runtime-artifacts/research'
            )
            foreach ($d in $dirs) {
                New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
            }
            Write-Host "[ok] 代码域运行时目录: .ai-runtime-artifacts/"
        }
        'novel' {
            $dirs = @(
                '.harness-novel-runtime/plans',
                '.harness-novel-runtime/execution-logs',
                '.harness-novel-runtime/tracking',
                '.harness-novel-runtime/memory'
            )
            foreach ($d in $dirs) {
                New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
            }
            Write-Host "[ok] 小说域运行时目录: .harness-novel-runtime/"
        }
        'news' {
            $dirs = @(
                '.harness-news-runtime/plans',
                '.harness-news-runtime/execution-logs',
                '.harness-news-runtime/tracking',
                '.harness-news-runtime/memory',
                '.harness-news-runtime/articles'
            )
            foreach ($d in $dirs) {
                New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
            }
            Write-Host "[ok] 新闻域运行时目录: .harness-news-runtime/"
        }
    }
}

# === 生成 MEMORY.md ===
function Generate-Memory {
    $memFile = Join-Path $Root 'MEMORY.md'
    if ($DryRun) {
        Write-DryRun "would create MEMORY.md (route=$Route)"
        return
    }
    if ((Test-Path $memFile) -and -not $Force) {
        Write-Host "[keep] MEMORY.md 已存在 (use -Force to overwrite)"
        return
    }

    $date = Get-Date -Format 'yyyy-MM-dd'
    $datetime = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'

    switch ($Route) {
        'code' {
@"
# 项目记忆 — Route: code

## 项目信息
- 名称:
- 技术栈:
- 语言:

## 关键决策
- 日期: $date

## 进行中
in_progress:
  - current_phase: init

## 阻塞项
blockers: []

## 测试状态
testing:
  framework: 待定
  last_run: 未执行

## 代码审查
review:
  status: 待配置

## 最后更新
last_updated: $datetime
"@ | Set-Content -Path $memFile -Encoding UTF8
        }
        'novel' {
@"
# 项目记忆 — Route: novel

## 项目信息
- 书名:
- 题材:
- 核心卖点:
- 目标字数:

## 人物状态追踪
characters: []

## 伏笔追踪
foreshadowing: []

## 章节索引+一句话摘要
chapter_index: []

## 进行中
in_progress:
  - current_phase: init

## 阻塞项
blockers: []

## 最后更新
last_updated: $datetime
"@ | Set-Content -Path $memFile -Encoding UTF8
        }
        'news' {
@"
# 项目记忆 — Route: news

## 项目信息
- 集名:
- 领域:
- 更新频率:

## 进行中
in_progress:
  - current_phase: init

## 阻塞项
blockers: []

## 最后更新
last_updated: $datetime
"@ | Set-Content -Path $memFile -Encoding UTF8
        }
    }
    Write-Host "[ok] MEMORY.md 已创建 (Route: $Route)"
}

# === 平台投影 ===

function Bootstrap-Cursor {
    Copy-Tree (Join-Path $Kit 'adapters\cursor\.cursor') (Join-Path $Root '.cursor') 'Cursor'
    Sync-SkillsPlatform 'cursor'
}

function Bootstrap-Trae {
    Copy-Tree (Join-Path $Kit 'adapters\trae\.trae') (Join-Path $Root '.trae') 'Trae'
    Sync-SkillsPlatform 'trae'
}

function Bootstrap-Claude {
    if ($DryRun) {
        Write-DryRun 'Claude Code: would copy adapters/claude/.claude -> .claude/'
        return
    }
    $src = Join-Path $Kit 'adapters\claude\.claude'
    $dst = Join-Path $Root '.claude'
    if (Test-Path $src) {
        Copy-Tree $src $dst 'Claude Code'
    }
}

function Bootstrap-Agents {
    if ($DryRun) {
        Write-DryRun 'would copy adapters/agents/AGENTS.md -> AGENTS.md'
        return
    }
    Copy-Item (Join-Path $Kit 'adapters\agents\AGENTS.md') (Join-Path $Root 'AGENTS.md') -Force
    Write-Host '[ok] AGENTS.md'
}

function Bootstrap-Codex {
    if ($DryRun) {
        Write-DryRun 'Codex: would copy AGENTS.md'
        return
    }
    Bootstrap-Agents
    Write-Host '[ok] Codex: harness-foundry/adapters/codex/entrypoints/AGENTS.harness.md'
}

function Bootstrap-Mimocode {
    if ($DryRun) {
        Write-DryRun 'MimoCode: would copy adapters/mimocode -> .mimocode/'
        return
    }
    $src = Join-Path $Kit 'adapters\mimocode'
    $dst = Join-Path $Root '.mimocode'
    if (Test-Path $src) {
        Copy-Tree $src $dst 'MimoCode'
    }
}

# === 主流程 ===

# 环境检查
$missing = $false
@('bash', 'mkdir') | ForEach-Object {
    if (-not (Get-Command $_ -ErrorAction SilentlyContinue)) {
        Write-Warning "[warn] 缺少命令: $_"
    }
}
if (-not (Test-Path $Kit)) {
    Write-Error "harness-foundry 目录不存在: $Kit"
    exit 1
}
if ($missing) { exit 1 }
Write-Host "[ok] 环境检查通过"

switch ($Target) {
    'cursor'   { Bootstrap-Cursor }
    'trae'     { Bootstrap-Trae }
    'claude'   { Bootstrap-Claude }
    'codex'    { Bootstrap-Codex }
    'mimocode' { Bootstrap-Mimocode }
    'all'      {
        Bootstrap-Agents
        Bootstrap-Cursor
        Bootstrap-Trae
        Bootstrap-Claude
        Bootstrap-Codex
        Bootstrap-Mimocode
    }
}

Create-RuntimeDirs
Generate-Memory

Write-Host ""
Write-Host "Harness Foundry bootstrap complete (target=$Target, route=$Route)."
Write-Host "Quick start: 见 core/intent-routing.md 路由表"
Write-Host "Docs: harness-foundry/README.md"
