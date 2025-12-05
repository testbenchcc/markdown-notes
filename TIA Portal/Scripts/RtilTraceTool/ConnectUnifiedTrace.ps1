# ================== USER SETTINGS ==================
$defaultIP  = '33.7.0.2'   # Change this if you want a different default
$viewerPath = 'C:\Program Files\Siemens\Automation\Portal V19\Bin\RTILtraceViewer.exe'
$toolPath   = 'C:\Program Files\Siemens\Automation\WinCCUnified\bin\RTILtraceTool.exe'
# ===================================================

# Bypass execution policy for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Menu
Write-Host ''
Write-Host 'Select trace startup mode:'
Write-Host ' 1) Simulation (viewer only)'
Write-Host " 2) Connect to $defaultIP (default)"
Write-Host ' 3) Connect to custom address'
$choice = Read-Host 'Enter 1, 2, or 3 [default 2]'

switch ($choice) {
    '1' {
        Write-Host 'Starting RTILtraceViewer for simulation...'
        Start-Process $viewerPath
    }

    '3' {
        $ip = Read-Host 'Enter host IP address'
        if (-not $ip) {
            Write-Host 'No IP entered. Aborting.'
            break
        }
        Write-Host "Starting trace tool for $ip..."
        Start-Process $toolPath -ArgumentList "-mode receiver -host $ip -tcp"
        Start-Process $viewerPath
    }

    default {   # Option 2 or blank
        $ip = $defaultIP
        Write-Host "Starting trace tool for default address $ip..."
        Start-Process $toolPath -ArgumentList "-mode receiver -host $ip -tcp"
        Start-Process $viewerPath
    }
}
