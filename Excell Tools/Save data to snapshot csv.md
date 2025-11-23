## Save data to CSV file


```Javascript
export async function saveDimToCsv(tagPrefix, card, maxChannel, tagPostfix, storageDir, fileName) {
    const fs = HMIRuntime.FileSystem;
    HMIRuntime.Trace("[1] saveDimToCsv start");

    // 2. Make sure folder exists

    const dirPath = storageDir;
    const filePath = `${dirPath}/${fileName}.csv`;

    try {
        await fs.CreateDirectory(dirPath).catch(() => {});
        HMIRuntime.Trace("[2] Snapshot directory ready");
    } catch (e) {
        HMIRuntime.Trace(`[2] Cannot create Snapshot directory: ${e}`);
        return;
    }

    // 3. Collect all channel points                             

    const chMax = parseInt(maxChannel, 10);
    if (isNaN(chMax) || chMax < 0) {
        HMIRuntime.Trace("[3] Invalid maxChannel parameter");
        return;
    }

    const points = [];
    for (let channel = 0; channel <= chMax; channel++) {
        const basePath = `${tagPrefix}${card}(${channel})${tagPostfix}`;
        let workingTag = Tags(basePath).Read();
        workingTag = String(workingTag).replace(/"/g, "").replace(/\./g, ";");

		// Fetch tag values from PLC
		// We should be using a TagSet instead of individual reads. 
        const pt = {
            workingTag: workingTag,
            name: Tags(workingTag + ".io.name").Read(),
            pAndId: Tags(workingTag + ".io.p&id").Read(),
            desc: Tags(workingTag + ".io.desc").Read(),
            pLbl: Tags(workingTag + ".io.pLbl").Read(),
            gsHi: Tags(workingTag + ".gsHi").Read(),
            configDis: Tags(workingTag + ".configDis").Read(),
            notPres: Tags(workingTag + ".notPres").Read(),
            almDlySp: Tags(workingTag + ".almDlySp").Read(),
            almShtdnEn: Tags(workingTag + ".almShtdnEn").Read(),
            almEn: Tags(workingTag + ".almEn").Read()
        };
        points.push(pt);
    }
    HMIRuntime.Trace(`[3] Collected ${points.length} channel(s)`);

    // 4. Prepare and format headers / ensure file exists
    const csvEscape = v => {
        const s = String(v);
        return /[",;\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
    };

    const wantHeaders = Object.keys(points[0]);
    let haveHeaders = [];
    let fileExists = true;

    try {
        const firstLine = await fs.ReadFile(filePath, "utf8").then(t => t.split(/\r?\n/)[0]);
        haveHeaders = firstLine ? firstLine.split(',') : [];
    } catch {
        fileExists = false;
    }

    if (!fileExists) {
        // create file with header only so AppendFile() has a target
        await fs.WriteFile(filePath, wantHeaders.join(',') + "\n", "utf8");
        haveHeaders = [...wantHeaders];
    }

    // Verify header columns match expectation
    const missing = wantHeaders.filter(h => !haveHeaders.includes(h));
    if (missing.length) {
        try {
            // Read entire file, rebuild with extended headers
            const txt = await fs.ReadFile(filePath, "utf8");
            const lines = txt.split(/\r?\n/).filter(Boolean);
            const oldRows = lines.slice(1);
            const newHeaders = haveHeaders.concat(missing);

            const remapped = oldRows.map(r => {
                const cols = r.split(',');
                return newHeaders.map(h => {
                    const idx = haveHeaders.indexOf(h);
                    return idx !== -1 ? (cols[idx] ?? '') : '';
                }).join(',');
            });

            const rebuilt = newHeaders.join(',') + "\n" + remapped.join('\n') + "\n";
            await fs.WriteFile(filePath, rebuilt, "utf8");
            haveHeaders = newHeaders;
            HMIRuntime.Trace("[4] Header extended:  file rebuilt");
        } catch (e) {
            HMIRuntime.Trace(`[4] Header rebuild failed: ${e}`);
            return;
        }
    }

    // 5. Append new rows
    const newRows = points.map(p => haveHeaders.map(h => csvEscape(p[h] ?? "")).join(',')).join('\n') + '\n';
    try {
        await fs.AppendFile(filePath, newRows, "utf8");
        HMIRuntime.Trace("[5] CSV append ok");
    } catch (e) {
        HMIRuntime.Trace(`[5] CSV append failed: ${e}`);
    }
}
```
##### Function Calls

