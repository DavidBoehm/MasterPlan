# Canon LBP122DW Printer Debug Guide
## ACEMAGIC F2A Mini PC - Windows 11

**Error:** 0x0000000b (Error 11) on both USB and WiFi
**Root Cause:** Print job failing at spooler/driver level, not connection level

---

## Phase 1: Quick Diagnosis (5 minutes)

### 1.1 Check Event Viewer
1. Win + R → `eventvwr`
2. Windows Logs → Application
3. Filter by Source: `Print` or `PrintService`
4. Look for errors around the time of failed print

**What to look for:**
- "The print spooler failed to..."
- "Driver..."
- "Port monitor..."

### 1.2 Test with Simple Text
1. Open Notepad
2. Type: `TEST PRINT`
3. File → Print
4. Select Canon printer

**Result:**
- ✓ Works: Problem is with complex documents (PDF/Word)
- ✗ Fails: Problem is fundamental (driver/spooler)

### 1.3 Check Printer Status
```powershell
# Run as Administrator
Get-Printer | Select-Object Name, PrinterStatus, PrinterState
```

**Expected:** PrinterStatus = Normal

---

## Phase 2: Test with New User Profile (5 minutes)

Before diving deep, quickly rule out user profile corruption.

### 2.1 Create Test User
```powershell
# Run as Administrator
$TestUser = "PrinterTest"
$Password = Read-Host "Enter password for test user" -AsSecureString
New-LocalUser -Name $TestUser -Password $Password -Description "Printer troubleshooting test account"
Add-LocalGroupMember -Group "Users" -Member $TestUser
Write-Host "Test user '$TestUser' created. Log out and log in as this user." -ForegroundColor Green
```

Or manually:
1. Settings → Accounts → Other users → Add account
2. "I don't have this person's sign-in information"
3. "Add a user without a Microsoft account"
4. Username: `PrinterTest`, Password: (create one)
5. Account type: Standard User

### 2.2 Test Print as New User
1. Sign out of current user
2. Sign in as `PrinterTest`
3. Add printer fresh (Settings → Printers → Add)
4. Try printing a test page

**Result:**
- ✓ Works: **Your original user profile is corrupted.** Fix by deleting `HKEY_CURRENT_USER\Printers` registry key in original profile, or migrate to new user.
- ✗ Fails: Problem is system-wide. Continue to Phase 3.

### 2.3 Cleanup
After testing:
```powershell
Remove-LocalUser -Name "PrinterTest" -Confirm:$false
Write-Host "Test user removed" -ForegroundColor Green
```

---

## Phase 3: Nuclear Reset (10 minutes)

### 3.1 Clear Print Spooler
```powershell
# Save as Reset-Spooler.ps1 and run as Admin
Stop-Service Spooler -Force
Get-ChildItem C:\Windows\System32\spool\PRINTERS -Recurse | Remove-Item -Force -Recurse
Start-Service Spooler
Write-Host "Spooler reset complete" -ForegroundColor Green
```

### 2.2 Delete and Re-add Printer
1. Settings → Bluetooth & devices → Printers & scanners
2. Remove Canon LBP122DW
3. Restart computer

---

## Phase 4: USB Connection (15 minutes)

### 4.1 Check USB Negotiation
The ACEMAGIC F2A has USB 3.x ports that may not negotiate with the printer.

**Fix:** Force USB 2.0 via hub
- Connect a USB 2.0 hub between PC and printer
- Or: Try different USB ports (some may be USB 2.0 compatible)

### 4.2 Install via USB (Manual Method)
1. Connect USB cable
2. Settings → Printers → "Add manually"
3. "Add a local printer or network printer"
4. Use existing port: `USB001` (or `USB002` if exists)
5. Manufacturer: Canon
6. Model: Generic PCL6 / Generic Text Only
7. Test print

**Success?** If yes, driver was the issue.

### 4.3 Disable Bidirectional Support
1. Printer Properties → Ports tab
2. **UNCHECK** "Enable bidirectional support"
3. **UNCHECK** "Enable printer pooling"
4. Apply → OK
5. Test print

---

## Phase 5: WiFi Connection (Preferred - 15 minutes)

### 5.1 Get Printer IP Address
On printer LCD:
1. Menu → Network Settings → Wi-Fi → Connection Info
2. Note the IP (e.g., `192.168.1.105`)

### 5.2 Verify Network Connectivity
```powershell
# From the mini PC
ping 192.168.1.105  # Replace with actual IP

# Test port 9100 (raw printing)
telnet 192.168.1.105 9100

# Test port 631 (IPP)
telnet 192.168.1.105 631
```

**Expected:** Port 9100 or 631 should connect (blank screen = success)

