;--------------------------------
; Thinkmay client installer

Name "Thinkmay Client"
OutFile "thinkmay-client-windows-amd64-installer.exe"
InstallDir "$LOCALAPPDATA\Thinkmay\Client"
RequestExecutionLevel user

Icon "images\logo.ico"
UninstallIcon "images\logo.ico"

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

  ; Register custom URL protocol handler (thinkmay:)
  WriteRegStr HKCU "Software\Classes\thinkmay" "" "URL:thinkmay Protocol"
  WriteRegStr HKCU "Software\Classes\thinkmay" "URL Protocol" ""
  WriteRegStr HKCU "Software\Classes\thinkmay\shell\open\command" "" '"$INSTDIR\thinkmay-client.exe" -url "%1"'

  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

;--------------------------------
; Uninstall

Section "Uninstall"
  Delete "$SMPROGRAMS\Thinkmay\Thinkmay Client.lnk"
  Delete "$DESKTOP\Thinkmay Client.lnk"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"

  ; Unregister custom URL protocol handler
  DeleteRegKey HKCU "Software\Classes\thinkmay"
SectionEnd
