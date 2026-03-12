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

## 2. Identifying the Locks

If you don’t know the MAC address of the smart locks, try these methods:

* **Check the Hardware:** Look at the back of the lock (under the battery cover) or on the original box for a sticker labeled **MAC** or **ID**.
* **Check the Station List:** If you can't find a physical sticker, look for stations in the bottom `airodump-ng` list that show as `(not associated)`. Keep an eye out for manufacturer names (OUIs) like Yale, August, or Schlage. *(Tip: You can check MAC vendor prefixes online to confirm.)*

---

## 3. The "Targeted" Scan

Once you find the router's **BSSID** and the **channel** it's operating on (e.g., Channel 6), lock `airodump-ng` onto it. This allows you to observe the connection stability continuously, without your Wi-Fi card "hopping" across other channels and missing data.

```bash
sudo airodump-ng -c 6 --bssid [ROUTER_MAC] wlan0mon
```

> **The Diagnosis:** Look at the **"Lost"** column in the station row for the lock. If you see a high "Lost" count, it confirms that data packets are actively being dropped mid-air due to heavy interference or a weak signal.
## 1. How to Read the Airodump-ng Table

The screen will split into two sections. The top section shows Access Points (the office routers), and the bottom section shows "Stations" (client devices, like the smart locks).

### The Top Section (Routers)

| Column | What to look for at the Office |
| :--- | :--- |
| **BSSID** | The MAC address of the dentist's router. Note this down. |
| **PWR** | Signal Strength. Closer to 0 is better. `-40` is great. `-80` or `-90` means the router signal is too weak to reach the locks. |
| **CH** | The channel. If it's on a busy channel (1, 6, or 11) with many other routers, the locks will struggle with interference. |
| **ESSID** | The name of the WiFi network (e.g., "Dentist_Guest" or "Office_Staff"). |

### The Bottom Section (The Locks)

| Column | The Diagnostic |
| :--- | :--- |
| **STATION** | The MAC address of the device. Look for the lock's MAC address here. |
| **PWR** | The signal strength of the lock itself. If the router is `-50` but the lock is `-85`, the lock’s tiny antenna can't "shout" loud enough to be heard by the router. |
| **BSSID** | If this says `(not associated)`, the lock is actively trying to connect but failing. |
| **Probes** | If you see the lock's MAC and a name next to it, the lock is "shouting" for a specific WiFi name that might be misspelled, out of range, or no longer exists. |
