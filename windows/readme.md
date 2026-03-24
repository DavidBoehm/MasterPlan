# Windows Toolkit Scripts — Beginner's Guide

Welcome! This folder contains helpful tools for Windows users. You don't need to be a command-line expert—each script is menu-driven and guides you step by step. To use any script, right-click it and choose "Run with PowerShell" (or double-click for .bat files). Most scripts will show a menu and wait for your input.

---

## 📋 Script Index

- [admin_shell.bat](admin_shell.bat):
	- **Purpose:** Instantly open a new PowerShell window as Administrator in the current folder. Use this before running scripts that require admin rights.

- [netkit.ps1](netkit.ps1):
	- **Purpose:** All-in-one network and WSL (Linux) toolkit. Menu options include:
		- Show your IP address, gateway, and DNS
		- List active network connections
		- Flush DNS cache
		- List or shut down WSL distros
		- Test internet, ping sweep your network, scan for Bonjour/mDNS devices
		- View disk space, system uptime, and more
		- SSH launcher, subnet calculator, and other network tools

- [printer_kit.ps1](printer_kit.ps1):
	- **Purpose:** Advanced printer diagnostics and troubleshooting. Menu options include:
		- View printer status, queue, and jobs
		- Restart the print spooler
		- Hard clear stuck print jobs
		- Network probe (ping, port 9100, MAC address)
		- Print a test page

- [reg_kit.ps1](reg_kit.ps1):
	- **Purpose:** Interactive registry tweaks toolkit. Lets you:
		- Safely back up your registry
		- Apply or revert common Windows tweaks (right-click menu, Bing search, menu speed, USB power, auto-end tasks)
		- All changes are menu-driven and reversible

- [toolkit.ps1](toolkit.ps1):
	- **Purpose:** System admin toolkit for common tasks. Menu options include:
		- Check active TCP connections
		- Flush DNS
		- Test open ports
		- List WSL distros, update/shutdown WSL
		- Check firewall, local admins, pending updates
		- Run commands in WSL, check Git status, run Python scripts

---

## 🛠️ How to Use These Scripts

1. **Open as Administrator:** Some scripts need admin rights. Use [admin_shell.bat](admin_shell.bat) to open a PowerShell window as admin.
2. **Run a Script:** Right-click the script and select "Run with PowerShell". For .bat files, double-click.
3. **Follow the Menu:** Each script will show a menu. Type the number or letter for the action you want, then press Enter.
4. **Read the Output:** The script will guide you and show results in color. If you see errors about permissions, try running as admin.

---

## ℹ️ Tips for Beginners

- You can't break your computer with these scripts—they are designed to be safe and reversible.
- If you get stuck, close the PowerShell window and start again.
- Always read the menu and prompts carefully.
- For registry changes, always back up first (the script will prompt you).

---

Enjoy your Windows toolkit! If you have questions, ask your IT support or search for the script name online for more help.
