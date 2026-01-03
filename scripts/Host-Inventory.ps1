# Host-Inventory.ps1
# Manage host/system inventory and validate compatibility

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptRoot "Common.ps1")

$DataPath = Resolve-Path (Join-Path $ScriptRoot "..\data")
$HostsCsv = Join-Path $DataPath "hosts.csv"

# Initialize hosts.csv if missing
if (-not (Test-Path $HostsCsv)) {
    "HostName,Role,Status,CPU_Model,CPU_Count,RAM_GB,Motherboard,Cooler,PSU,GPU,Storage,OS,Location,Notes" |
        Out-File $HostsCsv -Encoding UTF8
}

function Get-Hosts { Import-Csv $HostsCsv }
function Save-Hosts($h) { $h | Export-Csv $HostsCsv -NoTypeInformation -Encoding UTF8 }

function Add-Host {
    Clear-Host
    Write-Host "=== Add New Host ===" -ForegroundColor Cyan
    $hosts = @(Get-Hosts)
    $hosts += [PSCustomObject]@{
        $HostName    = Read-Host "Host name"
        $Role        = Read-Host "Role (Server/Workstation/NAS/etc)"
        $Status      = Read-Host "Status (Built/Planned/Retired/PartedOut)"
        $CPU_Model   = Read-Host "CPU model"
        $CPU_Count   = Read-Int  "CPU count"
        $RAM_GB      = Read-Int "Total RAM (GB)"
        $RAM_Speed   = Read-Int "Effective RAM speed (MHz)"
        RAM_Sticks  = Read-Int "Number of DIMMs"
        $Motherboard = Read-Host "Motherboard"
        $Cooler      = Read-Host "Cooler model"
        $PSUICulture         = Read-Host "PSU"
        $GPU         = Read-Host "GPU"
        $Storage     = Read-Host "Storage"
        $OS          = Read-Host "OS"
        $Location    = Read-Host "Location"
        $Notes       = Read-Host "Notes"
    }
    Save-Hosts $hosts
    Write-Host "Host added." -ForegroundColor Green
    Pause
}

function Show-Hosts {
    Clear-Host
    Write-Host "=== All Hosts ===" -ForegroundColor Cyan
    $hosts = Get-Hosts
    if ($hosts.Count -eq 0) {
        Write-Host "(no hosts defined)" -ForegroundColor DarkGray
    } else {
        $hosts | Format-Table HostName,Role,Status,CPU_Model,RAM_GB,GPU -AutoSize
    }
    Pause
}

function Show-BuiltHosts {
    Clear-Host
    Write-Host "=== Built Hosts (Active Reservations) ===" -ForegroundColor Cyan
    $hosts = Get-Hosts | Where-Object Status -eq "Built"
    if ($hosts.Count -eq 0) {
        Write-Host "(no built hosts)" -ForegroundColor DarkGray
    } else {
        $hosts | Format-Table HostName,Role,CPU_Model,CPU_Count,RAM_GB,GPU,Cooler -AutoSize
    }
    Pause
}

function Validate-Hosts {
    Clear-Host
    Write-Host "=== Host Compatibility Validation ===" -ForegroundColor Cyan

    $hosts = Get-Hosts | Where-Object Status -eq "Built"
    $cpuPath = Join-Path $DataPath "cpu.csv"
    $coolPath = Join-Path $DataPath "cooler.csv"

    if (-not (Test-Path $cpuPath)) {
        Write-Host "cpu.csv not found - skipping CPU checks" -ForegroundColor Yellow
        $cpus = @()
    } else {
        $cpus = Import-Csv $cpuPath
    }

    if (-not (Test-Path $coolPath)) {
        Write-Host "cooler.csv not found - skipping cooler checks" -ForegroundColor Yellow
        $coolers = @()
    } else {
        $coolers = Import-Csv $coolPath
    }

    if ($hosts.Count -eq 0) {
        Write-Host "`n(no built hosts to validate)" -ForegroundColor DarkGray
        Pause
        return
    }

    $issues = 0

    foreach ($h in $hosts) {
        Write-Host "`nHost: $($h.HostName)" -ForegroundColor Yellow

        # Find matching CPU and cooler
        $cpu = $cpus | Where-Object Model -eq $h.CPU_Model | Select-Object -First 1
        $clr = $coolers | Where-Object Model -eq $h.Cooler | Select-Object -First 1

        # CPU socket vs cooler compatibility
        if ($cpu -and $clr) {
            if (-not (Test-CoolerCompatibility $cpu.Socket $clr.SocketSupport)) {
                Write-Host "  [X] Cooler incompatible with CPU socket" -ForegroundColor Red
                Write-Host "      CPU Socket:     $($cpu.Socket)"
                Write-Host "      Cooler Sockets: $($clr.SocketSupport)"
                $issues++
            } else {
                Write-Host "  [OK] Cooler/socket compatible" -ForegroundColor Green
            }
        } elseif ($h.Cooler -and -not $clr) {
            Write-Host "  [?] Cooler '$($h.Cooler)' not in inventory" -ForegroundColor DarkYellow
        } elseif ($h.CPU_Model -and -not $cpu) {
            Write-Host "  [?] CPU '$($h.CPU_Model)' not in inventory" -ForegroundColor DarkYellow
        } else {
            Write-Host "  [OK] No cooler/CPU issues detected" -ForegroundColor Green
        }
    }

    Write-Host ""
    if ($issues -eq 0) {
        Write-Host "Validation complete - no issues found." -ForegroundColor Green
    } else {
        Write-Host "Validation complete - $issues issue(s) found." -ForegroundColor Red
    }
    Pause
}

