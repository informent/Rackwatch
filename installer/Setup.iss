#ifndef AppVersion
  #error AppVersion must be supplied
#endif
#ifndef PayloadDir
  #error PayloadDir must be supplied
#endif
#ifndef OutputDir
  #error OutputDir must be supplied
#endif
[Setup]
AppId={{3DF36DF9-4462-5623-8978-FBBFD49C29F0}
AppName=Rackwatch
AppVersion={#AppVersion}
AppPublisher=informent
AppPublisherURL=https://github.com/informent/Rackwatch
DefaultDirName={localappdata}\Programs\Rackwatch
DefaultGroupName=Rackwatch
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir={#OutputDir}
OutputBaseFilename=Rackwatch-v{#AppVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\Rackwatch.exe
CloseApplications=yes
CloseApplicationsFilter=Rackwatch.exe
RestartApplications=no
SetupLogging=yes
[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked
[Files]
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Excludes: "*.pdb"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{autoprograms}\Rackwatch"; Filename: "{app}\Rackwatch.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Rackwatch"; Filename: "{app}\Rackwatch.exe"; WorkingDir: "{app}"; Tasks: desktopicon
[Run]
Filename: "{app}\Rackwatch.exe"; Description: "Open Rackwatch"; Flags: nowait postinstall skipifsilent unchecked
