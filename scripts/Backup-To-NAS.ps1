# Backup-To-NAS.ps1
# Backup inventory data to NAS share

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $ScriptRoot "..")

# ============================================
# CONFIGURE YOUR NAS PATH HERE
# ============================================
$NASPath = "\\NAS\Backups\Inventory"
# ============================================

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$Dest = Join-Path $NASPath $Timestamp

Clear-Host
Write-Host "=== NAS Backup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source:      $Root"
Write-Host "Destination: $Dest"
Write-Host ""

# Test NAS connectivity
if (-not (Test-Path (Split-Path $NASPath -Parent))) {
    Write-Host "[ERROR] Cannot reach NAS path: $NASPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check that:"
    Write-Host "  - NAS is online and accessible"
    Write-Host "  - Share path is correct"
    Write-Host "  - You have write permissions"
    Write-Host ""
    Pause
    return
}

$confirm = Read-Host "Type BACKUP to proceed"
if ($confirm -ne "BACKUP") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    Pause
    return
}

try {
    New-Item -ItemType Directory -Force -Path "$Dest\data", "$Dest\scripts" | Out-Null

    Write-Host ""
    Write-Host "Copying data to NAS..." -NoNewline
    robocopy "$Root\data" "$Dest\data" /E /Z /R:3 /W:5 /NJH /NJS /NDL /NC /NS | Out-Null
    Write-Host " done" -ForegroundColor Green

    Write-Host "Copying scripts to NAS..." -NoNewline
    robocopy "$Root\scripts" "$Dest\scripts" /E /Z /R:3 /W:5 /NJH /NJS /NDL /NC /NS | Out-Null
    Write-Host " done" -ForegroundColor Green

    # Copy launcher scripts
    Copy-Item "$Root\Start-Inventory.ps1" $Dest -ErrorAction SilentlyContinue
    Copy-Item "$Root\Start-Inventory-GUI.ps1" $Dest -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "NAS backup complete: $Dest" -ForegroundColor Green
} catch {
    Write-Host "Backup failed: $_" -ForegroundColor Red
}

Pause
