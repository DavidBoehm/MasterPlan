# 🐧 Linux Systems, Security & Hierarchy: The Definitive Guide

This guide is designed for developers transitioning to **WSL** and **Ubuntu**, focusing on system structure, safety, and the "under-the-hood" mechanics of the Linux environment.

---

## 📂 1. The Filesystem Hierarchy Standard (FHS)
In Linux, everything starts at **root (`/`)**. Unlike Windows, there are no drive letters; external drives and partitions are "mounted" into folders within this single tree.

| Directory | Purpose | Analogy |
| :--- | :--- | :--- |
| **`/bin`** | Essential **bin**aries (commands) like `ls`, `cp`, and `bash`. | The Toolbox |
| **`/boot`** | Files needed to start the system (The Linux Kernel). | The Ignition |
| **`/dev`** | **Dev**ice files (Hardware represented as files). | The Hardware Map |
| **`/etc`** | System-wide **etc**etera (Configuration files). | The Control Panel |
| **`/home`** | Personal folders for users (e.g., `/home/david`). | My Documents |
| **`/lib`** | Essential **lib**raries (Shared code needed by `/bin`). | The DLLs |
| **`/mnt`** | **M**ou**nt** points for filesystems (WSL puts Windows `C:` here). | Plugged-in Drives |
| **`/opt`** | **Opt**ional software (Add-on apps like Google Chrome). | Program Files |
| **`/root`** | The home directory for the root user (Superuser). | The Vault |
| **`/tmp`** | **Tmp**orary files (Usually wiped on every reboot). | The Scratchpad |
| **`/usr`** | **U**ser **S**ystem **R**esources (Where 90% of user apps live). | The City Library |
| **`/var`** | **Var**iable files (Logs, spool files, and databases). | The Records Room |



---

## 🔐 2. Security Best Practices
Security in Linux is built on the **Principle of Least Privilege**.

* **The `sudo` Rule:** Never log in directly as `root`. Use `sudo` (SuperUser DO) for administrative tasks. This creates an audit log and prevents accidental "fat-finger" deletions of system files.
* **Permissions Logic:**
    * **Directories:** Standard is `755` (`drwxr-xr-x`). This allows the owner to edit, and everyone else to enter and view.
    * **Files:** Standard is `644` (`-rw-r--r--`). This allows the owner to edit, and everyone else to only read.
* **SSH Hygiene:** If you use SSH to access your WSL from another machine, disable password-based login in `/etc/ssh/sshd_config` and use **SSH Keys** (Ed25519 is recommended).
* **Package Audits:** Periodically run `sudo apt update && sudo apt list --upgradable` to ensure security patches are applied to your binaries.

---

## 🔗 3. Baseline Symlinks (System Links)
A Symbolic Link (Symlink) is a file that points to another file. Ubuntu uses these to maintain backward compatibility and simplify the structure.

* **The "UsrMerge":** In modern Ubuntu, `/bin`, `/lib`, and `/sbin` are actually symlinks pointing to their counterparts inside `/usr/`. 
    * *Check it yourself:* `ls -ld /bin`
* **`/etc/localtime`:** A symlink to a file in `/usr/share/zoneinfo/`. Changing your timezone simply means repointing this link.
* **Standard Streams:** Linux treats input and output as files:
    * `/dev/stdin` → Points to your keyboard input.
    * `/dev/stdout` → Points to your terminal screen.



---

## ⚙️ 4. Core Environment Variables
Environment variables are dynamic values that affect the behavior of processes. You can see yours by running `printenv`.

| Variable | Description |
| :--- | :--- |
| **`$PATH`** | The most critical variable. A list of directories the shell searches for commands. |
| **`$HOME`** | The path to your current user's home (usually `/home/david`). |
| **`$USER`** | Your current login name. |
| **`$SHELL`** | Which shell you are using (e.g., `/usr/bin/zsh` or `/bin/bash`). |
| **`$PWD`** | Your current directory (changes every time you `cd`). |

### How to modify permanently:
To add a folder (like your 3D printing scripts) to your path:
1.  Open your config: `nano ~/.bashrc`
2.  Add to the bottom: `export PATH=$PATH:/home/david/scripts`
3.  Apply changes: `source ~/.bashrc`

---

## 🚀 5. Workflow Best Practices
* **Case Sensitivity:** Remember that Linux sees `MyProject` and `myproject` as two different things. Pick a naming convention (like `kebab-case`) and stick to it.
* **Avoid Spaces:** Spaces in filenames (e.g., `My File.txt`) are a headache in Linux. Use underscores or dashes (`my_file.txt`).
* **Dotfiles:** Files starting with a `.` (like `.bashrc`) are hidden. Use `ls -a` to see them. This is where all your tool configurations live.
* **Stay Local:** When working in WSL, keep your files in the Linux filesystem (`/home/david/`) rather than the Windows mount (`/mnt/c/`) for much faster performance—especially for Git and Node.js projects.