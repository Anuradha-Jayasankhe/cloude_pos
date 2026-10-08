#define AppName "StoreBuddy POS"
#define AppPublisher "StoreBuddy"

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#ifndef AppExeName
  #define AppExeName "store_buddy_pos.exe"
#endif

#ifndef SourceDir
  #define SourceDir "..\\build\\windows\\x64\\runner\\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\\build\\windows\\installer"
#endif

[Setup]
AppId={{4E9D3AC3-17FD-4A7B-A98F-8FA48A4C4B63}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Programs\{#AppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=store-buddy-pos-windows-{#AppVersion}-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent