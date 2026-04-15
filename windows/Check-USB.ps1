#Requires -RunAsAdministrator
<#
.SYNOPSIS
    USB port and device diagnostic tool
.DESCRIPTION
    Lists USB controllers, connected devices, port speeds, and checks
    Event Viewer for USB-related errors and device connection issues.
.EXAMPLE
    .\Get-UsbDiagnostics.ps1
    .\Get-UsbDiagnostics.ps1 -HoursBack 24
#>

param(
    [int]$HoursBack = 24
)

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       USB DIAGNOSTIC REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# Section 1: USB Controllers
# ========================================
Write-Host "--- USB CONTROLLERS ---" -ForegroundColor Yellow
Write-Host ""

$Controllers = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -like "*USB*" -and 
    ($_.FriendlyName -like "*Controller*" -or $_.FriendlyName -like "*Root Hub*")
} | Sort-Object FriendlyName

foreach ($Controller in $Controllers) {
    $StatusColor = switch ($Controller.Status) {
        "OK" { "Green" }
        "Error" { "Red" }
        default { "Yellow" }
    }
    
    Write-Host "Device:  $($Controller.FriendlyName)" -ForegroundColor White
    Write-Host "Status:  $($Controller.Status)" -ForegroundColor $StatusColor
    Write-Host "ID:      $($Controller.InstanceId)" -ForegroundColor DarkGray
    Write-Host "---"
}

Write-Host ""

# ========================================
# Section 2: Connected USB Devices
# ========================================
Write-Host "--- CONNECTED USB DEVICES ---" -ForegroundColor Yellow
Write-Host ""

$UsbDevices = Get-PnpDevice | Where-Object { 
    $_.InstanceId -like "USB\*" -and 
    $_.FriendlyName -notlike "*Root Hub*" -and
    $_.FriendlyName -notlike "*Controller*"
} | Sort-Object FriendlyName

if ($UsbDevices.Count -eq 0) {
    Write-Host "No USB devices found or access denied" -ForegroundColor Yellow
} else {
    $DeviceTable = @()
    foreach ($Device in $UsbDevices) {
        $StatusColor = switch ($Device.Status) {
            "OK" { "Green" }
            "Error" { "Red" }
            default { "Gray" }
        }
        
        # Try to get more info
        try {
            $Details = Get-PnpDeviceProperty -InstanceId $Device.InstanceId | Where-Object { 
                $_.KeyName -eq "DEVPKEY_Device_Address" -or 
                $_.KeyName -eq "DEVPKEY_Device_BusReportedDeviceDesc" 
            }
        } catch {
            $Details = $null
        }
        
        Write-Host "Device:  $($Device.FriendlyName)" -ForegroundColor White
        Write-Host "Status:  $($Device.Status)" -ForegroundColor $StatusColor
        Write-Host "ID:      $($Device.InstanceId.Split('\')[1])" -ForegroundColor DarkGray
        Write-Host "---"
        
        $DeviceTable += [PSCustomObject]@{
            Name = $Device.FriendlyName
            Status = $Device.Status
            InstanceID = $Device.InstanceId
        }
    }
}

Write-Host ""

# ========================================
# Section 3: USB Hub Info (Registry)
# ========================================
Write-Host "--- USB PORT INFORMATION ---" -ForegroundColor Yellow
Write-Host ""

