# Understand-Anything 多平台集成脚本 (Windows PowerShell)
# 集成到 Harness Foundry 支持的所有平台：Claude Code, Cursor, Trae, Codex
#
# Usage:
#   .\scripts\install-understand-anything.ps1              # 交互式安装
#   .\scripts\install-understand-anything.ps1 -All       # 安装所有平台
#   .\scripts\install-understand-anything.ps1 -Claude      # 仅 Claude Code
#   .\scripts\install-understand-anything.ps1 -Trae        # 仅 Trae
#   .\scripts\install-understand-anything.ps1 -Cursor      # 仅 Cursor
#   .\scripts\install-understand-anything.ps1 -Codex       # 仅 Codex
#   .\scripts\install-understand-anything.ps1 -Uninstall   # 卸载
#   .\scripts\install-understand-anything.ps1 -DryRun     # 预览

param(
    [switch]$All,
    [switch]$Claude,
    [switch]$Cursor,
    [switch]$Trae,
    [switch]$Codex,
    [switch]$DryRun,
    [switch]$Uninstall,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Understand-Anything 源码位置
$UA_REPO_DIR = if ($env:UA_REPO_DIR) { $env:UA_REPO_DIR } else { Join-Path $HOME '.understand-anything\repo' }
$UA_PLUGIN_DIR = Join-Path $UA_REPO_DIR 'understand-anything-plugin'

# 检测本地克隆位置
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$LocalClone = Join-Path $RepoRoot 'reference_github\Understand-Anything'
if (Test-Path (Join-Path $LocalClone 'understand-anything-plugin')) {
    $UA_PLUGIN_DIR = Join-Path $LocalClone 'understand-anything-plugin'
}

# Skills 源目录
$UA_SKILLS_SRC = Join-Path $UA_PLUGIN_DIR 'skills'

# 各平台 Skills 目标目录
$CLAUDE_SKILLS = Join-Path $RepoRoot '.claude\skills'
$CURSOR_SKILLS = Join-Path $RepoRoot '.cursor\skills'
$TRAE_SKILLS = Join-Path $RepoRoot '.trae\skills'
$CODEX_SKILLS = Join-Path $HOME '.agents\skills'

# 全局安装目录
$GLOBAL_CLAUDE_SKILLS = Join-Path $HOME '.claude\skills'
$GLOBAL_TRAE_SKILLS = Join-Path $HOME '.trae\skills'

function Show-Usage {
    @"
Understand-Anything 多平台集成脚本 (Windows)

Usage: install-understand-anything.ps1 [OPTIONS]

选项:
  -All         安装到所有支持的平台
  -Claude      仅 Claude Code
  -Cursor      仅 Cursor
  -Trae        仅 Trae
  -Codex       仅 Codex
  -DryRun      预览模式，不实际执行
  -Uninstall   卸载所有平台的集成
  -Help        显示帮助

示例:
  .\scripts\install-understand-anything.ps1 -All
  .\scripts\install-understand-anything.ps1 -Trae -Cursor
"@
}

function Get-SkillNames {
    if (Test-Path $UA_SKILLS_SRC) {
        Get-ChildItem -Path $UA_SKILLS_SRC -Directory | Select-Object -ExpandProperty Name
    }
}

function Check-UA {
    if (-not (Test-Path $UA_SKILLS_SRC)) {
        Write-Host "Warn: Understand-Anything skills 未找到: $UA_SKILLS_SRC" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "请先安装 Understand-Anything:"
        Write-Host "  git clone https://github.com/Egonex-AI/Understand-Anything.git `"$env:USERPROFILE\.understand-anything\repo`""
        Write-Host "  cd `$env:USERPROFILE\.understand-anything\repo; pnpm install"
        Write-Host ""
        Write-Host "或者设置 UA_REPO_DIR 环境变量指向已克隆的目录"
        exit 1
    }

    Write-Host "[INFO] 使用 Understand-Anything: $UA_PLUGIN_DIR" -ForegroundColor Green
    $skills = (Get-SkillNames) -join ', '
    Write-Host "  可用 Skills: $skills"
    Write-Host ""
}

function Copy-Skills {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$Platform
    )

    if (-not (Test-Path $Src)) {
        Write-Host "[ERROR] 源目录不存在: $Src" -ForegroundColor Red
        return
    }

    if (-not (Test-Path $Dst)) {
        New-Item -ItemType Directory -Path $Dst -Force | Out-Null
    }

    if ($DryRun) {
        Write-Host "  [dry] ${Platform}: 复制 skills -> $Dst"
        foreach ($skill in Get-SkillNames) {
            Write-Host "       - $skill"
        }
        return
    }

    $count = 0
    foreach ($skill in Get-SkillNames) {
        $skillSrc = Join-Path $Src $skill
        $skillDst = Join-Path $Dst $skill

        if (Test-Path $skillSrc) {
            if (Test-Path $skillDst) {
                Remove-Item -Path $skillDst -Recurse -Force
            }
            Copy-Item -Path $skillSrc -Destination $skillDst -Recurse
            Write-Host "  + $skill -> $Dst\$skill"
            $count++
        }
    }

    Write-Host "[OK] 已安装 $count 个 Skills 到 $Platform" -ForegroundColor Green
}

