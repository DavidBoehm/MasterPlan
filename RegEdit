# Windows Registry Tweaks & Shortcuts

## 📂 Special Folder Shortcuts (GUIDs)
Create a new folder and name it `Name.{GUID}` to access these features.

| Name | GUID | Description |
| :--- | :--- | :--- |
| **God Mode** | `{ED7BA470-8E54-465E-825C-99712043E01C}` | 200+ settings (Device Manager, Power, etc.) in one list. |
| **All Apps** | `{42aedc87-2188-41fd-b9a3-0c966feabec1}` | Every app on your PC (inc. hidden ones) in a single folder. |
| **Administrative Tools** | `{D20EA4E1-3957-11d2-A40B-0C0020319642}` | Task Scheduler, Event Viewer, Services. |
| **Network Connections** | `{7007ACC7-3202-11D1-AAD2-00805FC1270E}` | Direct access to your Ethernet/Wi-Fi adapters. |
| **Devices & Printers** | `{2227A280-3AEA-1069-A2DE-08002B30309D}` | Essential for checking your Anycubic/Elegoo connections. |

---

## 🚀 Registry Tweaks Features
This script performs the following optimizations:

*   **Restore Classic Right-Click Menu**: Removes "Show more options" in Windows 11.
*   **Disable Bing/Web Search**: Limits Start menu search to local files (3D models, scripts).
*   **Speed up Menus**: Reduces hover delay from `400ms` to `50ms`.
*   **Unlock USB Power Settings**: Exposes "USB Selective Suspend" to prevent 3D printer disconnects.
*   **Auto-End Tasks**: Forces hung applications to close quickly during shutdown.

## 📝 How to Use
1.  Open **Notepad**.
2.  Copy the code block below.
3.  Save the file as `David_Power_Tweaks.reg` (ensure the extension is `.reg`, not `.txt`).
4.  Double-click the file and select **Yes** to confirm.
5.  **Restart your computer** to apply changes.

---

## 💻 Registry Scripts

### Part 1: System Performance & UI
```reg
Windows Registry Editor Version 5.00

; 1. Restore Windows 10 Classic Context Menu (Windows 11 only)
[HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32]
@=""

; 2. Disable Bing/Web Results in Start Menu Search
[HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Explorer]
"DisableSearchBoxSuggestions"=dword:00000001

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
"BingSearchEnabled"=dword:00000000

; 3. Make Menus Snappier (Reduce hover delay to 50ms)
[HKEY_CURRENT_USER\Control Panel\Desktop]
"MenuShowDelay"="50"

; 4. Unlock Hidden "USB Selective Suspend" Attribute in Power Options
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e0332c-9d01-4952-b912-78213f3a28ad]
"Attributes"=dword:00000002

; 5. Force Close Hung Applications on Shutdown
[HKEY_CURRENT_USER\Control Panel\Desktop]
"AutoEndTasks"="1"
"WaitToKillAppTimeout"="2000"
"HungAppTimeout"="2000"
```

### Part 2: Custom Workflow Menu
*Adds a "David's Workflow..." submenu to the right-click context menu.*
> **Note:** Update the file paths below to match your installed applications.

```reg
Windows Registry Editor Version 5.00

; Create the Folder in the Menu
[HKEY_CLASSES_ROOT\*\shell\DavidTools]
"MUIVerb"="David's Workflow..."
"SubCommands"="Slicer;Blender;Notepad"
"Icon"="shell32.dll,21"

; Define the Apps in the CommandStore
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Slicer]
@="Open in Slicer"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Slicer\command]
@="\"C:\\Path\\To\\Your\\Slicer.exe\" \"%1\""

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Blender]
@="Open in Blender"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Blender\command]
@="\"C:\\Program Files\\Blender Foundation\\Blender\\blender.exe\" \"%1\""

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Notepad]
@="Open in Notepad++"
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\Notepad\command]
@="\"C:\\Program Files\\Notepad++\\notepad++.exe\" \"%1\""
```
