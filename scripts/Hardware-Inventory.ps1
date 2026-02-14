# ============================================================
# Hardware-Inventory.ps1
# Comprehensive hardware inventory management
# ============================================================

# Source common functions
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptRoot "Common.ps1")

# Initialize paths
$DataPath = Resolve-Path (Join-Path $ScriptRoot "..\data")
$HardwareDbPath = Join-Path $DataPath "hardware_db.json"
$UserDbPath = Join-Path $DataPath "user_db.json"

# Component types and their CSV files (lowercase to match existing files)
$Script:ComponentTypes = @{
    "CPU" = "cpu.csv"
    "GPU" = "gpu.csv"
    "RAM" = "ram.csv"
    "PSU" = "psu.csv"
    "Motherboard" = "motherboard.csv"
    "Storage" = "storage.csv"
    "Cooler" = "cooler.csv"
}

# CSV Headers for each component type
$Script:ComponentHeaders = @{
    "CPU" = @("ID", "Brand", "Model", "Cores", "Threads", "BaseClock", "BoostClock", "TDP", "Socket", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
    "GPU" = @("ID", "Brand", "Model", "VRAM", "CoreClock", "MemoryClock", "TDP", "Interface", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
    "RAM" = @("ID", "Brand", "Model", "Capacity", "Speed", "Type", "Latency", "Voltage", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
    "PSU" = @("ID", "Brand", "Model", "Wattage", "Efficiency", "Modular", "FormFactor", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
    "Motherboard" = @("ID", "Brand", "Model", "Socket", "Chipset", "FormFactor", "MemorySlots", "MaxMemory", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
    "Storage" = @("ID", "Brand", "Model", "Capacity", "Type", "Interface", "FormFactor", "ReadSpeed", "WriteSpeed", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
    "Cooler" = @("ID", "Brand", "Model", "Type", "TDP", "FanSize", "Height", "SocketSupport", "Quantity", "Status", "PurchaseDate", "PurchasePrice", "Notes")
}

function Initialize-InventorySystem {
    # Ensure Data directory exists
    if (!(Test-Path $DataPath)) {
        New-Item -ItemType Directory -Path $DataPath -Force | Out-Null
        Write-Host "Created Data directory" -ForegroundColor Green
    }

    # Check for database files
    $dbExists = Test-Path $HardwareDbPath
    $userDbExists = Test-Path $UserDbPath

    if (!$dbExists) {
        Write-Host "WARNING: hardware_db.json not found. Spec lookups will not be available." -ForegroundColor Yellow
        Write-Host "You can still add items manually." -ForegroundColor Yellow
    }

    if (!$userDbExists) {
        # Create empty user_db.json
        $emptyDb = @{
            "CPU" = @()
            "GPU" = @()
            "RAM" = @()
            "PSU" = @()
            "Motherboard" = @()
            "Storage" = @()
            "Cooler" = @()
        }
        $emptyDb | ConvertTo-Json -Depth 10 | Set-Content $UserDbPath -Encoding UTF8
        Write-Host "Created user_db.json for custom specifications" -ForegroundColor Green
    }

    # Initialize CSV files if they don't exist
    foreach ($type in $ComponentTypes.Keys) {
        $csvPath = Join-Path $DataPath $ComponentTypes[$type]
        if (!(Test-Path $csvPath)) {
            $headers = $ComponentHeaders[$type] -join ","
            $headers | Set-Content $csvPath -Encoding UTF8
            Write-Host "Created $($ComponentTypes[$type])" -ForegroundColor Green
        }
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   HARDWARE INVENTORY MANAGER" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Manage CPUs" -ForegroundColor White
    Write-Host "2. Manage GPUs" -ForegroundColor White
    Write-Host "3. Manage RAM" -ForegroundColor White
    Write-Host "4. Manage PSUs" -ForegroundColor White
    Write-Host "5. Manage Motherboards" -ForegroundColor White
    Write-Host "6. Manage Storage" -ForegroundColor White
    Write-Host "7. Manage Coolers" -ForegroundColor White
    Write-Host ""
    Write-Host "8. View All Inventory" -ForegroundColor Yellow
    Write-Host "9. Search Inventory" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "X. Exit" -ForegroundColor Red
    Write-Host ""
}

function Show-ComponentMenu {
    param([string]$ComponentType)
    
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   $ComponentType MANAGEMENT" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Add New $ComponentType" -ForegroundColor Green
    Write-Host "2. View All ${ComponentType}s" -ForegroundColor White
    Write-Host "3. Edit $ComponentType" -ForegroundColor Yellow
    Write-Host "4. Delete $ComponentType" -ForegroundColor Red
    Write-Host "5. Search Specifications" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "X. Back to Main Menu" -ForegroundColor Gray
    Write-Host ""
}

function Add-ComponentItem {
    param([string]$ComponentType)
    
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   ADD NEW $ComponentType" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get brand and model
    $brand = Read-Host "Enter brand (e.g., Intel, AMD, NVIDIA)"
    if ([string]::IsNullOrWhiteSpace($brand)) {
        Write-Host "Brand cannot be empty!" -ForegroundColor Red
        Pause
        return
    }
    
    $model = Read-Host "Enter model (e.g., i9-14900K, RTX 4090)"
    if ([string]::IsNullOrWhiteSpace($model)) {
        Write-Host "Model cannot be empty!" -ForegroundColor Red
        Pause
        return
    }
    
    # Try to look up specifications
    Write-Host ""
    Write-Host "Looking up specifications..." -ForegroundColor Yellow
    $specs = Get-ComponentSpecs -ComponentType $ComponentType -Brand $brand -Model $model
    
    $item = @{}
    
    if ($specs) {
        Write-Host "Found specifications in database!" -ForegroundColor Green
        Write-Host ""
        
        # Display found specs
        foreach ($key in $specs.Keys) {
            if ($key -ne "Brand" -and $key -ne "Model") {
                Write-Host "$key : $($specs[$key])" -ForegroundColor Cyan
            }
        }
        
        Write-Host ""
        $useSpecs = Read-Host "Use these specifications? (Y/N)"
        
        if ($useSpecs -eq "Y" -or $useSpecs -eq "y") {
            $item = $specs.Clone()
        } else {
            $item = Get-ManualComponentSpecs -ComponentType $ComponentType -Brand $brand -Model $model
        }
    } else {
        Write-Host "Specifications not found in database." -ForegroundColor Yellow
        Write-Host "Please enter specifications manually." -ForegroundColor Yellow
        Write-Host ""
        $item = Get-ManualComponentSpecs -ComponentType $ComponentType -Brand $brand -Model $model
    }
    
    # Add common fields
    $item["Brand"] = $brand
    $item["Model"] = $model
    $item["Quantity"] = Read-Int "Quantity"
    $item["Status"] = Read-Host "Status (Available/In-Use/Sold/RMA)"
    $item["PurchaseDate"] = Read-Host "Purchase Date (YYYY-MM-DD, optional)"
    $item["PurchasePrice"] = Read-Host "Purchase Price (optional)"
    $item["Notes"] = Read-Host "Notes (optional)"
    
    # Generate new ID
    $csvPath = Join-Path $DataPath $ComponentTypes[$ComponentType]
    $existingItems = Import-Csv $csvPath -Encoding UTF8
    $maxId = 0
    if ($existingItems) {
        $maxId = ($existingItems | ForEach-Object { [int]$_.ID } | Measure-Object -Maximum).Maximum
    }
    $item["ID"] = $maxId + 1
    
    # Save to CSV
    $headers = $ComponentHeaders[$ComponentType]
    $row = $headers | ForEach-Object { 
        $val = if ($item.ContainsKey($_)) { "$($item[$_])" } else { "" }
        "`"$($val -replace '"','""')`""
    }
    
    ($row -join ",") | Add-Content $csvPath -Encoding UTF8
    
    Write-Host ""
    Write-Host "$ComponentType added successfully! (ID: $($item["ID"]))" -ForegroundColor Green
    Pause
}

function Get-ManualComponentSpecs {
    param(
        [string]$ComponentType,
        [string]$Brand,
        [string]$Model
    )
    
    $specs = @{}
    
    switch ($ComponentType) {
        "CPU" {
            $specs["Cores"] = Read-Host "Cores"
            $specs["Threads"] = Read-Host "Threads"
            $specs["BaseClock"] = Read-Host "Base Clock (GHz)"
            $specs["BoostClock"] = Read-Host "Boost Clock (GHz)"
            $specs["TDP"] = Read-Host "TDP (W)"
            $specs["Socket"] = Read-Host "Socket"
        }
        "GPU" {
            $specs["VRAM"] = Read-Host "VRAM (GB)"
            $specs["CoreClock"] = Read-Host "Core Clock (MHz)"
            $specs["MemoryClock"] = Read-Host "Memory Clock (MHz)"
            $specs["TDP"] = Read-Host "TDP (W)"
            $specs["Interface"] = Read-Host "Interface (PCIe 4.0 x16, etc.)"
        }
        "RAM" {
            $specs["Capacity"] = Read-Host "Capacity per module (GB)"
            $specs["Speed"] = Read-Host "Speed (MHz)"
            $specs["Type"] = Read-Host "Type (DDR4, DDR5)"
            $specs["Latency"] = Read-Host "Latency (CL)"
            $specs["Voltage"] = Read-Host "Voltage (V)"
        }
        "PSU" {
            $specs["Wattage"] = Read-Host "Wattage (W)"
            $specs["Efficiency"] = Read-Host "Efficiency (80+ Bronze/Gold/Platinum)"
            $specs["Modular"] = Read-Host "Modular (Full/Semi/Non)"
            $specs["FormFactor"] = Read-Host "Form Factor (ATX, SFX)"
        }
        "Motherboard" {
            $specs["Socket"] = Read-Host "Socket"
            $specs["Chipset"] = Read-Host "Chipset"
            $specs["FormFactor"] = Read-Host "Form Factor (ATX, mATX, ITX)"
            $specs["MemorySlots"] = Read-Host "Memory Slots"
            $specs["MaxMemory"] = Read-Host "Max Memory (GB)"
        }
        "Storage" {
            $specs["Capacity"] = Read-Host "Capacity (GB/TB)"
            $specs["Type"] = Read-Host "Type (SSD/HDD/NVMe)"
            $specs["Interface"] = Read-Host "Interface (SATA/NVMe)"
            $specs["FormFactor"] = Read-Host "Form Factor (2.5in/M.2)"
            $specs["ReadSpeed"] = Read-Host "Read Speed (MB/s, optional)"
            $specs["WriteSpeed"] = Read-Host "Write Speed (MB/s, optional)"
        }
        "Cooler" {
            $specs["Type"] = Read-Host "Type (Air/AIO/Custom)"
            $specs["TDP"] = Read-Host "TDP Rating (W)"
            $specs["FanSize"] = Read-Host "Fan Size (mm)"
            $specs["Height"] = Read-Host "Height (mm)"
            $specs["SocketSupport"] = Read-Host "Compatible Socket(s)"
        }
    }
    
    # Ask if user wants to save to user_db.json
    Write-Host ""
    $saveToDb = Read-Host "Save these specifications to user database for future use? (Y/N)"
    if ($saveToDb -eq "Y" -or $saveToDb -eq "y") {
        Save-ToUserDatabase -ComponentType $ComponentType -Brand $Brand -Model $Model -Specs $specs
    }
    
    return $specs
}

function Save-ToUserDatabase {
    param(
        [string]$ComponentType,
        [string]$Brand,
        [string]$Model,
        [hashtable]$Specs
    )
    
    try {
        $userDb = Get-Content $UserDbPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        $newEntry = @{
            "Brand" = $Brand
            "Model" = $Model
        }
        
        foreach ($key in $Specs.Keys) {
            $newEntry[$key] = $Specs[$key]
        }
        
        # Convert hashtable to PSCustomObject
        $newObj = New-Object PSObject -Property $newEntry
        
        # Add to appropriate category
        $currentList = @($userDb.$ComponentType)
        $currentList += $newObj
        $userDb.$ComponentType = $currentList
        
        $userDb | ConvertTo-Json -Depth 10 | Set-Content $UserDbPath -Encoding UTF8
        Write-Host "Specifications saved to user database!" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not save to user database: $_" -ForegroundColor Yellow
    }
}

function View-ComponentItems {
    param([string]$ComponentType)
    
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   $ComponentType INVENTORY" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    $csvPath = Join-Path $DataPath $ComponentTypes[$ComponentType]
    $items = Import-Csv $csvPath -Encoding UTF8
    
    if (!$items -or $items.Count -eq 0) {
        Write-Host "No ${ComponentType}s in inventory." -ForegroundColor Yellow
    } else {
        $items | Format-Table -AutoSize
        Write-Host ""
        Write-Host "Total: $($items.Count) ${ComponentType}(s)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Pause
}

function Edit-ComponentItem {
    param([string]$ComponentType)
    
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   EDIT $ComponentType" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    $csvPath = Join-Path $DataPath $ComponentTypes[$ComponentType]
    $items = Import-Csv $csvPath -Encoding UTF8
    
    if (!$items -or $items.Count -eq 0) {
        Write-Host "No ${ComponentType}s in inventory." -ForegroundColor Yellow
        Pause
        return
    }
    
    # Display items
    $items | Select-Object ID, Brand, Model, Quantity, Status | Format-Table -AutoSize
    
    $id = Read-Host "Enter ID to edit (0 to cancel)"
    if ($id -eq "0") { return }
    
    $item = $items | Where-Object { $_.ID -eq $id }
    if (!$item) {
        Write-Host "ID not found!" -ForegroundColor Red
        Pause
        return
    }
    
    Write-Host ""
    Write-Host "Editing: $($item.Brand) $($item.Model)" -ForegroundColor Cyan
    Write-Host "Leave blank to keep current value" -ForegroundColor Gray
    Write-Host ""
    
    $headers = $ComponentHeaders[$ComponentType]
    $newItem = @{}
    
    foreach ($header in $headers) {
        if ($header -eq "ID") {
            $newItem["ID"] = $item.ID
            continue
        }
        
        $currentValue = $item.$header
        $newValue = Read-Host "$header [$currentValue]"
        
        if ([string]::IsNullOrWhiteSpace($newValue)) {
            $newItem[$header] = $currentValue
        } else {
            $newItem[$header] = $newValue
        }
    }
    
    # Remove old item and add updated one
    $updatedItems = $items | Where-Object { $_.ID -ne $id }
    
    # Create CSV content
    $csvContent = @()
    $csvContent += ($headers -join ",")
    
    foreach ($i in $updatedItems) {
        $row = $headers | ForEach-Object { 
            $val = "$($i.$_)"
            "`"$($val -replace '"','""')`""
        }
        $csvContent += ($row -join ",")
    }
    
    # Add edited item
    $row = $headers | ForEach-Object { 
        $val = "$($newItem[$_])"
        "`"$($val -replace '"','""')`""
    }
    $csvContent += ($row -join ",")
    
    $csvContent | Set-Content $csvPath -Encoding UTF8
    
    Write-Host ""
    Write-Host "$ComponentType updated successfully!" -ForegroundColor Green
    Pause
}

function Remove-ComponentItem {
    param([string]$ComponentType)
    
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   DELETE $ComponentType" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    $csvPath = Join-Path $DataPath $ComponentTypes[$ComponentType]
    $items = Import-Csv $csvPath -Encoding UTF8
    
    if (!$items -or $items.Count -eq 0) {
        Write-Host "No ${ComponentType}s in inventory." -ForegroundColor Yellow
        Pause
        return
    }
    
    # Display items
    $items | Select-Object ID, Brand, Model, Quantity, Status | Format-Table -AutoSize
    
    $id = Read-Host "Enter ID to delete (0 to cancel)"
    if ($id -eq "0") { return }
    
    $item = $items | Where-Object { $_.ID -eq $id }
    if (!$item) {
        Write-Host "ID not found!" -ForegroundColor Red
        Pause
        return
    }
    
    Write-Host ""
    Write-Host "WARNING: You are about to delete:" -ForegroundColor Red
    Write-Host "$($item.Brand) $($item.Model) (ID: $id)" -ForegroundColor Yellow
    $confirm = Read-Host "Are you sure? (YES to confirm)"
    
    if ($confirm -ne "YES") {
        Write-Host "Deletion cancelled." -ForegroundColor Yellow
        Pause
        return
    }
    
    # Remove item
    $updatedItems = $items | Where-Object { $_.ID -ne $id }
    
    # Create CSV content
    $headers = $ComponentHeaders[$ComponentType]
    $csvContent = @()
    $csvContent += ($headers -join ",")
    
    foreach ($i in $updatedItems) {
        $row = $headers | ForEach-Object { 
            $val = "$($i.$_)"
            "`"$($val -replace '"','""')`""
        }
        $csvContent += ($row -join ",")
    }
    
    $csvContent | Set-Content $csvPath -Encoding UTF8
    
    Write-Host ""
    Write-Host "$ComponentType deleted successfully!" -ForegroundColor Green
    Pause
}

function Search-Specifications {
    param([string]$ComponentType)
    
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   SEARCH $ComponentType SPECS" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    $searchTerm = Read-Host "Enter brand or model to search"
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        Write-Host "Search term cannot be empty!" -ForegroundColor Red
        Pause
        return
    }
    
    Write-Host ""
    Write-Host "Searching databases..." -ForegroundColor Yellow
    
    $results = @()
    
    # Search hardware_db.json
    if (Test-Path $HardwareDbPath) {
        try {
            $hwDb = Get-Content $HardwareDbPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($hwDb.$ComponentType) {
                $hwResults = $hwDb.$ComponentType | Where-Object { 
                    $_.Brand -like "*$searchTerm*" -or $_.Model -like "*$searchTerm*"
                }
                if ($hwResults) {
                    $results += $hwResults
                }
            }
        } catch {
            Write-Host "Error reading hardware_db.json: $_" -ForegroundColor Red
        }
    }
    
    # Search user_db.json
    if (Test-Path $UserDbPath) {
        try {
            $userDb = Get-Content $UserDbPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($userDb.$ComponentType) {
                $userResults = $userDb.$ComponentType | Where-Object { 
                    $_.Brand -like "*$searchTerm*" -or $_.Model -like "*$searchTerm*"
                }
                if ($userResults) {
                    $results += $userResults
                }
            }
        } catch {
            Write-Host "Error reading user_db.json: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    if ($results.Count -eq 0) {
        Write-Host "No specifications found matching '$searchTerm'" -ForegroundColor Yellow
    } else {
        Write-Host "Found $($results.Count) matching specification(s):" -ForegroundColor Green
        Write-Host ""
        
        foreach ($result in $results) {
            Write-Host "Brand: $($result.Brand)" -ForegroundColor Cyan
            Write-Host "Model: $($result.Model)" -ForegroundColor Cyan
            foreach ($prop in $result.PSObject.Properties) {
                if ($prop.Name -ne "Brand" -and $prop.Name -ne "Model") {
                    Write-Host "  $($prop.Name): $($prop.Value)" -ForegroundColor White
                }
            }
            Write-Host ""
        }
    }
    
    Pause
}

function View-AllInventory {
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   COMPLETE INVENTORY SUMMARY" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($type in $ComponentTypes.Keys | Sort-Object) {
        $csvPath = Join-Path $DataPath $ComponentTypes[$type]
        $items = Import-Csv $csvPath -Encoding UTF8
        
        Write-Host "$type : " -NoNewline -ForegroundColor Yellow
        if ($items) {
            $totalQty = ($items | Measure-Object -Property Quantity -Sum).Sum
            Write-Host "$($items.Count) unique part(s), $totalQty total units" -ForegroundColor White
        } else {
            Write-Host "0 items" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Pause
}

function Search-AllInventory {
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   SEARCH ALL INVENTORY" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
    
    $searchTerm = Read-Host "Enter search term (brand, model, or any field)"
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        Write-Host "Search term cannot be empty!" -ForegroundColor Red
        Pause
        return
    }
    
    Write-Host ""
    Write-Host "Searching all inventory..." -ForegroundColor Yellow
    Write-Host ""
    
    $foundAny = $false
    
    foreach ($type in $ComponentTypes.Keys | Sort-Object) {
        $csvPath = Join-Path $DataPath $ComponentTypes[$type]
        $items = Import-Csv $csvPath -Encoding UTF8
        
        if ($items) {
            $matches = $items | Where-Object {
                $matched = $false
                foreach ($prop in $_.PSObject.Properties) {
                    if ($prop.Value -like "*$searchTerm*") {
                        $matched = $true
                        break
                    }
                }
                $matched
            }
            
            if ($matches) {
                Write-Host "=== $type ===" -ForegroundColor Cyan
                $matches | Format-Table -AutoSize
                Write-Host ""
                $foundAny = $true
            }
        }
    }
    
    if (!$foundAny) {
        Write-Host "No items found matching '$searchTerm'" -ForegroundColor Yellow
    }
    
    Pause
}

function Manage-ComponentType {
    param([string]$ComponentType)
    
    do {
        Show-ComponentMenu -ComponentType $ComponentType
        $choice = Read-Host "Select option"
        
        switch ($choice) {
            "1" { Add-ComponentItem -ComponentType $ComponentType }
            "2" { View-ComponentItems -ComponentType $ComponentType }
            "3" { Edit-ComponentItem -ComponentType $ComponentType }
            "4" { Remove-ComponentItem -ComponentType $ComponentType }
            "5" { Search-Specifications -ComponentType $ComponentType }
            "X" { return }
            "x" { return }
            default { 
                Write-Host "Invalid option!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "X" -and $choice -ne "x")
}

# Main script
Clear-Host
Write-Host "Initializing Hardware Inventory System..." -ForegroundColor Cyan
Initialize-InventorySystem

do {
    Show-MainMenu
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" { Manage-ComponentType -ComponentType "CPU" }
        "2" { Manage-ComponentType -ComponentType "GPU" }
        "3" { Manage-ComponentType -ComponentType "RAM" }
        "4" { Manage-ComponentType -ComponentType "PSU" }
        "5" { Manage-ComponentType -ComponentType "Motherboard" }
        "6" { Manage-ComponentType -ComponentType "Storage" }
        "7" { Manage-ComponentType -ComponentType "Cooler" }
        "8" { View-AllInventory }
        "9" { Search-AllInventory }
        "X" { 
            Write-Host "Returning to main menu..." -ForegroundColor Cyan
            break
        }
        "x" { 
            Write-Host "Returning to main menu..." -ForegroundColor Cyan
            break
        }
        default { 
            Write-Host "Invalid option!" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "X" -and $choice -ne "x")