#!/usr/bin/env pwsh
<#
.SYNOPSIS
  自动从 skills/*/SKILL.md + _meta.json + categories.yaml 生成 skills/INDEX.md

.DESCRIPTION
  Windows PowerShell / pwsh 原生版本。功能与 gen-skill-index.sh 等价。
  无需 bash/WSL，直接在 Windows 上运行。

.PARAMETER Mode
  write    - 写入 INDEX.md（默认）
  dryrun   - 打印到 stdout
  check    - 仅校验，不一致则 exit 1

.EXAMPLE
  pwsh scripts/gen-skill-index.ps1
  pwsh scripts/gen-skill-index.ps1 -Mode dryrun
  pwsh scripts/gen-skill-index.ps1 -Mode check
#>

param(
    [ValidateSet("write", "dryrun", "check")]
    [string]$Mode = "write"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir
$SkillsDir = Join-Path $Root "skills"
$IndexFile = Join-Path $SkillsDir "INDEX.md"
$CategoriesFile = Join-Path $SkillsDir "categories.yaml"

# ========== 工具函数 ==========

function Strip-Quotes {
    param([string]$Value)
    if (-not $Value) { return "" }
    $Value -replace '^[''""]' -replace '[''""]$'
}

function Get-Frontmatter {
    param([string]$File, [string]$Field)
    if (-not $File -or -not $Field) { return "" }
    if (-not (Test-Path $File)) { return "" }

    $raw = Get-Content $File -Raw -Encoding UTF8
    # 提取 YAML frontmatter（两个 --- 之间）
    if ($raw -notmatch '(?s)^---\s*\r?\n(.*?)\r?\n---') { return "" }
    $fm = $Matches[1]
    $escapedField = [regex]::Escape($Field)

    # 先尝试 YAML 多行块（|, >, >-, |-）
    if ($fm -match "(?m)^${escapedField}:\s*[|>]-?\s*$") {
        $lines = $fm -split '\r?\n'
        $collecting = $false
        $buf = ""
        foreach ($line in $lines) {
            if ($line -match "^${escapedField}:\s*[|>]") {
                $collecting = $true
                continue
            }
            if ($collecting) {
                if ($line -match '^\s+(\S.*)$') {
                    if ($buf) { $buf += " " }
                    $buf += $Matches[1]
                }
                elseif ($line -match '^\S') {
                    break
                }
                # 空行忽略，继续累积
            }
        }
        return Strip-Quotes $buf
    }

    # 单行字段：description: "..." 或 description: ...
    if ($fm -match "(?m)^${escapedField}:\s*(.+)$") {
        return Strip-Quotes $Matches[1]
    }
    return ""
}

function Get-Meta {
    param([string]$File, [string]$Field)
    if (-not $File -or -not $Field) { return "" }
    if (-not (Test-Path $File)) { return "" }

    try {
        $json = Get-Content $File -Raw -Encoding UTF8 | ConvertFrom-Json
        $val = $json.$Field
        if ($val) { return $val.ToString() }
    }
    catch {
        # JSON 损坏或无此字段，返回空
    }
    return ""
}

# ========== 1. 收集所有 skill ==========
$skills = @()

Get-ChildItem $SkillsDir -Directory | ForEach-Object {
    $dir = $_.FullName
    $slug = $_.Name
    $skillMd = Join-Path $dir "SKILL.md"
    $metaJson = Join-Path $dir "_meta.json"

    if (-not (Test-Path $skillMd)) { return }

    $desc = Get-Frontmatter $skillMd "description"
    $purpose = Get-Meta $metaJson "purpose"
    $catId = Get-Meta $metaJson "category"
    $domain = Get-Meta $metaJson "domain"

    # _meta.json 的 purpose 优先于 SKILL.md frontmatter 的 description
    if ($purpose) { $desc = $purpose }
    if (-not $desc) { $desc = "(No description)" }
    if (-not $domain) { $domain = "shared" }

    $skills += [PSCustomObject]@{
        Slug   = $slug
        Desc   = $desc
        CatId  = $catId
        Domain = $domain
    }
}

# 按 slug 字母排序
$skills = $skills | Sort-Object Slug
$count = $skills.Count

# ========== 2. 解析 categories.yaml ==========
$categories = @()
$curId = ""
$curTitle = ""
$curDesc = ""

Get-Content $CategoriesFile -Encoding UTF8 | ForEach-Object {
    $line = $_.TrimEnd()
    if ($line -match '^\s*- id:\s*(.+)$') {
        if ($curId) {
            $categories += [PSCustomObject]@{ Id = $curId; Title = $curTitle; Desc = $curDesc }
        }
        $curId = $Matches[1]
        $curTitle = ""
        $curDesc = ""
    }
    elseif ($line -match '^\s*title:\s*(.+)$') {
        $curTitle = $Matches[1]
    }
    elseif ($line -match '^\s*description:\s*(.+)$') {
        $curDesc = $Matches[1]
    }
}
# 最后一个分类
if ($curId) {
    $categories += [PSCustomObject]@{ Id = $curId; Title = $curTitle; Desc = $curDesc }
}

# 建立 category 查找表
$catLookup = @{}
foreach ($cat in $categories) {
    $catLookup[$cat.Id] = $cat
}

# ========== 3. 计算分类成员 + 未分类 ==========
$catMembers = @{}
$unclassified = @()

foreach ($sk in $skills) {
    $c = $sk.CatId
    if ($c -and $catLookup.ContainsKey($c)) {
        if (-not $catMembers.ContainsKey($c)) {
            $catMembers[$c] = @()
        }
        $catMembers[$c] += $sk
    }
    else {
        $unclassified += $sk
    }
}

# ========== 4. 生成 INDEX.md 内容 ==========
$now = Get-Date -Format "yyyy-MM-dd"
$nl = "`n"

# 使用 List[string] 拼接，比 StringBuilder 更简洁
$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add("# Skill 索引$($nl)")
$lines.Add("$($nl)")
$lines.Add("> 自动生成的 Skill 索引 — 共 $count 个 Skill，采用扁平目录结构。$($nl)")
$lines.Add("> 最后更新：$now$($nl)")
$lines.Add("> 生成方式：``pwsh scripts/gen-skill-index.ps1``$($nl)")
$lines.Add("$($nl)")
$lines.Add("## 按字母顺序索引$($nl)")
$lines.Add("$($nl)")
$lines.Add("| 序号 | Skill 目录 | 说明 |$($nl)")
$lines.Add("|------|-----------|------|$($nl)")

$i = 1
foreach ($sk in $skills) {
    $lines.Add("| $i | ``$($sk.Slug)`` | $($sk.Desc) |$($nl)")
    $i++
}

$lines.Add("$($nl)")
$lines.Add("## 按功能分类$($nl)")
$lines.Add("$($nl)")
$lines.Add("> 分类定义见 [categories.yaml](./categories.yaml)。新 skill 请在 ``_meta.json`` 中声明 ``category`` 字段。$($nl)")
$lines.Add("$($nl)")

# categories.yaml
foreach ($cat in $categories) {
    $members = $catMembers[$cat.Id]
    if (-not $members -or $members.Count -eq 0) { continue }

    $lines.Add("### $($cat.Title)$($nl)")
    if ($cat.Desc) {
        $lines.Add("$($nl)")
        $lines.Add("_$($cat.Desc)_$($nl)")
    }
    $lines.Add("$($nl)")
    foreach ($m in $members) {
        $lines.Add("- ``$($m.Slug)`` - $($m.Desc)$($nl)")
    }
    $lines.Add("$($nl)")
}

# 未分类
if ($unclassified.Count -gt 0) {
    $lines.Add("### 未分类（待补 category 字段）$($nl)")
    $lines.Add("$($nl)")
    $lines.Add("> 以下 skill 尚未在 ``_meta.json`` 中声明 ``category``，建议补充。$($nl)")
    $lines.Add("$($nl)")
    foreach ($sk in $unclassified) {
        $lines.Add("- ``$($sk.Slug)`` - $($sk.Desc)$($nl)")
    }
    $lines.Add("$($nl)")
}

$lines.Add("---$($nl)")
$lines.Add("$($nl)")
$lines.Add("_本文件由脚本自动生成，请勿手改。如需修改分类，请编辑 ``skills/categories.yaml``；如需修改 skill 描述，请编辑 ``SKILL.md`` 的 frontmatter 或 ``_meta.json`` 的 ``purpose`` 字段。_$($nl)")

$content = $lines -join ""

# ========== 5.  ==========
switch ($Mode) {
    "dryrun" {
        Write-Output $content
        exit 0
    }
    "check" {
        if (-not (Test-Path $IndexFile)) {
            Write-Host "❌ INDEX.md 不存在，请运行：pwsh scripts/gen-skill-index.ps1"
            exit 1
        }
        $existing = Get-Content $IndexFile -Raw -Encoding UTF8
        # 直接用 LF 比对（bash 生成的也是 LF）
        if ($existing -ne $content) {
            Write-Host "❌ INDEX.md 与脚本生成内容不一致，请运行：pwsh scripts/gen-skill-index.ps1"
            exit 1
        }
        Write-Host "✅ INDEX.md 是最新的"
        exit 0
    }
    "write" {
        # 写 UTF8 无 BOM，LF 换行
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($IndexFile, $content, $utf8NoBom)
        Write-Host "✅ INDEX.md 已更新（$count 个 skill）"
        if ($unclassified.Count -gt 0) {
            Write-Host "ℹ️  有 $($unclassified.Count) 个 skill 未分类，详见 INDEX.md 末尾"
        }
        exit 0
    }
}
