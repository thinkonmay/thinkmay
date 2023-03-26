$env:Path += ';C:\gstreamer\1.22.0\msvc_x86_64\bin'
$env:PKG_CONFIG_PATH = "C:\gstreamer\1.22.0\msvc_x86_64\lib\pkgconfig"

git submodule update --init --recursive

# install gstreamer
# mkdir artifact
# Invoke-WebRequest -Uri "https://github.com/thinkonmay/thinkremote-rtchub/releases/download/asset-gstreamer-1.22.0/lib.zip" -OutFile artifact/lib.zip 
# Expand-Archive artifact/lib.zip -DestinationPath  package/hub


# build GO 
go clean --cache

Set-Location .\worker\daemon
go build -ldflags -H=windowsgui -o daemon.exe
Set-Location ../../

Set-Location .\worker\webrtc
go build -o hub.exe  ./cmd/server/
Set-Location ../../



robocopy .\worker\daemon package daemon.exe
robocopy .\worker\webrtc package/hub/bin hub.exe

Remove-Item "./worker/hub/hub.exe"
Remove-Item "./worker/daemon/daemon.exe"

# build .NET
Set-Location .\worker\hid
dotnet build . --output "bin" --self-contained true --runtime win-x64
Set-Location ../..

robocopy .\worker\hid\bin package/hid

robocopy .\worker\daemon\tools .\package\tools thinkremote-svc.exe
robocopy .\worker\daemon\scripts .\package\scripts 

# Compress-Archive .\package -DestinationPath .\artifact\thinkremote.zip 