<#
.SYNOPSIS
    Simplified Network & WSL Toolkit
#>

# ---------------------------------------------------------
# 1. DEFINE FUNCTIONS
# ---------------------------------------------------------
Start-Transcript -Path "C:\Scripts\Session.log" -Append

function Get-BasicIPInfo {
    Write-Host "`n[+] Getting Current IP Address..." -ForegroundColor Cyan
    Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi", "Ethernet" -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, IPAddress | Format-Table
}

function Get-ActiveConnections {
    Write-Host "`n[+] Checking Active TCP Connections..." -ForegroundColor Cyan
    Get-NetTCPConnection -State Established | Select-Object LocalAddress, LocalPort, RemoteAddress | Format-Table
}

function Flush-LocalDNS {
    Write-Host "`n[+] Flushing DNS Resolver Cache..." -ForegroundColor Yellow
    Clear-DnsClientCache
    Write-Host "[+] DNS Cache Flushed." -ForegroundColor Green
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

function Test-Internet {
    Write-Host "`n[+] Pinging Google (8.8.8.8) to test internet..." -ForegroundColor Cyan
    Test-Connection -ComputerName 8.8.8.8 -Count 4 -ErrorAction SilentlyContinue | Format-Table IPv4Address, ResponseTime
}

function Get-RouterIP {
    Write-Host "`n[+] Finding Default Gateway (Router IP)..." -ForegroundColor Cyan
    Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object InterfaceAlias, NextHop | Format-Table
}

function Get-MacAddress {
    Write-Host "`n[+] Getting MAC Addresses..." -ForegroundColor Cyan
    getmac /v /fo list
}

function Get-WiFiName {
    Write-Host "`n[+] Checking connected Wi-Fi network..." -ForegroundColor Cyan
    netsh wlan show interfaces | Select-String -Pattern "\bSSID\b|Signal"
}
function Get-SystemUptime {
    Write-Host "`n[+] Getting System Uptime..." -ForegroundColor Cyan
    $OS = Get-CimInstance Win32_OperatingSystem
    $Uptime = (Get-Date) - $OS.LastBootUpTime
    Write-Host "Uptime: $($Uptime.Days) Days, $($Uptime.Hours) Hours, $($Uptime.Minutes) Minutes" -ForegroundColor White
}

function Get-DiskSpace {
    Write-Host "`n[+] Checking C: Drive Space..." -ForegroundColor Cyan
    Get-Volume -DriveLetter C | Select-Object DriveLetter, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="Free(GB)";Expression={[math]::Round($_.SizeRemaining/1GB,2)}} | Format-Table
}

function Get-DnsServers {
    Write-Host "`n[+] Checking DNS Servers..." -ForegroundColor Cyan
    Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null } | Select-Object InterfaceAlias, ServerAddresses | Format-Table
}

function Get-CurrentUser {
    Write-Host "`n[+] Current Logged In User..." -ForegroundColor Cyan
    Write-Host "User: $env:USERNAME" -ForegroundColor White
    Write-Host "Domain/Computer: $env:USERDOMAIN" -ForegroundColor White
}
function Invoke-SshSession {
    Write-Host "`n[+] Initiate SSH Connection (e.g., Unraid / Linux VM)..." -ForegroundColor Cyan
    $Target = Read-Host "Enter user@IP (e.g., root@192.168.1.10)"
    ssh $Target
}

function Export-WslBackup {
    Write-Host "`n[+] Backup WSL Distro..." -ForegroundColor Cyan
    wsl --list --short
    $Distro = Read-Host "`nEnter Distro Name to backup"
    $Path = Read-Host "Enter destination (e.g., C:\Backups\$Distro.tar)"
    Write-Host "`n[+] Exporting $Distro to $Path. This may take a while..." -ForegroundColor Yellow
    wsl --export $Distro $Path
    Write-Host "[+] Export complete." -ForegroundColor Green
}

