<#  smb-share.ps1
    Start or stop an SMB share for one specific directory.
    Creates/uses a local account "testline" with password "dfs337DFS337!!!".
    Run from an *elevated* PowerShell console.                                    #>

# Unified mounts the share as '/net/mount'
#region Settings  ---------------------------------------------------------------
$sharePath = Join-Path -Path $PSScriptRoot -ChildPath 'projectData'
$shareUser  = 'testline'
$sharePass  = 'dfs337DFS337!!!'     # plain-text by request
#endregion

#region Helper functions  -------------------------------------------------------
function Test-Admin {
    $id  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prn = [Security.Principal.WindowsPrincipal]$id
    $prn.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-LocalUser {
    param([string]$user,[string]$pwdPlain)

    if (-not (Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
        $sec = ConvertTo-SecureString $pwdPlain -AsPlainText -Force
        New-LocalUser -Name $user -Password $sec -PasswordNeverExpires -UserMayNotChangePassword
        Write-Host "Created local user $user."
    }
}

function Grant-NtfsRights {
    param([string]$path,[string]$user)

    icacls $path /grant "${user}:(OI)(CI)F" /T | Out-Null
}

function Get-ShareName {
    param([string]$path)
    $leaf = Split-Path $path -Leaf
    $san  = ($leaf -replace '[^A-Za-z0-9_\-]', '_')
    $san.Substring(0, [Math]::Min(80, $san.Length))
}

function Ensure-SMBFirewallRules {
    # Check if File and Printer Sharing rules are enabled
    $fpsRules = Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue

    if ($fpsRules) {
        $disabledRules = $fpsRules | Where-Object { $_.Enabled -eq "False" }
        if ($disabledRules) {
            Write-Output "Enabling File and Printer Sharing rules..."
            Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"
        } else {
            Write-Output "File and Printer Sharing rules are already enabled."
        }
    } else {
        Write-Output "File and Printer Sharing rules not found. Creating custom SMB rule..."
        # Check if custom SMB rule already exists
        $customRule = Get-NetFirewallRule -DisplayName "Allow SMB" -ErrorAction SilentlyContinue
        if (-not $customRule) {
            New-NetFirewallRule -DisplayName "Allow SMB" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
            Write-Output "Custom SMB firewall rule created."
        } else {
            Write-Output "Custom SMB firewall rule already exists."
        }
    }
}

function Start-LocalShare {
    param([string]$path, [string]$user, [string]$pwd)

    # Check if the directory exists and create it if it doesn't
    if (-not (Test-Path -Path $path)) {
        Write-Host "Creating directory: $path" -ForegroundColor Cyan
        New-Item -Path $path -ItemType Directory | Out-Null
    }

    # open firewall for file sharing
    Ensure-LocalUser $user $pwd
    Grant-NtfsRights  $path $user
    Ensure-SMBFirewallRules

    $name = Get-ShareName $path
    $existingShare = Get-SmbShare -Name $name -ErrorAction SilentlyContinue
    if ($existingShare) {
        # Check if the share points to the correct path
        if ($existingShare.Path -eq $path) {
            Write-Host "Share $name already exists and is pointing to the correct path." -ForegroundColor Yellow
            return
        } else {
            # Remove the existing share if it points to a different path
            Remove-SmbShare -Name $name -Force -Confirm:$false
            Write-Host "Removed existing share $name that was pointing to $($existingShare.Path)." -ForegroundColor Cyan
        }
    }

    New-SmbShare -Name $name -Path $path -Description "Project share" -FullAccess $user | Out-Null
    Write-Host "Started share \\$env:COMPUTERNAME\$name (user: $user)."
}

function Stop-LocalShare {
    param([string]$path)

    $share = Get-SmbShare | Where-Object { $_.Path -eq $path }
    if (-not $share) {
        Write-Host "No SMB share found for $path." -ForegroundColor Yellow
        return
    }

    Remove-SmbShare -Name $share.Name -Force -Confirm:$false
    Write-Host "Stopped share $($share.Name)."
}
function Ensure-SmbEnv {
    Import-Module SmbShare -ErrorAction SilentlyContinue
    if (-not (Get-Module SmbShare)) {
        Write-Host "SmbShare module not available or not on Windows." -ForegroundColor Yellow
        return
    }
    $svc = Get-Service -Name LanmanServer -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
        Write-Host "Starting 'Server' service for SMB visibility..." -ForegroundColor Cyan
        Start-Service -Name LanmanServer -ErrorAction SilentlyContinue
    }
}

function Show-ExistingShares {
    Ensure-SmbEnv
    try {
        $shares = Get-SmbShare -ErrorAction Stop
        if (-not $shares -or $shares.Count -eq 0) {
            Write-Host "No SMB shares found." -ForegroundColor Yellow
        } else {
            $shares |
                Select-Object Name, Path, Description, CurrentUsers, EncryptData, ContinuouslyAvailable |
                Format-Table -AutoSize | Out-Host
        }
    } catch {
        Write-Host "Could not list SMB shares: $($_.Exception.Message)" -ForegroundColor Red
    }
    # [void](Read-Host "Press Enter to return to the menu")
}

#endregion

#region Elevate if needed  ------------------------------------------------------
if (-not (Test-Admin)) {
    Write-Host "Restarting script with Administrator privileges..."
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
#endregion
Write-Host "Active Shares: "
Show-ExistingShares

while ($true) {
    Write-Host ""
    Write-Host "================  SMB Share Manager  ================"
    Write-Host "Fixed share path: $sharePath"   
    Write-Host "  1) Start share"
    Write-Host "  2) Stop share"
    Write-Host "  3) Show existing shares"
    Write-Host "  *Use CTRL+C to exit*"
    $choice = Read-Host "Select an option (1-3)"

    switch ($choice) {
        "1" { Start-LocalShare $sharePath $shareUser $sharePass }
        "2" { Stop-LocalShare  $sharePath }
        "3" { Show-ExistingShares }
        default { Write-Host "Invalid choice." -ForegroundColor Yellow }
    }
}
#endregion