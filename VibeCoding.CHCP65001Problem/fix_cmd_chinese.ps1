# =====================================================================
# Fix CMD + PowerShell Chinese Display - Comprehensive Fix
# 修復 cmd / PowerShell 中文亂碼 - 完整診斷與修復腳本
# =====================================================================

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Section($title) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host $title -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

# ---------------------------------------------------------------------
Write-Section "[1/7] 目前狀態診斷"
# ---------------------------------------------------------------------

Write-Host "目前 cmd 預設代碼頁:" -ForegroundColor Yellow
try {
    $cp = (Get-ItemProperty -Path 'HKCU:\Console' -Name CodePage -ErrorAction Stop).CodePage
    Write-Host "  HKCU\Console\CodePage = $cp (0x$('{0:X}' -f $cp))"
} catch { Write-Host "  HKCU\Console\CodePage = (未設定)" }

Write-Host "目前 cmd 預設字型:" -ForegroundColor Yellow
try {
    $face = (Get-ItemProperty -Path 'HKCU:\Console' -Name FaceName -ErrorAction Stop).FaceName
    Write-Host "  HKCU\Console\FaceName = '$face'"
} catch { Write-Host "  HKCU\Console\FaceName = (未設定，使用點陣字型)" }

Write-Host "AutoRun 設定:" -ForegroundColor Yellow
try {
    $ar = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name AutoRun -ErrorAction Stop).AutoRun
    Write-Host "  AutoRun = '$ar'"
} catch { Write-Host "  AutoRun = (未設定)" }

Write-Host "系統 ANSI 代碼頁:" -ForegroundColor Yellow
$acp = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name ACP).ACP
$oemcp = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -Name OEMCP).OEMCP
Write-Host "  ACP = $acp,  OEMCP = $oemcp"
Write-Host "  (950=Big5, 65001=UTF-8, 936=GBK)"

Write-Host "PowerShell 編碼:" -ForegroundColor Yellow
Write-Host "  [Console]::OutputEncoding = $([Console]::OutputEncoding.WebName)"
Write-Host "  `$OutputEncoding           = $($OutputEncoding.WebName)"

# ---------------------------------------------------------------------
Write-Section "[2/7] 偵測可用的中文字型"
# ---------------------------------------------------------------------

$fontsDir = "$env:WINDIR\Fonts"
$candidates = @(
    @{File='mingliu.ttc';   Name='MingLiU';      Desc='細明體 (繁中)'},
    @{File='mingliub.ttc';  Name='MingLiU';      Desc='細明體 (繁中)'},
    @{File='msjh.ttc';      Name='Microsoft JhengHei'; Desc='微軟正黑體 (繁中)'},
    @{File='msjhl.ttc';     Name='Microsoft JhengHei Light'; Desc='微軟正黑體 Light'},
    @{File='msyh.ttc';      Name='Microsoft YaHei'; Desc='微軟雅黑 (簡中)'},
    @{File='simsun.ttc';    Name='SimSun';       Desc='宋體 (簡中)'},
    @{File='nsimsun.ttf';   Name='NSimSun';      Desc='新宋體 (簡中)'},
    @{File='msgothic.ttc';  Name='MS Gothic';    Desc='MS ゴシック (日文，含中文)'}
)

