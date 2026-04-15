#Requires -RunAsAdministrator
<#
.SYNOPSIS
    List all local users with detailed privilege and status information.
.DESCRIPTION
    Displays comprehensive information about local user accounts including
group memberships, password status, and account state.
.EXAMPLE
    .\Get-AllUsers.ps1
#>

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "       LOCAL USER ACCOUNTS REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all local users
$Users = Get-LocalUser | Sort-Object Name

# Get all groups for reference
$Groups = Get-LocalGroup

foreach ($User in $Users) {
    # Skip system accounts (optional - comment out if you want to see them)
    if ($User.Name -match "^(Administrator|Guest|DefaultAccount|WDAGUtilityAccount)$") {
        continue
    }
    
    # Determine account status
    $Status = if ($User.Enabled) { "Enabled" } else { "Disabled" }
    $StatusColor = if ($User.Enabled) { "Green" } else { "Red" }
    
    # Get user's group memberships
    $UserGroups = @()
    foreach ($Group in $Groups) {
        $GroupMembers = Get-LocalGroupMember -Group $Group.Name -ErrorAction SilentlyContinue
        if ($GroupMembers -and ($GroupMembers.Name -contains $User.Name -or $GroupMembers.SID -contains $User.SID)) {
            $UserGroups += $Group.Name
        }
    }
    
    # Determine privilege level
    $Privilege = "Standard User"
    if ($UserGroups -contains "Administrators") {
        $Privilege = "Administrator"
    } elseif ($UserGroups -contains "Guests") {
        $Privilege = "Guest"
    }
    
    # Password info
    $PasswordLastSet = if ($User.PasswordLastSet) { $User.PasswordLastSet.ToString("yyyy-MM-dd") } else { "Never" }
    $PasswordExpires = if ($User.PasswordExpires) { $User.PasswordExpires.ToString("yyyy-MM-dd") } else { "Never" }
    $LastLogon = if ($User.LastLogon) { $User.LastLogon.ToString("yyyy-MM-dd HH:mm") } else { "Never" }
    
    # Display user info
    Write-Host "Username:       " -NoNewline
    Write-Host $User.Name -ForegroundColor Yellow
    
    Write-Host "Full Name:      " -NoNewline
    Write-Host $(if($User.FullName){$User.FullName}else{"(none)"}) -ForegroundColor White
    
    Write-Host "Status:         " -NoNewline
    Write-Host $Status -ForegroundColor $StatusColor
    
    Write-Host "Privilege:      " -NoNewline
    $PrivColor = switch ($Privilege) {
        "Administrator" { "Magenta" }
        "Guest" { "DarkGray" }
        default { "White" }
    }
    Write-Host $Privilege -ForegroundColor $PrivColor
    
    Write-Host "Groups:         " -NoNewline
    if ($UserGroups.Count -gt 0) {
        Write-Host ($UserGroups -join ", ") -ForegroundColor Cyan
    } else {
        Write-Host "None" -ForegroundColor DarkGray
    }
    
    Write-Host "Last Logon:     " -NoNewline
    Write-Host $LastLogon -ForegroundColor White
    
    Write-Host "Password Set:   " -NoNewline
    Write-Host $PasswordLastSet -ForegroundColor White
    
    Write-Host "Password Exp:   " -NoNewline
    Write-Host $PasswordExpires -ForegroundColor White
    
    Write-Host "Description:    " -NoNewline
    Write-Host $(if($User.Description){$User.Description}else{"(none)"}) -ForegroundColor DarkGray
    
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "              SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$EnabledCount = ($Users | Where-Object { $_.Enabled }).Count
$DisabledCount = ($Users | Where-Object { -not $_.Enabled }).Count
$AdminCount = 0
foreach ($User in $Users) {
    $IsAdmin = Get-LocalGroupMember -Group "Administrators" -Member $User.Name -ErrorAction SilentlyContinue
    if ($IsAdmin) { $AdminCount++ }
}

Write-Host "Total Users:      $($Users.Count)" -ForegroundColor White
Write-Host "Enabled:          $EnabledCount" -ForegroundColor Green
Write-Host "Disabled:         $DisabledCount" -ForegroundColor Red
Write-Host "Administrators:   $AdminCount" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Cyan

# Option to export to file
Write-Host ""
$Export = Read-Host "Export to file? (Y/N)"
if ($Export -match '^[Yy]$') {
    $LogFile = "$env:COMPUTERNAME`_users_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $Output = @()
    $Output += "LOCAL USER ACCOUNTS REPORT"
    $Output += "Computer: $env:COMPUTERNAME"
    $Output += "Generated: $(Get-Date)"
    $Output += "========================================"
    $Output += ""
    
    foreach ($User in $Users) {
        $UserGroups = @()
        foreach ($Group in $Groups) {
            $GroupMembers = Get-LocalGroupMember -Group $Group.Name -ErrorAction SilentlyContinue
            if ($GroupMembers -and ($GroupMembers.Name -contains $User.Name)) {
                $UserGroups += $Group.Name
            }
        }
        
        $Privilege = "Standard User"
        if ($UserGroups -contains "Administrators") { $Privilege = "Administrator" }
        elseif ($UserGroups -contains "Guests") { $Privilege = "Guest" }
        
        $Output += "Username:     $($User.Name)"
        $Output += "Full Name:    $(if($User.FullName){$User.FullName}else{'(none)'})"
        $Output += "Status:       $(if($User.Enabled){'Enabled'}else{'Disabled'})"
        $Output += "Privilege:    $Privilege"
        $Output += "Groups:       $($UserGroups -join ', ')"
        $Output += "Last Logon:   $(if($User.LastLogon){$User.LastLogon}else{'Never'})"
        $Output += "Password Set: $(if($User.PasswordLastSet){$User.PasswordLastSet}else{'Never'})"
        $Output += "Description:  $(if($User.Description){$User.Description}else{'(none)'})"
        $Output += "----------------------------------------"
    }
    
    $Output += ""
    $Output += "SUMMARY"
    $Output += "Total Users:    $($Users.Count)"
    $Output += "Enabled:        $EnabledCount"
    $Output += "Disabled:       $DisabledCount"
    $Output += "Administrators: $AdminCount"
    
    $Output | Out-File -FilePath $LogFile -Encoding UTF8
    Write-Host ""
    Write-Host "Saved to: $LogFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
