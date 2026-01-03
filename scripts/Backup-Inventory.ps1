# Backup-Inventory.ps1
# Create timestamped local backup of inventory data

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $ScriptRoot "..")

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupDir = Join-Path $Root "backups"
$Dest = Join-Path $BackupDir $Timestamp

Clear-Host
Write-Host "=== Local Backup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source:      $Root"
Write-Host "Destination: $Dest"
Write-Host ""

$confirm = Read-Host "Type BACKUP to proceed"
if ($confirm -ne "BACKUP") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    Pause
    return
}

try {
    New-Item -ItemType Directory -Force -Path "$Dest\data", "$Dest\scripts" | Out-Null

    Write-Host ""
    Write-Host "Copying data..." -NoNewline
    robocopy "$Root\data" "$Dest\data" /E /Z /R:2 /W:2 /NJH /NJS /NDL /NC /NS | Out-Null
    Write-Host " done" -ForegroundColor Green

    Write-Host "Copying scripts..." -NoNewline
    robocopy "$Root\scripts" "$Dest\scripts" /E /Z /R:2 /W:2 /NJH /NJS /NDL /NC /NS | Out-Null
    Write-Host " done" -ForegroundColor Green

    # Copy launcher scripts
    Copy-Item "$Root\Start-Inventory.ps1" $Dest -ErrorAction SilentlyContinue
    Copy-Item "$Root\Start-Inventory-GUI.ps1" $Dest -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "Backup complete: $Dest" -ForegroundColor Green
} catch {
    Write-Host "Backup failed: $_" -ForegroundColor Red
}

Pause
