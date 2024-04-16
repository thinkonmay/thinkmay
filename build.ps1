cd worker

cd webrtc
go build -o ../../binary/hub.exe -buildvcs=false ./cmd/
cd ..

cd daemon
go build -o ../../binary/daemon.exe -buildvcs=false ./service/window/
cd ..

cd sunshine/build
ninja
cd ../../
del ../binary/shmsunshine.exe
del ../binary/libparent.dll
copy sunshine/build/sunshine.exe ../binary/shmsunshine.exe
copy sunshine/build/libparent.dll ../binary/libparent.dll

cd ..

# cd app/moonlight
# .\scripts\build-arch.bat release x64
# cd ../..

# cd app/demo
# npm i
# npm run tauri build -- --debug
# cd ../..

# cd browser/win11
# npm i
# npm run tauri build
# cd ../..

# copy ./browser/win11/src-tauri/target/release/thinkmay.exe ./binary/thinkmay.exe
# copy ./app/demo/src-tauri/target/release/moonlight.exe ./binary/moonlight.exe