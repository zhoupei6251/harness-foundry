# Sync skills from .agents/skills per _manifest.yaml (Windows)
param(
    [ValidateSet('all','cursor','trae')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ManifestPath = Join-Path $Root '.agents\skills\_manifest.yaml'
$Src = Join-Path $Root '.agents\skills'
$KitCursorSkills = Join-Path $Root 'harness-kit\adapters\cursor\.cursor\skills'

if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }

function Get-LayerSkills($Layer) {
    $lines = Get-Content $ManifestPath -Encoding UTF8
    $inLayer = $false
    $inSkills = $false
    $result = @()
    foreach ($line in $lines) {
        if ($line -match "^  ${Layer}:`s*$") { $inLayer = $true; $inSkills = $false; continue }
        if ($inLayer -and $line -match '^  [a-z_]+:') { break }
        if ($inLayer -and $line -match '^\s+skills:\s*$') { $inSkills = $true; continue }
        if ($inLayer -and $inSkills -and $line -match '^\s+-\s+(.+)$') {
            $result += $Matches[1].Trim()
        }
    }
    $result
}

function Get-ProjectionLayers($Platform) {
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

function Get-TargetSkills($Platform) {
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

function Copy-Skill($Slug, $DstBase) {
    if ($Slug -notmatch '^[a-z0-9-]+$') {
        Write-Host "  [skip] invalid slug: $Slug"
        return
    }
    $srcDir = Join-Path $Src $Slug
    if (-not (Test-Path $srcDir)) {
        $srcDir = Join-Path $KitCursorSkills $Slug
    }
    if (-not (Test-Path $srcDir)) {
        Write-Host "  [skip] $Slug"
        return
    }
    $dest = Join-Path $DstBase $Slug
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $srcDir $dest -Recurse -Force
    Write-Host "  [ok] $Slug"
}

function Sync-Platform($Platform) {
    $dst = if ($Platform -eq 'cursor') { Join-Path $Root '.cursor\skills' } else { Join-Path $Root '.trae\skills' }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Write-Host "==> Sync $Platform -> $dst"
    $skills = @(Get-TargetSkills $Platform)
    foreach ($s in $skills) { Copy-Skill $s $dst }
    if (Test-Path $dst) {
        Get-ChildItem $dst -Directory | ForEach-Object {
            if ($_.Name -eq 'aigc-platform-backend') { return }
            if ($skills -notcontains $_.Name) {
                Write-Host "  [prune] $($_.FullName)"
                Remove-Item $_.FullName -Recurse -Force
            }
        }
    }
    Write-Host "==> ${Platform}: $($skills.Count) skills"
}

switch ($Target) {
    'cursor' { Sync-Platform 'cursor' }
    'trae'   { Sync-Platform 'trae' }
    'all'    { Sync-Platform 'cursor'; Sync-Platform 'trae' }
}

Write-Host 'Done.'
