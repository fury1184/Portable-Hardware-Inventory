
Set-StrictMode -Version Latest

$ModuleRoot = $PSScriptRoot
$DataPath = Resolve-Path (Join-Path $ModuleRoot '..\data')

$script:HardwareDbPath = Join-Path $DataPath 'hardware_db.json'
$script:CPU_CSV  = Join-Path $DataPath 'cpu.csv'
$script:GPU_CSV  = Join-Path $DataPath 'gpu.csv'
$script:RAM_CSV  = Join-Path $DataPath 'ram.csv'
$script:MOBO_CSV = Join-Path $DataPath 'motherboard.csv'
$script:STOR_CSV = Join-Path $DataPath 'storage.csv'
$script:COOL_CSV = Join-Path $DataPath 'cooler.csv'
$script:PSU_CSV  = Join-Path $DataPath 'psu.csv'

function Get-HardwarePaths {
 [pscustomobject]@{
  HardwareDbPath=$script:HardwareDbPath
  CPU_CSV=$script:CPU_CSV; GPU_CSV=$script:GPU_CSV; RAM_CSV=$script:RAM_CSV
  Motherboard_CSV=$script:MOBO_CSV; Storage_CSV=$script:STOR_CSV
  Cooler_CSV=$script:COOL_CSV; PSU_CSV=$script:PSU_CSV
 }
}

function Initialize-Csv($Path,$Headers){
 if(!(Test-Path $Path)){
  [pscustomobject]@{}|Select $Headers|Export-Csv $Path -NoTypeInformation
 }
}

function Initialize-InventoryFiles{
 Initialize-Csv $script:CPU_CSV 'Name','Socket','Cores','Threads','BaseClock','BoostClock','TDP','Quantity','Location','Notes','AddedOn'
 Initialize-Csv $script:GPU_CSV 'Name','VRAM','Bus','TDP','Interface','Quantity','Location','Notes','AddedOn'
 Initialize-Csv $script:RAM_CSV 'Name','Type','Speed','Capacity','Quantity','Location','Notes','AddedOn'
 Initialize-Csv $script:MOBO_CSV 'Name','Socket','Chipset','FormFactor','Quantity','Location','Notes','AddedOn'
 Initialize-Csv $script:STOR_CSV 'Name','Type','Capacity','Interface','Quantity','Location','Notes','AddedOn'
 Initialize-Csv $script:COOL_CSV 'Name','Socket','Type','Quantity','Location','Notes','AddedOn'
 Initialize-Csv $script:PSU_CSV 'Name','Wattage','Efficiency','Modular','Quantity','Location','Notes','AddedOn'
}

function Get-HardwareFromDatabase($Type,$Name){
 $db = Get-Content $script:HardwareDbPath -Raw | ConvertFrom-Json
 if ($db.$Type) {
  $db.$Type | Where-Object { $_.Name -ieq $Name }
 }
}

function Search-HardwareDatabase($SearchTerm,$Type){
 $db = Get-Content $script:HardwareDbPath -Raw | ConvertFrom-Json
 $items = if($Type) {
  @($db.$Type)
 } else {
  @($db.PSObject.Properties.Value | ForEach-Object { $_ })
 }
 $items | Where-Object { $_.Name -match $SearchTerm }
}

function Add-HardwareToDatabase($Type,$Name,[hashtable]$Specs){
 $db=Get-Content $script:HardwareDbPath -Raw|ConvertFrom-Json
 $db.$Type+= [pscustomobject](@{Name=$Name}+ $Specs)
 $db|ConvertTo-Json -Depth 10|Set-Content $script:HardwareDbPath
}

function Add-HardwareInventory($Type,$Name,$Quantity,$Location,$Notes){
 Initialize-InventoryFiles
 $spec=Get-HardwareFromDatabase $Type $Name
 if(!$spec){throw "$Type not in DB"}
 $map=@{CPU=$script:CPU_CSV;GPU=$script:GPU_CSV;RAM=$script:RAM_CSV;Motherboard=$script:MOBO_CSV;Storage=$script:STOR_CSV;Cooler=$script:COOL_CSV;PSU=$script:PSU_CSV}
 $row=[ordered]@{Name=$spec.Name}
 $spec.PSObject.Properties|? Name -ne 'Name'|%{$row[$_.Name]=$_.Value}
 $row.Quantity=$Quantity;$row.Location=$Location;$row.Notes=$Notes;$row.AddedOn=Get-Date
 [pscustomobject]$row|Export-Csv $map[$Type] -Append -NoTypeInformation
}

Export-ModuleMember -Function *
