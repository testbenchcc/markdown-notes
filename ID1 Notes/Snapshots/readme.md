## Purpose  
This process is designed to offload the storage of important data from the PLC to the HMI. The primary goal is to preserve critical PLC data without relying on the PLC program itself.  

In the event that online access to the PLC program is lost-such as during a program upgrade or other complications-the data remains safely stored on the HMI’s SD card. Because this storage location is not affected by PLC or HMI downloads, full program downloads can be performed without the risk of losing data that would normally be overwritten in a single snapshot.  

Additionally, since the PLC can only store one snapshot at a time, using the HMI for storage allows multiple snapshots (or `fingerprints`) of the system’s settings to be saved for easier recovery and reference.  

The HMI also has the capability to connect to SMB network shares. Since all ID1 systems operate on the 33.7.0.0/24 subnet, we can dedicate the address 33.7.0.243/24 to the development PC and configure all ID1 HMIs to connect to that share. By synchronizing the SD card with the SMB share, data stored on the HMI becomes easily accessible for editing, backups, or transfer into another matching ID1 system.  

File overwrite behavior is handled differently depending on the sync direction. When copying from the SD card to the SMB share, files are not overwritten-this ensures that any new snapshots are preserved on the network. When copying from the SMB share back to the SD card, overwrites are allowed. This makes it possible to modify existing files on the network and have those changes reflected and usable on the HMI after a sync.  

Because the files are stored in CSV format, they are human-readable, simple to process, and easy to edit. This format also allows for integration with Git, enabling version control and comparison of system configuration changes over time. For example, if a system is serviced after commissioning, we can compare the original configured settings with any changes made by the customer.  

---

### High level overview


```mermaid-remote
id: 8
title: Snapshot flow
```


## Implementation notes
### Importing into your project
This scripting is tailored to the ID1 systems. It will only work with the UDTs implemented in this project.

- Open the global library `saveRestore_v2` stored within `Siemens_Global_Libraries` repository. This library contains popup screens, a hmi tag table, object groups, and the `saveRestore_v2` script folder.
- Drag the `saveRestore_v2` script folder into the HMI `Scripts` area on the HMI..
- Drag `Copy of Screens to info` and `Copy of Screens to saveRestore_v2` into you `Screens` folder on the HMI.
- Drag `group_CustSaveRestore_v2` to your customer page. 
- Drag `group_DfsSaveRestore_v2` to the DFS config page.
- Drag `saveRestore_v2` tag table into the `HMI tags` folder on the HMI.

### Customizing to your project
Two places need updates to match your project: the `saveRestore_v2` script folder’s `Global definitions area` (`GDA` for short) and the `saveIoFunctionCalls` script.

- In `GDA`, save locations, customer setpoint tags, DFS setpoint tags, and the field lists used for IO snapshots are defined.
  - In most cases you only need to update the customer and DFS setpoint tag lists. Everything else can remain the same.
- `saveIoFunctionCalls` is a centralized place where all of the `saveIOToCsv_v2` calls are made. These calls need to be customized to your project.

### Programming computer setup
Configure the programming laptop with the following IP:
- `33.7.0.243/24`

This allows each HMI to be configured exactly the same when using the SMB Share as well as other unrelated services like an NTP server.

#### SMB usage and configuration
Using the this method is not nessisary, but is allows you to sync the existing configuration files directly into the repository folder. If you do not want to use this, go to the next section. 

The SMB share must be configured on the HMI to use this method. A button in the master copies area synchronizes the HMI SD contents to the share and vice versa. Overwriting is disabled when copying files from the SD card to the share. Overwriting is enabled when copying files from the share to the SD card. This is done so that the files can be edited on the programing computer and moved back onto the HMI to be restored.

HMI Share Configuration:
- Network Path: `//33.7.0.243/projectData` 
- Username: `testline`
- Password: `dfs337DFS337!!!`

A PowerShell script is available to create and close the SMB share:
Repository: `Siemens_Global_Libraries`
Path: `\Tools\powershell\smb-share.ps1`

Usage:
- Copy `smb-share.ps1` to the root folder of the repository you are working in.
- Right click and select `Run with PowerShell`.
- On start, it will elevate to admin level and lists active shares. Ensure there are no other `projectData` shares running to avoid conflicts.
- To check if the share is connected, you can click the refresh button on the HMIs network share configuration page. The shares status should say `connected`

#### Accessing the data without SMB
All CSV files created by the `saveRestore_v2` scripts can be read from the HMI SD card.
Shut down the HMI before removing the card to reduce the risk of data corruption.

