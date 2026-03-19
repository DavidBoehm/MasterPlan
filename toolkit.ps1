<#
.SYNOPSIS
    Interactive Admin Toolkit Framework
#>

# ---------------------------------------------------------
# 1. DEFINE FUNCTIONS
# ---------------------------------------------------------

function Get-ActiveConnections {
    Write-Host "`n[+] Checking Active TCP Connections..." -ForegroundColor Cyan
    Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort | Format-Table
}

function Flush-LocalDNS {
    Write-Host "`n[+] Flushing DNS Resolver Cache..." -ForegroundColor Yellow
    Clear-DnsClientCache
    Write-Host "[+] DNS Cache Flushed." -ForegroundColor Green
}

function Test-PortOpen {
    $Target = Read-Host "Enter IP or Domain"
    $Port = Read-Host "Enter Port Number"
    Write-Host "`n[+] Testing port $Port on $Target..." -ForegroundColor Cyan
    $Result = Test-NetConnection -ComputerName $Target -Port $Port -WarningAction SilentlyContinue
    if ($Result.TcpTestSucceeded) {
        Write-Host "[+] Port $Port is OPEN on $Target" -ForegroundColor Green
    } else {
        Write-Host "[-] Port $Port is CLOSED or FILTERED on $Target" -ForegroundColor Red
    }
}

function Get-WslDistros {
    Write-Host "`n[+] Listing Installed WSL Distributions..." -ForegroundColor Cyan
    wsl --list --verbose
}

function Stop-WslInstance {
    Write-Host "`n[+] Shutting down all WSL instances..." -ForegroundColor Yellow
    wsl --shutdown
    Write-Host "[+] WSL Shutdown Complete." -ForegroundColor Green
}

function Update-Wsl {
    Write-Host "`n[+] Updating WSL Kernel..." -ForegroundColor Cyan
    wsl --update
}

function Get-FirewallStatus {
    Write-Host "`n[+] Checking Windows Firewall Profiles..." -ForegroundColor Cyan
    Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction | Format-Table
}

function Get-LocalAdmins {
    Write-Host "`n[+] Listing Local Administrators..." -ForegroundColor Cyan
    Get-LocalGroupMember -Group "Administrators" | Select-Object Name, PrincipalSource | Format-Table
}

function Get-PendingUpdates {
    Write-Host "`n[+] Checking for missing Windows Updates (Requires Admin)..." -ForegroundColor Cyan
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $Result = $Searcher.Search("IsInstalled=0")
    $Result.Updates | Select-Object Title | Format-Table
}

function Get-ActivePacketCaptures {
    Write-Host "`n[+] Checking for active packet captures..." -ForegroundColor Cyan
    $PktmonStatus = pktmon status | Select-String "Running"
    if ($PktmonStatus) {
        Write-Host "[!] Windows Pktmon is currently RUNNING!" -ForegroundColor Red
    } else {
        Write-Host "[+] Windows Pktmon is stopped." -ForegroundColor Green
    }
    $CaptureProcs = Get-Process -Name wireshark, dumpcap, tshark, tcpdump -ErrorAction SilentlyContinue
    if ($CaptureProcs) {
        Write-Host "[!] Active capture processes found:" -ForegroundColor Red
        $CaptureProcs | Select-Object ProcessName, Id | Format-Table
    } else {
        Write-Host "[+] No third-party capture processes detected." -ForegroundColor Green
    }
}

function Invoke-WslDirectCommand {
    Write-Host "`n[+] Available WSL Distros:" -ForegroundColor Cyan
    wsl --list --short
    $Distro = Read-Host "`nEnter Distro Name to target"
    $Command = Read-Host "Enter Linux command to execute (e.g., df -h, ls -la)"
    Write-Host "`n[+] Executing '$Command' on $Distro..." -ForegroundColor Yellow
    wsl --distribution $Distro --exec bash -c $Command
}

