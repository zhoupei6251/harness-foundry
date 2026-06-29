# Sync skills from .agents/skills per _manifest.yaml (Windows)
# 功能与 sync-skills.sh 对齐：--dry-run + SKIP_FROM_SYNC + mimocode
param(
    [ValidateSet('all','cursor','trae','mimocode')]
    [string]$Target = 'all',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$ManifestPath = Join-Path $Root '.agents\skills\_manifest.yaml'
$Src = Join-Path $Root '.agents\skills'
$KitCursorSkills = Join-Path $Root 'adapters\cursor\.cursor\skills'

# 第三方来源 skill 列表（不参与 sync）
$SKIP_FROM_SYNC = @(
    'subagent-driven-development',
    'dispatching-parallel-agents',
    'using-git-worktrees',
    'executing-plans'
)

if (-not (Test-Path $ManifestPath)) {
    Write-Host "Warn: manifest not found: $ManifestPath" -ForegroundColor Yellow
    Write-Host "Run 'bash scripts/sync-skills.sh --target all --dry-run' first or create .agents/skills/_manifest.yaml"
    exit 0
}

function Get-LayerSkills([string]$Layer) {
    $lines = Get-Content $ManifestPath -Encoding UTF8
    $inLayer = $false
    $result = @()
    foreach ($line in $lines) {
        # Layer header: "  layer_name:"
        if ($line -match "^  ${Layer}:`s*$") { $inLayer = $true; continue }
        # Next layer header → exit
        if ($inLayer -and $line -match '^  [a-z_]+:') { break }
        # Skill entry: "      - skill_name"
        if ($inLayer -and $line -match '^    - (.+)$') {
            $result += $Matches[1].Trim()
        }
    }
    $result
}

function Get-ProjectionLayers([string]$Platform) {
    $lines = Get-Content $ManifestPath -Encoding UTF8
    $inPlatform = $false
    foreach ($line in $lines) {
        if ($line -match "^  ${Platform}:`s*$") { $inPlatform = $true; continue }
        if ($inPlatform -and $line -match '^  [a-z]+:') { break }
        if ($inPlatform -and $line -match 'include_layers:\s*\[([^\]]+)\]') {
            return ($Matches[1] -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
    }
    @()
}

function Get-TargetSkills([string]$Platform) {
    $seen = @{}
    $list = @()
    foreach ($layer in (Get-ProjectionLayers $Platform)) {
        foreach ($s in (Get-LayerSkills $layer)) {
            if (-not $seen.ContainsKey($s)) {
                $seen[$s] = $true
                $list += $s
            }
        }
    }
    $list
}

function Copy-Skill([string]$Slug, [string]$DstBase) {
    if ($Slug -notmatch '^[a-z0-9-]+$') {
        Write-Host "  [skip] invalid slug: $Slug"
        return
    }
    if ($SKIP_FROM_SYNC -contains $Slug) {
        Write-Host "  [skip-from-sync] $Slug — 第三方来源，保留本地副本"
        return
    }
    $srcDir = Join-Path $Src $Slug
    if (-not (Test-Path $srcDir)) {
        $srcDir = Join-Path $KitCursorSkills $Slug
    }
    if (-not (Test-Path $srcDir)) {
        $srcDir = Join-Path $Root "skills\$Slug"
    }
    if (-not (Test-Path $srcDir)) {
        Write-Host "  [skip] $Slug"
        return
    }
    if ($DryRun) {
        Write-Host "  [dry] $Slug -> $DstBase\$Slug"
        return
    }
    $dest = Join-Path $DstBase $Slug
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $srcDir $dest -Recurse -Force
    Write-Host "  [ok] $Slug"
}

function Sync-Platform([string]$Platform) {
    $dst = switch ($Platform) {
        'cursor'   { Join-Path $Root '.cursor\skills' }
        'trae'     { Join-Path $Root '.trae\skills' }
        'mimocode' { Join-Path $Root 'adapters\mimocode\.agents\skills' }
    }
    if ($DryRun) {
        Write-Host "==> [dry] Sync $Platform -> $dst"
    } else {
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Write-Host "==> Sync $Platform -> $dst"
    }
    $skills = @(Get-TargetSkills $Platform)
    foreach ($s in $skills) { Copy-Skill $s $dst }

    # 清理多余 skill
    if (-not $DryRun -and (Test-Path $dst)) {
        Get-ChildItem $dst -Directory | ForEach-Object {
            if ($_.Name -eq 'aigc-platform-backend') { return }
            if ($skills -notcontains $_.Name -and $SKIP_FROM_SYNC -notcontains $_.Name) {
                Write-Host "  [prune] $($_.FullName)"
                Remove-Item $_.FullName -Recurse -Force
            }
        }
    }
    Write-Host "==> ${Platform}: $($skills.Count) skills (含 $($SKIP_FROM_SYNC.Count) 第三方 skip)"
}

switch ($Target) {
    'cursor'   { Sync-Platform 'cursor' }
    'trae'     { Sync-Platform 'trae' }
    'mimocode' { Sync-Platform 'mimocode' }
    'all'      { Sync-Platform 'cursor'; Sync-Platform 'trae'; Sync-Platform 'mimocode' }
}

Write-Host 'Done.'
