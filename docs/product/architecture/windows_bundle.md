# Windows bundle and installer flow

This document describes how the Windows executable bundle is produced by `.github/workflows/window.yml`, how the final installed/bundled directory is shaped, and where new Windows binaries such as the ZeroClaw assistant plugin should fit.

## CI workflow overview

The Windows workflow has four relevant jobs:

1. `build_sunshine`
2. `build_daemon`
3. `build_package`
4. `publish`

The first two jobs build standalone executables and upload GitHub Actions artifacts. `build_package` downloads those artifacts, overlays them into the Windows assets directory, runs NSIS, and uploads `installer.exe`. `publish` uploads the installer to the binaries collection.

## Sunshine build artifact

Job: `build_sunshine`

Runner: `windows-2025`

Build steps:

```powershell
cd ./worker/sunshine
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -G "Ninja" ..
ninja
```

Packaging step:

```powershell
mkdir -p artifacts
cp ./worker/sunshine/build/sunshine.exe ./artifacts/shmsunshine.exe
```

Uploaded artifact:

```text
sunshine-windows
```

Important output file:

```text
shmsunshine.exe
```

## Daemon build artifact

Job: `build_daemon`

Runner: `windows-2025`

Build steps:

```powershell
cd ./worker/daemon
go mod download
go build -o daemon.exe ./cmd/
go build -o pb.exe ./cmd/pocketbase/
```

Packaging step:

```powershell
mkdir -p artifacts
cp ./worker/daemon/daemon.exe ./artifacts/daemon.exe
cp ./worker/daemon/pb.exe ./artifacts/pb.exe
```

Uploaded artifact:

```text
daemon-windows
```

Important output files:

```text
daemon.exe
pb.exe
```

Note: the current NSIS installer only copies `daemon.exe` from the downloaded daemon artifact into `assets`. `pb.exe` is uploaded in the daemon artifact but is not currently copied into the final `assets` directory by `build_package`.

## Package job

Job: `build_package`

Runner: `windows-2025`

Inputs:

- `sunshine-windows` artifact downloaded into `sunshine/`
- `daemon-windows` artifact downloaded into `daemon/`
- external Windows assets repo cloned with:

```powershell
git clone https://github.com/thinkonmay/assets -b win
```

Additional package input:

```powershell
curl -o ivshmem.tar.gz https://dl.quantum2.xyz/ivshmem.tar.gz
tar -xf ivshmem.tar.gz -C ./assets
rm ivshmem.tar.gz
```

The package job overlays CI-built executables into the cloned `assets` tree:

```powershell
mkdir -p artifacts
cp daemon/daemon.exe ./assets
cp sunshine/shmsunshine.exe ./assets

./nsis.ps1
cp installer.exe ./artifacts
```

Uploaded artifact:

```text
msi-windows
```

Important output file:

```text
installer.exe
```

## NSIS packaging

`nsis.ps1` is a small wrapper around NSIS:

```powershell
makensis windows_installer.nsi
```

`windows_installer.nsi` creates:

```text
installer.exe
```

Default install directory:

```text
$DESKTOP\thinkmay
```

The installer copies the root of `assets` to the installation directory:

```nsi
SetOutPath $INSTDIR
File ".\assets\*"
```

Then it copies selected asset subdirectories:

```nsi
SetOutPath "$INSTDIR\display"
File ".\assets\display\*"

SetOutPath "$INSTDIR\ivshmem"
File ".\assets\ivshmem\*"

SetOutPath "$INSTDIR\audio"
File ".\assets\audio\*"

SetOutPath "$INSTDIR\microphone"
File ".\assets\microphone\*"

SetOutPath "$INSTDIR\gamepad"
File ".\assets\gamepad\*"

SetOutPath "$INSTDIR\service"
File ".\assets\service\*"

SetOutPath "$INSTDIR\storage"
File ".\assets\storage\*"

SetOutPath "$INSTDIR\assistant"
File ".\assets\assistant\*"

SetOutPath "$INSTDIR\directx"
File ".\assets\directx\*"

SetOutPath "$INSTDIR\directx\include"
File ".\assets\directx\include\*"
```

