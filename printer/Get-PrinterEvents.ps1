#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Scan Event Viewer for printer-related errors
.DESCRIPTION
    Queries Windows Event Logs for PrintService and printer-related errors
    Similar to 'cat' for Windows Event Logs
.EXAMPLE
    .\Get-PrinterEvents.ps1
    .\Get-PrinterEvents.ps1 -HoursBack 24
    .\Get-PrinterEvents.ps1 -Export
#>

param(
    [int]$HoursBack = 24,
    [switch]$Export,
    [switch]$ErrorsOnly
)

$StartTime = (Get-Date).AddHours(-$HoursBack)
$Events = @()

Write-Host "Scanning Event Logs for printer events (last $HoursBack hours)..." -ForegroundColor Cyan
Write-Host ""

# PrintService Operational Log (where most print errors live)
try {
    $Filter = @{LogName='Microsoft-Windows-PrintService/Operational'; StartTime=$StartTime}
    if ($ErrorsOnly) {
        $Filter['Level'] = 1,2  # Critical and Error
    }
    $PrintEvents = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue
    $Events += $PrintEvents
    Write-Host "Found $($PrintEvents.Count) PrintService/Operational events" -ForegroundColor Green
} catch {
    Write-Host "No PrintService Operational events found or access denied" -ForegroundColor Yellow
}

# PrintService Admin Log
try {
    $Filter = @{LogName='Microsoft-Windows-PrintService/Admin'; StartTime=$StartTime}
    if ($ErrorsOnly) {
        $Filter['Level'] = 1,2
    }
    $AdminEvents = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue
    $Events += $AdminEvents
    Write-Host "Found $($AdminEvents.Count) PrintService/Admin events" -ForegroundColor Green
} catch {
    Write-Host "No PrintService Admin events found" -ForegroundColor Yellow
}

# Application Log (older print errors)
try {
    $Filter = @{LogName='Application'; StartTime=$StartTime; ProviderName='*Print*'}
    $AppEvents = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue
    $Events += $AppEvents
    Write-Host "Found $($AppEvents.Count) Application log print events" -ForegroundColor Green
} catch {
    Write-Host "No Application log events found" -ForegroundColor Yellow
}

# System Log (driver/install issues)
try {
    $Filter = @{LogName='System'; StartTime=$StartTime; ProviderName='*Print*'}
    $SysEvents = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue
    $Events += $SysEvents
    Write-Host "Found $($SysEvents.Count) System log print events" -ForegroundColor Green
} catch {
    Write-Host "No System log events found" -ForegroundColor Yellow
}

# Sort by time
$Events = $Events | Sort-Object TimeCreated -Descending

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TOTAL EVENTS: $($Events.Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($Events.Count -eq 0) {
    Write-Host "No printer events found in the last $HoursBack hours." -ForegroundColor Green
    Write-Host "Either no activity, or spooler was cleared." -ForegroundColor Gray
    exit
}

# Display events
foreach ($Event in $Events) {
    $LevelColor = switch ($Event.Level) {
        1 { "Red" }      # Critical
        2 { "Red" }      # Error
        3 { "Yellow" }   # Warning
        default { "White" }
    }
    
    $LevelText = switch ($Event.Level) {
        1 { "CRITICAL" }
        2 { "ERROR" }
        3 { "WARNING" }
        4 { "INFO" }
        default { "OTHER" }
    }
    
    Write-Host "[$($Event.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))] " -NoNewline -ForegroundColor Gray
    Write-Host "[$LevelText] " -NoNewline -ForegroundColor $LevelColor
    Write-Host "[$($Event.LogName.Split('/')[-1])] " -NoNewline -ForegroundColor Cyan
    Write-Host "$($Event.Id): $($Event.Message.Split("`n")[0])" -ForegroundColor White
    
    # Show full message for errors
    if ($Event.Level -le 2 -and $Event.Message) {
        $Message = $Event.Message -replace "`r`n", "`n" -replace "`n", " | "
        if ($Message.Length -gt 120) { $Message = $Message.Substring(0, 120) + "..." }
        Write-Host "    $Message" -ForegroundColor DarkGray
    }
}

# Export option
if ($Export) {
    $LogFile = "PrinterEvents_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $Events | Select-Object TimeCreated, LevelDisplayName, Id, LogName, @{N='Message';E={$_.Message.Substring(0,[Math]::Min(200, $_.Message.Length))}} | 
        Format-Table -AutoSize | Out-File $LogFile
    Write-Host ""
    Write-Host "Exported to: $LogFile" -ForegroundColor Green
}

# Quick stats
Write-Host ""
Write-Host "--- Summary ---" -ForegroundColor Yellow
$Events | Group-Object LevelDisplayName | ForEach-Object {
    $Color = switch ($_.Name) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        default { "Green" }
    }
    Write-Host "$($_.Name): $($_.Count)" -ForegroundColor $Color
}
