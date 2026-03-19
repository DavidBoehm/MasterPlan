# 💾 Unraid Master Reference Guide

## ⌨️ Kernel Emergency Keys (Magic SysRq)
Use these when the Unraid WebGUI and SSH become completely unresponsive. This safely syncs disks and prevents parity corruption before rebooting. 
* **Execution:** Hold **`Alt`** + **`PrintScreen`** (SysRq), then press the following sequence of keys slowly (wait 2-3 seconds between each).
* **Mnemonic:** **R**aising **E**lephants **I**s **S**o **U**tterly **B**oring

* **`R`** - **R**ecover keyboard from X server (unRaw).
* **`E`** - T**e**rminate all processes (SIGTERM). Allows graceful shutdown of containers/VMs.
* **`I`** - K**i**ll remaining processes (SIGKILL).
* **`S`** - **S**ync data to disk. (Crucial for Unraid to avoid parity checks).
* **`U`** - **U**nmount filesystems (remounts as Read-Only).
* **`B`** - Re**b**oot system.

## 🛠️ Common CLI Commands

**System & Logs**
* `diagnostics` - Generates a zip of all system logs to the `/boot/logs` directory.
* `tail -f /var/log/syslog` - Live view of the main system log.
* `watch smbstatus` - Live view of active SMB connections and locked files.
* `powerdown` - Safely stops the array and shuts down the server.

**Array & Storage**
* `mover` - Manually triggers the Mover operation.
* `mover stop` - Halts an active Mover operation.
* `btrfs scrub start -B /mnt/cache` - Force a scrub on a BTRFS cache pool.
* `xfs_repair -v /dev/mdX` - Run XFS repair on a specific array disk (replace X with disk number).

**Docker Management**
* `docker ps` - List running containers.
* `docker stats` - Live CPU/RAM usage per container.
* `docker system prune -a` - Clean up unused images, containers, and networks.

## 🚀 Optimization Strategies

**Enable Turbo Write (Reconstruct Write)**
* **Effect:** Significantly increases array write speeds by keeping all disks spinning during writes, avoiding the read-modify-write penalty.
* **Path:** **Settings** > **Disk Settings** > **Tunable (md_write_method)** -> Select **`reconstruct write`**.

**CPU Pinning & Isolation**
* **Effect:** Prevents Unraid OS and general Docker containers from fighting for CPU cycles with high-priority VMs or heavy containers.
* **Path:** **Settings** > **CPU Pinning**.
* **Rule:** Leave Core 0 (and its hyperthreaded pair) for the Unraid OS. Pin specific containers to other dedicated cores.

**Appdata Cache Exclusivity**
* **Effect:** Prevents Docker containers from locking up or waking spinning drives.
* **Path:** **Shares** > **appdata** > **Primary Storage: Cache** -> **Secondary Storage: None**.

## 💡 Essential Tips & Tricks

* **Fix Common Permissions:** Use **Tools** > **New Permissions** if Docker containers or SMB users suddenly cannot write to specific folders.
* **Install "CA Auto Update Applications":** Automates Docker container updates on a schedule.
* **Install "Mover Tuning":** A plugin that prevents the mover from running if the parity check is running, or only moves files based on age/cache capacity.
* **Install "Dynamix Cache Directories":** Keeps directory structures in RAM. Prevents spinning up hard drives just to browse folder contents over SMB.
* **Flash Drive Backup:** Click on **Main** -> **Boot Device (Flash)** -> **Flash Backup**. Do this before any OS upgrade.