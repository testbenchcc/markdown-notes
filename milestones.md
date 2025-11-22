### Primary
- [ ] Polish demand? I think i removed this from the out req functions in exchange to sts global and local. Verify.
- [ ] Engine States?
	- [ ] Global
		- [ ] ENG01 Global: Supplying 
	- [ ] Local
		- [ ] ENG01 Local: Filling Tank 1
		- [ ] ENG01 Local: Filling Tank 2
	- [ ] Global and Local
		- [ ] Recirculating / Polishing
		- [ ] Standby / Waiting for Polish
- [ ] Add engine status to tell the user what the engine is doing other than global supply. IE Filling tank 2, supplying chem, recirculating.
- [x] Tank Faceplates / Enabled / State / Lead and lag / force to lead
- [ ] Tank 1 is disabled; and tank 2 and the SCME are enabled; tank 2 is supplying global and the SCME is supplying local; If tank 1 is disabled on the DFS config page, the SCME will not fill tank 2.
- [ ] SCME Vessel Empty Alarms
- [ ] Tank Empty Alarms
- [ ] SCME Alarms need to be added along with any trending items
- [x] SCME AIM Status screen button is broken. Points to a page that does not exist.
- [x] 2025-06-18 17:13 - I can not move the engines into auto...why?
	- ~~Issue resolved itself~~
- [x] 2025-06-16 12:10 - Create Engine States to reflect pulling from different sources
- [x] 2025-06-16 12:11 - Add Lead / Lag functionality to the Tanks
- [x] 2025-06-16 12:11 - Rework SMCE selection; Change to Lead / Lag functionality
- [x] 2025-06-18 12:29 - Add requests to valves
- [x] 2025-06-18 12:31 - Update engine outlet valves. They need to support the filling of other vessels. 
- [x] 2025-06-18 12:32 - Create an SCME ready; SMCE is present and has a Lead drum ready to go.
- [x] 2025-06-18 12:33 - Update the vessel selection to include SCME Ready.


### Secondary
- [x] 2025-06-16 12:13 - Complete the JavaScript [[Unified Data Snapshots]] code; Restore script is needed;
- [ ] 2025-06-18 12:29 - [[Unified Data Snapshots v2]] restore popup needs to be updated to include browsed files to restore.
- [ ] 2025-06-16 12:13 - Test the `Network Storage` feature on the Unified Comfort HMIs
	- Can we save directly to the network drive or do we need to save to internal storage and then copy it over?
	- I have created a samba server on the zero, but the HMI will not connect. I have been able to connect to the server on NixOS using Tailscale (advertised route `pizero2`)


#### PLCDataService 
 - [ ] Getting a len error when trying to write string values with defined lengths. Ie Using `String[64]` as a datatype in the plc-config.json file.

test