### 5.3 Add via TCP/IP (Best Method)
1. Settings → Printers → "Add printer"
2. "The printer that I want isn't listed"
3. "Add a printer using a TCP/IP address"
4. Device type: `TCP/IP Device`
5. Hostname/IP: `192.168.1.105` (your printer IP)
6. Port name: `IP_192.168.1.105` (auto-filled)
7. **UNCHECK** "Query the printer..."
8. Additional port info: `Generic Network Card`
9. Driver: `Generic PCL6` or `HP LaserJet PCL6`

### 5.4 Canon-Specific Driver Install
If generic doesn't work:
1. Download from: `https://www.usa.canon.com/support/lbp122dw`
2. Run `LBP122DW_MFDrivers_W32_W64...exe`
3. Select: "Network connection"
4. Let it auto-detect or enter IP manually

---

## Phase 6: Driver Issues (20 minutes)

### 6.1 Use Generic PCL6 Driver
Canon lasers speak PCL6 - HP's driver often works better than Canon's:
1. Add printer manually
2. Driver: `Generic` → `Generic PCL6 Printer`
3. Or: `HP` → `HP LaserJet PCL 6`

### 6.2 Disable Advanced Features
Printer Properties → Advanced:
- [ ] Enable advanced printing features
- [ ] Spool print documents...
- [ ] Enable bidirectional support
- [x] Print directly to printer (try this)

### 6.3 Change Data Type
1. Printer Properties → Advanced → Print Processor
2. Change from `RAW` to `EMF` or vice versa
3. Test print

---

## Phase 7: Windows 11 Specific Fixes

### 7.1 Disable Windows Protected Print Mode
Settings → Privacy & security → Device access → **Turn OFF** "Windows Protected Print Mode"

### 7.2 Check Print Service
```powershell
# Ensure services are running
Get-Service Spooler, PrintNotify

# Restart if needed
Restart-Service Spooler -Force
```

### 7.3 Disable Printer Extensions
```powershell
# Registry fix for WSD printer issues
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Print\Printers" -Name "DisableWsdPrinterExtension" -Value 1
Restart-Service Spooler
```

---

## Phase 8: Nuclear Option - CUPS on Raspberry Pi

If Windows refuses to cooperate:

### 8.1 Setup Pi as Print Server ($15 solution)
1. Raspberry Pi Zero 2 W with Raspberry Pi OS
2. Connect Canon via USB to Pi
3. Install CUPS:
   ```bash
   sudo apt update
   sudo apt install cups
   sudo usermod -a -G lpadmin pi
   ```
4. Add printer in CUPS web interface (`http://pi.local:631`)
5. Share printer

### 8.2 Connect Windows to Pi
1. Windows → Add printer
2. "The printer I want isn't listed"
3. "Select a shared printer by name"
4. URL: `http://pi.local:631/printers/Canon_LBP122DW`
5. Driver: Generic/Text Only or Generic PCL6

---

## Troubleshooting Checklist

| Step | Status |
|------|--------|
| Event Viewer checked | [ ] |
| Spooler reset | [ ] |
| Printer removed/re-added | [ ] |
| USB 2.0 hub tried | [ ] |
| WiFi IP confirmed | [ ] |
| TCP/IP manual add tried | [ ] |
| Generic PCL6 driver tried | [ ] |
| Bidirectional support disabled | [ ] |
| Print directly to printer tried | [ ] |
| Protected Print Mode disabled | [ ] |

---

## Common Error Codes

| Code | Meaning | Fix |
|------|---------|-----|
| 0x0000000b | Spooler error | Reset spooler, reinstall printer |
| 0x00000006 | Access denied | Run as admin, check permissions |
| 0x00000002 | File not found | Reinstall driver |
| 0x00000bbb | Port error | Change port type |

---

## Working Configuration (Once Found)

**Document here what actually worked:**

- Connection method: [USB / WiFi TCP-IP / WiFi WSD]
- Port type: [USB001 / TCP/IP Port 9100 / WSD]
- Driver: [Generic PCL6 / HP PCL6 / Canon Official]
- Special settings: [bidirectional off / direct printing / etc]

---

## Quick Scripts

### Reset Everything Script
```powershell
#Requires -RunAsAdministrator
Stop-Service Spooler -Force
Remove-Item C:\Windows\System32\spool\PRINTERS\* -Force -Recurse -ErrorAction SilentlyContinue
Get-Printer | Where-Object { $_.Name -like "*Canon*" -or $_.Name -like "*LBP*" } | Remove-Printer -Confirm:$false
Start-Service Spooler
Write-Host "Reset complete. Add printer fresh." -ForegroundColor Green
```

### Test Print Script
```powershell
$Printer = "Canon LBP122DW"
$TestFile = "$env:TEMP\testprint.txt"
"TEST PRINT - $(Get-Date)" | Out-File $TestFile
Start-Process -FilePath "notepad.exe" -ArgumentList "/p `"$TestFile`" `"$Printer`""
```

---

**Last Updated:** 2026-04-15
**Client:** ACEMAGIC F2A + Canon LBP122DW
**Issue:** Error 0x0000000b on USB and WiFi
