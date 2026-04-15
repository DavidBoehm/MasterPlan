#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Interactive user creation wizard for Windows 11
.DESCRIPTION
    Walks through creating a new local user account with prompts
    for username, password, and privilege level.
.EXAMPLE
    .\New-UserWizard.ps1
#>

Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      CREATE NEW USER WIZARD" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get username
$UserName = Read-Host "Enter new username"
if ([string]::IsNullOrWhiteSpace($UserName)) {
    Write-Host "Username cannot be empty!" -ForegroundColor Red
    exit
}

# Check if user already exists
$ExistingUser = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
if ($ExistingUser) {
    Write-Host "User '$UserName' already exists!" -ForegroundColor Red
    exit
}

# Get password
$Password = Read-Host "Enter password" -AsSecureString
$ConfirmPassword = Read-Host "Confirm password" -AsSecureString

# Convert to plain text to compare
$BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)

$BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ConfirmPassword)
$PlainConfirm = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)

if ($PlainPassword -ne $PlainConfirm) {
    Write-Host "Passwords do not match!" -ForegroundColor Red
    exit
}

if ($PlainPassword.Length -lt 1) {
    Write-Host "Password cannot be empty!" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Select privilege level:" -ForegroundColor Yellow
Write-Host "  [1] Standard User (recommended)" -ForegroundColor White
Write-Host "  [2] Administrator" -ForegroundColor White
Write-Host "  [3] Guest User" -ForegroundColor White
$PrivilegeChoice = Read-Host "Choice"

$IsGuest = $false
$GroupName = "Users"

switch ($PrivilegeChoice) {
    '1' { $GroupName = "Users" }
    '2' { $GroupName = "Administrators" }
    '3' { 
        $GroupName = "Guests"
        $IsGuest = $true
    }
    default { 
        Write-Host "Invalid choice, defaulting to Standard User" -ForegroundColor Yellow
        $GroupName = "Users" 
    }
}

# Full name (optional)
Write-Host ""
$FullName = Read-Host "Enter full name (optional, press Enter to skip)"

# Description (optional)
$Description = Read-Host "Enter description (optional, press Enter to skip)"

# Password expiration
Write-Host ""
$PasswordExpires = Read-Host "Require password change at next logon? (Y/N)"
$ChangeAtLogon = $PasswordExpires -match '^[Yy]$'

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "           SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Username:     $UserName" -ForegroundColor White
Write-Host "Full Name:    $(if($FullName){$FullName}else{'(none)'})" -ForegroundColor White
Write-Host "Description:  $(if($Description){$Description}else{'(none)'})" -ForegroundColor White
Write-Host "Group:        $GroupName" -ForegroundColor White
Write-Host "Guest User:   $IsGuest" -ForegroundColor White
Write-Host "Change PW:    $ChangeAtLogon" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Confirm = Read-Host "Create user? (Y/N)"
if ($Confirm -notmatch '^[Yy]$') {
    Write-Host "Cancelled." -ForegroundColor Red
    exit
}

# Create the user
try {
    $Params = @{
        Name = $UserName
        Password = $Password
        UserMayNotChangePassword = $false
        PasswordNeverExpires = $false
    }
    
    if ($FullName) { $Params['FullName'] = $FullName }
    if ($Description) { $Params['Description'] = $Description }
    
    New-LocalUser @Params | Out-Null
    
    # Add to group
    Add-LocalGroupMember -Group $GroupName -Member $UserName
    
    # Force password change if requested
    if ($ChangeAtLogon) {
        net user $UserName /logonpasswordchg:yes | Out-Null
    }
    
    Write-Host ""
    Write-Host "User '$UserName' created successfully!" -ForegroundColor Green
    Write-Host "Added to group: $GroupName" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "Failed to create user: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
