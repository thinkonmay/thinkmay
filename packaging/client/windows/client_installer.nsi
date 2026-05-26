;--------------------------------
; Thinkmay client installer

Name "Thinkmay Client"
OutFile "thinkmay-client-windows-amd64-installer.exe"
InstallDir "$LOCALAPPDATA\Thinkmay\Client"
RequestExecutionLevel user

;--------------------------------
; Pages

Page directory
Page instfiles

;--------------------------------
; Installation

Section "Thinkmay Client"
  SetOutPath $INSTDIR
  File /r ".\artifacts\windows\*"

  CreateDirectory "$SMPROGRAMS\Thinkmay"
  CreateShortcut "$SMPROGRAMS\Thinkmay\Thinkmay Client.lnk" "$INSTDIR\thinkmay-client.exe"
  CreateShortcut "$DESKTOP\Thinkmay Client.lnk" "$INSTDIR\thinkmay-client.exe"

  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

;--------------------------------
; Uninstall

Section "Uninstall"
  Delete "$SMPROGRAMS\Thinkmay\Thinkmay Client.lnk"
  Delete "$DESKTOP\Thinkmay Client.lnk"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
SectionEnd
