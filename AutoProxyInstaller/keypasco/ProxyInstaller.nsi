; ProxyInstaller.nsi
;
; This script is based on example1.nsi but it remembers the directory, 
; has uninstall support and (optionally) installs start menu shortcuts.
;
; It will install ProxyInstaller.nsi into a directory that the user selects.
;
; See install-shared.nsi for a more robust way of checking for administrator rights.
; See install-per-user.nsi for a file association example.

;--------------------------------

; The name of the installer
Name "ProxyInstaller"

; The file to write
OutFile "ProxyInstaller.exe"

; Request application privileges for Windows Vista and higher
RequestExecutionLevel admin

; Build Unicode installer
Unicode True

; The default installation directory
InstallDir C:\Keypasco\KeypascoProxyInstaller

; Registry key to check for directory (so if you install again, it will 
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_ProxyInstaller" "Install_Dir"

;--------------------------------

; Pages

; Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "ProxyInstaller (required)"

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  ; File "ProxyInstaller.nsi"
  File /r ".\KeypascoProxyInstaller\*.*" ;
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_ProxyInstaller "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxyInstaller" "DisplayName" "NSIS ProxyInstaller"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxyInstaller" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxyInstaller" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxyInstaller" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
SectionEnd

Section "Run the program"
  ; ExecWait 'powershell.exe Unblock.bat'
  ; ExecWait 'powershell.exe ProxyInstall.ps1'
SectionEnd


; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\ProxyInstaller"
  CreateShortcut "$SMPROGRAMS\ProxyInstaller\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$SMPROGRAMS\ProxyInstaller\ProxyInstaller (MakeNSISW).lnk" "$INSTDIR\ProxyInstaller.nsi"

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxyInstaller"
  DeleteRegKey HKLM SOFTWARE\NSIS_ProxyInstaller

  ; Remove files and uninstaller
  Delete $INSTDIR\uninstall.exe
  Delete $INSTDIR\*
  Delete $INSTDIR\files\*
  Delete $INSTDIR\backup\*
  Delete $INSTDIR\doc\*
  Delete $INSTDIR\rpm\*

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\ProxyInstaller\*.lnk"

  ; Remove directories
  RMDir "$INSTDIR\files"
  RMDir "$INSTDIR\backup"
  RMDir "$INSTDIR\doc"
  RMDir "$INSTDIR\rpm"
  RMDir "$SMPROGRAMS\ProxyInstaller"
  RMDir "$INSTDIR"

SectionEnd
