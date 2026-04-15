#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Captures comprehensive hardware and OS information.
.DESCRIPTION
    Gathers system details and outputs to a log file named after the computer.
    Run as Administrator for full hardware access.
.EXAMPLE
    .\Get-SystemInfo.ps1
    Outputs: COMPUTERNAME_log.txt in the current directory
#>

# Get computer name for the log file
$ComputerName = $env:COMPUTERNAME
$LogFile = "${ComputerName}_log.txt"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Create output array
$Output = @()

# Header
$Output += "========================================"
$Output += "SYSTEM INFORMATION REPORT"
$Output += "Computer: $ComputerName"
$Output += "Generated: $Timestamp"
$Output += "========================================"
$Output += ""

# OS Information
$Output += "--- OPERATING SYSTEM ---"
$OS = Get-CimInstance -ClassName Win32_OperatingSystem
$Uptime = (Get-Date) - $OS.LastBootUpTime
$UptimeDays = [math]::Round($Uptime.TotalDays, 2)
$Output += "OS Name:        $($OS.Caption)"
$Output += "Version:        $($OS.Version)"
$Output += "Build:          $($OS.BuildNumber)"
$Output += "Architecture:   $($OS.OSArchitecture)"
$Output += "Install Date:   $($OS.InstallDate)"
$Output += "Last Boot:      $($OS.LastBootUpTime)"
$Output += "Uptime:         $UptimeDays days"
$Output += ""

# System Info
$Output += "--- SYSTEM ---"
$CS = Get-CimInstance -ClassName Win32_ComputerSystem
$Output += "Manufacturer:   $($CS.Manufacturer)"
$Output += "Model:          $($CS.Model)"
$Output += "System Type:    $($CS.SystemType)"
$Output += "Total RAM:      $([math]::Round($CS.TotalPhysicalMemory / 1GB, 2)) GB"
$Output += "Domain:         $($CS.Domain)"
$Output += "Logged User:    $($CS.UserName)"
$Output += ""

# BIOS Information
$Output += "--- BIOS ---"
$BIOS = Get-CimInstance -ClassName Win32_BIOS
$Output += "Manufacturer:   $($BIOS.Manufacturer)"
$Output += "Version:        $($BIOS.Version)"
$Output += "Serial Number:  $($BIOS.SerialNumber)"
$Output += "Release Date:   $($BIOS.ReleaseDate)"
$Output += ""

# CPU Information
$Output += "--- PROCESSOR ---"
$CPU = Get-CimInstance -ClassName Win32_Processor
foreach ($Proc in $CPU) {
    $Output += "Name:           $($Proc.Name)"
    $Output += "Cores:          $($Proc.NumberOfCores)"
    $Output += "Logical Procs:  $($Proc.NumberOfLogicalProcessors)"
    $Output += "Base Speed:     $($Proc.MaxClockSpeed) MHz"
    $Output += "Socket:         $($Proc.SocketDesignation)"
    $Output += ""
}

# Memory Details
$Output += "--- MEMORY MODULES ---"
$RAM = Get-CimInstance -ClassName Win32_PhysicalMemory
foreach ($Stick in $RAM) {
    $CapacityGB = [math]::Round($Stick.Capacity / 1GB, 2)
    $Output += "Slot:           $($Stick.DeviceLocator)"
    $Output += "Size:           $CapacityGB GB"
    $Output += "Speed:          $($Stick.Speed) MHz"
    $Output += "Manufacturer:   $($Stick.Manufacturer)"
    $Output += "Part Number:    $($Stick.PartNumber)"
    $Output += ""
}

# Storage Information
$Output += "--- STORAGE ---"
$Disks = Get-CimInstance -ClassName Win32_DiskDrive
foreach ($Disk in $Disks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
    $Output += "Model:          $($Disk.Model)"
    $Output += "Size:           $SizeGB GB"
    $Output += "Interface:      $($Disk.InterfaceType)"
    $Output += "Media Type:     $($Disk.MediaType)"
    $Output += "Serial:         $($Disk.SerialNumber)"
    $Output += ""
}

