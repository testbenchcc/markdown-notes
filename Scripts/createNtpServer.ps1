<# 
.SYNOPSIS
    Configure Windows 10 as an NTP server. Now self-elevates.

.DESCRIPTION
    - Enables Windows Time NTP server provider
    - Announces this host as a reliable time source
    - Optional upstream peers for this host to sync from
    - Opens Windows Firewall for UDP 123 inboundss
    - Restarts Windows Time service
    - Prints configuration and health info
#>

param(
    [string]$Peers = "0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org"
)

#region Helper functions --------------------------------------------------------
function Test-Admin {
    $id  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prn = [Security.Principal.WindowsPrincipal]$id
    return $prn.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
#endregion

#region Elevate if needed -------------------------------------------------------
if (-not (Test-Admin)) {
    Write-Host "Restarting script with Administrator privileges..." -ForegroundColor Yellow
    # Rebuild argument string if user passed -Peers
    $argList = @()
    if ($PSBoundParameters.ContainsKey('Peers')) {
        $argList += '-Peers'
        $argList += '"' + $Peers + '"'
    }
    $argString = '-ExecutionPolicy Bypass -File "' + $PSCommandPath + '" ' + ($argList -join ' ')
    Start-Process powershell.exe $argString -Verb RunAs | Out-Null
    exit
}
#endregion

Write-Host "Configuring Windows Time service to act as an NTP server..." -ForegroundColor Cyan

# Registry paths
$base        = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time"
$tpNtpServer = Join-Path $base "TimeProviders\NtpServer"
$configKey   = Join-Path $base "Config"
$paramsKey   = Join-Path $base "Parameters"

# Create keys if missing
New-Item -Path $tpNtpServer -Force | Out-Null
New-Item -Path $configKey   -Force | Out-Null
New-Item -Path $paramsKey   -Force | Out-Null

# 1) Enable the built in NTP server provider
New-ItemProperty -Path $tpNtpServer -Name "Enabled" -PropertyType DWord -Value 1 -Force | Out-Null

# 2) Announce as a reliable time source
#    5 means always reliable time source, advertise as a time server
New-ItemProperty -Path $configKey -Name "AnnounceFlags" -PropertyType DWord -Value 5 -Force | Out-Null

# 3) Make sure the service type is NTP
New-ItemProperty -Path $paramsKey -Name "Type" -PropertyType String -Value "NTP" -Force | Out-Null

# 4) Optionally set upstream peers for this host to sync from
if ($Peers.Trim()) {
    # Flags 0x8 = client mode, special poll
    New-ItemProperty -Path $paramsKey -Name "NtpServer" -PropertyType String -Value ($Peers.Trim() + ",0x8") -Force | Out-Null
    New-ItemProperty -Path (Join-Path $base "TimeProviders\NtpClient") -Name "SpecialPollInterval" -PropertyType DWord -Value 3600 -Force | Out-Null
}

# 5) Open Windows Firewall for inbound UDP 123
$ruleName = "NTP Server UDP 123"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol UDP -LocalPort 123 -Action Allow | Out-Null
} else {
    Set-NetFirewallRule -DisplayName $ruleName -Enabled True | Out-Null
}

# 6) Restart Windows Time service
Write-Host "Restarting Windows Time service..." -ForegroundColor Cyan
Stop-Service w32time -ErrorAction SilentlyContinue
Start-Service w32time

# 7) Resync if peers were set
if ($Peers.Trim()) {
    Write-Host "Triggering an initial sync with configured peers..." -ForegroundColor Cyan
    w32tm /config /update | Out-Null
    w32tm /resync /nowait | Out-Null
}

# 8) Show status and config
Write-Host "`nCurrent Windows Time configuration:" -ForegroundColor Green
w32tm /query /configuration

Write-Host "`nService status:" -ForegroundColor Green
Get-Service w32time | Format-Table -Auto

Write-Host "`nChecking that UDP 123 is listening:" -ForegroundColor Green
try {
    Get-NetUDPEndpoint -LocalPort 123 | Format-Table -Auto
} catch {
    Write-Warning "Could not query UDP endpoints. You can also run: netstat -ano | findstr :123"
}

Write-Host "`nQuick test from this machine against itself:" -ForegroundColor Green
w32tm /stripchart /computer:127.0.0.1 /dataonly /samples:5

Write-Host "`nAll set. This PC is now serving NTP on UDP 123 to your network." -ForegroundColor Cyan
