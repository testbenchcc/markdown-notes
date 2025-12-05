# Using `ConnectUnifiedTrace.ps1` with TIA Portal

## Purpose
Launch the WinCC Unified trace tools from inside TIA Portal. The script shows a menu with three choices:

1. **Simulation** - opens **RTILtraceViewer** only.  
2. **Default target** - connects the trace tool to the predefined IP address.  
3. **Custom target** - lets you enter any host IP.

You can change the default IP and the tool paths by editing the variables at the top of the script.

---

## One‑time setup inside TIA Portal

1. Open the **Tools** menu at the top of TIA Portal  
2. Choose **External Applications**  
3. Click **Configure...**  
4. In *List of applications*, select **\<Add new...>**  
5. Fill out the dialog like this:

| Field      | Value                                                                                     |
|------------|-------------------------------------------------------------------------------------------|
| **Name**   | Start Trace Tool                                                                          |
| **Command**| `powershell.exe`                                                                          |
| **Arguments** | `-ExecutionPolicy Bypass -File "C:\<YOUR PATH>\ConnectUnifiedTrace.ps1"`               |
| **Start in** | *(leave blank)*                                                                         |

6. Click **OK** to save. You will now see *Start Trace Tool* under **Tools → External Applications**.

---

## Everyday use

1. In TIA Portal, go to **Tools → External Applications → Start Trace Tool**  
2. A console window opens and shows the menu  
3. Type **1**, **2**, or **3** (press **Enter** for option 2)  
4. The selected trace tools start automatically  

---

## Customizing

Open the script and edit these variables near the top:

```powershell
$defaultIP  = '33.7.0.2'   # default target address
$viewerPath = 'C:\Program Files\Siemens\Automation\Portal V19\Bin\RTILtraceViewer.exe'
$toolPath   = 'C:\Program Files\Siemens\Automation\WinCCUnified\bin\RTILtraceTool.exe'
