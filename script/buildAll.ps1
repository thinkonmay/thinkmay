$env:Path += ';C:\gstreamer\1.22.0\msvc_x86_64\bin'
$env:PKG_CONFIG_PATH = "C:\gstreamer\1.22.0\msvc_x86_64\lib\pkgconfig"

git submodule update --init --recursive


# build GO 
go clean --cache

Set-Location .\worker\daemon
go build  -o daemon.exe ./cmd/
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

Compress-Archive .\package -DestinationPath .\artifact\thinkremote.zip 