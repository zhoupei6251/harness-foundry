# Harness bootstrap (Windows PowerShell)
param(
    [ValidateSet('all','cursor','trae','codex')]
    [string]$Target = 'all',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Kit = Join-Path $Root 'harness-kit'

function Copy-Tree($Src, $Dst, $Label) {
    if (-not (Test-Path $Src)) {
        Write-Warning "Missing $Label source: $Src"
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

function Ensure-Artifacts {
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
}

function Sync-SkillsPlatform($Platform) {
    & (Join-Path $PSScriptRoot 'sync-skills.ps1') -Target $Platform
}

function Bootstrap-Cursor {
    Copy-Tree (Join-Path $Kit 'adapters\cursor\.cursor') (Join-Path $Root '.cursor') 'Cursor'
    Sync-SkillsPlatform 'cursor'
}

function Bootstrap-Trae {
    Copy-Tree (Join-Path $Kit 'adapters\trae\.trae') (Join-Path $Root '.trae') 'Trae'
    $tester = Join-Path $Root '.trae\agents\harness-tester.md'
    if (Test-Path $tester) { Remove-Item $tester -Force; Write-Host '[prune] harness-tester.md' }
    Sync-SkillsPlatform 'trae'
}

function Bootstrap-Agents {
    Copy-Item (Join-Path $Kit 'adapters\agents\AGENTS.md') (Join-Path $Root 'AGENTS.md') -Force
    Write-Host '[ok] AGENTS.md'
}

Ensure-Artifacts

switch ($Target) {
    'cursor' { Bootstrap-Cursor }
    'trae'   { Bootstrap-Trae }
    'codex'  { Bootstrap-Agents; Write-Host '[ok] Codex: harness-kit/adapters/codex/entrypoints/AGENTS.harness.md' }
    'all'    { Bootstrap-Agents; Bootstrap-Cursor; Bootstrap-Trae; Write-Host '[ok] Codex: harness-kit/adapters/codex/entrypoints/AGENTS.harness.md' }
}

Write-Host ""
Write-Host "Harness bootstrap complete (target=$Target)."
