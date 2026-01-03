# Start-Inventory-GUI.ps1
# GUI launcher for Portable Hardware Inventory
# Project root anchor – do not move this file

if (-not $Global:InventoryInitialized) {
    Write-Host "ERROR: Inventory not initialized. Launch Start-Inventory.ps1." -ForegroundColor Red
    exit 1
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Portable Hardware Inventory"
$form.Size = New-Object System.Drawing.Size(420, 400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = Join-Path $scriptRoot "scripts"

function Invoke-Script($name) {
    $path = Join-Path $scripts $name
    Start-Process pwsh `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$path`"" `
        -WorkingDirectory $scriptRoot
}

$buttons = @(
    @{ Text = "Hardware Inventory"; Script = "Hardware-Inventory.ps1" }
    @{ Text = "Host Inventory";     Script = "Host-Inventory.ps1" }
    @{ Text = "Build Planner";      Script = "Build-Planner.ps1" }
    @{ Text = "Backup (Local)";     Script = "Backup-Inventory.ps1" }
    @{ Text = "Backup (NAS)";       Script = "Backup-To-NAS.ps1" }
)

$y = 20
foreach ($b in $buttons) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $b.Text
    $btn.Tag = $b.Script
    $btn.Size = New-Object System.Drawing.Size(360, 40)
    $btn.Location = New-Object System.Drawing.Point(20, $y)
    $btn.FlatStyle = "Flat"

    $btn.Add_Click({
        Invoke-Script $this.Tag
    })

    $form.Controls.Add($btn)
    $y += 50
}

$exit = New-Object System.Windows.Forms.Button
$exit.Text = "Exit"
$exit.Size = New-Object System.Drawing.Size(360, 40)
$exit.Location = New-Object System.Drawing.Point(20, $y)
$exit.FlatStyle = "Flat"
$exit.Add_Click({ $form.Close() })
$form.Controls.Add($exit)

[void]$form.ShowDialog()
