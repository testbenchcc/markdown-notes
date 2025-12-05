### Process review
#### Common Difficulties
1. **Port Access:**  
    Most new systems connect to the **top Ethernet port**, but the firmware update requires the **bottom port**, which is often obstructed by existing cable routing or air lines.
2. **Physical Constraints:**  
    The **power cable has little to no slack**, making it difficult to hold the `Set` and `Next` buttons while plugging in the block. This makes it difficult entering firmware mode.
#### Process Overview

- Total update time: **8–10 minutes per solenoid block**
	- Software: **~3-4 min**
	- Physical work: **~5-6 min**
#### Recommended Improvements
**Hardware Layout**
- Use an extension cable or provide a dedicated 12V power supply so the power cable routing does not need to be cut or reworked.
- Utilize the solenoid block’s **bottom Ethernet port** for future connections. This allows firmware updates and communication through the existing cabling and switch, eliminating the need to unmount the block.
- The current **90 degree M12 D-coded Ethernet connector** forces the cable downward into the system due to its keying. This likely explains why the **top port** is commonly used. Selecting a connector with the key rotated **90° clockwise** would resolve the clearance issue and allow use of the bottom port.
### Firmware Update Procedure

#### Required Hardware

- M12-D to RJ45 Ethernet cable (male-to-male)
#### Hardware Preparation

1. **Disconnect all cables** from the solenoid block.
2. **Remove the block** from the system for easier access.
3. **Enter firmware update mode:**
    1. Hold down both the **Set** and **Next** buttons simultaneously.
    2. While holding, **apply power** to the solenoid block.
    3. Continue holding both buttons for about **10 seconds**.
    4. The screen will remain blank at first. After releasing the buttons, the block will boot normally after a short delay.
4. **Connect the Ethernet cable:**
    - Plug into the **bottom M12 Ethernet port** on the solenoid block (firmware port).
    - Connect the other end directly to your computer.
#### Software Setup
1. **Enable TFTP Client:**
    - Open _Windows Features_ and check **TFTP Client**.
    - Click **OK** to install if not already enabled.
2. **Set your computer’s IP address:**
    1. Go to `Control Panel\Network and Internet\Network Connections`.
    2. Right-click your Ethernet adapter -> **Properties**.
    3. Select **Internet Protocol Version 4 (TCP/IPv4)** -> **Properties**.
    4. Configure your IP to match the solenoid block’s subnet:
        - If the solenoid block is:
            - IP: `33.7.0.12`
            - Mask: `255.255.255.0`
        - Then set your computer to:
            - IP: `33.7.0.100`
            - Mask: `255.255.255.0`
    > **Note:** During this process, the solenoid is connected directly to your computer, so there is no risk of IP conflicts. Just ensure your computer’s IP does not match the solenoid block’s address.
3. **Verify network connection:**
    - Open Command Prompt and run:
    
        ```bash
        ping 33.7.0.12
        ```
        
    - You should receive a successful reply.
4. **Run the TFTP Loader utility:**
    1. Launch `TFTP-Load.exe`.
    2. Set **IP Address** to the solenoid block’s IP.
    3. Click **Find Node** - this will populate the **MAC Address** and **Ethernet Interface** fields.
    4. Click **Get Build Number** to fetch the current firmware build.
    5. Under **Firmware Image**, click **Browse** and select the `.bin` file provided by Aventics.
    6. Click **Run All Steps** to perform the firmware update automatically.
##### Example Console Output (Successful Update)

```shell
=== 2025-10-20 10:56:25: Pinging 33.7.0.16
Executing ping -n 1 -w 1000 33.7.0.16
Reply from 33.7.0.16: bytes=32 time=3ms TTL=64
...
Transfer successful: 2877648 bytes in 12 second(s), 239804 bytes/s
...
=== 2025-10-20 10:58:46: Getting build number
Build Number: 1.1 Build 45938
====== 2025-10-20 10:58:46: Updating complete
```

#### Solenoid Block Configuration
- The blocks configuration (IP, subnet mask, and Profinet name) is preserved through the course of the update. The block should be good-to-go after the update. 