function New-Symlink {
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    if (-not (Test-Path $TargetPath)) {
        return $false
    }

    # 使用 mklink /J 创建 junction (Windows)
    if (Test-Path $LinkPath) {
        if ((Get-Item $LinkPath).LinkType -eq 'SymbolicLink' -or (Get-Item $LinkPath).LinkType -eq 'Junction') {
            Remove-Item -Path $LinkPath -Force
        } else {
            return $false
        }
    }

    $result = cmd /c mklink /J `"$LinkPath`" `"$TargetPath`" 2>&1
    return $LASTEXITCODE -eq 0
}

function Link-Skills {
    param(
        [string]$Src,
        [string]$Dst,
        [string]$Platform
    )

    if (-not (Test-Path $Src)) {
        Write-Host "[ERROR] 源目录不存在: $Src" -ForegroundColor Red
        return
    }

    if (-not (Test-Path $Dst)) {
        New-Item -ItemType Directory -Path $Dst -Force | Out-Null
    }

    if ($DryRun) {
        Write-Host "  [dry] ${Platform}: 创建符号链接 -> $Dst"
        foreach ($skill in Get-SkillNames) {
            Write-Host "       - $skill"
        }
        return
    }

    $count = 0
    foreach ($skill in Get-SkillNames) {
        $skillSrc = Join-Path $Src $skill
        $skillLink = Join-Path $Dst $skill

        if (-not (Test-Path $skillSrc)) {
            continue
        }

        if (New-Symlink -LinkPath $skillLink -TargetPath $skillSrc) {
            Write-Host "  + $skill -> $Dst\$skill (junction)"
            $count++
        } else {
            # Fallback: copy
            Copy-Item -Path $skillSrc -Destination $skillLink -Recurse -Force
            Write-Host "  + $skill -> $Dst\$skill (copy fallback)"
            $count++
        }
    }

    Write-Host "[OK] 已创建 $count 个链接到 $Platform" -ForegroundColor Green
}

function Install-Claude {
    Write-Host ""
    Write-Host "==> Claude Code 安装" -ForegroundColor Blue
    Write-Host "================================"

    if ($Uninstall) {
        if (Test-Path $CLAUDE_SKILLS) {
            foreach ($skill in Get-SkillNames) {
                $path = Join-Path $CLAUDE_SKILLS $skill
                if (Test-Path $path) {
                    Remove-Item -Path $path -Recurse -Force
                }
            }
            Write-Host "[OK] 已卸载 Claude Code Skills" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Claude Code Skills 不存在，跳过"
        }
        return
    }

    Write-Host ""
    Write-Host "Claude Code 推荐使用 Marketplace 安装:"
    Write-Host "  1. 在 Claude Code 中运行:"
    Write-Host "     /plugin marketplace add Egonex-AI/Understand-Anything"
    Write-Host "     /plugin install understand-anything"
    Write-Host ""
    Write-Host "  2. 或者手动复制 Skills 到项目目录:"
    Write-Host ""

    if ((Test-Path $RepoRoot) -or $DryRun) {
        Copy-Skills -Src $UA_SKILLS_SRC -Dst $CLAUDE_SKILLS -Platform "Claude Code (项目)"
    }

    if ((Test-Path $GLOBAL_CLAUDE_SKILLS) -or $DryRun) {
        Copy-Skills -Src $UA_SKILLS_SRC -Dst $GLOBAL_CLAUDE_SKILLS -Platform "Claude Code (全局)"
    }
}

function Install-Cursor {
    Write-Host ""
    Write-Host "==> Cursor 安装" -ForegroundColor Blue
    Write-Host "================================"

    if ($Uninstall) {
        if (Test-Path $CURSOR_SKILLS) {
            foreach ($skill in Get-SkillNames) {
                $path = Join-Path $CURSOR_SKILLS $skill
                if (Test-Path $path) {
                    Remove-Item -Path $path -Recurse -Force
                }
            }
            Write-Host "[OK] 已卸载 Cursor Skills" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Cursor Skills 不存在，跳过"
        }
        return
    }

    Copy-Skills -Src $UA_SKILLS_SRC -Dst $CURSOR_SKILLS -Platform "Cursor"
}

function Install-Trae {
    Write-Host ""
    Write-Host "==> Trae 安装" -ForegroundColor Blue
    Write-Host "================================"

    if ($Uninstall) {
        if (Test-Path $TRAE_SKILLS) {
            foreach ($skill in Get-SkillNames) {
                $path = Join-Path $TRAE_SKILLS $skill
                if (Test-Path $path) {
                    Remove-Item -Path $path -Recurse -Force
                }
            }
            Write-Host "[OK] 已卸载 Trae Skills" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Trae Skills 不存在，跳过"
        }
        return
    }

    Link-Skills -Src $UA_SKILLS_SRC -Dst $TRAE_SKILLS -Platform "Trae"

    if ((Test-Path $GLOBAL_TRAE_SKILLS) -or $DryRun) {
        Link-Skills -Src $UA_SKILLS_SRC -Dst $GLOBAL_TRAE_SKILLS -Platform "Trae (全局)"
    }
}

function Install-Codex {
    Write-Host ""
    Write-Host "==> Codex 安装" -ForegroundColor Blue
    Write-Host "================================"

    if ($Uninstall) {
        if (Test-Path $CODEX_SKILLS) {
            foreach ($skill in Get-SkillNames) {
                $path = Join-Path $CODEX_SKILLS $skill
                if (Test-Path $path) {
                    Remove-Item -Path $path -Recurse -Force
                }
            }
            Write-Host "[OK] 已卸载 Codex Skills" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Codex Skills 不存在，跳过"
        }
        return
    }

    Link-Skills -Src $UA_SKILLS_SRC -Dst $CODEX_SKILLS -Platform "Codex"
}

# === 参数处理 ===
if ($Help) { Show-Usage; return }

$Targets = @()
if ($All) { $Targets = @('claude', 'cursor', 'trae', 'codex') }
else {
    if ($Claude) { $Targets += 'claude' }
    if ($Cursor) { $Targets += 'cursor' }
    if ($Trae) { $Targets += 'trae' }
    if ($Codex) { $Targets += 'codex' }
}

if ($Targets.Count -eq 0) {
    $Targets = @('claude', 'cursor', 'trae', 'codex')
}

# === 主流程 ===
Write-Host ""
Write-Host "=============================================="
Write-Host "  Understand-Anything 多平台集成"
Write-Host "=============================================="
Write-Host ""

if ($Uninstall) {
    Write-Host "模式: 卸载"
} elseif ($DryRun) {
    Write-Host "模式: 预览 (dry-run)"
} else {
    Write-Host "模式: 安装"
}
Write-Host ""

Check-UA

foreach ($target in $Targets) {
    switch ($target) {
        'claude' { Install-Claude }
        'cursor' { Install-Cursor }
        'trae' { Install-Trae }
        'codex' { Install-Codex }
    }
}

Write-Host ""
Write-Host "=============================================="
if ($Uninstall) {
    Write-Host "[OK] 卸载完成!" -ForegroundColor Green
} else {
    Write-Host "[OK] 安装完成!" -ForegroundColor Green
}
Write-Host "=============================================="
Write-Host ""
Write-Host "下一步:"
Write-Host ""
Write-Host "  Claude Code: 重启后使用 /understand 开始分析"
Write-Host "  Cursor: 重启后使用 /understand 开始分析"
Write-Host "  Trae: 重启后使用 /understand 开始分析"
Write-Host "  Codex: 重启后使用 /understand 开始分析"
Write-Host ""
Write-Host "  文档: $UA_PLUGIN_DIR\README.md"
Write-Host ""
