Thinkmay Client

Run ./thinkmay-client with a Thinkmay remote URL or explicit connection flags.

This package is dynamically linked against the runner-provided SDL2 and FFmpeg libraries. On Linux systems, install the matching SDL2 and FFmpeg runtime packages if the binary cannot find shared libraries at startup.

---
Custom URL Handler Registration:
To register the 'thinkmay:' URL scheme in your Linux desktop environment:
1. Copy 'thinkmay-client.desktop' to '~/.local/share/applications/'
2. Run: xdg-mime default thinkmay-client.desktop x-scheme-handler/thinkmay
3. Update the desktop database: update-desktop-database ~/.local/share/applications/