function Edit-Host {
    Clear-Host
    Write-Host "=== Edit Host ===" -ForegroundColor Cyan
    $hosts = @(Get-Hosts)

    if ($hosts.Count -eq 0) {
        Write-Host "(no hosts to edit)" -ForegroundColor DarkGray
        Pause
        return
    }

    for ($i = 0; $i -lt $hosts.Count; $i++) {
        Write-Host "$($i + 1). $($hosts[$i].HostName) [$($hosts[$i].Status)]"
    }

    $sel = Read-Int "`nSelect host number (0 to cancel)"
    if ($sel -lt 1 -or $sel -gt $hosts.Count) { return }

    $h = $hosts[$sel - 1]
    Write-Host "`nEditing: $($h.HostName)" -ForegroundColor Yellow
    Write-Host "(Press Enter to keep current value)`n"

    $props = @("HostName","Role","Status","CPU_Model","CPU_Count","RAM_GB","Motherboard","Cooler","PSU","GPU","Storage","OS","Location","Notes")

    foreach ($p in $props) {
        $current = $h.$p
        $new = Read-Host "$p [$current]"
        if ($new -ne "") { $h.$p = $new }
    }

    Save-Hosts $hosts
    Write-Host "Host updated." -ForegroundColor Green
    Pause
}

do {
    Clear-Host
    Write-Host "=== Host Inventory ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Add Host"
    Write-Host "2. Edit Host"
    Write-Host "3. Show All Hosts"
    Write-Host "4. Show Built Hosts"
    Write-Host "5. Validate Compatibility"
    Write-Host ""
    Write-Host "X. Exit"
    Write-Host ""

    switch (Read-Host "Select") {
        '1' { Add-Host }
        '2' { Edit-Host }
        '3' { Show-Hosts }
        '4' { Show-BuiltHosts }
        '5' { Validate-Hosts }
        'X' { return }
    }
} while ($true)

function Test-HostRamVsInventory {
    param (
        [string]$RamCsvPath,
        [string]$HostsCsvPath
    )

    $ramInv   = Import-Csv $RamCsvPath
    $hosts    = Import-Csv $HostsCsvPath | Where-Object Status -eq 'Built'

    $totalInventoryRam = 0
    foreach ($r in $ramInv) {
        $size = [int]($r.Size_GB  | ForEach-Object { $_ })
        $qty  = [int]($r.Quantity | ForEach-Object { $_ })
        $totalInventoryRam += ($size * $qty)
    }

    $totalHostRam = 0
    foreach ($h in $hosts) {
        $totalHostRam += [int]($h.RAM_GB | ForEach-Object { $_ })
    }

    Write-Host "`n=== RAM Capacity Validation ===" -ForegroundColor Cyan
    Write-Host "Inventory RAM : $totalInventoryRam GB"
    Write-Host "Host RAM Used : $totalHostRam GB"

    if ($totalHostRam -gt $totalInventoryRam) {
        Write-Host "⚠ WARNING: Hosts claim MORE RAM than inventory!" -ForegroundColor Yellow
        Write-Host "  Over by: $($totalHostRam - $totalInventoryRam) GB"
    }
    else {
        Write-Host "✔ RAM usage within inventory limits" -ForegroundColor Green
    }
}
