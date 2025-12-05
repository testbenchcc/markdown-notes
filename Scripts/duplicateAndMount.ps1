## What will this script do?
# 1. Removes the old `keys.vhd` file.
# 2. Creates a new copy of `keys.backup.vhd` named `keys.vhd`.
# 3. Mounts the new `keys.vhd` file.
#
## Why?
# - License keys can become corrupted if the IPC is shut down improperly.
#   This script ensures that a clean, known-good VHD is used each time the system starts,
#   preventing corruption from being carried forward and guaranteeing a consistent state.
#   By duplicating from a stable backup, you can recover or remount your license environment
#   even after unexpected power loss, file corruption, or improper shutdown.
#
## Setup
# 1. Create a folder named `keyBackup` in the root of the `C:\` drive
# 2. Copy `duplicateAndMountVhd.ps1` into the new `C:\keyBackup` folder
# 3. Add or create a new VHD in the new folder named `keys.backup.vhd`
#
## Helpful info
# `Mount-DiskImage` command requires elevation for normal users.
# If used in conjunction with Task Scheduler, the task must be executed by the SYSTEM user.
# Task Action:
#   - Program: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
#   - Arguments: -File "C:\keyBackup\duplicateAndMountVhd.ps1"
# USER VARIABLES
$folder     = 'C:\keyBackup' 
$baseName    = 'keys'                                   # without extension
# SCRIPT VARIABLES
$origVhdPath = Join-Path $folder   "$baseName.vhd"
$bakVhdPath  = Join-Path $folder   "$baseName.backup.vhd"
# DELETE OLD VHD
if (Test-Path $origVhdPath) {
    Remove-Item $origVhdPath -Force
}
# DUPLICATE BACKUP AS NEW VHD
if (Test-Path $bakVhdPath) {
    Copy-Item $bakVhdPath -Destination $origVhdPath       # keeps the backup intact
} else {
    Write-Error "Backup VHD not found at $bakVhdPath"
    exit 1
}
# MOUNT THE NEW VHD
Mount-DiskImage -ImagePath $origVhdPath -ErrorAction Stop