Files can be observed using the HMIs programs area using `Files` tool.

### Exporting Values from an Excel IO Sheet
An IO configuration CSV file that mimics the same structure as the `Save IO Data` function on the HMI can be created using Excel and a VBA Macro. This can be used to create initial default values or a custom configuration. The generated file can then be copied into the `ioSnapshots` folder on the HMI and restored.

The Macro file is located in the repository: `Siemens_Global_Libraries`  
Path: `\Tools\excel\IoSnapshotExcel_v2.bas`

#### Steps to use the Macro:
1. Open your IO sheet in Excel.  
2. Go to the **Developer** tab and select **Visual Basic**.  
3. In the Project Explorer, right-click your IO Excel file, select **Import**, and navigate to `IoSnapshotExcel_v2.bas`.  
4. Close the Visual Basic window.  
5. On the Excel ribbon, select **Macros**.  
6. Run the macro `Snapshot_makesheet_all`.  
7. When prompted, choose a save location. Save the file into the `ioSnapshots` folder on the HMI.  

---

### How It Works

#### IO Snapshots

When you save an I/O snapshot, the function writes a new CSV file to the HMI’s SD card.
The storage path is defined in `saveRestore_v2` → `GDA`.
By default, the snapshot file is named after the system’s T-number and the current system time.

When restoring, the popup window lists all available snapshot files.
Select the file you want, and the system will load its contents.

#### SP Snapshots

Setpoint snapshots work a little differently. Because setpoints are specific to each T-number, the file name combines the system’s T-number with a postfix defined in `GDA`.
By default, filenames look like this:

```
T0000015700_customerConfig.csv
```

Once created, any new saves are appended to the same file.
If the system’s T-number changes, a new file is generated automatically.

Since the T-number will not be set initally, you can create an initial file named `_customerConfig.csv` with default configurations.
Engineering’s **System Configurator** can provide a list of D-numbers and T-numbers, along with some configuration items:

```
...\D86763-MTI-ID1 Clear Chems\5. Engineering\Systems\D86763_System Configurator_9-2-25.xlsx
```

Here’s a sample created for the CTU/BCTU systems using this method:

| timestamp                | saveName    | Sys\_DB;docScreen.project | Sys\_DB;docScreen.tNumber | Sys\_DB;docScreen.sysName | Sys\_DB;Cfg;ScmeEnable | Sys\_DB;Cfg;Tank01Enable | Sys\_DB;Cfg;Tank01Enable | Sys\_DB;Cfg;WasteDilute | Sys\_DB;Cfg;Engine\_Filter\_Amount | Sys\_DB;Cfg;Metrology | Sys\_DB;Cfg;Particle\_Counter | Sys\_DB;Cfg;Indirect\_Vent |
| ------------------------ | ----------- | ------------------------- | ------------------------- | ------------------------- | ---------------------- | ------------------------ | ------------------------ | ----------------------- | ---------------------------------- | --------------------- | ----------------------------- | -------------------------- |
| 2025-09-10T19:08:57.063Z | D86763-D106 | D86763-D106               | T0000015689               | BCTU                      | TRUE                   | TRUE                     | TRUE                     | FALSE                   | 3                                  | FALSE                 | FALSE                         | FALSE                      |
| 2025-09-10T19:08:57.063Z | D86763-D107 | D86763-D107               | T0000015689               | BCTU                      | TRUE                   | TRUE                     | TRUE                     | FALSE                   | 3                                  | FALSE                 | FALSE                         | FALSE                      |
| 2025-09-10T19:08:57.063Z | D86763-D108 | D86763-D108               | T0000015689               | BCTU                      | TRUE                   | TRUE                     | TRUE                     | FALSE                   | 3                                  | FALSE                 | FALSE                         | FALSE                      |
| 2025-09-10T19:08:57.063Z | D86763-D126 | D86763-D126               | T0000015690               | BCTU                      | TRUE                   | TRUE                     | TRUE                     | TRUE                    | 6                                  | FALSE                 | FALSE                         | FALSE                      |

Because the testline and field service teams usually know the system’s D-number, they can use it to locate the correct configuration.
From there, they can fill in the lesser-known system details, adjust the DFS configuration if needed, and create a new restore point.

## Know bugs
- The list boxes don’t support scrolling with the touch interface; a mouse is required if you need to scroll.
As a workaround, you can manually enter the desired name in the restore popup’s **Name** field to bypass scrolling.