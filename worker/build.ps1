cd daemon/hub
go build -o ../../package/hub.exe ./cmd/
cd ..
go build -o ../package/daemon.exe ./service/window/
cd ..
cd sunshine/build
ninja
cd ../../
del package/libsunshine.dll
copy sunshine/build/libsunshine.dll ./package/libsunshine.dll