#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

#define AppName "Wbs Player"
#define AppExeName "wbs_player.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{B9F8A2C1-E4D3-4F6A-9B51-72C2D56E1A10}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\Wbs Player
DefaultGroupName={#AppName}
OutputDir=..\build\installer
OutputBaseFilename=wbs_player-setup
ArchitecturesInstallIn64BitMode=x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#AppExeName}

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked
