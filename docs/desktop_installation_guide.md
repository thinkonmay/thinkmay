# Thinkmay Desktop Client Installation Guide

This document outlines the installation procedure for the Thinkmay native Go desktop client across Windows, macOS, and Linux platforms. It covers packaging formats, installer flows, file layouts, and the registration of the `thinkmay://` custom URL scheme handler.

---

## 1. Windows Installation

Windows distribution supports both a standalone `.zip` archive for portable execution and an automated NSIS installer (`.exe`).

### Installer Specifications
- **Format**: NSIS Installer (`thinkmay-client-windows-amd64-installer.exe`)
- **Default Directory**: `$LOCALAPPDATA\Thinkmay\Client`
- **Privilege Level**: User-level (`RequestExecutionLevel user`). Does **not** require Administrator rights.

### Installation Flow
1. The installer extracts files from the build artifacts (`thinkmay-client.exe`, `thinkmay-cli.exe`, along with required Windows runtime DLLs for FFmpeg and SDL2) to the `$INSTDIR`.
2. Creates shortcuts:
   - Start Menu: `$SMPROGRAMS\Thinkmay\Thinkmay Client.lnk`
   - Desktop: `$DESKTOP\Thinkmay Client.lnk`
3. Registers the `thinkmay://` protocol handler in the current user's registry hive:
   ```registry
   HKCU\Software\Classes\thinkmay
     (Default) = "URL:thinkmay Protocol"
     URL Protocol = ""
   
   HKCU\Software\Classes\thinkmay\shell\open\command
     (Default) = '"$INSTDIR\thinkmay-client.exe" -url "%1"'
   ```
4. Generates `$INSTDIR\uninstall.exe` for cleanup.

### Uninstallation Flow
1. Deletes the Start Menu and Desktop shortcuts.
2. Recursively removes `$INSTDIR` and all files.
3. Deletes the registry key `HKCU\Software\Classes\thinkmay` to unregister the protocol.

---

## 2. macOS Installation

macOS distribution packages the binary into a standard self-contained application bundle.

### Bundle Specifications
- **Format**: App Bundle (`Thinkmay Client.app`) distributed inside a `.zip` archive or a `.dmg` disk image.
- **Default Directory**: `/Applications` (system-wide) or `~/Applications` (user-level).
- **Architecture Support**: Native `arm64` (Apple Silicon) and `amd64` (Intel).

### Installation Flow
1. Users mount the `.dmg` file and drag the `Thinkmay Client.app` bundle into `/Applications`.
2. **Library Linking Resolution**:
   During the packaging pipeline, dynamic dependencies (FFmpeg, SDL2) are copied directly to `Thinkmay Client.app/Contents/Frameworks/`. The pipeline executes `install_name_tool` to update dynamic loader paths inside the main binary to `@executable_path/../Frameworks/` to ensure offline self-containment.
3. **Custom URL handler Registration**:
   The custom scheme is declared in `Thinkmay Client.app/Contents/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key>
       <string>Thinkmay Client URL</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>thinkmay</string>
       </array>
     </dict>
   </array>
   ```
   Upon copying the application bundle to the Applications folder, macOS LaunchServices automatically parses `Info.plist` and registers the `thinkmay://` URL scheme handler.

---

## 3. Linux Installation

Linux distribution supports both a Debian package (`.deb`) and a standalone portable tarball (`.tar.gz`).

### 3.1 Debian Package Installation (`.deb`)
The `.deb` package installs files into standard system locations and requires administrative privileges.

- **Installation Directory**: `/usr/share/thinkmay-client/`
- **Execution Script**: Installs a wrapper script to `/usr/bin/thinkmay-client` that sets up `LD_LIBRARY_PATH` before invoking the binary:
  ```bash
  #!/bin/bash
  export LD_LIBRARY_PATH="/usr/share/thinkmay-client/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  exec "/usr/share/thinkmay-client/thinkmay-client-bin" "$@"
  ```
- **Desktop Entry**: Installs a desktop entry to `/usr/share/applications/thinkmay-client.desktop` declaring:
  ```ini
  Exec=/usr/bin/thinkmay-client -url %u
  MimeType=x-scheme-handler/thinkmay;
  ```
- **Post-Install Trigger**:
  Updates the system MIME database:
  ```bash
  update-desktop-database -q /usr/share/applications || true
  ```

### 3.2 Tarball Manual Installation (`.tar.gz`)
The tarball allows manual extraction and registration in a user's home directory.

1. **Extraction**: Extract to a local directory, for example, `~/bin/thinkmay-client`.
2. **MIME Association**:
   Copy the provided `.desktop` file to the local applications directory:
   ```bash
   cp thinkmay-client.desktop ~/.local/share/applications/
   ```
3. **Registration**:
   Bind the scheme default handler and refresh the desktop databases:
   ```bash
   xdg-mime default thinkmay-client.desktop x-scheme-handler/thinkmay
   update-desktop-database ~/.local/share/applications/
   ```
   > [!IMPORTANT]
   > Users must ensure the executable script is available in their shell `$PATH` or edit the `Exec=` path in the local `.desktop` file to use the absolute path to their extracted wrapper.

---

## 4. Custom URL Scheme Integration Reference

Regardless of the platform-specific launching mechanism, opening a `thinkmay:` link flows into the client config parser similarly:

| Operating System | URL Dispatch Route | Executed CLI Output Command |
| --- | --- | --- |
| **Windows** | Windows Shell API (Registry Command) | `thinkmay-client.exe -url "thinkmay:..."` |
| **macOS** | Cocoa Event Loop (`kAEGetURL` AppleEvent) | Internal application capture (`getMacOSURL()`) |
| **Linux** | Desktop Environment MIME system | `thinkmay-client -url "thinkmay:..."` |

### Parameter Mapping Summary
When launched via custom URL handler, the client strips the `thinkmay:` prefix and parses query parameters.
- **Required**: `vmid`, `video` (or `token`).
- **Optional**: `audio`, `mic`, `data` (enables inputs), `codec`, `usb` (requires `data`).
- **Overrides**: Explicit command-line arguments override any parameters passed via URL.
