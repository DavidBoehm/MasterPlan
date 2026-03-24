# Interactive Windows Registry Tweaks Toolkit
# Applies and reverts tweaks from RegEdit.md with backup and styled menu

function Write-Color {
	param(
		[string]$Text,
		[ConsoleColor]$Color = 'White',
		[switch]$NoNewLine
	)
	$old = $Host.UI.RawUI.ForegroundColor
	$Host.UI.RawUI.ForegroundColor = $Color
	if ($NoNewLine) { Write-Host -NoNewline $Text }
	else { Write-Host $Text }
	$Host.UI.RawUI.ForegroundColor = $old
}

function Backup-Registry {
	param([string]$BackupPath)
	Write-Color "[+] Backing up registry to $BackupPath ..." Yellow
	reg export HKCU $BackupPath\HKCU.reg /y | Out-Null
	reg export HKLM $BackupPath\HKLM.reg /y | Out-Null
	Write-Color "[✓] Registry backup complete." Green
}

function Restore-Registry {
	param([string]$BackupPath)
	Write-Color "[!] Restoring registry from $BackupPath ..." Red
	reg import $BackupPath\HKCU.reg | Out-Null
	reg import $BackupPath\HKLM.reg | Out-Null
	Write-Color "[✓] Registry restore complete. Please reboot for all changes to take effect." Green
}

$tweaks = @(
	@{ Name = 'Restore Classic Right-Click Menu';
	   Description = 'Removes "Show more options" in Windows 11.';
	   Apply = { Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '(default)' -Value '' -Force };
	   Revert = { Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -ErrorAction SilentlyContinue }
	},
	@{ Name = 'Disable Bing/Web Search';
	   Description = 'Limits Start menu search to local files.';
	   Apply = {
		   New-Item -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
		   Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -Type DWord
		   Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -Type DWord
	   };
	   Revert = {
		   Remove-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -ErrorAction SilentlyContinue
		   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -ErrorAction SilentlyContinue
	   }
	},
	@{ Name = 'Speed up Menus';
	   Description = 'Reduces hover delay from 400ms to 50ms.';
	   Apply = { Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '50' };
	   Revert = { Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '400' }
	},
	@{ Name = 'Unlock USB Power Settings';
	   Description = 'Exposes "USB Selective Suspend" in power options.';
	   Apply = { Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e0332c-9d01-4952-b912-78213f3a28ad' -Name 'Attributes' -Value 2 -Type DWord };
	   Revert = { Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e0332c-9d01-4952-b912-78213f3a28ad' -Name 'Attributes' -Value 1 -Type DWord }
	},
	@{ Name = 'Auto-End Tasks';
	   Description = 'Forces hung applications to close quickly during shutdown.';
	   Apply = {
		   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -Value '1'
		   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WaitToKillAppTimeout' -Value '2000'
		   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Value '2000'
	   };
	   Revert = {
		   Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'AutoEndTasks' -ErrorAction SilentlyContinue
		   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WaitToKillAppTimeout' -Value '5000'
		   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'HungAppTimeout' -Value '5000'
	   }
	}
)

function Show-Menu {
	Write-Color "\n==== Windows Registry Tweaks Toolkit ====" Cyan
	Write-Color "Select tweaks to apply (comma separated, e.g. 1,3,5):" Yellow
	for ($i=0; $i -lt $tweaks.Count; $i++) {
		Write-Color ("[$($i+1)] $($tweaks[$i].Name) - $($tweaks[$i].Description)") White
	}
	Write-Color "[R] Revert all tweaks (restore from backup)" Red
	Write-Color "[Q] Quit" DarkGray
}

$backupDir = Join-Path $env:TEMP "regtweaks_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Show-Menu
$choice = Read-Host "\nEnter your choice"

if ($choice -eq 'R' -or $choice -eq 'r') {
	Restore-Registry -BackupPath $backupDir
	exit
}
elseif ($choice -eq 'Q' -or $choice -eq 'q') {
	Write-Color "Exiting. No changes made." DarkGray
	exit
}

Backup-Registry -BackupPath $backupDir

$selected = $choice -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[1-9][0-9]*$' }
foreach ($idx in $selected) {
	$i = [int]$idx - 1
	if ($i -ge 0 -and $i -lt $tweaks.Count) {
		Write-Color "Applying: $($tweaks[$i].Name) ..." Cyan
		try {
			& $tweaks[$i].Apply
			Write-Color "[✓] $($tweaks[$i].Name) applied." Green
		} catch {
			Write-Color "[!] Failed to apply $($tweaks[$i].Name): $_" Red
		}
	}
}

Write-Color "\nAll selected tweaks processed. You may need to reboot for changes to take effect." Yellow
Write-Color "To revert, re-run this script and choose [R]evert." Cyan
