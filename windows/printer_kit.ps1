# --- Admin Check ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ ERROR: This script must be run as Administrator." -ForegroundColor Red
    Pause
    Exit
}

# --- Interactive Menu Loop ---
while ($true) {
    Clear-Host
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   🖨️ Advanced Printer Diagnostics    " -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "1. Basic Overview (Status & Queue)" -ForegroundColor Yellow
    Write-Host "2. Detailed Info (Drivers, Default, Share)" -ForegroundColor Yellow
    Write-Host "3. View Active Print Jobs (Detailed)" -ForegroundColor Yellow
    Write-Host "4. Restart Print Spooler Service" -ForegroundColor Yellow
    Write-Host "5. Hard Clear Print Queue (Nuke stuck jobs)" -ForegroundColor Yellow
    Write-Host "6. Network Probe (Ping, Port 9100, MAC)" -ForegroundColor Yellow
    Write-Host "7. Print a Test Page" -ForegroundColor Yellow
    Write-Host "8. Exit" -ForegroundColor Yellow
    Write-Host "-------------------------------------" -ForegroundColor Cyan

    $choice = Read-Host "Select an action (1-8)"

    switch ($choice) {
        "1" {
            Write-Host "`n--- Basic Printer Overview ---" -ForegroundColor Green
            Get-Printer | Select-Object Name, PrinterStatus, JobCount, PortName | Format-Table -AutoSize
            Pause
        }
        "2" {
            Write-Host "`n--- Detailed Printer Information ---" -ForegroundColor Green
            Get-Printer | Select-Object Name, DriverName, PortName, IsDefault, Shared | Format-Table -AutoSize
            Pause
        }
        "3" {
            Write-Host "`n--- Active Print Jobs ---" -ForegroundColor Green
            $printers = Get-Printer | Where-Object JobCount -gt 0
            if ($printers) {
                foreach ($p in $printers) {
                    Write-Host "`nJobs for $($p.Name):" -ForegroundColor Cyan
                    Get-PrintJob -PrinterName $p.Name | Select-Object Id, DocumentName, UserName, JobStatus, Size | Format-Table -AutoSize
                }
            } else {
                Write-Host "✓ No active print jobs found in any queue." -ForegroundColor Green
            }
            Pause
        }
        "4" {
            Write-Host "`nRestarting Print Spooler..." -ForegroundColor Yellow
            Restart-Service -Name Spooler -Force
            Write-Host "✓ Spooler service restarted successfully." -ForegroundColor Green
            Pause
        }
        "5" {
            Write-Host "`nInitiating Hard Clear of Print Queue..." -ForegroundColor Yellow
            Write-Host "Stopping Spooler..." -ForegroundColor DarkGray
            Stop-Service -Name Spooler -Force
            
            Write-Host "Deleting stuck spool files..." -ForegroundColor DarkGray
            Remove-Item -Path "$env:windir\System32\spool\PRINTERS\*.*" -Force -Recurse -ErrorAction SilentlyContinue
            
            Write-Host "Starting Spooler..." -ForegroundColor DarkGray
            Start-Service -Name Spooler
            Write-Host "✓ Print queue completely cleared." -ForegroundColor Green
            Pause
        }
        "6" {
            $ip = Read-Host "`nEnter Printer IP or Hostname"
            if ([string]::IsNullOrWhiteSpace($ip)) { continue }
            
            Write-Host "`n[1/3] Pinging $ip..." -ForegroundColor Cyan
            Test-Connection -ComputerName $ip -Count 3 -ErrorAction SilentlyContinue | Format-Table Address, IPv4Address, ResponseTime
            
            Write-Host "[2/3] Probing Raw Print Port (9100)..." -ForegroundColor Cyan
            $portTest = Test-NetConnection -ComputerName $ip -Port 9100 -InformationLevel Quiet
            if ($portTest) {
                Write-Host "✓ Port 9100 is OPEN (Printer accepting raw jobs)." -ForegroundColor Green
            } else {
                Write-Host "❌ Port 9100 is CLOSED or unreachable." -ForegroundColor Red
            }

            Write-Host "`n[3/3] Checking ARP Cache for MAC Address..." -ForegroundColor Cyan
            $arpResult = arp -a | Select-String $ip
            if ($arpResult) {
                Write-Host $arpResult -ForegroundColor Green
            } else {
                Write-Host "❌ No MAC address found in local ARP cache." -ForegroundColor DarkGray
            }
            Pause
        }
        "7" {
            Write-Host "`n--- Available Printers ---" -ForegroundColor Cyan
            Get-Printer | Select-Object -ExpandProperty Name
            $printerName = Read-Host "`nEnter the EXACT name of the printer"
            
            if (Get-Printer -Name $printerName -ErrorAction SilentlyContinue) {
                Write-Host "Sending test page to '$printerName'..." -ForegroundColor Yellow
                Invoke-CimMethod -ClassName Win32_Printer -MethodName PrintTestPage -Filter "Name='$printerName'" | Out-Null
                Write-Host "✓ Test page sent." -ForegroundColor Green
            } else {
                Write-Host "❌ Printer not found. Check spelling." -ForegroundColor Red
            }
            Pause
        }
        "8" {
            Write-Host "`nExiting toolkit. Goodbye!" -ForegroundColor Cyan
            Break
        }
        Default {
            Write-Host "`n❌ Invalid selection. Try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}