param([string]$InstallRoot = "$env:LOCALAPPDATA\Rackwatch")
$ErrorActionPreference = 'Stop'
$source = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
Copy-Item (Join-Path $source 'Rackwatch.exe') $InstallRoot -Force
Get-ChildItem $source -File | Where-Object Name -ne 'Rackwatch.exe' | Copy-Item -Destination $InstallRoot -Force
$shortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Rackwatch.lnk'
$shell = New-Object -ComObject WScript.Shell
$link = $shell.CreateShortcut($shortcut); $link.TargetPath = Join-Path $InstallRoot 'Rackwatch.exe'; $link.WorkingDirectory = $InstallRoot; $link.Description = 'Rackwatch local server console'; $link.Save()
Write-Host "Installed Rackwatch to $InstallRoot"
