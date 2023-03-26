$env:Path += ';C:\gstreamer\1.22.0\msvc_x86_64\bin'
$env:PKG_CONFIG_PATH = "C:\gstreamer\1.22.0\msvc_x86_64\lib\pkgconfig"


# build GO 
go clean --cache

Set-Location .\worker\webrtc
go build -o hub.exe  ./cmd/server/
Set-Location ../../

Remove-Item "./package/hub/bin/hub.exe"
robocopy .\worker\webrtc package/hub/bin hub.exe
Remove-Item "./worker/webrtc/hub.exe"
