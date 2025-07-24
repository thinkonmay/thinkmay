;--------------------------------
;General information

;The name of the installer
Name "g4play"

;The output file path of the installer to be created
OutFile "g4play.exe"

;The default installation directory
InstallDir "$DESKTOP\thinkmay"

;Request application privileges for user level privileges
RequestExecutionLevel user


;--------------------------------
;Installer pages

;Show a page where the user can customize the install directory
Page directory
;Show a page where the progress of the install is listed
Page instfiles


;--------------------------------
;Installer Components

;A section for each component that should be installed
Section "Component Name"

  ;Set output path to the installation directory
  SetOutPath $INSTDIR
  File ".\assets\daemon.exe"
  File ".\assets\turn.json"
  File ".\assets\timeout.json"
  File ".\assets\sessionIDs.json"
  File ".\assets\cluster.yaml"

  SetOutPath "$INSTDIR\storage"
  File ".\assets\storage\*"

  SetOutPath "$INSTDIR\store"
  File ".\assets\store\*"

  SetOutPath "$INSTDIR\store\localization"
  File ".\assets\store\localization\*"

SectionEnd

Section "Register protocol" ; 
  WriteRegStr HKCU "Software\Classes\thinkmay" "" "thinkmay procotol"
  WriteRegStr HKCU "Software\Classes\thinkmay" "URL Protocol" ""
  WriteRegStr HKCU "Software\Classes\thinkmay\shell\open\command" "" '"$INSTDIR\daemon.exe" "%1"'
SectionEnd
