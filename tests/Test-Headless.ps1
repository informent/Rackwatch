param([Parameter(Mandatory=$true)][string]$Exe)
$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('Rackwatch-headless-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
function Invoke-Headless([string]$Arguments, [int]$Expected) {
    $process = Start-Process -FilePath $Exe -ArgumentList $Arguments -WindowStyle Hidden -PassThru
    try {
        $deadline = [DateTime]::UtcNow.AddSeconds(150)
        while (!$process.HasExited) {
            $process.Refresh()
            if ($process.MainWindowHandle -ne 0) { throw 'Unattended command opened a desktop window' }
            if ([DateTime]::UtcNow -ge $deadline) { throw 'Unattended command timed out' }
            Start-Sleep -Milliseconds 100
        }
        $process.WaitForExit()
        if ($process.ExitCode -ne $Expected) { throw "Expected exit $Expected, received $($process.ExitCode)" }
    }
    finally { if (!$process.HasExited) { $process.Kill(); $process.WaitForExit() }; $process.Dispose() }
}
try {
    $server = Join-Path $root 'server'
    New-Item -ItemType Directory -Path (Join-Path $server 'addons') -Force | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $server 'addons/empty.lua'), [byte[]]@())
    $report = Join-Path $root 'audit.json'
    $arguments = '--scan --folder "' + $server + '" --output "' + $report + '" --fail-on-findings'
    Invoke-Headless $arguments 3
    $json = Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
    if ($json.Result.SuspiciousAddonFiles -ne 1 -or $json.Result.Ports.Count -ne 0) { throw 'Audit evidence is incorrect' }
    $before = (Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash
    Invoke-Headless $arguments 2
    if ((Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash -ne $before) { throw 'Existing report changed' }
    Invoke-Headless '--invalid' 2
    Write-Output 'PASS: packaged unattended workflow, report content, existing-output protection, argument exits and no desktop window'
}
finally {
    $resolved = [IO.Path]::GetFullPath($root)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolved.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or !([IO.Path]::GetFileName($resolved)).StartsWith('Rackwatch-headless-')) { throw 'Unsafe cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
