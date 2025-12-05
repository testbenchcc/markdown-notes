I'm working with a VMware virtual machine for PLC programming and frequently switch between a NAT adapter and a USB NIC. When both are enabled, all traffic seems to default to the NAT adapter. If I disable the NAT adapter after it was active, the routing remains stuck on it. But if I start without the NAT adapter and only enable the USB NIC, everything works until the NAT is re-enabled, then I lose access to tools on the USB NIC. Some software still works across both networks, but I can’t ping or communicate with the tools I need. Can you help me figure out how to manually adjust, reset, or prioritize routing in Windows (or VMware) without restarting the machine every time? Ideally, I’d like to toggle between adapters more reliably during development.

### Script Overview
- After disconnecting from the VMs NAT connection, run this script to fix the routing issues and allow access to the adapters set network address. 
- Make sure the `NIC Alias` is correct using `Get-NetIPInterface -AddressFamily IPv4 | Sort-Object InterfaceIndex`

```powershell
# Notes 
 FixNicRouting.ps1
   • Detects the first static IPv4 on the chosen adapter
   • Builds the subnet mask from the CIDR prefix safely
   • Derives the network address
   • Deletes any old route on this interface
   • Adds a fresh persistent route with your chosen metric

# User Settings 
$nicAlias = 'usb_xhci 2'   # adapter you care about
$metric   = 1              # route cost

# helper: convert prefix length into mask bytes
function Convert-PrefixToMaskBytes {
    param([int]$prefix)

    $bytes = 0,0,0,0
    for ($i = 0; $i -lt 4; $i++) {
        if ($prefix -ge 8)        { $bytes[$i] = 255; $prefix -= 8 }
        elseif ($prefix -gt 0)    { $bytes[$i] = 256 - [math]::Pow(2, 8 - $prefix); $prefix = 0 }
    }
    return ,$bytes                # comma forces array return
}

# 0. Elevate to Admin 
if (-not ([Security.Principal.WindowsPrincipal] `
          [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {

    Write-Host 'Restarting with admin rights…'
    Start-Process powershell -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# 1. Get the static IP entry for the defined nicAlias
$ipEntry = Get-NetIPAddress -InterfaceAlias $nicAlias -AddressFamily IPv4 |
           Where-Object { $_.PrefixOrigin -eq 'Manual' } |
           Select-Object -First 1 IPAddress, PrefixLength, InterfaceIndex

if (-not $ipEntry) { throw "No static IPv4 address found on $nicAlias" }

$plcIP   = $ipEntry.IPAddress
$prefix  = $ipEntry.PrefixLength
$idx     = $ipEntry.InterfaceIndex

# 2. Mask and network
$maskBytes   = Convert-PrefixToMaskBytes $prefix
$plcMask     = ($maskBytes -join '.')
$ipBytes     = ([System.Net.IPAddress]::Parse($plcIP)).GetAddressBytes()
$netBytes    = for ($i = 0; $i -lt 4; $i++) { $ipBytes[$i] -band $maskBytes[$i] }
$plcPrefix   = ($netBytes -join '.')

# 3. Build and run the route commands
$delCmd = "route delete $plcPrefix mask $plcMask if $idx"
$addCmd = "route -p add $plcPrefix mask $plcMask $plcIP metric $metric if $idx"

cmd /c $delCmd | Out-Null
cmd /c $addCmd | Out-Null

Write-Host "PLC route $plcPrefix/$prefix bound to interface $idx ($nicAlias)"

```