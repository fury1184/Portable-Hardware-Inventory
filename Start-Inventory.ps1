# ============================================================
# Start-Inventory.ps1
# Single entry point for Portable Hardware Inventory
# ============================================================

Clear-Host
Write-Host "Starting Portable Hardware Inventory..." -ForegroundColor Cyan

# -------------------------------
# Global Initialization Flags
# -------------------------------
$Global:InventoryInitialized = $true
$Global:InventoryMode        = 'INVENTORY'   # INVENTORY | LOOKUP
$Global:LookupOnly           = $false

# -------------------------------
# Resolve Root Path
# -------------------------------
$Global:InventoryRoot   = $PSScriptRoot
$Global:HardwareDbPath  = Join-Path $Global:InventoryRoot 'data\hardware_db.json'

# -------------------------------
# Ensure data directory exists
# -------------------------------
$dataDir = Join-Path $Global:InventoryRoot 'data'
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
}

# -------------------------------
# Ensure database exists
# -------------------------------
if (-not (Test-Path $Global:HardwareDbPath)) {
    Write-Host "Creating hardware database..." -ForegroundColor Yellow
    '{}' | Set-Content -Encoding UTF8 $Global:HardwareDbPath
}

# -------------------------------
# Determine write capability
# -------------------------------
try {
    $item = Get-Item $Global:HardwareDbPath
    if ($item.IsReadOnly) {
        throw "Database is read-only"
    }
}
catch {
    Write-Host "Database is read-only. Switching to LOOKUP mode." -ForegroundColor Yellow
    $Global:InventoryMode = 'LOOKUP'
    $Global:LookupOnly    = $true
}

# -------------------------------
# Load HardwareInventory module
# -------------------------------
$modulePath = Join-Path $Global:InventoryRoot 'module\HardwareInventory.psm1'
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Host "WARNING: HardwareInventory module not found at /module." -ForegroundColor Yellow
}

# -------------------------------
# Status Header (never lies)
# -------------------------------
Write-Host "====================================="
Write-Host "Portable Hardware Inventory"
Write-Host "Root     : $Global:InventoryRoot"
Write-Host "Database : $Global:HardwareDbPath"
Write-Host "Mode     : $Global:InventoryMode"
Write-Host "Runtime  : PowerShell $($PSVersionTable.PSVersion)"
Write-Host "====================================="
Write-Host ""

# -------------------------------
# Launcher Menu
# -------------------------------
Write-Host "Select interface:"
Write-Host "  1) CLI Inventory"
Write-Host "  2) GUI Inventory"
Write-Host ""
$choice = Read-Host "Choice"

switch ($choice) {
    '1' {
        . (Join-Path $Global:InventoryRoot 'Hardware-Inventory.ps1')
    }
    '2' {
        . (Join-Path $Global:InventoryRoot 'Start-Inventory-GUI.ps1')
    }
    default {
        Write-Host "Invalid selection." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Inventory session ended."
Pause
