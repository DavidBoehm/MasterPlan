#Requires -RunAsAdministrator
<#
.SYNOPSIS
    USB port and device diagnostic tool with menu options
.DESCRIPTION
    Interactive menu to view USB Event Logs or USB Device diagnostics
.EXAMPLE
    .\Get-UsbDiagnostics.ps1
#>

param(
    [int]$HoursBack = 24
)

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       USB DIAGNOSTIC TOOL" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] USB Event Log Only" -ForegroundColor White
    Write-Host "      View Event Viewer USB errors only" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] USB Devices & Controllers" -ForegroundColor White
    Write-Host "      View connected devices, ports, speeds" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Printer-Specific USB Check" -ForegroundColor White
    Write-Host "      Focus on printer USB connection only" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Full Diagnostic Report" -ForegroundColor White
    Write-Host "      Run everything (event log + devices + summary)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

function Get-EventLogOnly {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       USB EVENT LOG" -ForegroundColor Cyan
    Write-Host "       (Last $HoursBack hours)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $StartTime = (Get-Date).AddHours(-$HoursBack)
    $UsbEvents = @()

    $LogSources = @(
        @{LogName='Microsoft-Windows-USB-USBHUB/Operational'},
        @{LogName='System'; ProviderName='USBHUB*'},
        @{LogName='System'; ProviderName='USB*'},
        @{LogName='System'; ProviderName='Kernel-PnP'},
        @{LogName='Microsoft-Windows-Kernel-PnP/Operational'}
    )

    foreach ($Source in $LogSources) {
        try {
            $Filter = @{StartTime=$StartTime}
            if ($Source.LogName) { $Filter['LogName'] = $Source.LogName }
            if ($Source.ProviderName) { $Filter['ProviderName'] = $Source.ProviderName }
            $Events = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue
            $UsbEvents += $Events
        } catch {}
    }

    $UsbEvents = $UsbEvents | Where-Object { 
        $_.Message -like "*USB*" -or 
        $_.Message -like "*device*" -or
        $_.Message -like "*Printer*" -or
        $_.Id -eq 200 -or $_.Id -eq 201 -or $_.Id -eq 202
    } | Sort-Object TimeCreated -Descending

    if ($UsbEvents.Count -eq 0) {
        Write-Host "No USB events found in the last $HoursBack hours" -ForegroundColor Green
    } else {
        $Errors = $UsbEvents | Where-Object { $_.Level -le 2 }
        $Warnings = $UsbEvents | Where-Object { $_.Level -eq 3 }
        
        Write-Host "Total Events: $($UsbEvents.Count) | Errors: $($Errors.Count) | Warnings: $($Warnings.Count)" -ForegroundColor Cyan
        Write-Host ""

        foreach ($Event in $UsbEvents) {
            $LevelColor = switch ($Event.Level) {
                1 { "Red" }
                2 { "Red" }
                3 { "Yellow" }
                default { "White" }
            }
            
            $ShortMessage = $Event.Message.Split("`n")[0]
            if ($ShortMessage.Length -gt 80) { $ShortMessage = $ShortMessage.Substring(0, 77) + "..." }
            
            Write-Host "[$($Event.TimeCreated.ToString('yyyy-MM-dd HH:mm'))] " -NoNewline -ForegroundColor Gray
            Write-Host "[$($Event.Id)] " -NoNewline -ForegroundColor Cyan
            Write-Host $ShortMessage -ForegroundColor $LevelColor
        }

        if ($Errors.Count -gt 0) {
            Write-Host ""
            Write-Host "[!] USB Errors Detected - Consider USB 2.0 hub workaround" -ForegroundColor Red
        }
    }

    Write-Host ""
    Pause
}

