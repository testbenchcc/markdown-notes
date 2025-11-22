**WinCC Unified – Quick-reference for reading/writing the AIM / AOM / DIM / DOM UDTs**  
_(all code is plain JavaScript for RT Unified scripts; import nothing extra)_

---

## 1 Locate the UDT instance

| Piece        | Comes from                            | Typical value       |
| ------------ | ------------------------------------- | ------------------- |
| `tagPrefix`  | function arg (DB & array prefix)      | `"COMM_IO_DB;AOI_"` |
| `card`       | function arg (module name)            | `"DIM03"`           |
| `channel`    | function arg (array index)            | `"7"`               |
| `tagPostfix` | function arg (always `";workingTag"`) | `";workingTag"`     |

```js
const basePath = `${tagPrefix}${card}(${channel})${tagPostfix}`;   // e.g.  COMM_IO_DB;AOI_DIM03(7);workingTag
let workingTag = Tags(basePath).Read();                            // returns "DB1.DBX200.0"
workingTag = String(workingTag).replace(/"/g,"").replace(/\./g,";"); // "DB1;DBX200;0"
```

_`workingTag` is now the root of the real UDT tag in PLC memory; all field names are appended to it._

---

## 2 Write multiple fields atomically

```js
const tagSet = Tags.CreateTagSet();            // batch container :contentReference[oaicite:1]{index=1}
for (const f of fields) tagSet.Add(workingTag + f);

tagSet.Item[0].Value = name;     // …assign in same order you added
// …
tagSet.Write();                  // one round-trip, all fields updated :contentReference[oaicite:2]{index=2}
```

_Why TagSet?_ The Siemens object model guarantees faster, single-cycle updates and reduced traffic compared to individual `Tag.Write()` calls .

---

## 3 Read a whole point in one call

```js
const readSet = Tags.CreateTagSet();
for (const f of fields) readSet.Add(workingTag + f);

readSet.Read();                                      // synchronous
const name      = readSet.Item[0].Value;
const desc      = readSet.Item[1].Value;
// …
```

Use `ReadAsync()` if the screen must stay responsive.

---

## 4 Argument-to-field maps

### DIM (defaults v2_1) – digital **input**

|arg|UDT field|
|---|---|
|`name`|`.io.name`|
|`pAndId`|`.io.p&id`|
|`desc`|`.io.desc`|
|`pLbl`|`.io.pLbl`|
|`gsHi`|`.gsHi`|
|`configDis`|`.configDis`|
|`present` _(invert!)_|`.notPres`|
|`almDlySp`|`.almDlySp`|
|`almShtdnEn`|`.almShtdnEn`|
|`almEn`|`.almEn`|
|||

### DOM – digital **output**

`name, pAndId, desc, pLbl, configDis, present¬➜notPres`

### AIM – analog **input** / AOM – analog **output**

`name, desc, pLbl, present¬➜notPres, rawMin, rawMax, scldMin, scldMax, numSamp, unit`

_(AOM uses identical field names; only the UDT type differs.)_

---

## 5 Skeleton helpers

```js
function writeAim(pointArgs){
  const {tagPrefix, card, channel, tagPostfix,
         name, desc, pLbl, present,
         rawMin, rawMax, scldMin, scldMax,
         numSamp, unit} = pointArgs;

  const base   = `${tagPrefix}${card}(${channel})${tagPostfix}`;
  let   wTag   = Tags(base).Read();
  wTag         = String(wTag).replace(/"/g,"").replace(/\./g,";");

  const f = [".io.name",".io.desc",".io.unit",".io.area",".io.pLbl",
             ".notPres",".io.rawMin",".io.rawMax",".io.scldMin",
             ".io.scldMax",".numSamp"];

  const t = Tags.CreateTagSet();
  f.forEach(x => t.Add(wTag+x));

  t.Item[0].Value  = name;
  t.Item[1].Value  = desc;
  t.Item[2].Value  = unit;
  t.Item[3].Value  = channel;      // we store the channel number in .io.area
  t.Item[4].Value  = pLbl;
  t.Item[5].Value  = !present;     // invert!
  t.Item[6].Value  = rawMin;
  t.Item[7].Value  = rawMax;
  t.Item[8].Value  = scldMin;
  t.Item[9].Value  = scldMax;
  t.Item[10].Value = numSamp;

  t.Write();
}
```

Swap the _field list_ and the argument map for DIM/DOM to create their counterparts.

---

## 6 Best-practice checklist 

- **Invert `present` → `.notPres`** every time.
    
- **Keep field order fixed.** `TagSet.Item[n]` refers strictly to the _Add()_ order.
    
- **Use semicolons**, never dots, when composing runtime tag paths.
    
- **Prefer synchronous `Read()` / `Write()` in one-off scripts**; use the `Async` variants for UI-driven loops.
    
- **Watch data types:**
    
    - Strings → UDT `STRING`
        
    - REALs → `parseFloat()` before assign (see DIM helper)
        
    - Booleans stay Boolean.
        
- **Trace liberally** during development: `HMIRuntime.Trace(...)`.
    

---

## 7 Troubleshooting

|Symptom|Typical cause|
|---|---|
|Quality = 0x8200 (“Bad path”)|`workingTag` still contains dots or quotes.|
|Only some fields update|`TagSet.Add()` order ≠ assignment order, or mismatched field list.|
|Inconsistent values after write|Using multiple `Tag.Write()` instead of a TagSet – values arrive in different PLC cycles.|

---

Keep this page handy whenever you extend your default-loader or create new point utilities. All read/write interactions with the four IO-UDTs follow this exact recipe – master it once, reuse everywhere.