# Desktop client launch arguments and URL search parameters

This document is the launch contract for the native Go desktop client (`thinkmay-client`). It lists every supported CLI argument and the URL search parameters that can set those arguments when the app is launched through the `thinkmay:` custom URL handler.

For the custom protocol registration itself, see `docs/product/architecture/desktop_client_url_handler.md`. For the media architecture after startup, see `docs/desktop_client_architecture.md`.

## Configuration sources and precedence

The desktop client builds one `client/config.Config` from these sources:

1. Built-in defaults from `worker/proxy/client/config/config.go`.
2. CLI flags.
3. URL search parameters from `-url` or a positional `thinkmay:` URL.

Explicit CLI flags override URL search parameters. For example:

```powershell
thinkmay-client.exe -url "thinkmay:https://thinkmay.net/en/remote/?vmid=vm1&video=t1&codec=h265" -codec h264
```

The final codec is `h264`, because `-codec` was explicitly set.

When the first positional argument starts with `thinkmay:`, the parser treats it as the remote URL even without `-url`:

```powershell
thinkmay-client.exe "thinkmay:https://thinkmay.net/en/remote/?vmid=vm1&video=t1"
```

Windows and Linux packaging normally call the client with `-url`; macOS receives the launch URL through the app bundle URL event path.

## Required fields

For a normal streaming launch, the resolved config must include:

| Field | How to provide it |
| --- | --- |
| QUIC address | `-addr`, `addr=`, `server=`, or URL host fallback. |
| VM ID | `-vmid` or `vmid=`. |
| Video listener token | `-token`, `video=`, or `token=`. |

`-usb-list` is the exception: it lists local USB devices and exits before these streaming fields are required.

USB forwarding also requires a HID/data listener token:

```text
-usb requires -data-token or data=<token>
```

## CLI arguments

| Argument | Type | Default | URL search parameters | Purpose |
| --- | --- | --- | --- | --- |
| `-url` | string | empty | n/a | Remote URL or `thinkmay:` custom URL to parse. |
| `-addr` | string | `saigon2.thinkmay.net:50005` without URL; URL host fallback with URL | `addr`, `server` | QUIC endpoint. URL `addr`/`server` default to port `50005`; URL host fallback defaults to port `443`. |
| `-vmid` | string | empty | `vmid` | Target VM ID. |
| `-token` | string | empty | `video`, `token` | Video listener token. |
| `-audio-token` | string | empty | `audio`, `audio-token` | Audio listener token. Enables audio playback when present. |
| `-mic-token` | string | empty | `mic`, `mic-token` | Microphone listener token. Enables microphone capture when present. |
| `-data-token` | string | empty | `data`, `data-token` | HID/data listener token. Enables input and USB forwarding path when present. |
| `-codec` | string | `h264` | `codec` | Video codec. Accepted values: `h264`, `avc`, `h265`, `hevc`, `av1`. Normalized to `h264`, `h265`, or `av1`. |
| `-hwaccel` | string | `auto` | `hwaccel` | FFmpeg hardware decoder preference. Accepted by help text: `auto`, `d3d11va`, `dxva2`, `cuda`, `qsv`, `videotoolbox`, `vaapi`, `vdpau`, `vulkan`, `none`. |
| `-present` | string | `d3d11` on Windows; `sdl` on Linux/macOS | `present` | Presenter backend. Current values include `d3d11`, `sdl`, and `software-debug`. |
| `-width` | integer | `1280` | `width` | Initial window width. |
| `-height` | integer | `720` | `height` | Initial window height. |
| `-fullscreen` | boolean | `true` | `fullscreen` | Start in fullscreen desktop mode. |
| `-vsync` | boolean | `false` | `vsync` | Enable presenter VSync. |
| `-fps` | unsigned integer | `120` | `fps` | Initial remote FPS control sent after connection. |
| `-bitrate` | unsigned integer | `10000` | `bitrate` | Initial remote bitrate control sent after connection. |
| `-stats` | boolean | `true` | `stats` | Enable terminal stats dashboard. |
| `-usb` | boolean | `false` | `usb` | Enable USB forwarding over the HID/data channel. |
| `-usb-list` | boolean | `false` | `usb-list` | List gousb-visible USB devices and exit. |
| `-usb-all` | boolean | `false` | `usb-all` | Forward all currently attached USB devices visible to gousb when USB forwarding is enabled. |
| `-usb-vidpid` | string | empty | `usb-vidpid` | Comma-separated USB allowlist such as `1234:abcd,046d:c534`. |
| `-usb-detach-kernel-driver` | boolean | `false` | `usb-detach-kernel-driver` | Allow USB forwarding to detach kernel drivers from allowlisted devices. |