function Get-DevicesOnly {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       USB DEVICES & CONTROLLERS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "--- USB CONTROLLERS ---" -ForegroundColor Yellow
    Write-Host ""

    $Controllers = Get-PnpDevice | Where-Object { 
        $_.FriendlyName -like "*USB*" -and 
        ($_.FriendlyName -like "*Controller*" -or $_.FriendlyName -like "*Root Hub*")
    } | Sort-Object FriendlyName

    foreach ($Controller in $Controllers) {
        $StatusColor = if ($Controller.Status -eq "OK") { "Green" } else { "Red" }
        Write-Host "Controller: $($Controller.FriendlyName)" -ForegroundColor White
        Write-Host "  Status: $($Controller.Status)" -ForegroundColor $StatusColor
        
        # Detect USB version
        if ($Controller.FriendlyName -like "*3.2*") { Write-Host "  Speed: USB 3.2 Gen 2 (10 Gbps)" -ForegroundColor Magenta }
        elseif ($Controller.FriendlyName -like "*3.1*") { Write-Host "  Speed: USB 3.1 (5-10 Gbps)" -ForegroundColor Magenta }
        elseif ($Controller.FriendlyName -like "*3.0*") { Write-Host "  Speed: USB 3.0 (5 Gbps)" -ForegroundColor Magenta }
        elseif ($Controller.FriendlyName -like "*xHCI*") { Write-Host "  Speed: USB 3.x xHCI" -ForegroundColor Magenta }
        else { Write-Host "  Speed: USB 2.0 or lower" -ForegroundColor Green }
        Write-Host ""
    }

    Write-Host "--- CONNECTED USB DEVICES ---" -ForegroundColor Yellow
    Write-Host ""

    $UsbDevices = Get-PnpDevice | Where-Object { 
        $_.InstanceId -like "USB\*" -and 
        $_.FriendlyName -notlike "*Root Hub*" -and
        $_.FriendlyName -notlike "*Controller*"
    } | Sort-Object FriendlyName

    foreach ($Device in $UsbDevices) {
        $StatusColor = if ($Device.Status -eq "OK") { "Green" } else { "Red" }
        Write-Host "Device: $($Device.FriendlyName)" -ForegroundColor White
        Write-Host "  Status: $($Device.Status)" -ForegroundColor $StatusColor
        Write-Host ""
    }

    # Check for USB 3.0
    Write-Host "--- USB VERSION SUMMARY ---" -ForegroundColor Yellow
    $HasUsb3 = $Controllers | Where-Object { 
        $_.FriendlyName -match "3\.[0-2]|xHCI" 
    }
    if ($HasUsb3) {
        Write-Host "[!] USB 3.x controllers detected" -ForegroundColor Yellow
        Write-Host "    May cause issues with USB 2.0 printers" -ForegroundColor Gray
        Write-Host "    Fix: Use USB 2.0 hub between PC and printer" -ForegroundColor Cyan
    } else {
        Write-Host "[OK] Only USB 2.0 controllers found" -ForegroundColor Green
    }

    Write-Host ""
    Pause
}

function Get-PrinterOnly {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       PRINTER USB CHECK" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $PrinterDevices = Get-PnpDevice | Where-Object { 
        $_.FriendlyName -like "*Canon*" -or 
        $_.FriendlyName -like "*LBP*" -or
        $_.FriendlyName -like "*Printer*"
    }

    if ($PrinterDevices) {
        foreach ($Printer in $PrinterDevices) {
            $StatusColor = if ($Printer.Status -eq "OK") { "Green" } else { "Red" }
            
            Write-Host "Printer Found:" -ForegroundColor Cyan
            Write-Host "  Name:   $($Printer.FriendlyName)" -ForegroundColor White
            Write-Host "  Status: $($Printer.Status)" -ForegroundColor $StatusColor
            Write-Host "  ID:     $($Printer.InstanceId.Split('\')[1])" -ForegroundColor DarkGray
            
            try {
                $Location = Get-PnpDeviceProperty -InstanceId $Printer.InstanceId -KeyName "DEVPKEY_Device_LocationInfo" -ErrorAction SilentlyContinue
                if ($Location.Data) {
                    Write-Host "  Port:   $($Location.Data)" -ForegroundColor Gray
                }
            } catch {}
            
            if ($Printer.Status -ne "OK") {
                Write-Host ""
                Write-Host "[!] Printer not ready - try:" -ForegroundColor Red
                Write-Host "    1. USB 2.0 hub" -ForegroundColor White
                Write-Host "    2. Different USB port" -ForegroundColor White
                Write-Host "    3. WiFi instead of USB" -ForegroundColor White
            }
            Write-Host ""
        }
    } else {
        Write-Host "No printer USB devices found" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Printer may be:" -ForegroundColor Gray
        Write-Host "  - Powered off" -ForegroundColor Gray
        Write-Host "  - Connected via WiFi" -ForegroundColor Gray
        Write-Host "  - Using a generic driver" -ForegroundColor Gray
    }

    Write-Host ""
    Pause
}

function Get-FullReport {
    Clear-Host
    Write-Host "Running full diagnostic..." -ForegroundColor Cyan
    Write-Host ""

    # Just run all the other functions
    Get-DevicesOnly
    Get-PrinterOnly
    Get-EventLogOnly
}

# Main Menu Loop
do {
    Show-Menu
    $Choice = Read-Host "Select option"
    
    switch ($Choice) {
        '1' { Get-EventLogOnly }
        '2' { Get-DevicesOnly }
        '3' { Get-PrinterOnly }
        '4' { Get-FullReport }
        'Q' { break }
        'q' { break }
    }
} while ($Choice -notin @('Q', 'q'))

Clear-Host
Write-Host "Done!" -ForegroundColor Cyan
