# Common.ps1 - Shared functions for Portable Hardware Inventory

function Read-Int {
    param(
        [string]$Prompt,
        [switch]$AllowBlank
    )
    $v = Read-Host $Prompt
    if ($AllowBlank -and $v -eq "") { return "" }
    try { return [int]$v } catch { return 0 }
}

function ConvertTo-SocketList {
    param($value)
    if (-not $value) { return "" }
    ($value -split '[, ]+' |
        Where-Object { $_ -ne "" } |
        ForEach-Object { $_.Trim().ToUpper() -replace '\s','' } |
        Sort-Object -Unique) -join ','
}

function Test-CoolerCompatibility {
    param($CpuSocket, $CoolerSockets)
    if (-not $CpuSocket -or -not $CoolerSockets) { return $true }
    foreach ($s in $CpuSocket.Split(',')) {
        if ($CoolerSockets.Split(',') -contains $s) { return $true }
    }
    return $false
}

function Import-Inventory {
    param([string]$Path)
    if (Test-Path $Path) { Import-Csv $Path } else { @() }
}

function Export-Inventory {
    param([string]$Path, $Data)
    $Data | Export-Csv $Path -NoTypeInformation -Encoding UTF8
}

function Get-DataPath {
    $ScriptRoot = Split-Path -Parent $MyInvocation.ScriptName
    Resolve-Path (Join-Path $ScriptRoot "..\data")
}
