#define MyAppName "DailyHQ"
#define MyAppPublisher "DailyHQ"
#define MyAppExeName "daily_hq.exe"
#define MyAppVersion GetFileVersion(SourcePath + "\..\build\windows\x64\runner\Release\" + MyAppExeName)

[Setup]
AppId={{7AE5590D-F24D-47C5-90CC-C6EC4F4DA909}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=..\build\installer
OutputBaseFilename=DailyHQ-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#MyAppName}\Quick Thought"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--quick-thought"; WorkingDir: "{app}"; HotKey: "ctrl+alt+t"; Comment: "Open DailyHQ Quick Thought (Ctrl+Alt+T)"
Name: "{autoprograms}\{#MyAppName}\Quick Journal"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--quick-journal"; WorkingDir: "{app}"; HotKey: "ctrl+alt+j"; Comment: "Open DailyHQ Journal (Ctrl+Alt+J)"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
