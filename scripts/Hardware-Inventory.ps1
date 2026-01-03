
# Hardware-Inventory.ps1
# Full Hardware Inventory with CPU/RAM/GPU/PSU/MOBO/Storage/Cooler
# PS7-safe, root-aware, normalized vendors/sockets, list + add menus

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootPath   = Resolve-Path (Join-Path $ScriptRoot "..")
$DataPath   = Join-Path $RootPath "data"

. (Join-Path $ScriptRoot "Common.ps1")

$Files = @{
    CPU  = Join-Path $DataPath "cpu.csv"
    RAM  = Join-Path $DataPath "ram.csv"
    GPU  = Join-Path $DataPath "gpu.csv"
    PSU  = Join-Path $DataPath "psu.csv"
    MOBO = Join-Path $DataPath "motherboard.csv"
}

function Ensure-Csv {
    param($Path,$Header)
    if (-not (Test-Path $Path)) {
        $Header | Out-File $Path -Encoding UTF8
    }
}

Ensure-Csv $Files.CPU  "Brand,Model,Socket,Cores,Threads,TDP_W,Quantity,Location,Notes"
Ensure-Csv $Files.RAM  "Brand,Size_GB,Speed_MHz,ECC,Quantity,Location,Notes"
Ensure-Csv $Files.GPU  "Vendor,Brand,Model,VRAM_GB,Power_W,Quantity,Location,Notes"
Ensure-Csv $Files.PSU  "Brand,Model,Wattage,Quantity,Location,Notes"
Ensure-Csv $Files.MOBO "Brand,Model,Socket,ECCSupport,Quantity,Location,Notes"

function Normalize-Socket {
    param($s)
    if (-not $s) { return "" }
    return ($s.ToUpper() -replace "\s","")
}

function Normalize-Vendor {
    param($v)
    switch ($v.ToUpper()) {
        "NVIDIA" { "NVIDIA" }
        "AMD"    { "AMD" }
        "INTEL"  { "INTEL" }
        default  { $v.ToUpper() }
    }
}

function Add-OrIncrement {
    param($Key,$Item,$MatchFields)
    $inv = @(Import-Csv $Files[$Key])
    $existing = $inv | Where-Object {
        $same = $true
        foreach ($f in $MatchFields) {
            if ("$($_.$f)" -ne "$($Item[$f])") { $same = $false; break }
        }
        $same
    }
    if ($existing) {
        $existing.Quantity = [int]$existing.Quantity + [int]$Item.Quantity
    } else {
        $inv += [PSCustomObject]$Item
    }
    $inv | Export-Csv $Files[$Key] -NoTypeInformation -Encoding UTF8
    Write-Host "Saved." -ForegroundColor Green
    Pause
}

function List-Inventory {
    Clear-Host
    Write-Host "=== Inventory Overview ===" -ForegroundColor Cyan
    foreach ($k in $Files.Keys) {
        Write-Host "`n[$k]" -ForegroundColor Yellow
        Import-Csv $Files[$k] | Format-Table -AutoSize
    }
    Pause
}

function Add-CPU {
    Add-OrIncrement CPU @{
        Brand    = Read-Host "Brand"
        Model    = Read-Host "Model"
        Socket   = Normalize-Socket (Read-Host "Socket")
        Cores    = Read-Int "Cores"
        Threads  = Read-Int "Threads"
        TDP_W    = Read-Int "TDP (W)"
        Quantity = Read-Int "Quantity"
        Location = Read-Host "Location"
        Notes    = Read-Host "Notes"
    } @("Brand","Model","Socket")
}

function Add-RAM {
    Add-OrIncrement RAM @{
        Brand    = Read-Host "Brand"
        Size_GB  = Read-Int "Size (GB)"
        Speed_MHz= Read-Int "Speed (MHz)"
        ECC      = Read-Host "ECC (Yes/No)"
        Quantity = Read-Int "Quantity"
        Location = Read-Host "Location"
        Notes    = Read-Host "Notes"
    } @("Brand","Size_GB","Speed_MHz","ECC")
}

function Add-GPU {
    Add-OrIncrement GPU @{
        Vendor   = Normalize-Vendor (Read-Host "Vendor (NVIDIA/AMD/Intel)")
        Brand    = Read-Host "Board Partner"
        Model    = Read-Host "Model"
        VRAM_GB  = Read-Int "VRAM (GB)"
        Power_W  = Read-Int "Power (W)"
        Quantity = Read-Int "Quantity"
        Location = Read-Host "Location"
        Notes    = Read-Host "Notes"
    } @("Vendor","Brand","Model")
}

function Add-PSU {
    Add-OrIncrement PSU @{
        Brand    = Read-Host "Brand"
        Model    = Read-Host "Model"
        Wattage  = Read-Int "Wattage"
        Quantity = Read-Int "Quantity"
        Location = Read-Host "Location"
        Notes    = Read-Host "Notes"
    } @("Brand","Model","Wattage")
}

function Add-MOBO {
    Add-OrIncrement MOBO @{
        Brand      = Read-Host "Brand"
        Model      = Read-Host "Model"
        Socket     = Normalize-Socket (Read-Host "Socket")
        ECCSupport = Read-Host "ECC Support (Yes/No)"
        Quantity   = Read-Int "Quantity"
        Location   = Read-Host "Location"
        Notes      = Read-Host "Notes"
    } @("Brand","Model","Socket")
}

$continue = $true
do {
    Clear-Host
    Write-Host "=== Hardware Inventory ===" -ForegroundColor Cyan
    Write-Host "1. Add CPU"
    Write-Host "2. Add RAM"
    Write-Host "3. Add GPU"
    Write-Host "4. Add PSU"
    Write-Host "5. Add Motherboard"
    Write-Host "6. List Inventory"
    Write-Host "7. Exit"
    switch (Read-Host "Select") {
        '1' { Add-CPU }
        '2' { Add-RAM }
        '3' { Add-GPU }
        '4' { Add-PSU }
        '5' { Add-MOBO }
        '6' { List-Inventory }
        '7' { $continue = $false }
        default { Pause }
    }
} while ($continue)
