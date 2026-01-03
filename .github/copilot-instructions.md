<!-- .github/copilot-instructions.md -->
# Portable-Hardware-Inventory — Copilot instructions

Purpose: help AI coding assistants be immediately productive in this repo.

- Quick start:
  - Project anchors: [Start-Inventory-GUI.ps1](Start-Inventory-GUI.ps1) (GUI launcher) and the PowerShell module at [module/HardwareInventory.psm1](module/HardwareInventory.psm1).
  - Run the GUI (Windows): `pwsh -NoProfile -ExecutionPolicy Bypass -File Start-Inventory-GUI.ps1` from the project root.
  - Run a specific script: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\Hardware-Inventory.ps1`.

- Big picture architecture:
  - `module/HardwareInventory.psm1`: canonical module that normalizes paths (uses `$PSScriptRoot`) and provides JSON/CSV helpers and exported functions used by scripts.
  - `scripts/`: interactive CLI scripts (menu-driven) that operate on CSV files under `data/`.
  - `Start-Inventory-GUI.ps1`: lightweight WinForms launcher that spawns `pwsh` processes to run scripts.
  - `data/`: persistent CSV files (inventory tables) and `hardware_db.json` (structured DB for part specifications).

- Key patterns and conventions (follow these exactly):
  - Path anchoring: always use `$PSScriptRoot` or the script's resolved root; do not assume CWD. See `module/HardwareInventory.psm1` and `scripts/*.ps1` for examples.
  - Encoding and CSV headers: CSVs are expected to be text/UTF8 with consistent headers initialized by `Initialize-Csv` / `Ensure-Csv`. When adding fields, update both the initializer in `module/HardwareInventory.psm1` and the corresponding header string in `scripts/*`.
  - Normalization helpers: `Normalize-Socket` and `Normalize-Vendor` are used before storage/comparison — preserve and reuse these for matching logic.
  - Add-or-increment pattern: scripts use an `Add-OrIncrement` style to merge new rows by matching key fields rather than blindly appending.
  - Module exports: the module exports all functions via `Export-ModuleMember -Function *`; prefer adding new reusable utilities to `module/HardwareInventory.psm1`.

- Data model and integration points:
  - Part specs: `data/hardware_db.json` is the authoritative JSON for part specifications; CSVs are the inventory snapshots. Use `Get-HardwareFromDatabase`, `Search-HardwareDatabase`, and `Add-HardwareToDatabase` in the module to work with the JSON DB.
  - Inventory CSV files: `cpu.csv`, `gpu.csv`, `ram.csv`, `motherboard.csv`, `psu.csv`, etc. See `module/HardwareInventory.psm1` for the paths and field lists.
  - GUI launcher: `Start-Inventory-GUI.ps1` spawns `pwsh` to run `scripts/*` files; keep scripts idempotent and root-aware so they work when launched this way.

- Developer workflows & useful commands:
  - Load module interactively: `Import-Module .\module\HardwareInventory.psm1` then call helpers like `Get-HardwarePaths`.
  - Inspect DB: `Get-Content data\hardware_db.json -Raw | ConvertFrom-Json` or `Get-HardwareFromDatabase`.
  - Run a script with verbose/debug output: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\Hardware-Inventory.ps1 -Verbose` (scripts use standard Write-Host; add `-Verbose` switches in helpers where you extend them).
  - GUI launch: double-click `Start-Inventory-GUI.ps1` or run from PowerShell as above.

- Platform & dependency notes:
  - Target runtime: PowerShell Core/7+ (module manifest declares `PowerShellVersion = '7.0'`).
  - UI: uses .NET `System.Windows.Forms` — Windows-only behavior expected for the GUI.
  - ExecutionPolicy: launcher and README expect `-ExecutionPolicy Bypass` for convenience.

- When changing data formats or adding fields:
  - Update CSV header initializers in both `module/HardwareInventory.psm1` (Initialize-InventoryFiles) and the matching `Ensure-Csv` header strings in `scripts/*`.
  - Update any import/export mapping logic (for example `Add-HardwareInventory` maps DB properties to CSV columns).

- Examples (use exact naming):
  - Add via module: `Add-HardwareInventory -Type CPU -Name 'Ryzen 5 3600' -Quantity 1 -Location 'Shelf' -Notes 'spare'` (module exposes these helpers).
  - Find a spec: `Search-HardwareDatabase 'Ryzen'` or `Get-HardwareFromDatabase CPU 'Ryzen 5 3600'`.

- Useful files to inspect:
  - [Start-Inventory-GUI.ps1](Start-Inventory-GUI.ps1)
  - [module/HardwareInventory.psm1](module/HardwareInventory.psm1)
  - [scripts/Hardware-Inventory.ps1](scripts/Hardware-Inventory.ps1)
  - `data/` (CSV files and `hardware_db.json`)

If anything here is unclear or you'd like more detail (for example, line-level references or examples of unit tests, CI, or a contributor workflow), tell me which area to expand and I'll update this file.