```javascript
export async function Button_MainMenu_5_OnUp(item, x, y, modifiers, trigger) {
  // Save inhibit is used to prevent the user from pressing the save button repeatadly, resulting in excess calls.
  const saveInh = Tags("saveInhibit").Write(1);
  // Get the save path integer from the io field tags and parse it as base 10
  const savePathInt = parseInt(Tags("savePathInt").Read(), 10);
  // Name provided in the io field
  const saveName = Tags("saveName").Read();
  // Fetch the selected path using the int returned from the path drop down io field.
  const savePath = HMIRuntime.Resources.TextLists("@Default.storagePaths").Item(savePathInt).Item(HMIRuntime.Language);                    

  // Since we are writing to a file, we need to wait for each function to finish before starting the next.
  //           saveDimToCsv(tagPrefix,            card, maxChannel,    tagPostfix, storageDir, fileName)
  await global.saveDimToCsv("COMM_IO_DB;AOI_", "DIM03",       "15", ";workingTag",   savePath, saveName);
  await global.saveDimToCsv("COMM_IO_DB;AOI_", "DIM04",       "15", ";workingTag",   savePath, saveName);
  await global.saveDimToCsv("COMM_IO_DB;AOI_", "DIM05",       "15", ";workingTag",   savePath, saveName);
  await global.saveDimToCsv("COMM_IO_DB;AOI_", "DIM06",       "15", ";workingTag",   savePath, saveName);
  await global.saveDimToCsv("COMM_IO_DB;AOI_", "DIM07",       "15", ";workingTag",   savePath, saveName);

  // Close the popup when the process is finished
  HMIRuntime.UI.SysFct.ClosePopup(".");
  // Remove the save inhibit
  HMIRuntime.Tags.SysFct.ResetBitInTag("saveInhibit", 0);
}
```

These calls are placed in the `Save to File` button on-release event:
![[Pasted image 20250616140827.png]]
###### Improvements
- Instead of using the D#, we should use the T#. 

##### CSV File produced
| workingTag          | name     | pAndId   | desc                            | pLbl     | gsHi | configDis | notPres | almDlySp | almShtdnEn | almEn |
| ------------------- | -------- | -------- | ------------------------------- | -------- | ---- | --------- | ------- | -------- | ---------- | ----- |
| COMM_WRK;IO;HS00_00 | HS 00.00 | HS 00.00 | Local EMO 1                     | HS 00.00 | TRUE | TRUE      | FALSE   | 0        | TRUE       | TRUE  |
| COMM_WRK;IO;REMO    | REMO     | REMO     | Remote EMO                      | REMO     | TRUE | TRUE      | FALSE   | 0        | TRUE       | TRUE  |
| COMM_WRK;IO;RLSAF   | RLSAF    | RLSAF    | Remote Life Safety              | RLSAF    | TRUE | TRUE      | FALSE   | 0        | TRUE       | TRUE  |
| COMM_WRK;IO;ZS20_00 | ZS 20.00 | ZS 20.00 | Common Cabinet Door Interlock 1 | ZS 20.00 | TRUE | TRUE      | FALSE   | 0        | FALSE      | TRUE  |
| COMM_WRK;IO;PS00_00 | PS 00.00 | PS 00.00 | Cabinet Exhaust Fault           | PS 00.00 | TRUE | TRUE      | FALSE   | 0        | TRUE       | TRUE  |
| ...                 | ...      | ...      | ...                             | ...      | ...  | ...       | ...     | ...      | ...        | ...   |


##### How it works
Each row in the CSV represents a UDT instance. The `workingTag` column contains the base tag path, and the other columns represent fields within that UDT.
To reference a specific tag in your PLC or HMI, concatenate the `workingTag` value with the column header using a dot (`.`) as a separator.

**Example:**  
For the row where `workingTag` is `COMM_WRK;IO;HS00_00` and the column is `name`,  
the resulting tag would be:

```
COMM_WRK;IO;HS00_00.name = "HS 00.00"
```

This structure allows easy parsing and mapping to actual tag addresses in our system.

Additionally, tag fields that are not present in the original file can be added manually as new columns. Since you're constructing the full tag path using the `workingTag` and field name, these extra fields can be used just like the others; even if they weren’t part of the original data.
#### Restore Code

```javascript
export async function restoreDimToCsv(filePath) {
  // All of the information we need to restore the tags is stored in the CSV data. All we need to provide is the file path.
  // Work in progress
}
```