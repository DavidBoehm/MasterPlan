# 🛠️ Smart Lock Network Diagnostics

## 1. Bettercap: Network Monitoring & Reconnaissance

Bettercap is a powerful, flexible tool that allows you to monitor network traffic and diagnose connectivity issues in real-time. 

### What it does (The "Simple" Version)
* **Active Discovery:** Unlike Nmap (which scans once), Bettercap’s `net.probe` constantly "pokes" every IP. If a lock tries to connect and fails, Bettercap will catch it in real-time.
* **Packet Sniffing:** It can "see" the traffic moving through the air. You can watch the lock's handshake process to see if it’s getting "Rejected" or "Timed Out."
* **Man-in-the-Middle (MITM):** It can trick a device into thinking your laptop is the router. This lets you see exactly what the lock is trying to say to the cloud.
* **WiFi Recon:** It maps out every device on a specific frequency, showing you which devices are "shouting" the loudest (e.g., smart TVs or dental computers).

### Essential Bettercap Commands

* **`net.probe on`** — Starts looking for all devices (Active Discovery).
* **`net.show`** — Shows a clean table of every device found.
* **`wifi.recon on`** — Switches your wireless card to "Spy Mode" for WiFi.
* **`net.sniff on`** — Shows you raw network data (like passwords or URLs) in plain text.
* **`ticker on`** — Keeps your terminal screen updated automatically with new events.

---

## 2. Active Diagnostics Scans

### A. The "New Device" Watch
Run this to see if the locks are even attempting to join the network. It actively looks for new devices.

```bash
sudo bettercap -iface wlan0
net.probe on
net.show
```

> **The Diagnosis:** > * If the lock’s MAC address **never appears** in the list, the lock isn't even reaching the router. It’s a physical signal issue (e.g., lead walls, distance).
> * If you see the locks **appear and then immediately disappear**, you have a de-authentication or signal stability issue.

### B. The "Deauth" Scan
Bettercap can tell you if something is actively kicking the locks off the network.

```bash
wifi.recon on
wifi.show
```

> **The Diagnosis:** Look at the "Clients" column. If the lock connects and then immediately receives a "Deauth" packet, the office's router security (like "Client Isolation" or "MAC Filtering") is intentionally blocking it.

---

## 3. Network Capacity & Headcount

### The Nmap Probe
Use Nmap to check the total number of connected devices on the subnet.

```bash
sudo nmap -sn 192.168.1.0/24
```

> **The Diagnosis:** This gives you a "headcount." If you see 40+ devices (TVs, guest phones, dental sensors) on a consumer-grade router, the locks are likely being kicked off because the router's DHCP table is full or it is out of resources.

---

## 4. Environmental & Frequency Troubleshooting

### The 2.4GHz vs. 5GHz Trap
Most smart locks only work on the 2.4GHz frequency band.

* **The Issue:** If the office has a "Mesh" system with a single name (SSID) for both bands, the lock might be trying to connect to 5GHz and failing.
* **The Fix:** Use your Kali laptop to see if the 2.4GHz band is overcrowded or experiencing heavy interference. You can use a tool like `linssid` for this analysis.

## 5. Aircrack-ng Suite: Signal Strength & Handshakes

While famous for cracking, the Aircrack-ng suite is incredible for diagnosing physical layer issues and verifying if a device is even capable of completing a connection.

### The Signal Strength Check (`airodump-ng`)
First, put your wireless card into monitor mode to passively listen to all traffic, then watch the airwaves.

```bash
sudo airmon-ng start wlan0
sudo airodump-ng wlan0mon
```

> **The Diagnosis:** Look at the `PWR` (Power/Signal) column for the lock's MAC address. 
> * **-30 to -60:** Excellent/Good signal.
> * **-70:** Okay, but might experience occasional drops.
> * **-80 to -90:** Terrible signal. If the lock is in this range, it will constantly drop off the network or fail to connect entirely due to physical distance or interference.

### The Handshake Watch
You can monitor a specific channel to see if the lock successfully completes the WPA 4-way handshake with the router.

```bash
sudo airodump-ng -c [channel_number] --bssid [router_mac] wlan0mon
```

> **The Diagnosis:** If you see the lock attempting to connect but it never captures a "WPA handshake" in the top right corner (or the connection loops endlessly), the lock might have the wrong WiFi password or the router is refusing the connection outright.

---

## 6. Wireshark: Deep Packet Inspection

When Bettercap tells you the lock is failing, Wireshark tells you *exactly* which step of the conversation is breaking down.

### Setting Up the Filter
Open Wireshark on your monitor mode interface (`wlan0mon`) and filter strictly for the smart lock's MAC address so you don't get overwhelmed by other traffic.

**Wireshark Display Filter:**
```text
wlan.addr == [Lock_MAC_Address]
```

### What to Look For (The Connection Steps)
Watch the packet types as the lock tries to connect to the router:

1. **Authentication / Association:** Is the lock allowed to talk to the router? 
   > **The Diagnosis:** If you see "Authentication Reject" or "Association Denied," the router has a MAC filter, or the network security type (like WPA3) is incompatible with the lock (which usually requires WPA2).
2. **EAPOL (The Handshake):** This handles the password.
   > **The Diagnosis:** If the EAPOL packets fail or loop, the lock has the wrong WiFi password saved.
3. **DHCP (Getting an IP Address):** > **The Diagnosis:** Look for a `DHCP Discover` packet sent by the lock. If you see the lock asking for an IP but the router never replies with a `DHCP Offer`, the router's IP pool is exhausted, or a VLAN/Subnet issue is blocking it.
4. **DNS (Finding the Cloud):**
   > **The Diagnosis:** If the lock gets an IP but constantly sends DNS requests (e.g., "Where is api.smartlock.com?") and gets no answer, the office firewall is blocking the lock from reaching the outside internet.
