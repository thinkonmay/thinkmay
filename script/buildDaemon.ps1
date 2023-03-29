# build GO 
go clean --cache

Set-Location .\worker\daemon
go build   -o daemon.exe .
Set-Location ../../

Remove-Item "./package/daemon.exe"
robocopy .\worker\daemon package daemon.exe
Remove-Item "./worker/daemon/daemon.exe"
