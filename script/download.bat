powershell Invoke-WebRequest -Uri https://gstreamer.freedesktop.org/data/pkg/windows/1.22.0/msvc/gstreamer-1.0-msvc-x86_64-1.22.0-merge-modules.zip -OutFile artifact/gstreamer.zip 
cd artifact && powershell Expand-Archive gstreamer.zip -DestinationPath . 
robocopy ./projects/repos/cerbero.git msm
rmdir /s /q "./projects"
del gstreamer.zip
cd ..