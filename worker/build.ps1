cd daemon/hub
go build -o ../../package/hub.exe cmd/main.go
cd ..
go build -o ../package/daemon.exe cmd/main.go
cd ..
cd sunshine/build
ninja
cd ../../
del package/libsunshine.dll
del package/test.exe
copy sunshine/build/libsunshine.dll ./package/libsunshine.dll
copy sunshine/build/test.exe ./package/test.exe