function Get-GitStatus {
    $RepoPath = Read-Host "`nEnter path to Git repository (Leave blank for current dir)"
    if ([string]::IsNullOrWhiteSpace($RepoPath)) { $RepoPath = (Get-Location).Path }
    if (Test-Path "$RepoPath\.git") {
Write-Host "`n[+] Git Status for ${RepoPath}:" -ForegroundColor Cyan        Set-Location $RepoPath
        git status -s
    } else {
        Write-Host "`n[-] No .git directory found in $RepoPath" -ForegroundColor Red
    }
}

function Invoke-PythonScript {
    $ScriptPath = Read-Host "`nEnter full path to Python script (.py)"
    if (Test-Path $ScriptPath) {
        $Args = Read-Host "Enter arguments (if any)"
        Write-Host "`n[+] Executing $ScriptPath..." -ForegroundColor Yellow
        python $ScriptPath $Args
    } else {
        Write-Host "`n[-] Script not found at $ScriptPath" -ForegroundColor Red
    }
}

# ---------------------------------------------------------
# 2. BUILD THE MENU UI
# ---------------------------------------------------------

function Show-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host "          SYSTEM ADMIN TOOLKIT           " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host "[1] " -NoNewline -ForegroundColor Yellow; Write-Host "Get Active TCP Connections" -ForegroundColor White
    Write-Host "[2] " -NoNewline -ForegroundColor Yellow; Write-Host "Flush DNS Cache" -ForegroundColor White
    Write-Host "[3] " -NoNewline -ForegroundColor Yellow; Write-Host "Test Open Port" -ForegroundColor White
    Write-Host "[4] " -NoNewline -ForegroundColor Yellow; Write-Host "List WSL Distros" -ForegroundColor White
    Write-Host "[5] " -NoNewline -ForegroundColor Yellow; Write-Host "Shutdown All WSL" -ForegroundColor White
    Write-Host "[6] " -NoNewline -ForegroundColor Yellow; Write-Host "Update WSL" -ForegroundColor White
    Write-Host "[7] " -NoNewline -ForegroundColor Yellow; Write-Host "Check Firewall Status" -ForegroundColor White
    Write-Host "[8] " -NoNewline -ForegroundColor Yellow; Write-Host "List Local Admins" -ForegroundColor White
    Write-Host "[9] " -NoNewline -ForegroundColor Yellow; Write-Host "Check Pending Windows Updates" -ForegroundColor White
    Write-Host "[10] "-NoNewline -ForegroundColor Yellow; Write-Host "Check Active Packet Captures" -ForegroundColor White
    Write-Host "[11] "-NoNewline -ForegroundColor Yellow; Write-Host "Execute Command in Specific WSL Distro" -ForegroundColor White
    Write-Host "[12] "-NoNewline -ForegroundColor Yellow; Write-Host "Check Git Repository Status" -ForegroundColor White
    Write-Host "[13] "-NoNewline -ForegroundColor Yellow; Write-Host "Execute Python Script" -ForegroundColor White
    Write-Host "[Q] " -NoNewline -ForegroundColor Red; Write-Host "Quit" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Magenta
}

# ---------------------------------------------------------
# 3. EXECUTE MAIN LOOP
# ---------------------------------------------------------

$script:Running = $true

while ($script:Running) {
    Show-Menu
    $Selection = Read-Host "`nSelect an option"
    
    switch ($Selection) {
        '1'  { Get-ActiveConnections }
        '2'  { Flush-LocalDNS }
        '3'  { Test-PortOpen }
        '4'  { Get-WslDistros }
        '5'  { Stop-WslInstance }
        '6'  { Update-Wsl }
        '7'  { Get-FirewallStatus }
        '8'  { Get-LocalAdmins }
        '9'  { Get-PendingUpdates }
        '10' { Get-ActivePacketCaptures }
        '11' { Invoke-WslDirectCommand }
        '12' { Get-GitStatus }
        '13' { Invoke-PythonScript }
        'Q'  { 
            $script:Running = $false
            Write-Host "`nExiting Toolkit..." -ForegroundColor DarkGray 
            break
        }
        Default { 
            Write-Host "`n[!] Invalid selection. Please try again." -ForegroundColor Red 
        }
    }
    
    if ($script:Running) {
        Write-Host "`nPress any key to return to the menu..." -ForegroundColor DarkGray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}