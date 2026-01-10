# Hardware Inventory System - Architecture Update

## Overview of Changes

This update implements the **dual-database architecture** you requested:
- **hardware_db.json** = Read-only reference specifications (never written to)
- **user_db.json** = User-added specifications (writable)
- **Individual CSV files** = Actual inventory items you own

## What Changed

### 1. **Common.ps1** (Updated)
- Added `Get-ComponentSpecs()` function
- Looks up specs from hardware_db.json and user_db.json
- User database takes priority over hardware database

### 2. **Hardware-Inventory.ps1** (Completely Rewritten)
- **OLD**: Only detected CPU and wrote to hardware_db.json ❌
- **NEW**: Comprehensive inventory management for all component types ✅
- Never writes to hardware_db.json (read-only reference)
- Writes inventory items to individual CSV files

### 3. **Database Architecture**
```
data/
├── hardware_db.json          (READ-ONLY specs - never modified)
├── user_db.json              (User-added specs - writable)
├── cpu.csv                   (Your actual CPU inventory)
├── gpu.csv                   (Your actual GPU inventory)
├── ram.csv                   (Your actual RAM inventory)
├── psu.csv                   (Your actual PSU inventory)
├── motherboard.csv           (Your actual motherboard inventory)
├── storage.csv               (Your actual storage inventory)
└── cooler.csv                (Your actual cooler inventory)
```

## Installation Instructions

### Step 1: Backup Your Current System
```powershell
# Run your backup script first!
.\Backup-Inventory.ps1
```

### Step 2: Replace Files

**In your `scripts/` folder:**

1. **Replace `Common.ps1`** with the new version
2. **Replace `Hardware-Inventory.ps1`** with the new version

### Step 3: Create user_db.json

Create `data/user_db.json` with this content:
```json
{
    "CPU": [],
    "GPU": [],
    "RAM": [],
    "PSU": [],
    "Motherboard": [],
    "Storage": [],
    "Cooler": []
}
```

### Step 4: Ensure hardware_db.json Exists

Make sure `data/hardware_db.json` exists with your component specifications.

## CSV File Structure

### Important Note: Lowercase Filenames
The system uses **lowercase** CSV filenames to match your existing files:
- `cpu.csv` (not CPU.csv)
- `gpu.csv` (not GPU.csv)
- etc.

### CSV Headers

**cpu.csv:**
```
ID,Brand,Model,Cores,Threads,BaseClock,BoostClock,TDP,Socket,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

**gpu.csv:**
```
ID,Brand,Model,VRAM,CoreClock,MemoryClock,TDP,Interface,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

**ram.csv:**
```
ID,Brand,Model,Capacity,Speed,Type,Latency,Voltage,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

**psu.csv:**
```
ID,Brand,Model,Wattage,Efficiency,Modular,FormFactor,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

**motherboard.csv:**
```
ID,Brand,Model,Socket,Chipset,FormFactor,MemorySlots,MaxMemory,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

**storage.csv:**
```
ID,Brand,Model,Capacity,Type,Interface,FormFactor,ReadSpeed,WriteSpeed,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

**cooler.csv:**
```
ID,Brand,Model,Type,TDP,FanSize,Height,SocketSupport,Quantity,Status,PurchaseDate,PurchasePrice,Notes
```

## How It Works Now

### Adding Inventory Items

1. Launch the system: `Start-Inventory.ps1` → Choose CLI
2. Select component type (CPU, GPU, etc.)
3. Choose "Add New"
4. Enter Brand and Model
5. System automatically looks up specs from databases:
   - First checks `user_db.json` (user entries)
   - Falls back to `hardware_db.json` (official specs)
   - If not found, prompts for manual entry
6. If entered manually, you can save to `user_db.json` for future use
7. Item is saved to the appropriate CSV file (cpu.csv, gpu.csv, etc.)

### Database Priority

When looking up specifications:
1. **user_db.json** (checked first - your custom entries)
2. **hardware_db.json** (fallback - official specs)
3. **Manual entry** (if not found in either)

### Read-Only Protection

- `hardware_db.json` is NEVER modified by the inventory system
- Only `user_db.json` and CSV files are writable
- This prevents data corruption and protects your reference specs

## New Features

### Comprehensive Component Management
- Add/Edit/Delete all component types
- Quantity tracking for each item
- Status tracking (Available/In-Use/Sold/RMA)
- Purchase date and price tracking
- Notes field for custom information

### Spec Database Search
- Search hardware_db.json and user_db.json by brand/model
- View specifications before adding to inventory
- Helps verify you have the right specs

### Inventory Search & Summary
- Search across all component types
- View inventory summary (total counts)
- See quantity and status at a glance

## Compatibility with Existing Scripts

All your existing scripts remain compatible:

✅ **Build-Planner.ps1** - Still reads from CSV files
✅ **Host-Inventory.ps1** - Still manages hosts.csv
✅ **Backup-Inventory.ps1** - Still backs up data folder
✅ **Backup-To-NAS.ps1** - Still backs up to NAS

## Testing the Update

After installing, test these scenarios:

1. **Spec Lookup**: Add a component that exists in hardware_db.json
   - Should auto-populate specifications
   
2. **Manual Entry**: Add a component not in database
   - Should prompt for manual specs
   - Should offer to save to user_db.json
   
3. **User Database**: Add custom specs to user_db.json
   - Should be found when adding inventory items
   - Should take priority over hardware_db.json

4. **CSV Files**: Check that items are saved correctly
   - Open cpu.csv, gpu.csv, etc. in Excel/Notepad
   - Verify data is properly formatted

## Troubleshooting

### "hardware_db.json not found"
- This is just a warning
- You can still add items manually
- Spec lookups won't work until you have the database

### "Specifications not found"
- The brand/model isn't in either database
- Enter specs manually
- Choose to save to user_db.json for future use

### CSV file corruption
- Use your backup to restore
- CSV files are simple text - can be edited manually
- Make sure no commas in data fields

### Module not found warning
- This is from the old Start-Inventory.ps1 launcher
- It's looking for a module that doesn't exist
- Can be safely ignored or removed from launcher

## Future Enhancements

Possible improvements for later:
- Import/export functionality for databases
- Bulk import from CSV
- Advanced filtering and reporting
- Integration with build compatibility checking
- Auto-update hardware_db.json from online sources

## Questions?

If you run into issues:
1. Check your backup
2. Verify file locations match the README
3. Make sure CSV headers match exactly
4. Ensure JSON files are valid (use jsonlint.com)
5. Check that scripts are in the correct folders

## File Locations Summary

```
Project Root/
├── Start-Inventory.ps1          (launcher - no changes needed)
├── Start-Inventory.cmd          (batch launcher)
├── Start-Inventory-GUI.ps1      (GUI launcher - no changes needed)
├── scripts/
│   ├── Common.ps1               (REPLACE THIS)
│   ├── Hardware-Inventory.ps1   (REPLACE THIS)
│   ├── Host-Inventory.ps1       (no changes)
│   ├── Build-Planner.ps1        (no changes)
│   ├── Backup-Inventory.ps1     (no changes)
│   └── Backup-To-NAS.ps1        (no changes)
└── data/
    ├── hardware_db.json         (read-only reference)
    ├── user_db.json             (CREATE THIS if missing)
    ├── cpu.csv                  (lowercase!)
    ├── gpu.csv                  (lowercase!)
    ├── ram.csv                  (lowercase!)
    ├── psu.csv                  (lowercase!)
    ├── motherboard.csv          (lowercase!)
    ├── storage.csv              (lowercase!)
    ├── cooler.csv               (lowercase!)
    └── hosts.csv                (no changes)
```
