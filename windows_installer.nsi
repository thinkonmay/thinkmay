;--------------------------------
;General information

;The name of the installer
Name "Example Installer Name"

;The output file path of the installer to be created
OutFile "installer.exe"

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
  File ".\assets\*"

  SetOutPath "$INSTDIR\display"
  File ".\assets\display\*"

  SetOutPath "$INSTDIR\audio"
  File ".\assets\audio\*"

  SetOutPath "$INSTDIR\microphone"
  File ".\assets\microphone\*"

  SetOutPath "$INSTDIR\gamepad"
  File ".\assets\gamepad\*"

  SetOutPath "$INSTDIR\service"
  File ".\assets\service\*"

  SetOutPath "$INSTDIR\storage"
  File ".\assets\storage\*"

  SetOutPath "$INSTDIR\store"
  File ".\assets\store\*"

  SetOutPath "$INSTDIR\directx"
  File ".\assets\directx\*"

  SetOutPath "$INSTDIR\directx\include"
  File ".\assets\directx\include\*"

SectionEnd