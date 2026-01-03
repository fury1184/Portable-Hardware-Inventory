# ============================================================
# Hardware-Inventory.ps1
# Inventory operations (requires initialization)
# ============================================================

Clear-Host

# -------------------------------
# Guard: Must be initialized
# -------------------------------
if (-not $Global:InventoryInitialized) {
    Write-Host "ERROR: Inventory not initialized." -ForegroundColor Red
    Write-Host "Launch Start-Inventory.ps1 instead." -ForegroundColor Red
    Pause
    exit 1
}

if (-not $Global:HardwareDbPath -or -not (Test-Path $Global:HardwareDbPath)) {
    Write-Host "ERROR: Hardware database not found." -ForegroundColor Red
    Pause
    exit 1
}

# -------------------------------
# Status Header (never lies)
# -------------------------------
Write-Host "====================================="
Write-Host "Hardware Inventory"
Write-Host "Database : $Global:HardwareDbPath"
Write-Host "Mode     : $Global:InventoryMode"
Write-Host "Runtime  : PowerShell $($PSVersionTable.PSVersion)"
Write-Host "====================================="
Write-Host ""

# -------------------------------
# Helper: Assert inventory writable
# -------------------------------
function Assert-InventoryWritable {
    if ($Global:LookupOnly -or $Global:InventoryMode -ne 'INVENTORY') {
        throw "Inventory is in LOOKUP mode. Writes are disabled."
    }
}

# -------------------------------
# Load database
# -------------------------------
try {
    $HardwareDb = Get-Content $Global:HardwareDbPath -Raw | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: Failed to load hardware database." -ForegroundColor Red
    Pause
    exit 1
}

# -------------------------------
# CPU Detection
# -------------------------------
$CpuInfo = Get-CimInstance Win32_Processor | Select-Object -First 1
$CpuName = $CpuInfo.Name.Trim()

Write-Host "Detected CPU: $CpuName"

# -------------------------------
# Auto-populate CPU (only if honest)
# -------------------------------
if ($Global:InventoryMode -eq 'INVENTORY' -and -not $Global:LookupOnly) {

    if (-not $HardwareDb.CPU) {
        $HardwareDb | Add-Member -MemberType NoteProperty -Name CPU -Value @()
    }

    $ExistingCpu = $HardwareDb.CPU | Where-Object { $_.Name -eq $CpuName }

    if (-not $ExistingCpu) {
        $resp = Read-Host "Add CPU to inventory? (Y/N)"
        if ($resp -match '^[Yy]$') {
            Assert-InventoryWritable

            $HardwareDb.CPU += [PSCustomObject]@{
                Name     = $CpuName
                Quantity = 1
                Location = 'Host'
            }

            $HardwareDb | ConvertTo-Json -Depth 5 |
                Set-Content -Encoding UTF8 $Global:HardwareDbPath

            Write-Host "CPU added to inventory." -ForegroundColor Green
        }
    }
    else {
        Write-Host "CPU already exists in inventory." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Lookup-only mode: inventory changes disabled." -ForegroundColor Yellow
}

Write-Host ""
Pause
