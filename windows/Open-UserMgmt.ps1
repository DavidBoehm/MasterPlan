#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 User Management Console Launcher
.DESCRIPTION
    Interactive menu to open Windows management snap-ins (.msc files)
    for user account and security management.
.EXAMPLE
    .\Open-UserMgmt.ps1
#>

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   WINDOWS 11 USER MANAGEMENT TOOLS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Local Users and Groups    (lusrmgr.msc)" -ForegroundColor White
    Write-Host "      Manage users, groups, passwords" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Computer Management       (compmgmt.msc)" -ForegroundColor White
    Write-Host "      Users, groups, shares, device manager" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Local Security Policy     (secpol.msc)" -ForegroundColor White
    Write-Host "      Password policies, lockout, audit settings" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Group Policy Editor       (gpedit.msc)" -ForegroundColor White
    Write-Host "      User rights, restrictions, advanced config" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [5] User Accounts           (netplwiz)" -ForegroundColor White
    Write-Host "      Login settings, auto-login config" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [6] Advanced User Accounts    (control userpasswords2)" -ForegroundColor White
    Write-Host "      Legacy user management dialog" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [A] Open ALL consoles" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
}

function Open-MscFile {
    param(
        [string]$Name,
        [string]$Command
    )
    Write-Host ""
    Write-Host "Opening $Name..." -ForegroundColor Green
    try {
        Start-Process $Command
        Write-Host "Launched successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        '1' { Open-MscFile "Local Users and Groups" "lusrmgr.msc" }
        '2' { Open-MscFile "Computer Management" "compmgmt.msc" }
        '3' { Open-MscFile "Local Security Policy" "secpol.msc" }
        '4' { Open-MscFile "Group Policy Editor" "gpedit.msc" }
        '5' { Open-MscFile "User Accounts" "netplwiz" }
        '6' { 
            Write-Host ""
            Write-Host "Opening Advanced User Accounts..." -ForegroundColor Green
            Start-Process "control" -ArgumentList "userpasswords2"
            Start-Sleep -Seconds 1
        }
        'A' {
            Write-Host ""
            Write-Host "Opening all consoles..." -ForegroundColor Yellow
            Start-Process "lusrmgr.msc"
            Start-Sleep -Milliseconds 300
            Start-Process "secpol.msc"
            Start-Sleep -Milliseconds 300
            Start-Process "gpedit.msc"
            Start-Sleep -Milliseconds 300
            Start-Process "compmgmt.msc"
            Write-Host "All consoles launched!" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        'a' {
            Write-Host ""
            Write-Host "Opening all consoles..." -ForegroundColor Yellow
            Start-Process "lusrmgr.msc"
            Start-Sleep -Milliseconds 300
            Start-Process "secpol.msc"
            Start-Sleep -Milliseconds 300
            Start-Process "gpedit.msc"
            Start-Sleep -Milliseconds 300
            Start-Process "compmgmt.msc"
            Write-Host "All consoles launched!" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        'Q' { break }
        'q' { break }
        default {
            if ($choice -ne '') {
                Write-Host "Invalid option!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
} while ($choice -notin @('Q', 'q'))

Clear-Host
Write-Host "Done!" -ForegroundColor Cyan
