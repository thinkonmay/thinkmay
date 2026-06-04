Thinkmay Client

Run ./thinkmay-client with a Thinkmay remote URL or explicit connection flags.

This package is dynamically linked against the runner-provided SDL2 and FFmpeg libraries. On Linux systems, install the matching SDL2 and FFmpeg runtime packages if the binary cannot find shared libraries at startup.

---
Custom URL Handler Registration:
To register the 'thinkmay:' URL scheme in your Linux desktop environment:
1. Copy 'thinkmay-client.desktop' to '~/.local/share/applications/'
2. The desktop file invokes 'thinkmay-client' via the system PATH. You must either:
   a. Symlink or copy the 'thinkmay-client' script into a directory in your PATH (e.g., ~/.local/bin/ or /usr/local/bin/)
   b. Or edit '~/.local/share/applications/thinkmay-client.desktop' and modify the 'Exec=' line to point to the absolute path of the wrapper script (e.g., 'Exec=/absolute/path/to/thinkmay-client -url %u')
3. Run: xdg-mime default thinkmay-client.desktop x-scheme-handler/thinkmay
4. Update the desktop database: update-desktop-database ~/.local/share/applications/
