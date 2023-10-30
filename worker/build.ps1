cd daemon/hub
go build -o ../package/hub.exe cmd/main.go
cd ..
go build -o ./package/daemon.exe cmd/main.go
cd ..
cd sunshine/build
ninja
cd ../../
copy sunshine/build/libsunshine.dll daemon/package/libsunshine.dll
