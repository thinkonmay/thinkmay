cd worker
./build.ps1
cd ..

cd app/moonlight
.\scripts\build-arch.bat release x64
cd ../..

cd browser/win11
npm i
npm run tauri build
cd ../..

copy ./browser/win11/src-tauri/target/release/thinkmay.exe ./worker/package/thinkmay.exe