The installer also registers the `thinkmay://` protocol handler:

```nsi
WriteRegStr HKCU "Software\Classes\thinkmay" "" "thinkmay procotol"
WriteRegStr HKCU "Software\Classes\thinkmay" "URL Protocol" ""
WriteRegStr HKCU "Software\Classes\thinkmay\shell\open\command" "" "$INSTDIR\daemon.exe %1"
```

## Final bundle layout example

`D:\binary` is a useful example of the final bundle/install layout. It contains the runtime executables at the root plus driver/tool subdirectories.

Observed root files include:

```text
D:\binary\cluster.yaml
D:\binary\daemon.exe
D:\binary\exporter.exe
D:\binary\shmsunshine.exe
D:\binary\timeout.json
D:\binary\turn.json
D:\binary\workerinfo.json
```

Observed subdirectories include:

```text
D:\binary\audio\
D:\binary\directx\
D:\binary\display\
D:\binary\gamepad\
D:\binary\ivshmem\
D:\binary\microphone\
D:\binary\service\
D:\binary\storage\
D:\binary\temp\
```

The assistant bundle adds:

```text
$INSTDIR\assistant\
```

Important examples:

```text
D:\binary\daemon.exe
D:\binary\shmsunshine.exe
D:\binary\ivshmem\ivshmem.sys
D:\binary\ivshmem\ivshmem.inf
D:\binary\ivshmem\ivshmem-test.exe
D:\binary\display\MttVDD.dll
D:\binary\display\MttVDD.inf
D:\binary\display\vdd.exe
D:\binary\gamepad\ViGEmClient.dll
D:\binary\gamepad\vigembus.exe
D:\binary\storage\rclone.exe
D:\binary\storage\ludusavi.exe
D:\binary\storage\winfsp.msi
```

This layout matches the NSIS behavior: root-level assets go to `$INSTDIR`, and named subdirectories are copied into matching `$INSTDIR\...` directories.

## Adding the ZeroClaw assistant plugin to the Windows bundle

The assistant plugin is a Rust `cdylib` that builds a Windows DLL:

```text
worker/assistant/target/release/zeroclaw_thinkmay_assistant_channel.dll
```

The plugin should not contain Discord gateway logic or a Discord bot token. It is bundled with the ZeroClaw executable and a launcher script in the assistant folder.

Bundle path inside `assets`:

```text
assets\assistant\zeroclaw.exe
assets\assistant\zeroclaw_thinkmay_assistant_channel.dll
assets\assistant\run.ps1
```

Installed path:

```text
$INSTDIR\assistant\zeroclaw.exe
$INSTDIR\assistant\zeroclaw_thinkmay_assistant_channel.dll
$INSTDIR\assistant\run.ps1
```

`run.ps1` lives beside `zeroclaw.exe` and the plugin DLL. At runtime it copies the plugin DLL into ZeroClaw's user plugin directory:

```text
%USERPROFILE%\.zeroclaw\plugins\zeroclaw_thinkmay_assistant_channel.dll
```

Then it starts:

```powershell
.\zeroclaw.exe daemon
```

Required runtime environment:

```powershell
$env:ASSISTANT_GATEWAY_TOKEN = "<gateway scoped token>"
```

Optional runtime environment:

```powershell
$env:ASSISTANT_GATEWAY_WS_URL = "ws://127.0.0.1:18801/assistant/ws"
$env:ASSISTANT_DISCORD_USER_ID = "<scoped discord user id>"
```

## CI changes for the assistant bundle

The Windows workflow now has a separate assistant plugin build job. It builds our Rust plugin and downloads ZeroClaw's official prebuilt Windows binary using the same release artifact pattern documented by ZeroClaw's `setup.bat`:

```text
https://github.com/zeroclaw-labs/zeroclaw/releases/latest/download/zeroclaw-x86_64-pc-windows-msvc.zip
```