# Logical Drives
$Output += "--- DRIVE VOLUMES ---"
$Volumes = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
foreach ($Vol in $Volumes) {
    $FreeGB = [math]::Round($Vol.FreeSpace / 1GB, 2)
    $TotalGB = [math]::Round($Vol.Size / 1GB, 2)
    $UsedGB = $TotalGB - $FreeGB
    $PercentFree = [math]::Round(($FreeGB / $TotalGB) * 100, 1)
    $Output += "Drive $($Vol.DeviceID)"
    $Output += "  Label:        $($Vol.VolumeName)"
    $Output += "  Total:        $TotalGB GB"
    $Output += "  Used:         $UsedGB GB"
    $Output += "  Free:         $FreeGB GB ($PercentFree%)"
    $Output += "  File System:  $($Vol.FileSystem)"
    $Output += ""
}

# GPU Information
$Output += "--- GRAPHICS ---"
$GPU = Get-CimInstance -ClassName Win32_VideoController
foreach ($Card in $GPU) {
    if ($Card.Name -notlike "*Basic*") {
        $VRAM = [math]::Round($Card.AdapterRAM / 1GB, 2)
        $Output += "Name:           $($Card.Name)"
        $Output += "Video RAM:      $VRAM GB"
        $Output += "Resolution:     $($Card.CurrentHorizontalResolution) x $($Card.CurrentVerticalResolution)"
        $Output += "Driver Version: $($Card.DriverVersion)"
        $Output += ""
    }
}

# Network Adapters
$Output += "--- NETWORK ADAPTERS ---"
$NetAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($Adapter in $NetAdapters) {
    $IPConfig = Get-NetIPAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $Output += "Name:           $($Adapter.Name)"
    $Output += "Interface:      $($Adapter.InterfaceDescription)"
    $Output += "MAC Address:    $($Adapter.MacAddress)"
    
    # Handle LinkSpeed which may be string or numeric
    $SpeedVal = $Adapter.LinkSpeed
    if ($SpeedVal -is [string] -and $SpeedVal -match "^(\d+(?:\.\d+)?)\s*(\w+)$") {
        $SpeedNum = [decimal]$matches[1]
        $SpeedUnit = $matches[2]
        if ($SpeedUnit -eq 'Mbps') {
            $SpeedGbps = [math]::Round($SpeedNum / 1000, 2)
        } else {
            $SpeedGbps = $SpeedNum
        }
    } elseif ($SpeedVal -is [string]) {
        $SpeedGbps = $SpeedVal
    } else {
        $SpeedGbps = [math]::Round($SpeedVal / 1000000000, 2)
    }
    $Output += "Speed:          $SpeedGbps Gbps"
    
    if ($IPConfig) {
        $Output += "IP Address:     $($IPConfig.IPAddress)"
        $Output += "Subnet Mask:    $($IPConfig.PrefixLength)"
    }
    $Output += ""
}

# TPM Status
$Output += "--- SECURITY ---"
try {
    $TPM = Get-Tpm
    $Output += "TPM Present:    $($TPM.TpmPresent)"
    $Output += "TPM Ready:      $($TPM.TpmReady)"
    $Output += "TPM Enabled:    $($TPM.TpmEnabled)"
} catch {
    $Output += "TPM Status:     Unable to query (may require admin)"
}
try {
    $SecureBoot = Confirm-SecureBootUEFI
    $Output += "Secure Boot:    $SecureBoot"
} catch {
    $Output += "Secure Boot:    Unable to determine"
}
$Output += ""

# Installed Software (top 20 by install date)
$Output += "--- RECENTLY INSTALLED SOFTWARE (Last 20) ---"
$Software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName -ne $null } |
    Sort-Object InstallDate -Descending |
    Select-Object -First 20
foreach ($App in $Software) {
    $Output += "$($App.DisplayName) - $($App.DisplayVersion)"
}
$Output += ""

# Footer
$Output += "========================================"
$Output += "END OF REPORT"
$Output += "========================================"

# Write to file
$Output | Out-File -FilePath $LogFile -Encoding UTF8

# Also display to console
Write-Host "System information collected successfully!" -ForegroundColor Green
Write-Host "Output saved to: $(Resolve-Path $LogFile)" -ForegroundColor Cyan
Write-Host ""
