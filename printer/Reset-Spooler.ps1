#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Nuclear spooler reset - clears all print jobs and resets print spooler
.DESCRIPTION
    Stops the print spooler service, deletes all stuck print jobs from the
    spool folder, removes printer-related registry corruption, and restarts.
.EXAMPLE
    .\Reset-Spooler.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Red
Write-Host "   NUCLEAR SPOOLER RESET" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Step 1: Stop services
Write-Host "Step 1: Stopping print services..." -ForegroundColor Yellow

$Services = @("Spooler", "PrintNotify")
foreach ($Service in $Services) {
    try {
        $Svc = Get-Service $Service -ErrorAction SilentlyContinue
        if ($Svc -and $Svc.Status -eq "Running") {
            Stop-Service $Service -Force
            Write-Host "  [OK] Stopped $Service" -ForegroundColor Green
        } else {
            Write-Host "  [OK] $Service already stopped" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARN] Could not stop $Service`: $_" -ForegroundColor Yellow
    }
}

# Step 2: Clear spool folder
Write-Host ""
Write-Host "Step 2: Clearing spool folder..." -ForegroundColor Yellow

$SpoolPath = "C:\Windows\System32\spool\PRINTERS"
$TempBackup = "C:\temp\spooler_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if (Test-Path $SpoolPath) {
    # Count files before deletion
    $Files = Get-ChildItem $SpoolPath -Recurse -ErrorAction SilentlyContinue
    Write-Host "  Found $($Files.Count) spooler files" -ForegroundColor Cyan
    
    # Kill any spooler processes that might hold files
    Get-Process *spool* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    # Delete files
    try {
        Remove-Item "$SpoolPath\*" -Force -Recurse -ErrorAction Stop
        Write-Host "  [OK] Cleared spool folder" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Could not clear folder: $_" -ForegroundColor Red
        Write-Host "  Trying force delete..." -ForegroundColor Yellow
        
        # Forceful approach
        cmd /c "del /f /q /s `"$SpoolPath\*`" 2>nul"
        cmd /c "rmdir /s /q `"$SpoolPath`" 2>nul"
        New-Item -ItemType Directory -Path $SpoolPath -Force | Out-Null
        Write-Host "  [OK] Forced clear complete" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] Spool path not found, creating..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $SpoolPath -Force | Out-Null
}

# Step 3: Clear print queue registry entries
Write-Host ""
Write-Host "Step 3: Cleaning registry print queues..." -ForegroundColor Yellow

try {
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers"
    if (Test-Path $RegPath) {
        $Printers = Get-ChildItem $RegPath -ErrorAction SilentlyContinue
        $StuckJobs = 0
        
        foreach ($Printer in $Printers) {
            $JobsPath = "$($Printer.PSPath)\Jobs"
            if (Test-Path $JobsPath) {
                Remove-Item $JobsPath -Recurse -Force -ErrorAction SilentlyContinue
                $StuckJobs++
            }
        }
        Write-Host "  [OK] Cleared $StuckJobs stuck job queues" -ForegroundColor Green
    }
} catch {
    Write-Host "  [WARN] Registry cleanup skipped: $_" -ForegroundColor Yellow
}

# Step 4: Reset permissions on spool folder
Write-Host ""
Write-Host "Step 4: Resetting spool folder permissions..." -ForegroundColor Yellow

try {
    $Acl = Get-Acl $SpoolPath
    $SystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $AdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $SpoolerRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT SERVICE\Spooler", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    
    $Acl.SetAccessRule($SystemRule)
    $Acl.AddAccessRule($AdminRule)
    $Acl.AddAccessRule($SpoolerRule)
    Set-Acl $SpoolPath $Acl -ErrorAction SilentlyContinue
    Write-Host "  [OK] Permissions reset" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Permission reset skipped" -ForegroundColor Yellow
}

# Step 5: Restart services
Write-Host ""
Write-Host "Step 5: Restarting print services..." -ForegroundColor Yellow

foreach ($Service in $Services) {
    try {
        Start-Service $Service
        $Svc = Get-Service $Service
        if ($Svc.Status -eq "Running") {
            Write-Host "  [OK] Started $Service" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] $Service failed to start" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] Could not start $Service`: $_" -ForegroundColor Red
    }
}

# Step 6: Verify
Write-Host ""
Write-Host "Step 6: Verification..." -ForegroundColor Yellow

try {
    $TestPrinter = Get-Printer | Select-Object -First 1
    if ($TestPrinter) {
        Write-Host "  [OK] Found $($TestPrinter.Name) - printers accessible" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] No printers installed yet" -ForegroundColor Cyan
    }
    
    $SpoolerStatus = Get-Service Spooler
    Write-Host "  [OK] Spooler status: $($SpoolerStatus.Status)" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Verification check failed: $_" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   RESET COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Try printing a test page" -ForegroundColor White
Write-Host "  2. If errors persist, reinstall printer drivers" -ForegroundColor White
Write-Host "  3. Check Event Viewer for persistent errors" -ForegroundColor White
Write-Host ""

$Restart = Read-Host "Restart computer now? (Y/N)"
if ($Restart -match '^[Yy]$') {
    Write-Host "Restarting in 5 seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}
