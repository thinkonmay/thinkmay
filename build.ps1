cd worker

cd webrtc
go build -o ../../binary/hub.exe ./cmd/
cd ..

cd daemon
go build -o ../../binary/daemon.exe ./service/window/
cd ..

cd sunshine/build
ninja
cd ../../
del ../binary/libsunshine.dll
copy sunshine/build/libsunshine.dll ../binary/libsunshine.dll

cd ..

cd app/moonlight
.\scripts\build-arch.bat release x64
cd ../..

cd app/demo
npm i
npm run tauri build -- --debug
cd ../..

cd browser/win11
npm i
npm run tauri build
cd ../..

copy ./browser/win11/src-tauri/target/release/thinkmay.exe ./binary/thinkmay.exe
copy ./app/demo/src-tauri/target/release/moonlight.exe ./binary/moonlight.exe