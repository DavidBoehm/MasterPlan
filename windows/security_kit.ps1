<#
.SYNOPSIS
    Security & Malware Toolkit - Portable Security Tools Launcher
    Downloads and runs Microsoft Safety Scanner, Autoruns, and TCPView
#>

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
$ToolsDir = "$env:TEMP\MasterPlan_SecurityTools"
$LogDir = "$env:USERPROFILE\Documents\MasterPlan_Logs"

# Ensure directories exist
if (!(Test-Path $ToolsDir)) { New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null }
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# Tool definitions
$Tools = @{
    "SafetyScanner" = @{
        Name = "Microsoft Safety Scanner"
        Url = "https://go.microsoft.com/fwlink/?LinkId=212732"
        FileName = "MSERT.exe"
        Description = "Quick offline malware scan (expires after 10 days)"
        Args = "/Q /F:Y"  # Quiet mode, auto-clean
    }
    "Autoruns" = @{
        Name = "Autoruns (Sysinternals)"
        Url = "https://download.sysinternals.com/files/Autoruns.zip"
        FileName = "Autoruns64.exe"
        ZipName = "Autoruns.zip"
        Description = "View and manage startup programs, services, drivers"
        Args = ""
    }
    "TCPView" = @{
        Name = "TCPView (Sysinternals)"
        Url = "https://download.sysinternals.com/files/TCPView.zip"
        FileName = "tcpview64.exe"
        ZipName = "TCPView.zip"
        Description = "Real-time network connection viewer"
        Args = ""
    }
}

# ---------------------------------------------------------
# FUNCTIONS
# ---------------------------------------------------------

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    $LogFile = "$LogDir\security_kit.log"
    Add-Content -Path $LogFile -Value $LogEntry
    
    switch ($Level) {
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "ERROR"   { Write-Host $Message -ForegroundColor Red }
        default   { Write-Host $Message -ForegroundColor White }
    }
}

function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ToolStatus {
    param([string]$ToolKey)
    $tool = $Tools[$ToolKey]
    $toolPath = Join-Path $ToolsDir $tool.FileName
    $exists = Test-Path $toolPath
    $size = if ($exists) { (Get-Item $toolPath).Length / 1MB } else { 0 }
    
    return @{
        Exists = $exists
        Path = $toolPath
        SizeMB = [math]::Round($size, 2)
    }
}

