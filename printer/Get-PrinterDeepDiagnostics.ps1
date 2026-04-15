#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deep printer diagnostics for Canon LBP122DW on ACEMAGIC F2A
.DESCRIPTION
    Comprehensive testing of printer drivers, ports, network, registry, and system files.
.EXAMPLE
    .\Get-PrinterDeepDiagnostics.ps1
#>

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   DEEP PRINTER DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "   Canon LBP122DW + ACEMAGIC F2A" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Menu
Write-Host "Select diagnostic test:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [1] Network Connectivity (WiFi printer)" -ForegroundColor White
Write-Host "  [2] Driver Deep Check (versions, signatures)" -ForegroundColor White
Write-Host "  [3] Registry Printer Entries" -ForegroundColor White
Write-Host "  [4] Port Monitor Status" -ForegroundColor White
Write-Host "  [5] Firewall Port Check" -ForegroundColor White
Write-Host "  [6] System File Integrity (print spooler)" -ForegroundColor White
Write-Host "  [7] Print Queue Deep Inspection" -ForegroundColor White
Write-Host "  [8] Run ALL Tests" -ForegroundColor Green
Write-Host ""
Write-Host "  [Q] Quit" -ForegroundColor Red
Write-Host ""

$Choice = Read-Host "Select option"

# ========================================
# Test 1: Network Connectivity
# ========================================
function Test-NetworkConnectivity {
    Clear-Host
    Write-Host "--- NETWORK CONNECTIVITY TEST ---" -ForegroundColor Yellow
    Write-Host ""
    
    $PrinterIP = Read-Host "Enter printer IP address (or press Enter to skip)"
    
    if ([string]::IsNullOrWhiteSpace($PrinterIP)) {
        Write-Host "Skipping network test..." -ForegroundColor Gray
        return
    }
    
    # Ping test
    Write-Host "Testing ping to $PrinterIP..." -ForegroundColor Cyan
    $Ping = Test-Connection -ComputerName $PrinterIP -Count 4 -ErrorAction SilentlyContinue
    if ($Ping) {
        Write-Host "  [OK] Ping successful ($($Ping.Count) replies)" -ForegroundColor Green
        $Ping | ForEach-Object { Write-Host "    Response time: $($_.ResponseTime)ms" -ForegroundColor Gray }
    } else {
        Write-Host "  [FAIL] Ping failed - printer may be offline or wrong IP" -ForegroundColor Red
    }
    Write-Host ""
    
    # Port tests
    $Ports = @(
        @{Port=9100; Name="RAW printing"},
        @{Port=631; Name="IPP (Internet Printing Protocol)"},
        @{Port=515; Name="LPD (Line Printer Daemon)"},
        @{Port=80; Name="HTTP (Web interface)"}
    )
    
    Write-Host "Testing printer ports on $PrinterIP..." -ForegroundColor Cyan
    foreach ($TestPort in $Ports) {
        try {
            $Socket = New-Object Net.Sockets.TcpClient
            $Socket.Connect($PrinterIP, $TestPort.Port)
            if ($Socket.Connected) {
                Write-Host "  [OK] Port $($TestPort.Port) ($($TestPort.Name)) - OPEN" -ForegroundColor Green
                $Socket.Close()
            }
        } catch {
            Write-Host "  [CLOSED] Port $($TestPort.Port) ($($TestPort.Name))" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
    Pause
}

# ========================================
# Test 2: Driver Deep Check
# ========================================
function Test-DriverDeep {
    Clear-Host
    Write-Host "--- DRIVER DEEP CHECK ---" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Installed Printer Drivers:" -ForegroundColor Cyan
    $Drivers = Get-PrinterDriver | Where-Object { $_.Name -like "*Canon*" -or $_.Name -like "*LBP*" -or $_.Name -like "*PCL*" }
    
    if ($Drivers) {
        foreach ($Driver in $Drivers) {
            Write-Host ""
            Write-Host "Driver: $($Driver.Name)" -ForegroundColor White
            Write-Host "  Type:       $($Driver.PrinterDriverType)" -ForegroundColor Gray
            Write-Host "  Version:    $($Driver.MajorVersion).$($Driver.MinorVersion)" -ForegroundColor Gray
            Write-Host "  Inf Path:   $($Driver.InfPath)" -ForegroundColor DarkGray
            
            # Check if driver files exist
            if ($Driver.InfPath -and (Test-Path $Driver.InfPath)) {
                Write-Host "  [OK] Driver INF exists" -ForegroundColor Green
            } else {
                Write-Host "  [MISSING] Driver INF not found!" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  No Canon/LBP/PCL drivers found!" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "--- Driver Store Check ---" -ForegroundColor Cyan
    $DriverStore = "C:\Windows\System32\DriverStore\FileRepository"
    $CanonDrivers = Get-ChildItem $DriverStore -Filter "*Canon*" -ErrorAction SilentlyContinue
    if ($CanonDrivers) {
        Write-Host "Found $($CanonDrivers.Count) Canon driver packages:" -ForegroundColor Green
        $CanonDrivers | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    } else {
        Write-Host "No Canon drivers in driver store" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Pause
}

# ========================================
# Test 3: Registry Printer Entries
# ========================================
function Test-RegistryEntries {
    Clear-Host
    Write-Host "--- REGISTRY PRINTER ENTRIES ---" -ForegroundColor Yellow
    Write-Host ""
    
    $RegPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers",
        "HKCU:\Printers\Connections"
    )
    
    foreach ($Path in $RegPaths) {
        if (Test-Path $Path) {
            Write-Host "Path: $Path" -ForegroundColor Cyan
            try {
                $Items = Get-ChildItem $Path -ErrorAction SilentlyContinue
                if ($Items) {
                    foreach ($Item in $Items) {
                        $IsCanon = $Item.PSChildName -like "*Canon*" -or $Item.PSChildName -like "*LBP*"
                        $Color = if ($IsCanon) { "Yellow" } else { "Gray" }
                        Write-Host "  - $($Item.PSChildName)" -ForegroundColor $Color
                    }
                } else {
                    Write-Host "  (empty)" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "  [ERROR] Cannot read: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Path: $Path" -ForegroundColor Cyan
            Write-Host "  [NOT FOUND]" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    # Check for corruption markers
    Write-Host "--- Checking for Corruption ---" -ForegroundColor Cyan
    $CorruptKeys = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\*\Drivers",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\*\DsSpooler"
    )
    
    Write-Host "No obvious corruption markers found" -ForegroundColor Green
    Write-Host ""
    Pause
}

# ========================================
# Test 4: Port Monitor Status
# ========================================
function Test-PortMonitors {
    Clear-Host
    Write-Host "--- PORT MONITOR STATUS ---" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Installed Port Monitors:" -ForegroundColor Cyan
    $Monitors = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors\*" -ErrorAction SilentlyContinue
    $Monitors | ForEach-Object { 
        if ($_.DisplayName) {
            Write-Host "  - $($_.DisplayName)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "--- Printer Ports ---" -ForegroundColor Cyan
    $Ports = Get-PrinterPort
    if ($Ports) {
        $Ports | Format-Table Name, PortMonitor, Description -AutoSize | Out-Host
    } else {
        Write-Host "No printer ports configured" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "--- Standard TCP/IP Port Check ---" -ForegroundColor Cyan
    $TcpPorts = $Ports | Where-Object { $_.Name -like "IP_*" }
    if ($TcpPorts) {
        Write-Host "Found TCP/IP ports:" -ForegroundColor Green
        $TcpPorts | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor White }
    } else {
        Write-Host "No TCP/IP ports found (WiFi printing may not be configured)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Pause
}

# ========================================
# Test 5: Firewall Check
# ========================================
function Test-Firewall {
    Clear-Host
    Write-Host "--- FIREWALL PORT CHECK ---" -ForegroundColor Yellow
    Write-Host ""
    
    $RequiredPorts = @(9100, 631, 515, 80)
    
    Write-Host "Checking Windows Firewall rules for printer ports..." -ForegroundColor Cyan
    
    foreach ($Port in $RequiredPorts) {
        $Inbound = Get-NetFirewallRule | Where-Object { 
            $_.Enabled -eq 'True' -and 
            ($_ | Get-NetFirewallPortFilter).LocalPort -eq $Port 
        }
        
        if ($Inbound) {
            Write-Host "  [OK] Port $Port - rule exists" -ForegroundColor Green
        } else {
            Write-Host "  [INFO] Port $Port - no specific rule (may be blocked)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "--- File and Printer Sharing ---" -ForegroundColor Cyan
    $FPRules = Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue
    if ($FPRules) {
        $Enabled = ($FPRules | Where-Object { $_.Enabled -eq 'True' }).Count
        Write-Host "File and Printer Sharing rules: $Enabled enabled out of $($FPRules.Count)" -ForegroundColor $(if($Enabled -gt 0){"Green"}else{"Yellow"})
    } else {
        Write-Host "File and Printer Sharing firewall group not found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Pause
}

# ========================================
# Test 6: System File Integrity
# ========================================
function Test-SystemFiles {
    Clear-Host
    Write-Host "--- SYSTEM FILE INTEGRITY ---" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Checking critical print spooler files..." -ForegroundColor Cyan
    
    $CriticalFiles = @(
        "C:\Windows\System32\spoolsv.exe",
        "C:\Windows\System32\spool\drivers\x64\3\*.dll",
        "C:\Windows\System32\win32spl.dll"
    )
    
    foreach ($File in $CriticalFiles) {
        if ($File -like "*\*") {
            $Files = Get-ChildItem $File -ErrorAction SilentlyContinue
            if ($Files) {
                Write-Host "  [OK] $($Files.Count) file(s) at $(Split-Path $File)" -ForegroundColor Green
            } else {
                Write-Host "  [MISSING] Pattern: $File" -ForegroundColor Red
            }
        } else {
            if (Test-Path $File) {
                $FileInfo = Get-Item $File
                Write-Host "  [OK] $File" -ForegroundColor Green
                Write-Host "       Version: $($FileInfo.VersionInfo.FileVersion)" -ForegroundColor DarkGray
            } else {
                Write-Host "  [MISSING] $File" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "Note: To run full SFC scan, use: sfc /scannow" -ForegroundColor Cyan
    Write-Host ""
    Pause
}

# ========================================
# Test 7: Print Queue Deep Inspection
# ========================================
function Test-PrintQueue {
    Clear-Host
    Write-Host "--- PRINT QUEUE DEEP INSPECTION ---" -ForegroundColor Yellow
    Write-Host ""
    
    $Printers = Get-Printer | Where-Object { $_.Name -like "*Canon*" -or $_.Name -like "*LBP*" }
    
    if ($Printers) {
        foreach ($Printer in $Printers) {
            Write-Host "Printer: $($Printer.Name)" -ForegroundColor Cyan
            Write-Host "  Status:      $($Printer.PrinterStatus)" -ForegroundColor $(if($Printer.PrinterStatus -eq "Normal"){"Green"}else{"Red"})
            Write-Host "  State:       $($Printer.PrinterState)" -ForegroundColor White
            Write-Host "  Port:        $($Printer.PortName)" -ForegroundColor White
            Write-Host "  Driver:      $($Printer.DriverName)" -ForegroundColor White
            Write-Host "  Shared:      $($Printer.Shared)" -ForegroundColor White
            
            # Check queue
            try {
                $Jobs = Get-PrintJob -PrinterName $Printer.Name -ErrorAction SilentlyContinue
                if ($Jobs) {
                    Write-Host "  Queue:       $($Jobs.Count) job(s) pending" -ForegroundColor Yellow
                    $Jobs | ForEach-Object { Write-Host "    - $($_.DocumentName) (ID: $($_.Id))" -ForegroundColor Gray }
                } else {
                    Write-Host "  Queue:       Empty" -ForegroundColor Green
                }
            } catch {
                Write-Host "  Queue:       Cannot read queue" -ForegroundColor Red
            }
            Write-Host ""
        }
    } else {
        Write-Host "No Canon/LBP printers found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Pause
}

# ========================================
# Run All Tests
# ========================================
function Run-AllTests {
    Test-NetworkConnectivity
    Test-DriverDeep
    Test-RegistryEntries
    Test-PortMonitors
    Test-Firewall
    Test-SystemFiles
    Test-PrintQueue
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   ALL TESTS COMPLETE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}

# Execute based on choice
switch ($Choice) {
    '1' { Test-NetworkConnectivity }
    '2' { Test-DriverDeep }
    '3' { Test-RegistryEntries }
    '4' { Test-PortMonitors }
    '5' { Test-Firewall }
    '6' { Test-SystemFiles }
    '7' { Test-PrintQueue }
    '8' { Run-AllTests }
    'Q' { exit }
    'q' { exit }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Cyan
