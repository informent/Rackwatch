param([string]$InstallRoot = "$env:LOCALAPPDATA\Rackwatch")
$ErrorActionPreference = 'Stop'
$shortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Rackwatch.lnk'
if (Test-Path $shortcut) { Remove-Item $shortcut -Force }
if (Test-Path $InstallRoot) { Remove-Item $InstallRoot -Recurse -Force }
Write-Host 'Rackwatch removed.'