try {
    $UsbHubs = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB*" -ErrorAction SilentlyContinue
    $UsbHubs += Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB30*" -ErrorAction SilentlyContinue
    
    if ($UsbHubs) {
        Write-Host "Found $($UsbHubs.Count) USB root hub(s)" -ForegroundColor Green
    }
    
    # Get USB version info from registry
    $UsbDevs = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -ErrorAction SilentlyContinue
    $PrinterUsb = $UsbDevs | Where-Object { $_.GetValue("FriendlyName") -like "*Canon*" -or $_.GetValue("FriendlyName") -like "*Printer*" }
    
    if ($PrinterUsb) {
        Write-Host "Found USB printer registry entries:" -ForegroundColor Cyan
        $PrinterUsb | ForEach-Object {
            Write-Host "  $($_.PSChildName)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "Could not read USB registry: $_" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Section 4: Event Viewer - USB Errors
# ========================================
Write-Host "--- USB EVENT LOG (Last $HoursBack hours) ---" -ForegroundColor Yellow
Write-Host ""

$StartTime = (Get-Date).AddHours(-$HoursBack)
$UsbEvents = @()

# USB events
$LogSources = @(
    @{LogName='Microsoft-Windows-USB-USBHUB/Operational'; Source='*'},
    @{LogName='System'; ProviderName='USBHUB*'},
    @{LogName='System'; ProviderName='USB*'},
    @{LogName='System'; ProviderName='Kernel-PnP'},
    @{LogName='Microsoft-Windows-Kernel-PnP/Operational'; Source='*'}
)

foreach ($Source in $LogSources) {
    try {
        $Filter = @{StartTime=$StartTime}
        if ($Source.LogName) { $Filter['LogName'] = $Source.LogName }
        if ($Source.ProviderName) { $Filter['ProviderName'] = $Source.ProviderName }
        
        $Events = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue
        $UsbEvents += $Events
    } catch {
        # Silently continue
    }
}

# Filter and sort
$UsbEvents = $UsbEvents | Where-Object { 
    $_.Message -like "*USB*" -or 
    $_.Message -like "*device*" -or
    $_.Message -like "*Printer*" -or
    $_.Id -eq 200 -or  # Device install
    $_.Id -eq 201 -or  # Device arrival
    $_.Id -eq 202      # Device removal
} | Sort-Object TimeCreated -Descending | Select-Object -First 20

if ($UsbEvents.Count -eq 0) {
    Write-Host "No USB events found in the last $HoursBack hours" -ForegroundColor Green
} else {
    foreach ($Event in $UsbEvents) {
        $LevelColor = switch ($Event.Level) {
            1 { "Red" }
            2 { "Red" }
            3 { "Yellow" }
            default { "White" }
        }
        
        $ShortMessage = $Event.Message.Split("`n")[0]
        if ($ShortMessage.Length -gt 80) {
            $ShortMessage = $ShortMessage.Substring(0, 77) + "..."
        }
        
        Write-Host "[$($Event.TimeCreated.ToString('yyyy-MM-dd HH:mm'))] " -NoNewline -ForegroundColor Gray
        Write-Host "[$($Event.Id)] " -NoNewline -ForegroundColor Cyan
        Write-Host $ShortMessage -ForegroundColor $LevelColor
    }
}

Write-Host ""

# ========================================
# Section 5: Printer-Specific USB Check
# ========================================
Write-Host "--- PRINTER USB CONNECTION ---" -ForegroundColor Yellow
Write-Host ""

$PrinterUsbDevices = Get-PnpDevice | Where-Object { 
    $_.FriendlyName -like "*Canon*" -or 
    $_.FriendlyName -like "*LBP*" -or
    $_.FriendlyName -like "*Printer*"
}

if ($PrinterUsbDevices) {
    Write-Host "Found printer-related USB devices:" -ForegroundColor Green
    foreach ($PrinterDev in $PrinterUsbDevices) {
        Write-Host "  Name:   $($PrinterDev.FriendlyName)" -ForegroundColor White
        Write-Host "  Status: $($PrinterDev.Status)" -ForegroundColor $(if($PrinterDev.Status -eq "OK"){"Green"}else{"Red"})
        Write-Host "  ID:     $($PrinterDev.InstanceId)" -ForegroundColor DarkGray
        
        # Get location info
        try {
            $Location = Get-PnpDeviceProperty -InstanceId $PrinterDev.InstanceId -KeyName "DEVPKEY_Device_LocationInfo" -ErrorAction SilentlyContinue
            if ($Location) {
                Write-Host "  Port:   $($Location.Data)" -ForegroundColor Gray
            }
        } catch {}
        Write-Host ""
    }
} else {
    Write-Host "No Canon/Printer USB devices detected" -ForegroundColor Yellow
}

Write-Host ""

# ========================================
# Section 6: USB Speed/Port Check
# ========================================
Write-Host "--- USB SPEED CAPABILITIES ---" -ForegroundColor Yellow
Write-Host ""

try {
    $UsbControllers = Get-WmiObject Win32_USBController -ErrorAction SilentlyContinue
    foreach ($Controller in $UsbControllers) {
        Write-Host "Controller: $($Controller.Name)" -ForegroundColor White
        Write-Host "  Status: $($Controller.Status)" -ForegroundColor $(if($Controller.Status -eq "OK"){"Green"}else{"Red"})
        Write-Host ""
    }
} catch {
    Write-Host "Could not query USB controller info" -ForegroundColor Yellow
}

# Check for USB 3.0 specific info
Write-Host "USB 3.0+ Status:" -ForegroundColor Cyan
$Usb3 = Get-PnpDevice | Where-Object { $_.FriendlyName -like "*USB 3.0*" -or $_.FriendlyName -like "*USB3*" -or $_.FriendlyName -like "*xHCI*" }
if ($Usb3) {
    Write-Host "  USB 3.x controllers detected:" -ForegroundColor White
    $Usb3 | ForEach-Object { Write-Host "    - $($_.FriendlyName) [$($_.Status)]" -ForegroundColor $(if($_.Status -eq "OK"){"Green"}else{"Red"}) }
} else {
    Write-Host "  No USB 3.x controllers found (only USB 2.0)" -ForegroundColor Gray
}

Write-Host ""

# ========================================
# Summary & Recommendations
# ========================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "           SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = ($UsbEvents | Where-Object { $_.Level -le 2 }).Count
$WarningCount = ($UsbEvents | Where-Object { $_.Level -eq 3 }).Count

Write-Host "USB Controllers:     $($Controllers.Count)" -ForegroundColor White
Write-Host "USB Devices:         $($UsbDevices.Count)" -ForegroundColor White
Write-Host "USB Errors:          $ErrorCount" -ForegroundColor $(if($ErrorCount -gt 0){"Red"}else{"Green"})
Write-Host "USB Warnings:        $WarningCount" -ForegroundColor $(if($WarningCount -gt 0){"Yellow"}else{"Green"})
Write-Host ""

if ($ErrorCount -gt 0 -or $WarningCount -gt 0) {
    Write-Host "DIAGNOSTIC RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host ""
    
    if ($ErrorCount -gt 0) {
        Write-Host "  [!] USB errors detected" -ForegroundColor Red
        Write-Host "      → Try USB 2.0 hub between PC and printer" -ForegroundColor White
        Write-Host "      → Update USB controller drivers" -ForegroundColor White
    }
    
    $HasUsb3 = ($Controllers | Where-Object { $_.FriendlyName -like "*3.0*" -or $_.FriendlyName -like "*3.1*" -or $_.FriendlyName -like "*3.2*" })
    if ($HasUsb3 -and $PrinterUsbDevices) {
        $PrinterStatus = ($PrinterUsbDevices | Where-Object { $_.Status -ne "OK" })
        if ($PrinterStatus) {
            Write-Host "  [!] Printer on USB 3.0+ port showing issues" -ForegroundColor Red
            Write-Host "      → USB 3.0/3.1/3.2 may not negotiate well with older USB 2.0 printers" -ForegroundColor White
            Write-Host "      → Solution: USB 2.0 hub ($5-10) or use different port" -ForegroundColor White
        }
    }
    
    Write-Host ""
}

Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
