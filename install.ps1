#
# oooing-video-translate Windows 一键安装与配置脚本 (PowerShell)
#
$ErrorActionPreference = "Stop"

$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $repoDir) { $repoDir = (Get-Location).Path }
$skillsSrc = Join-Path $repoDir "skills"
$claudeDst = Join-Path $HOME ".claude\skills"
$agentDst = Join-Path $repoDir ".agent\skills"
$agentsDst = Join-Path $repoDir ".agents\skills"
$defaultOutputDir = Join-Path $repoDir "output"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  oooing-video-translate 安装向导 (Windows) " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. 检查基础命令
Write-Host ""
Write-Host "==> 1. 检查命令行依赖..." -ForegroundColor Yellow
$missing = @()

foreach ($bin in @("ffmpeg", "yt-dlp", "python")) {
    if (Get-Command $bin -ErrorAction SilentlyContinue) {
        Write-Host "    [OK] $bin" -ForegroundColor Green
    } else {
        Write-Host "    [缺] $bin" -ForegroundColor Red
        $missing += $bin
    }
}

if (Get-Command python3 -ErrorAction SilentlyContinue) {
    Write-Host "    [OK] python3" -ForegroundColor Green
} else {
    Write-Host "    [提示] 未发现 python3 命令，建议为 python.exe 创建 python3 别名/副本" -ForegroundColor DarkYellow
}

# 2. 检查 Python 库
Write-Host ""
Write-Host "==> 2. 检查 Python 转写库..." -ForegroundColor Yellow
$whisperOk = $false
try {
    $res = python -c "import faster_whisper; print('OK')" 2>$null
    if ($res -match "OK") {
        Write-Host "    [OK] faster-whisper (Windows 引擎)" -ForegroundColor Green
        $whisperOk = $true
    }
} catch {}

if (-not $whisperOk) {
    Write-Host "    [缺] faster-whisper 未安装，请执行: pip install faster-whisper" -ForegroundColor Red
}

# 3. 创建输出目录
New-Item -ItemType Directory -Force -Path (Join-Path $defaultOutputDir "tmp") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $defaultOutputDir "data") | Out-Null
Write-Host ""
Write-Host "==> 3. 默认输出目录已就绪: $defaultOutputDir" -ForegroundColor Green

# 4. 部署技能目录
$skills = @("oooing-video-download", "oooing-video-md", "oooing-subtitle-polish")
New-Item -ItemType Directory -Force -Path $claudeDst | Out-Null
New-Item -ItemType Directory -Force -Path $agentDst | Out-Null
New-Item -ItemType Directory -Force -Path $agentsDst | Out-Null

$normalizedOut = ($defaultOutputDir -replace '\\', '/')

Write-Host ""
Write-Host "==> 4. 正在部署技能并生成配置文件..." -ForegroundColor Yellow
foreach ($s in $skills) {
    Write-Host "    -> 安装技能: $s" -ForegroundColor Cyan
    
    $targets = @(
        (Join-Path $claudeDst $s),
        (Join-Path $agentDst $s),
        (Join-Path $agentsDst $s)
    )
    
    foreach ($tgt in $targets) {
        if (Test-Path $tgt) { Remove-Item -Recurse -Force $tgt }
        Copy-Item -Recurse -Force (Join-Path $skillsSrc $s) $tgt
        
        $example = Join-Path $tgt "config.example.json"
        $config = Join-Path $tgt "config.json"
        if (Test-Path $example) {
            $json = Get-Content $example -Raw -Encoding UTF8 | ConvertFrom-Json
            $json.output_dir = $normalizedOut
            $json | ConvertTo-Json -Depth 10 | Set-Content $config -Encoding UTF8
        }
    }
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "  - Claude Code 技能目录: $claudeDst"
Write-Host "  - Antigravity 技能目录: $agentDst"
Write-Host "  - 输出目录: $defaultOutputDir"
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