$installed = @()
foreach ($c in $candidates) {
    if (Test-Path (Join-Path $fontsDir $c.File)) {
        Write-Host "  [V] 找到: $($c.Name) - $($c.Desc)" -ForegroundColor Green
        $installed += $c
    }
}
if ($installed.Count -eq 0) {
    Write-Host "  [!] 未偵測到任何 CJK 字型檔！" -ForegroundColor Red
    $chosenFont = 'Consolas'
} else {
    $priority = @('MingLiU','Microsoft JhengHei','MS Gothic','NSimSun','SimSun','Microsoft YaHei')
    $chosenFont = $null
    foreach ($p in $priority) {
        if ($installed.Name -contains $p) { $chosenFont = $p; break }
    }
    if (-not $chosenFont) { $chosenFont = $installed[0].Name }
    Write-Host ""
    Write-Host "  -> 將使用字型: $chosenFont" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
Write-Section "[3/7] 清除 cmd 捷徑覆寫設定 (關鍵步驟)"
# ---------------------------------------------------------------------

$consoleSubKeys = Get-ChildItem 'HKCU:\Console' -ErrorAction SilentlyContinue
if ($consoleSubKeys) {
    Write-Host "找到以下 cmd 捷徑專屬設定（會覆寫預設值），準備刪除:" -ForegroundColor Yellow
    foreach ($k in $consoleSubKeys) {
        Write-Host "  刪除: $($k.PSChildName)" -ForegroundColor Gray
        Remove-Item -Path $k.PSPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[V] 已清除所有 cmd 捷徑覆寫設定" -ForegroundColor Green
} else {
    Write-Host "  (沒有捷徑覆寫設定，跳過)" -ForegroundColor Gray
}

# ---------------------------------------------------------------------
Write-Section "[4/7] 套用 cmd / Console 預設值"
# ---------------------------------------------------------------------

Set-ItemProperty -Path 'HKCU:\Console' -Name 'CodePage' -Value 65001 -Type DWord
Write-Host "[V] CodePage = 65001 (UTF-8)" -ForegroundColor Green

Set-ItemProperty -Path 'HKCU:\Console' -Name 'FaceName' -Value $chosenFont -Type String
Set-ItemProperty -Path 'HKCU:\Console' -Name 'FontFamily' -Value 54 -Type DWord
Set-ItemProperty -Path 'HKCU:\Console' -Name 'FontSize' -Value 1179648 -Type DWord
Set-ItemProperty -Path 'HKCU:\Console' -Name 'FontWeight' -Value 400 -Type DWord
Write-Host "[V] FaceName = $chosenFont" -ForegroundColor Green

if (-not (Test-Path 'HKCU:\Software\Microsoft\Command Processor')) {
    New-Item -Path 'HKCU:\Software\Microsoft\Command Processor' -Force | Out-Null
}
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Command Processor' -Name 'AutoRun' -Value '@chcp 65001>nul' -Type String
Write-Host "[V] cmd AutoRun = '@chcp 65001>nul'" -ForegroundColor Green

# ---------------------------------------------------------------------
Write-Section "[5/7] 修改 PowerShell Profile (永久設定 PS 的 UTF-8)"
# ---------------------------------------------------------------------

$psProfileSnippet = @'

# === Auto-added: UTF-8 console encoding (修復中文亂碼) ===
try {
    [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $OutputEncoding           = [System.Text.UTF8Encoding]::new()
    chcp 65001 > $null
} catch {}
# === End auto-added ===

'@

# 處理 Windows PowerShell 5.x 的 profile
$ps5Profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps5Dir = Split-Path $ps5Profile
if (-not (Test-Path $ps5Dir)) { New-Item -ItemType Directory -Path $ps5Dir -Force | Out-Null }

if (Test-Path $ps5Profile) {
    $existing = Get-Content $ps5Profile -Raw -ErrorAction SilentlyContinue
    if ($existing -notmatch 'Auto-added: UTF-8 console encoding') {
        Add-Content -Path $ps5Profile -Value $psProfileSnippet -Encoding UTF8
        Write-Host "[V] 已附加 UTF-8 設定到 Windows PowerShell profile" -ForegroundColor Green
        Write-Host "    路徑: $ps5Profile" -ForegroundColor Gray
    } else {
        Write-Host "  Windows PowerShell profile 已包含 UTF-8 設定，跳過" -ForegroundColor Gray
    }
} else {
    Set-Content -Path $ps5Profile -Value $psProfileSnippet -Encoding UTF8
    Write-Host "[V] 已建立 Windows PowerShell profile (含 UTF-8 設定)" -ForegroundColor Green
    Write-Host "    路徑: $ps5Profile" -ForegroundColor Gray
}

# 處理 PowerShell 7+ 的 profile
$ps7Profile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$ps7Dir = Split-Path $ps7Profile
if (-not (Test-Path $ps7Dir)) { New-Item -ItemType Directory -Path $ps7Dir -Force | Out-Null }

if (Test-Path $ps7Profile) {
    $existing7 = Get-Content $ps7Profile -Raw -ErrorAction SilentlyContinue
    if ($existing7 -notmatch 'Auto-added: UTF-8 console encoding') {
        Add-Content -Path $ps7Profile -Value $psProfileSnippet -Encoding UTF8
        Write-Host "[V] 已附加 UTF-8 設定到 PowerShell 7 profile" -ForegroundColor Green
    } else {
        Write-Host "  PowerShell 7 profile 已包含 UTF-8 設定，跳過" -ForegroundColor Gray
    }
} else {
    Set-Content -Path $ps7Profile -Value $psProfileSnippet -Encoding UTF8
    Write-Host "[V] 已建立 PowerShell 7 profile (含 UTF-8 設定)" -ForegroundColor Green
}

# ---------------------------------------------------------------------
Write-Section "[6/7] 設定當前 session"
# ---------------------------------------------------------------------

chcp 65001 > $null
[Console]::InputEncoding  = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding           = [System.Text.UTF8Encoding]::new()
Write-Host "[V] 當前 session 已切到 UTF-8" -ForegroundColor Green

# ---------------------------------------------------------------------
Write-Section "[7/7] 測試 - 開啟新 cmd 與 PowerShell"
# ---------------------------------------------------------------------

Write-Host "啟動測試視窗..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# 測試 cmd
$cmdTest = 'echo === CMD 中文測試 === & chcp & echo. & echo 你好世界 繁體中文 測試 ABC 123 & echo. & pause'
Start-Process -FilePath 'cmd.exe' -ArgumentList '/k', $cmdTest

Start-Sleep -Seconds 1

# 測試 PowerShell
$psTest = @'
Write-Host "=== PowerShell 中文測試 ===" -ForegroundColor Cyan
Write-Host "OutputEncoding: $($OutputEncoding.WebName)"
Write-Host "Console::OutputEncoding: $([Console]::OutputEncoding.WebName)"
Write-Host ""
Write-Host "你好世界 繁體中文 測試 ABC 123"
Write-Host ""
Read-Host "按 Enter 關閉"
'@
Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoExit', '-Command', $psTest

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host " 完成！剛剛開了 cmd 和 PowerShell 兩個測試視窗給你看" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "如果還是亂碼:" -ForegroundColor Yellow
Write-Host "  1. 在那個視窗左上角圖示按右鍵 -> 內容 -> 字型分頁"
Write-Host "  2. 確認字型是 $chosenFont"
Write-Host "  3. 把測試視窗截圖給我"
Write-Host ""
Write-Host "終極方案 (徹底解但需重開機):" -ForegroundColor Yellow
Write-Host "  控制台 -> 地區 -> 系統管理 -> 變更系統地區設定"
Write-Host "  -> 勾選『Beta：使用 Unicode UTF-8 提供全球語言支援』-> 重開機"
Write-Host ""
Read-Host "Press Enter to close this window"
