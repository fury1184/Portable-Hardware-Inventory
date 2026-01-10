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

# Get component specifications from hardware_db.json or user_db.json
function Get-ComponentSpecs {
    param(
        [string]$ComponentType,
        [string]$Brand,
        [string]$Model
    )
    
    $ScriptRoot = Split-Path -Parent $MyInvocation.ScriptName
    $DataPath = Resolve-Path (Join-Path $ScriptRoot "..\data")
    $HardwareDbPath = Join-Path $DataPath "hardware_db.json"
    $UserDbPath = Join-Path $DataPath "user_db.json"
    
    # Try user_db.json first (user entries take priority)
    if (Test-Path $UserDbPath) {
        try {
            $userDb = Get-Content $UserDbPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($userDb.$ComponentType) {
                $match = $userDb.$ComponentType | Where-Object { 
                    $_.Brand -eq $Brand -and $_.Model -eq $Model 
                } | Select-Object -First 1
                
                if ($match) {
                    # Convert PSCustomObject to hashtable
                    $specs = @{}
                    foreach ($prop in $match.PSObject.Properties) {
                        $specs[$prop.Name] = $prop.Value
                    }
                    return $specs
                }
            }
        } catch {
            Write-Verbose "Could not read user_db.json: $_"
        }
    }
    
    # Fall back to hardware_db.json
    if (Test-Path $HardwareDbPath) {
        try {
            $hwDb = Get-Content $HardwareDbPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($hwDb.$ComponentType) {
                $match = $hwDb.$ComponentType | Where-Object { 
                    $_.Brand -eq $Brand -and $_.Model -eq $Model 
                } | Select-Object -First 1
                
                if ($match) {
                    # Convert PSCustomObject to hashtable
                    $specs = @{}
                    foreach ($prop in $match.PSObject.Properties) {
                        $specs[$prop.Name] = $prop.Value
                    }
                    return $specs
                }
            }
        } catch {
            Write-Verbose "Could not read hardware_db.json: $_"
        }
    }
    
    # Not found in either database
    return $null
}
