# Rackwatch

A local Windows server inventory and troubleshooting console. Choose a server folder, run checks, and inspect findings and log previews. Scans do not modify server files or connect to a hosting account.

## Version 2.0.1

- Export portable JSON evidence and a standalone, human-readable HTML health report.
- Every report includes a deterministic A-F health grade and 0-100 risk score.
- Stage report exports before replacement, preserving existing target metadata and keeping the previous report intact if a write fails.

- Scan once in the background, with **Cancel scan** available while work runs.
- Skip symbolic links and junctions, including cycles. Unreadable paths produce a partial scan and visible findings.
- Classify addon and Workshop files by folder segments relative to the selected root, avoiding false counts from parent-folder names.
- Count empty addon/Workshop files, unreadable ZIP indexes and read failures as findings.
- Show logs by relative path so two `server.log` files remain distinct. UTF-8 previews read at most 64 KiB and display at most 5,000 characters.
- Distinguish readable ZIP indexes, failed ZIP checks and unsupported `.7z` archives. No archive is extracted or restored.
- Package Windows dependencies inside the standalone EXE.

## Run

Open `Rackwatch.exe`, choose **Choose server**, and then **Run checks**. You can also preselect a folder without starting a scan:

```powershell
.\Rackwatch.exe --folder "C:\Servers\Example"
```

The optional port check connects to localhost over TCP. It does not test UDP game-server availability, remote servers, or application health. Process counts match the selected folder's name and do not establish that a server is healthy.

ZIP checks read archive indexes only; they do not prove payload integrity or that a backup will restore. `.7z` content is not inspected. Files over 10 MiB are excluded from artifact hashing and included in the not-hashed count; computed hashes are not compared with a trusted baseline. Files can change during a live scan. Link skipping is not a security boundary against concurrent hostile filesystem changes.

## Build and validate

```powershell
dotnet run --project tests/ServerAuditTests.csproj -c Release
powershell -NoProfile -File tests/Test-Release.ps1
```

The engine suite uses temporary fixtures, including junctions and a permission-denied directory whose permissions are restored during cleanup. The release test opens the published desktop application and operates its controls, so run it on an available Windows desktop. GitHub Actions runs both suites on Windows. The **Verify published release** workflow tests the exact downloadable EXE on the runner.

See [VALIDATION.md](VALIDATION.md) for the release checks and limits.

## Principles

- No telemetry and no credential collection.
- Read-only checks before any mutating action.
- Clear evidence for every finding.
- Backups and rollback before future writes.

## License

MIT.

## Name change

Rackwatch replaces OpenServerOps. New builds use Rackwatch.exe and Rackwatch.csproj. Existing releases remain available under their original names.

Existing settings and data locations retain the OpenServerOps folder name for compatibility. Keep these folders when upgrading; no automatic move or data format change is required.

## Unattended server audits

Version 2.2.0 supports scheduled audits without opening a window:

```powershell
$p = Start-Process .\Rackwatch.exe -WindowStyle Hidden -ArgumentList '--scan --folder "C:\Servers\Example" --output "C:\Reports\audit.json" --fail-on-findings' -Wait -PassThru
$p.ExitCode
```

The output directory must exist and the JSON filename must be new, outside the scanned server folder. Reports contain the same inventory, risk grade, coverage and read issues as desktop scans. The command never changes server files or replaces an existing report.

No network probes run by default. Add `--ports 27015,27016` to check up to 32 distinct localhost TCP ports. With `--fail-on-findings`, exit 3 means the report was written with findings, skipped links or an unreachable requested port. Exit 0 means export succeeded, 2 means invalid arguments, and 1 means the scan or export failed. A two-minute cancellation budget is checked between filesystem operations. Use the report's coverage fields when deciding whether a scan is complete.

## Automatic setup

Windows setup packages install Rackwatch for your current account, bundle the .NET runtime, create a Start menu shortcut and register an uninstaller. A desktop shortcut is optional. No administrator password or manual file copying is required. Existing settings and saved data stay in their current locations. The portable ZIP remains available.

Download `Rackwatch-v2.2.0-setup.exe` from Releases and run it.

For unattended deployment:

```powershell
Start-Process .\Rackwatch-v2.2.0-setup.exe -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' -Wait -PassThru
```

Build from source with the [open-source Inno Setup compiler](https://github.com/jrsoftware/issrc) installed:

```powershell
pwsh -File scripts/Build-Setup.ps1 -Verify
```

The verification option installs into a temporary test folder, checks reinstall and launch, then uninstalls. It runs on the hosted Windows runner during CI. It does not remove existing user settings or backups.