function Install-SafetyScanner {
    Write-Log "Downloading Microsoft Safety Scanner..." -Level "INFO"
    $destination = Join-Path $ToolsDir $Tools["SafetyScanner"].FileName
    
    try {
        Invoke-WebRequest -Uri $Tools["SafetyScanner"].Url -OutFile $destination -UseBasicParsing
        Write-Log "Safety Scanner downloaded successfully ($([math]::Round((Get-Item $destination).Length/1MB, 2)) MB)" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to download Safety Scanner: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Install-SysinternalsTool {
    param([string]$ToolKey)
    $tool = $Tools[$ToolKey]
    $zipPath = Join-Path $ToolsDir $tool.ZipName
    $extractPath = Join-Path $ToolsDir $ToolKey
    
    Write-Log "Downloading $($tool.Name)..." -Level "INFO"
    
    try {
        Invoke-WebRequest -Uri $tool.Url -OutFile $zipPath -UseBasicParsing
        
        # Extract
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Move exe to main tools dir
        $exeSource = Join-Path $extractPath $tool.FileName
        $exeDest = Join-Path $ToolsDir $tool.FileName
        if (Test-Path $exeSource) {
            Copy-Item $exeSource $exeDest -Force
            Write-Log "$($tool.Name) installed successfully" -Level "SUCCESS"
        }
        
        # Cleanup
        Remove-Item $zipPath -Force
        Remove-Item $extractPath -Recurse -Force
        
        return $true
    }
    catch {
        Write-Log "Failed to install $($tool.Name): $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Start-SafetyScanner {
    $status = Get-ToolStatus "SafetyScanner"
    
    if (!$status.Exists) {
        Write-Log "Safety Scanner not found. Installing first..." -Level "WARNING"
        if (!(Install-SafetyScanner)) { return }
        $status = Get-ToolStatus "SafetyScanner"
    }
    
    Write-Log "Starting Microsoft Safety Scanner..." -Level "INFO"
    Write-Log "Scan types: Quick (default), Full, or Custom" -Level "INFO"
    Write-Log "Note: This tool expires after 10 days and must be re-downloaded" -Level "WARNING"
    
    $scanType = Read-Host "`nSelect scan type [Q]uick, [F]ull, or [C]ustom (default: Quick)"
    
    switch ($scanType.ToUpper()) {
        "F" { $args = "/F /F:Y" }
        "C" { 
            $path = Read-Host "Enter path to scan"
            $args = "/SCANFILE:`"$path`" /F:Y"
        }
        default { $args = "/Q /F:Y" }  # Quick scan
    }
    
    $logFile = "$LogDir\MSERT_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    Write-Log "Launching Safety Scanner with log: $logFile" -Level "INFO"
    Start-Process -FilePath $status.Path -ArgumentList "$args /LOG:`"$logFile`"" -Wait
    
    Write-Log "Safety Scanner completed. Check log: $logFile" -Level "SUCCESS"
    
    if (Test-Path $logFile) {
        $result = Get-Content $logFile -Raw
        if ($result -match "Threat|Infected|Malware|Found") {
            Write-Log "⚠️ THREATS DETECTED - Review the log immediately!" -Level "ERROR"
        }
        else {
            Write-Log "✓ No threats detected" -Level "SUCCESS"
        }
    }
}

function Start-Autoruns {
    $status = Get-ToolStatus "Autoruns"
    
    if (!$status.Exists) {
        Write-Log "Autoruns not found. Installing first..." -Level "WARNING"
        if (!(Install-SysinternalsTool "Autoruns")) { return }
        $status = Get-ToolStatus "Autoruns"
    }
    
    Write-Log "Starting Autoruns..." -Level "INFO"
    Write-Log "Tips: Red entries = no publisher, Yellow = other user, Pink = disabled" -Level "INFO"
    Write-Log "Save a baseline with File > Save, compare later with File > Compare" -Level "INFO"
    
    # Launch with elevated rights if possible
    if (Test-Admin) {
        Start-Process $status.Path
    } else {
        Write-Log "Launching without admin (some entries may be hidden). Run as admin for full scan." -Level "WARNING"
        Start-Process $status.Path
    }
}

function Start-TCPView {
    $status = Get-ToolStatus "TCPView"
    
    if (!$status.Exists) {
        Write-Log "TCPView not found. Installing first..." -Level "WARNING"
        if (!(Install-SysinternalsTool "TCPView")) { return }
        $status = Get-ToolStatus "TCPView"
    }
    
    Write-Log "Starting TCPView..." -Level "INFO"
    Write-Log "Green = new connection, Red = closing, Yellow = changing" -Level "INFO"
    Write-Log "Right-click > Whois for domain info, End Process to kill connection" -Level "INFO"
    
    Start-Process $status.Path
}

function Export-StartupReport {
    Write-Log "Generating startup/autoruns report..." -Level "INFO"
    
    $reportPath = "$LogDir\StartupReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    "=== STARTUP REPORT ===" | Out-File $reportPath
    "Generated: $(Get-Date)" | Out-File $reportPath -Append
    "Computer: $env:COMPUTERNAME" | Out-File $reportPath -Append
    "User: $env:USERNAME" | Out-File $reportPath -Append
    "" | Out-File $reportPath -Append
    
    "--- Startup Programs (Registry) ---" | Out-File $reportPath -Append
    Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue | 
        Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider | 
        Out-File $reportPath -Append
    
    "" | Out-File $reportPath -Append
    "--- Startup Programs (User) ---" | Out-File $reportPath -Append
    Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue | 
        Select-Object * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider | 
        Out-File $reportPath -Append
    
    "" | Out-File $reportPath -Append
    "--- Startup Folder Items ---" | Out-File $reportPath -Append
    Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | 
        Select-Object Name, LastWriteTime | Out-File $reportPath -Append
    Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue | 
        Select-Object Name, LastWriteTime | Out-File $reportPath -Append
    
    "" | Out-File $reportPath -Append
    "--- Scheduled Tasks (Ready/Running) ---" | Out-File $reportPath -Append
    Get-ScheduledTask | Where-Object { $_.State -in @('Ready', 'Running') -and $_.TaskPath -eq '\' } | 
        Select-Object TaskName, State, Author | Out-File $reportPath -Append
    
    "" | Out-File $reportPath -Append
    "--- Services (Auto Start) ---" | Out-File $reportPath -Append
    Get-Service | Where-Object { $_.StartType -eq 'Automatic' } | 
        Select-Object Name, DisplayName, Status | Sort-Object Name | Out-File $reportPath -Append
    
    "" | Out-File $reportPath -Append
    "--- Active Network Connections ---" | Out-File $reportPath -Append
    Get-NetTCPConnection -State Established | 
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | 
        Out-File $reportPath -Append
    
    Write-Log "Report saved to: $reportPath" -Level "SUCCESS"
}

function Show-ToolStatus {
    Clear-Host
    Write-Host "`n=========================================" -ForegroundColor Cyan
    Write-Host "    SECURITY TOOLS STATUS" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($toolKey in $Tools.Keys) {
        $tool = $Tools[$toolKey]
        $status = Get-ToolStatus $toolKey
        
        Write-Host "$($tool.Name)" -ForegroundColor Yellow
        Write-Host "  Description: $($tool.Description)"
        if ($status.Exists) {
            Write-Host "  Status: " -NoNewline
            Write-Host "INSTALLED" -ForegroundColor Green -NoNewline
            Write-Host " ($($status.SizeMB) MB)"
            Write-Host "  Path: $($status.Path)"
        } else {
            Write-Host "  Status: " -NoNewline
            Write-Host "NOT INSTALLED" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    Write-Host "Tools Directory: $ToolsDir" -ForegroundColor DarkGray
    Write-Host "Logs Directory: $LogDir" -ForegroundColor DarkGray
    Write-Host ""
}

function Update-AllTools {
    Write-Log "Updating all security tools..." -Level "INFO"
    
    Install-SafetyScanner
    Install-SysinternalsTool "Autoruns"
    Install-SysinternalsTool "TCPView"
    
    Write-Log "All tools updated!" -Level "SUCCESS"
}

# ---------------------------------------------------------
# MAIN MENU
# ---------------------------------------------------------

function Show-Menu {
    Clear-Host
    
    # ASCII Banner
    $BannerLines = @(
        '  _____                      _ _          _   _             _   '
        ' / ____|                    (_) |        | | | |           | |  '
        '| (___   ___  ___ _   _ _ __ _| |__   ___| |_| |_ ___ _ __ | |_ '
        ' \___ \ / _ \/ __| | | | \__| | |_ \ / _ | __| __/ _ | \__| __|'
        ' ____) |  __/ (__| |_| | |  | | | | |  __| |_| ||  __/ |   | |_ '
        '|_____/ \___|\___|\__,_|_|  |_|_| |_|\___|\__|\__\___|_|    \__|'
    )
    
    $Colors = @('Red', 'Yellow', 'Green', 'Cyan', 'Blue', 'Magenta')
    for ($i = 0; $i -lt $BannerLines.Count; $i++) {
        Write-Host $BannerLines[$i] -ForegroundColor $Colors[$i % $Colors.Count]
    }
    
    Write-Host ""
    Write-Host "Tools Directory: " -NoNewline -ForegroundColor DarkGray
    Write-Host $ToolsDir -ForegroundColor White
    Write-Host ""
    
    Write-Host "[1] " -NoNewline -ForegroundColor Yellow; Write-Host "Microsoft Safety Scanner - Quick malware scan"
    Write-Host "[2] " -NoNewline -ForegroundColor Yellow; Write-Host "Autoruns - View startup programs & services"
    Write-Host "[3] " -NoNewline -ForegroundColor Yellow; Write-Host "TCPView - Real-time network connections"
    Write-Host "[4] " -NoNewline -ForegroundColor Yellow; Write-Host "Export Startup Report - Generate baseline report"
    Write-Host "[5] " -NoNewline -ForegroundColor Yellow; Write-Host "Update/Install All Tools"
    Write-Host "[6] " -NoNewline -ForegroundColor Yellow; Write-Host "Check Tool Status"
    Write-Host "[C] " -NoNewline -ForegroundColor Red; Write-Host "Clean up tool files"
    Write-Host "[Q] " -NoNewline -ForegroundColor Red; Write-Host "Quit"
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Magenta
}

# ---------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------

$script:Running = $true

while ($script:Running) {
    Show-Menu
    $Selection = Read-Host "Select an option"
    
    switch ($Selection) {
        '1' { Start-SafetyScanner }
        '2' { Start-Autoruns }
        '3' { Start-TCPView }
        '4' { Export-StartupReport }
        '5' { Update-AllTools }
        '6' { Show-ToolStatus }
        'C' { 
            if ((Read-Host "Delete all tool files? [Y/N]") -eq 'Y') {
                Remove-Item $ToolsDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log "Tools cleaned up" -Level "SUCCESS"
            }
        }
        'Q' { 
            $script:Running = $false
            Write-Log "Exiting Security Toolkit..." -Level "INFO"
        }
        default { 
            Write-Log "Invalid selection. Please try again." -Level "ERROR"
        }
    }
    
    if ($script:Running) {
        Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
