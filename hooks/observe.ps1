# hooks/observe.ps1 - Instinct 捕获辅助脚本 (PowerShell 版本)
# 记录工具调用事件到 .observations.jsonl，供 instinct 提取使用
#
# 用法:
#   .\hooks\observe.ps1 pre <tool_name>   # PreToolUse 阶段
#   .\hooks\observe.ps1 post <tool_name>  # PostToolUse 阶段
#   .\hooks\observe.ps1 stop              # Stop 阶段（清理）
#   .\hooks\observe.ps1 stats             # 查看统计

param(
    [Parameter(Position=0)]
    [ValidateSet("pre", "post", "stop", "stats")]
    [string]$Phase,

    [Parameter(Position=1)]
    [string]$Tool = ""
)

$ErrorActionPreference = "SilentlyContinue"

function Get-ProjectId {
    try {
        $root = git rev-parse --show-toplevel 2>$null
        if ($root) {
            return Split-Path $root -Leaf
        }
    } catch {}
    return Split-Path (Get-Location) -Leaf
}

$ProjectId = Get-ProjectId
$ObservationsFile = ".observations.jsonl"
$InstinctDir = "references\instincts\project\$ProjectId\instincts"

switch ($Phase) {
    "pre" {
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $entry = @{
            timestamp = $timestamp
            project   = $ProjectId
            tool      = $Tool
            phase     = "pre"
        } | ConvertTo-Json -Compress
        Add-Content -Path $ObservationsFile -Value $entry -Encoding UTF8
    }
    "post" {
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $entry = @{
            timestamp = $timestamp
            project   = $ProjectId
            tool      = $Tool
            phase     = "post"
        } | ConvertTo-Json -Compress
        Add-Content -Path $ObservationsFile -Value $entry -Encoding UTF8
    }
    "stop" {
        New-Item -ItemType Directory -Force -Path $InstinctDir | Out-Null

        # 压缩过大的 observations 文件（保留最近 100 条）
        if (Test-Path $ObservationsFile) {
            $lines = Get-Content $ObservationsFile
            if ($lines.Count -gt 100) {
                $lines[-100..-1] | Set-Content $ObservationsFile -Encoding UTF8
            }
        }

        # 输出统计信息
        $instinctCount = 0
        if (Test-Path $InstinctDir) {
            $instinctCount = (Get-ChildItem -Path $InstinctDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
        }
        Write-Output "Instinct 统计: project=$ProjectId, count=$instinctCount"
    }
    "stats" {
        Write-Output "=== Instinct 统计 ==="
        Write-Output "项目: $ProjectId"

        $count = 0
        if (Test-Path $InstinctDir) {
            $count = (Get-ChildItem -Path $InstinctDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
        }
        Write-Output "项目 instinct 数量: $count"

        $globalDir = "references\instincts\global\instincts"
        $globalCount = 0
        if (Test-Path $globalDir) {
            $globalCount = (Get-ChildItem -Path $globalDir -Filter "*.yaml" -ErrorAction SilentlyContinue).Count
        }
        Write-Output "全局 instinct 数量: $globalCount"

        $obsCount = 0
        if (Test-Path $ObservationsFile) {
            $obsCount = (Get-Content $ObservationsFile).Count
        }
        Write-Output "Observations 记录数: $obsCount"
    }
    default {
        Write-Output "用法: .\hooks\observe.ps1 {pre|post|stop|stats} [tool_name]"
        exit 1
    }
}