```yaml
build_assistant_plugin:
  name: Assistant Plugin Win
  runs-on: windows-2025
  steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive
        token: ${{ secrets.GH_TOKEN }}
    - name: Setup Rust
      uses: dtolnay/rust-toolchain@stable
    - name: Build assistant plugin
      run: |
        cd ./worker/assistant
        cargo build --release
    - name: Download ZeroClaw prebuilt binary
      shell: powershell
      run: |
        $ErrorActionPreference = "Stop"
        $url = "https://github.com/zeroclaw-labs/zeroclaw/releases/latest/download/zeroclaw-x86_64-pc-windows-msvc.zip"
        curl -L -o zeroclaw-windows.zip $url
        New-Item -ItemType Directory -Force -Path zeroclaw-prebuilt | Out-Null
        tar -xf zeroclaw-windows.zip -C zeroclaw-prebuilt
        $exe = Get-ChildItem -Path zeroclaw-prebuilt -Recurse -Filter zeroclaw.exe | Select-Object -First 1
        if (-not $exe) {
          throw "zeroclaw.exe was not found in the ZeroClaw prebuilt release zip"
        }
        Copy-Item $exe.FullName ./zeroclaw.exe -Force
    - name: Package assistant plugin
      shell: powershell
      run: |
        $ErrorActionPreference = "Stop"
        New-Item -ItemType Directory -Force -Path artifacts | Out-Null
        Copy-Item ./worker/assistant/target/release/zeroclaw_thinkmay_assistant_channel.dll ./artifacts/zeroclaw_thinkmay_assistant_channel.dll -Force
        Copy-Item ./worker/assistant/run.ps1 ./artifacts/run.ps1 -Force
        Copy-Item ./zeroclaw.exe ./artifacts/zeroclaw.exe -Force
    - uses: actions/upload-artifact@v4
      with:
        name: assistant-plugin-windows
        path: artifacts
```

`build_package` depends on the assistant plugin build:

```yaml
needs: [build_daemon, build_sunshine, build_assistant_plugin]
```

It downloads the assistant artifact:

```yaml
- uses: actions/download-artifact@v4
  name: download assistant plugin
  with:
    name: assistant-plugin-windows
    path: assistant-plugin
```

Then it creates the final assistant bundle before `./nsis.ps1`:

```powershell
mkdir -p ./assets/assistant
cp assistant-plugin/zeroclaw_thinkmay_assistant_channel.dll ./assets/assistant/zeroclaw_thinkmay_assistant_channel.dll
cp assistant-plugin/run.ps1 ./assets/assistant/run.ps1
cp assistant-plugin/zeroclaw.exe ./assets/assistant/zeroclaw.exe
```

The package step does not rely on the Thinkmay assets repo for `zeroclaw.exe`; it uses the `zeroclaw.exe` downloaded from ZeroClaw's official prebuilt Windows release in `build_assistant_plugin`.

`windows_installer.nsi` copies the assistant folder into the final install:

```nsi
SetOutPath "$INSTDIR\assistant"
File ".\assets\assistant\*"
```

## Recommended verification

Verify final install/bundle layout resembles:

```text
$INSTDIR\daemon.exe
$INSTDIR\shmsunshine.exe
$INSTDIR\cluster.yaml
$INSTDIR\display\...
$INSTDIR\ivshmem\...
$INSTDIR\storage\...
$INSTDIR\assistant\zeroclaw.exe
$INSTDIR\assistant\zeroclaw_thinkmay_assistant_channel.dll
$INSTDIR\assistant\run.ps1
```

## Publish step

After packaging, the workflow publishes `installer.exe` by computing its MD5 and uploading it:

```bash
MD5_CHECKSUM=$(md5sum "./artifacts/installer.exe" | cut -d ' ' -f 1)
curl https://saigon2.thinkmay.net/api/collections/binaries/records \
  -H "Content-Type: multipart/form-data" \
  --form "name=thinkmay_binary_window" \
  --form "md5sum=${MD5_CHECKSUM}" \
  --form "file=@./artifacts/installer.exe"
```

Adding the assistant plugin to the assets tree changes the final `installer.exe`, but does not require a separate publish path unless the plugin should also be distributed independently.
