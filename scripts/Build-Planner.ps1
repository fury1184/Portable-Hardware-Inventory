# Build-Planner.ps1
# Check available parts for a new build

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptRoot "Common.ps1")

$DataPath = Resolve-Path (Join-Path $ScriptRoot "..\data")

function Get-AvailableRAM {
    $ramPath = Join-Path $DataPath "ram.csv"
    $hostsPath = Join-Path $DataPath "hosts.csv"

    $totalRAM = 0
    if (Test-Path $ramPath) {
        $ram = Import-Csv $ramPath
        foreach ($r in $ram) {
            $totalRAM += ([int]$r.CapacityGB * [int]$r.Quantity)
        }
    }

    $usedRAM = 0
    if (Test-Path $hostsPath) {
        $builtHosts = Import-Csv $hostsPath | Where-Object Status -eq "Built"
        foreach ($h in $builtHosts) {
            $usedRAM += [int]$h.RAM_GB
        }
    }

    return ($totalRAM - $usedRAM)
}

function Get-AvailableGPUs {
    param([int]$MinVRAM = 0)
    $gpuPath = Join-Path $DataPath "gpu.csv"

    if (-not (Test-Path $gpuPath)) { return @() }

    Import-Csv $gpuPath | Where-Object { [int]$_.VRAM_GB -ge $MinVRAM -and [int]$_.Quantity -gt 0 }
}

function Get-AvailableCPUs {
    param([string]$Socket = "")
    $cpuPath = Join-Path $DataPath "cpu.csv"

    if (-not (Test-Path $cpuPath)) { return @() }

    $cpus = Import-Csv $cpuPath | Where-Object { [int]$_.Quantity -gt 0 }
    if ($Socket) {
        $cpus = $cpus | Where-Object { $_.Socket -eq $Socket.ToUpper() }
    }
    return $cpus
}

function Get-CompatibleCoolers {
    param([string]$Socket)
    $coolPath = Join-Path $DataPath "cooler.csv"

    if (-not (Test-Path $coolPath) -or -not $Socket) { return @() }

    Import-Csv $coolPath | Where-Object {
        [int]$_.Quantity -gt 0 -and (Test-CoolerCompatibility $Socket $_.SocketSupport)
    }
}

function Plan-Build {
    Clear-Host
    Write-Host "=== Build Planner ===" -ForegroundColor Cyan
    Write-Host ""

    $neededRAM = Read-Int "RAM needed (GB)"
    $neededVRAM = Read-Int "Minimum GPU VRAM (GB)"
    $socket = Read-Host "CPU Socket filter (blank for all)"

    Write-Host ""
    Write-Host "=== RESULTS ===" -ForegroundColor Yellow

    # RAM check
    $freeRAM = Get-AvailableRAM
    if ($freeRAM -ge $neededRAM) {
        Write-Host "[OK] RAM: ${freeRAM}GB available (need ${neededRAM}GB)" -ForegroundColor Green
    } else {
        Write-Host "[X] RAM: ${freeRAM}GB available (need ${neededRAM}GB)" -ForegroundColor Red
    }

    # GPU check
    $gpus = Get-AvailableGPUs -MinVRAM $neededVRAM
    if ($gpus.Count -gt 0) {
        Write-Host "[OK] GPUs with ${neededVRAM}GB+ VRAM: $($gpus.Count) available" -ForegroundColor Green
        $gpus | ForEach-Object { Write-Host "     - $($_.Brand) $($_.Model) ($($_.VRAM_GB)GB)" }
    } else {
        Write-Host "[X] No GPUs with ${neededVRAM}GB+ VRAM available" -ForegroundColor Red
    }

    # CPU check
    $cpus = Get-AvailableCPUs -Socket $socket
    if ($cpus.Count -gt 0) {
        $socketLabel = if ($socket) { $socket.ToUpper() } else { "any socket" }
        Write-Host "[OK] CPUs ($socketLabel): $($cpus.Count) available" -ForegroundColor Green
        $cpus | ForEach-Object { Write-Host "     - $($_.Brand) $($_.Model) [$($_.Socket)]" }
    } else {
        Write-Host "[X] No CPUs available" -ForegroundColor Red
    }

    # Cooler check (if socket specified)
    if ($socket) {
        $coolers = Get-CompatibleCoolers -Socket $socket
        if ($coolers.Count -gt 0) {
            Write-Host "[OK] Compatible coolers for $($socket.ToUpper()): $($coolers.Count)" -ForegroundColor Green
            $coolers | ForEach-Object { Write-Host "     - $($_.Brand) $($_.Model)" }
        } else {
            Write-Host "[X] No compatible coolers for $($socket.ToUpper())" -ForegroundColor Red
        }
    }

    Write-Host ""
    Pause
}

function Show-Summary {
    Clear-Host
    Write-Host "=== Inventory Summary ===" -ForegroundColor Cyan
    Write-Host ""

    $freeRAM = Get-AvailableRAM
    Write-Host "Available RAM: ${freeRAM}GB"

    $gpus = Get-AvailableGPUs
    Write-Host "GPUs in stock: $($gpus.Count)"

    $cpus = Get-AvailableCPUs
    Write-Host "CPUs in stock: $($cpus.Count)"

    # Count by socket
    $sockets = $cpus | Group-Object Socket
    foreach ($s in $sockets) {
        Write-Host "  - $($s.Name): $($s.Count)"
    }

    Write-Host ""
    Pause
}

do {
    Clear-Host
    Write-Host "=== Build Planner ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Plan a Build"
    Write-Host "2. Inventory Summary"
    Write-Host ""
    Write-Host "X. Exit"
    Write-Host ""

    switch (Read-Host "Select") {
        '1' { Plan-Build }
        '2' { Show-Summary }
        'X' { return }
    }
} while ($true)
