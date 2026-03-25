Based on a standard "cable cutting" transition from Xfinity (Coax/HFC) to a fiber provider like BAM, here is a breakdown of what you will likely encounter and how to manage the cut-over.

### 1. The Physical Handoffs
* **Xfinity:** Look for a **Coaxial cable** coming from a wall plate or exterior box, typically connected to an Arris or Technicolor "Gateway" (modem/router combo).
* **BAM:** Look for an **Optical Network Terminal (ONT)**. This is a small box where the fiber line ends. It will have an Ethernet port (RJ45) that feeds the router.

### 2. Common "Dual Setup" Issues
If both are active but "not working correctly," check for these common conflicts:
* **IP Passthrough/Bridge Mode:** If they are using their own router (like eero, Orbi, or ASUS), both the Xfinity Gateway and the BAM ONT might be trying to act as the primary router. This causes a **Double NAT**, leading to "Connected, No Internet" errors or slow speeds.
* **SSID Conflict:** Both systems might be broadcasting the same Wi-Fi name (SSID). Devices will "stick" to the weaker Xfinity signal even if the BAM fiber is faster.
* **DNS Latency:** If the router is still using Xfinity's DNS servers while connected to BAM's hardware, lookups will be slow or fail.

### 3. Step-by-Step Transition
* **Identify the "Brain":** Determine if the client wants to use BAM’s provided router or their own existing mesh system.
* **The Swap:**
    1.  Power down the Xfinity Gateway.
    2.  Disconnect the Ethernet cable from the Xfinity "WAN" or "LAN 1" port.
    3.  Plug that same Ethernet cable into the **BAM ONT's Ethernet port**.
    4.  Power cycle the router and the ONT.
* **Verification:** Check the router's WAN IP. If it starts with `192.168.x.x`, it’s still getting a private IP from a gateway instead of a public IP from the fiber ONT.

### 4. Cleanup Checklist
* **MoCA Filters:** If they had Xfinity TV, there might be MoCA filters on the lines. If they are moving to pure streaming, these aren't needed but shouldn't hurt.
* **Port Forwarding:** If they have a home server (like **Unraid** or **Home Assistant**), you will need to re-configure any port forwarding or Static IPs on the new BAM interface.
* **Return Gear:** Ensure the client has the Xfinity Gateway, power brick, and any TV boxes set aside for return to avoid "unreturned equipment" fees.
s


**Would you like me to look up the specific administrative login IP or default credentials for the BAM-provided routers?**