function Get-LocalSubnetSweep {
    Write-Host "`n[+] Quick Subnet Ping Sweep..." -ForegroundColor Cyan
    $BaseIP = Read-Host "Enter first 3 octets (e.g., 192.168.1)"
    Write-Host "`nSweeping $BaseIP.1 to $BaseIP.254 (This takes a minute)..." -ForegroundColor Yellow
    1..254 | ForEach-Object {
        $ip = "$BaseIP.$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet -BufferSize 16) {
            Write-Host "[+] $ip is UP" -ForegroundColor Green
        }
    }
}
function Test-WebService {
    Write-Host "`n[+] Testing HTTP/HTTPS Service..." -ForegroundColor Cyan
    $Url = Read-Host "Enter URL (e.g., http://192.168.1.50)"
    try {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        Write-Host "[+] Service is UP! Status Code: $($Response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "[-] Service is DOWN or unreachable. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-RoutingTable {
    Write-Host "`n[+] Displaying IPv4 Routing Table..." -ForegroundColor Cyan
    Get-NetRoute -AddressFamily IPv4 | Sort-Object DestinationPrefix | Format-Table DestinationPrefix, NextHop, InterfaceAlias, RouteMetric
}

function Clear-ArpCache {
    Write-Host "`n[+] Flushing ARP Cache (Requires Admin)..." -ForegroundColor Yellow
    try {
        Remove-NetNeighbor -AddressFamily IPv4 -Confirm:$false
        Write-Host "[+] ARP Cache cleared." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed to clear ARP cache. Are you running as Admin?" -ForegroundColor Red
    }
}

function Restart-WslNetwork {
    Write-Host "`n[+] Restarting WSL Host Network Service (Fixes WSL internet issues)..." -ForegroundColor Yellow
    try {
        Restart-Service -Name "hns" -Force -ErrorAction Stop
        Write-Host "[+] Host Network Service (HNS) restarted successfully." -ForegroundColor Green
    } catch {
        Write-Host "[!] Failed. Requires Admin privileges." -ForegroundColor Red
    }
}
function Get-ListeningPorts {
    Write-Host "`n[+] Checking Active Listening Ports..." -ForegroundColor Cyan
    Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort | Sort-Object LocalPort -Unique | Format-Table
}
function Find-mDNSDevices {
    Write-Host "`n[+] Scanning for local mDNS/Bonjour services..." -ForegroundColor Cyan
    try {
        Resolve-DnsName -Name _services._dns-sd._udp.local -Type PTR -ErrorAction Stop | Select-Object NameHost | Format-Table
    } catch {
        Write-Host "[-] No mDNS services found. (Requires local mDNS support/Windows 10+)" -ForegroundColor Red
    }
}

function Start-ContinuousPing {
    $Target = Read-Host "`nEnter IP or Domain to monitor"
    Write-Host "`n[+] Pinging $Target. Press CTRL+C to stop..." -ForegroundColor Cyan
    while ($true) {
        $Result = Test-Connection -ComputerName $Target -Count 1 -ErrorAction SilentlyContinue
        $Time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        if ($Result.Status -eq "Success" -or $Result.StatusCode -eq 0) {
            Write-Host "[$Time] Reply from $Target : time=$($Result.ResponseTime)ms" -ForegroundColor Green
        } else {
            Write-Host "[$Time] Request timed out." -ForegroundColor Red
        }
        Start-Sleep -Seconds 1
    }
}

function Reset-DhcpLease {
    Write-Host "`n[+] Releasing and Renewing DHCP Lease..." -ForegroundColor Yellow
    ipconfig /release | Out-Null
    ipconfig /renew | Select-String "IPv4 Address"
    Write-Host "[+] DHCP Renewed." -ForegroundColor Green
}

function Invoke-SubnetCalculator {
    $InputStr = Read-Host "`nEnter IP/CIDR (e.g., 192.168.1.50/24)"
    if ($InputStr -match "^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$") {
        $IP = $matches[1]
        $CIDR = [int]$matches[2]
        $IPObj = [IPAddress]$IP
        $Mask = [Math]::Pow(2, 32) - 1 - ([Math]::Pow(2, 32 - $CIDR) - 1)
        $MaskBytes = [BitConverter]::GetBytes([uint32]$Mask)
        if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($MaskBytes) }
        $NetBytes = New-Object byte[] 4
        $BcastBytes = New-Object byte[] 4
        $IPBytes = $IPObj.GetAddressBytes()
        for ($i = 0; $i -lt 4; $i++) {
            $NetBytes[$i] = $IPBytes[$i] -band $MaskBytes[$i]
            $BcastBytes[$i] = $NetBytes[$i] -bor (-bnot $MaskBytes[$i] -band 255)
        }
        Write-Host "`n[+] Subnet Details for $InputStr" -ForegroundColor Cyan
        Write-Host "Subnet Mask: $([IPAddress]$MaskBytes)" -ForegroundColor White
        Write-Host "Network IP : $([IPAddress]$NetBytes)" -ForegroundColor White
        Write-Host "Broadcast  : $([IPAddress]$BcastBytes)" -ForegroundColor White
        Write-Host "Total IPs  : $([Math]::Pow(2, 32 - $CIDR))" -ForegroundColor White
    } else {
        Write-Host "[-] Invalid format. Use IP/CIDR." -ForegroundColor Red
    }
}
# ---------------------------------------------------------
# 2. BUILD THE MENU UI
# ---------------------------------------------------------

function Show-Menu {
    Clear-Host

    # --- GATHER HEADER STATS ---
    $User = "$env:USERDOMAIN\$env:USERNAME"
    $IPObj = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi", "Ethernet" -ErrorAction SilentlyContinue | Select-Object -First 1
    $IP = if ($IPObj) { $IPObj.IPAddress } else { "Offline" }
    $GatewayObj = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1
    $Gateway = if ($GatewayObj) { $GatewayObj.NextHop } else { "None" }
    $VolC = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
    $CFree = if ($VolC) { [math]::Round($VolC.SizeRemaining/1GB, 1) } else { 0 }
    $CTotal = if ($VolC) { [math]::Round($VolC.Size/1GB, 1) } else { 0 }
    $OS = Get-CimInstance Win32_OperatingSystem
    $Uptime = (Get-Date) - $OS.LastBootUpTime
    $UpStr = "$($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m"


# --- DISPLAY HEADER ---
# --- ASCII BANNER ---
# --- ASCII BANNER ---
# --- ASCII BANNER ---
# --- ASCII BANNER ---
    $BannerLines = @(
        '  __  __ _ _          _   _ _       _     ',
        ' |  \/  (_) | ___    | | | (_) __ _| |__  ',
        ' | |\/| | | |/ _ \   | |_| | |/ _` | _  \ ',
        ' | |  | | | |  __/   |  _  | | (_| | | | |',
        ' |_|  |_|_|_|\___|   |_| |_|_|\__, |_| |_|',
        '                              ___/ |       ',
        '                             |____/           ',
        '  _____         _      ____                            ',
        ' |_   _|__  ___| |__  |  _ \ ___  ___  ___ _   _  ___  ',
        '   | |/ _ \/ __|  _ \ | |_) / _ \/ __|/ __| | | |/ _ \ ',
        '   | |  __/ (__| | | ||  _ <  __/\__ \ (__| |_| |  __/',
        '   |_|\___|\___|_| |_||_| \_\___||___/\___|\__,_|\___|'
         '   '
    )

    $Colors = @('Red', 'Yellow', 'Green', 'Cyan', 'Blue', 'Magenta')
    $i = 0
    foreach ($Line in $BannerLines) {
        # Centering the output roughly for a standard console width
        Write-Host ("      " + $Line) -ForegroundColor $Colors[$i % $Colors.Count]
        $i++
    }
    Write-Host " User    : " -NoNewline -ForegroundColor DarkGray; Write-Host $User -ForegroundColor White
    Write-Host " Uptime  : " -NoNewline -ForegroundColor DarkGray; Write-Host $UpStr -ForegroundColor White
    Write-Host " Network : " -NoNewline -ForegroundColor DarkGray; Write-Host "$IP (Gateway: $Gateway)" -ForegroundColor White
    Write-Host " C:\     : " -NoNewline -ForegroundColor DarkGray; Write-Host "${CFree}GB Free / ${CTotal}GB Total" -ForegroundColor White
    Write-Host "=========================================" -ForegroundColor Magenta

    Write-Host "[1] " -NoNewline -ForegroundColor Yellow; Write-Host "List Active Connections" -ForegroundColor White
    Write-Host "[2] " -NoNewline -ForegroundColor Yellow; Write-Host "Flush DNS Cache" -ForegroundColor White
    Write-Host "[3] " -NoNewline -ForegroundColor Yellow; Write-Host "List WSL Distros" -ForegroundColor White
    Write-Host "[4] " -NoNewline -ForegroundColor Yellow; Write-Host "Shutdown All WSL" -ForegroundColor White
    Write-Host "[5] " -NoNewline -ForegroundColor Yellow; Write-Host "Update WSL" -ForegroundColor White
    Write-Host "[6] " -NoNewline -ForegroundColor Yellow; Write-Host "Test Internet Connectivity" -ForegroundColor White
    Write-Host "[7] " -NoNewline -ForegroundColor Yellow; Write-Host "Get MAC Address" -ForegroundColor White
    Write-Host "[8] " -NoNewline -ForegroundColor Yellow; Write-Host "Get Wi-Fi Network Name" -ForegroundColor White
    Write-Host "[9] " -NoNewline -ForegroundColor Yellow; Write-Host "Get DNS Servers" -ForegroundColor White
    Write-Host "[10] "-NoNewline -ForegroundColor Yellow; Write-Host "Initiate SSH Session" -ForegroundColor White
    Write-Host "[11] "-NoNewline -ForegroundColor Yellow; Write-Host "Backup/Export WSL Distro" -ForegroundColor White
    Write-Host "[12] "-NoNewline -ForegroundColor Yellow; Write-Host "Subnet Ping Sweep" -ForegroundColor White
    Write-Host "[13] "-NoNewline -ForegroundColor Yellow; Write-Host "List Active Listening Ports" -ForegroundColor White
    Write-Host "[14] "-NoNewline -ForegroundColor Yellow; Write-Host "Test Web Service" -ForegroundColor White
    Write-Host "[15] "-NoNewline -ForegroundColor Yellow; Write-Host "Display Routing Table" -ForegroundColor White
    Write-Host "[16] "-NoNewline -ForegroundColor Yellow; Write-Host "Clear ARP Cache" -ForegroundColor White
    Write-Host "[17] "-NoNewline -ForegroundColor Yellow; Write-Host "Restart WSL Network" -ForegroundColor White
    Write-Host "[18] "-NoNewline -ForegroundColor Yellow; Write-Host "Scan for mDNS / Bonjour Services" -ForegroundColor White
    Write-Host "[19] "-NoNewline -ForegroundColor Yellow; Write-Host "Continuous Ping Monitor" -ForegroundColor White
    Write-Host "[20] "-NoNewline -ForegroundColor Yellow; Write-Host "Release / Renew DHCP" -ForegroundColor White
    Write-Host "[21] "-NoNewline -ForegroundColor Yellow; Write-Host "Subnet Calculator" -ForegroundColor White
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
        '3'  { Get-WslDistros }
        '4'  { Stop-WslInstance }
        '5'  { Update-Wsl }
        '6'  { Test-Internet }
        '7'  { Get-MacAddress }
        '8'  { Get-WiFiName }
        '9'  { Get-DnsServers }
        '10' { Invoke-SshSession }
        '11' { Export-WslBackup }
        '12' { Get-LocalSubnetSweep }
        '13' { Get-ListeningPorts }
        '14' { Test-WebService }
        '15' { Get-RoutingTable }
        '16' { Clear-ArpCache }
        '17' { Restart-WslNetwork }
        '18' { Find-mDNSDevices }
        '19' { Start-ContinuousPing }
        '20' { Reset-DhcpLease }
        '21' { Invoke-SubnetCalculator }
        'Q'  { 
            $script:Running = $false
            Write-Host "`nExiting Toolkit..." -ForegroundColor DarkGray 
            Stop-Transcript
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