## URL search-parameter behavior

### Custom scheme stripping

When `RemoteURL` starts with `thinkmay:`, the parser removes that prefix and trims leading slashes before parsing the result as the real URL.

Both examples resolve to the same underlying URL:

```text
thinkmay:https://thinkmay.net/en/remote/?vmid=vm1&video=t1
thinkmay://https://thinkmay.net/en/remote/?vmid=vm1&video=t1
```

### Address selection

Address resolution follows this order unless `-addr` was explicitly provided:

1. `addr=<host-or-hostport>`
2. `server=<host-or-hostport>`
3. Hostname from the parsed URL

Port defaults differ by source:

| Source | Default port |
| --- | --- |
| `addr=` | `50005` |
| `server=` | `50005` |
| URL host fallback | `443` |

Examples:

```text
thinkmay:https://thinkmay.net/en/remote/?vmid=vm1&video=t1
# Addr: thinkmay.net:443

thinkmay:https://thinkmay.net/en/remote/?addr=saigon2.thinkmay.net&vmid=vm1&video=t1
# Addr: saigon2.thinkmay.net:50005

thinkmay:https://thinkmay.net/en/remote/?addr=saigon2.thinkmay.net:50005&vmid=vm1&video=t1
# Addr: saigon2.thinkmay.net:50005
```

### Boolean values

Boolean search parameters accept these true values:

```text
1, t, true, y, yes, on
```

They accept these false values:

```text
0, f, false, n, no, off
```

An empty value means `true`:

```text
?vsync&stats=false
```

In this example, `vsync` is `true` and `stats` is `false`.

### Repeated parameters

If a supported key appears more than once, the parser uses the last value returned for that key.

```text
?codec=h264&codec=h265
```

The final codec is `h265`, unless `-codec` was explicitly supplied on the CLI.

### Unknown web parameters

The native desktop parser ignores unsupported search parameters. It does not consume WebRTC-only parameters such as:

```text
mtu, fec, gcc, max_bitrate, min_bitrate
```

It also ignores website/navigation parameters such as:

```text
ref, log, vnc
```

This is intentional because the native desktop client joins the internal QUIC streaming path, not the browser WebRTC path.

## Website setting migration

When the website's **Open sessions in the Thinkmay desktop app** advanced setting is enabled, `GetStarted` builds a `thinkmay:` launch URL with `BuildDesktopLaunchURL` in `website/core/api/index.ts`. The helper converts the current browser remote state into desktop-supported search parameters.

### Migrated session credentials

| Website source | Desktop search parameter | Notes |
| --- | --- | --- |
| `remote.auth.vmid` or `vmid` from `remote.auth.videoUrl` | `vmid` | Required. |
| `token` from `remote.auth.videoUrl` | `video` | Required video listener token. |
| `token` from `remote.auth.audioUrl` | `audio` | Included when available. |
| `token` from `remote.auth.hidUrl` | `data` | Included when available; used for keyboard, mouse, controller, and USB paths. |
| `token` from `remote.auth.microUrl` | `mic` | Included only when `enable_microphone` is true and a microphone listener exists. |
| `remote.domain` or current worker address | `server` | Included as the desktop QUIC server hint. |

### Migrated remote settings

| Website setting | Desktop search parameter | Mapping rule |
| --- | --- | --- |
| `preferred_codec` | `codec` | Sends `h264` or `h265`. |
| `vsync` | `vsync` | Sends `true` or `false`; this keeps the desktop presenter VSync behavior aligned with the browser setting. |
| `framerate` | `fps` | Sends the rounded FPS value. |
| `disable_gcc`, `min_bitrate`, `max_bitrate` | `bitrate` | Sends Kbps. If `disable_gcc` is true, uses `min_bitrate`; otherwise uses `max_bitrate`. Website values are Mbps, so the helper multiplies by `1000`. |
| `enable_microphone` | `mic` inclusion | Does not create a boolean param; it controls whether the microphone token is passed. |
| `always_1080p` | `width`, `height` | When true, sends `width=1920&height=1080`. When false, omits both. |

Example migration:

```text
preferred_codec=h265
vsync=true
framerate=120
disable_gcc=true
min_bitrate=10
enable_microphone=true
always_1080p=true
```

becomes:

```text
codec=h265&vsync=true&fps=120&bitrate=10000&mic=<mic-token>&width=1920&height=1080
```

### Settings intentionally not migrated

These browser settings are currently omitted because the desktop app has no documented equivalent launch argument:

| Website setting | Reason |
| --- | --- |
| `objectFitFill` | Browser video element scaling only. |
| `client_cursor` | Browser cursor rendering behavior only. |
| `auto_relative_mouse` | Browser pointer-lock behavior only. |
| `keyboard_lock` | Browser keyboard lock behavior only. |
| `scancode` | Browser HID compatibility mode; desktop HID uses native SDL translation. |
| `touch_gamepad` | Browser/mobile virtual control setting. |
| `native_touch` | Browser/mobile touch behavior. |
| `hq` | It mutates `framerate`, bitrate, and `vsync`; the resulting concrete values are migrated instead. |
| `watchMode` | Browser status UI preference. |

## Recommended launch URLs

### Minimal video-only launch

```text
thinkmay:https://thinkmay.net/en/remote/?vmid=<vm-id>&video=<video-token>
```

### Full desktop session

```text
thinkmay:https://thinkmay.net/en/remote/?vmid=<vm-id>&video=<video-token>&audio=<audio-token>&data=<hid-token>&mic=<mic-token>&codec=h265&vsync=false&stats=true
```

### Explicit QUIC server

```text
thinkmay:https://thinkmay.net/en/remote/?server=saigon2.thinkmay.net:50005&vmid=<vm-id>&video=<video-token>&audio=<audio-token>&data=<hid-token>
```

### USB forwarding with allowlist

```text
thinkmay:https://thinkmay.net/en/remote/?vmid=<vm-id>&video=<video-token>&data=<hid-token>&usb=true&usb-vidpid=1234:abcd
```

## Implementation checklist for producers

When website or backend code generates a desktop launch URL:

1. Include `vmid` and `video` every time.
2. Include `audio`, `data`, and `mic` only when those listener IDs exist.
3. Prefer `video`, `audio`, `data`, and `mic` over the `*-token` aliases for generated URLs.
4. Include `codec` when the session requested a non-default codec.
5. Include `server` or `addr` only when the QUIC endpoint should differ from the URL host fallback.
6. Do not include listener URLs for WebRTC directly; include the listener IDs as search parameters.
7. Avoid logging complete URLs because listener IDs are bearer credentials.

## Examples mapped to config

Input:

```text
thinkmay:https://thinkmay.net/en/remote/?vmid=vm1&video=v1&audio=a1&data=d1&mic=m1&codec=h265&fps=90&bitrate=15000&fullscreen=false
```

Resolved important fields:

| Config field | Value |
| --- | --- |
| `Addr` | `thinkmay.net:443` |
| `VMID` | `vm1` |
| `Token` | `v1` |
| `AudioToken` | `a1` |
| `DataToken` | `d1` |
| `MicToken` | `m1` |
| `Codec` | `h265` |
| `Fps` | `90` |
| `Bitrate` | `15000` |
| `Fullscreen` | `false` |

Input with CLI override:

```powershell
thinkmay-client.exe -url "thinkmay:https://thinkmay.net/en/remote/?vmid=vm1&video=v1&codec=h265&stats=false" -codec h264 -stats
```

Resolved override behavior:

| Config field | Value | Reason |
| --- | --- | --- |
| `Codec` | `h264` | `-codec` overrides `codec=h265`. |
| `Stats` | `true` | `-stats` overrides `stats=false`. |
