# Mobile H.265 decode investigation (Android)

## Summary

The SM X910 tablet decodes H.265 in Chrome but showed `bytesReceived > 0` and
`framesDecoded = 0` in the Flutter app. This is **not** a device capability gap.
It is a **stack configuration gap** between Chrome and `flutter_webrtc` on Android.

## Current dependency state (2026-03)

| Component | Version |
|-----------|---------|
| `flutter_webrtc` (resolved) | **1.4.1** |
| `io.github.webrtc-sdk:android` | **144.7559.01** (libwebrtc m144) |
| H.265 in changelog | Added in 1.1.0 via [PR #1915](https://github.com/flutter-webrtc/flutter-webrtc/pull/1915) |
| webrtc-sdk H.265 Android patch | [webrtc-sdk/webrtc#184](https://github.com/webrtc-sdk/webrtc/pull/184) |

**Upgrade conclusion:** Bumping `flutter_webrtc` further is not required for basic H.265
support — we are already on the release that advertises HEVC. The problem is runtime
configuration, not missing symbols in the AAR.

## Why Chrome works on the same hardware

| Layer | Chrome (PWA) | Flutter app (`flutter_webrtc`) |
|-------|--------------|--------------------------------|
| WebRTC build | Chromium M136+ (auto-updated) | webrtc-sdk m144 AAR bundled in plugin |
| H.265 receive gate | Enabled by default in recent Chrome Android | Requires `WebRTC-Video-H26xPacketBuffer/Enabled` field trial |
| Frame assembly | H.26x-specific packet buffer in Chrome | Generic packet buffer unless field trial set |
| Presentation | `<video>` → MediaCodec | `RTCVideoRenderer` → SurfaceTexture/ImageReader |
| Field trials at init | Chrome sets internally | **Android plugin sets none** (iOS sets NWPathMonitor only) |

Chromium docs ([M136 H.265 commit](https://chromium.googlesource.com/chromium/src/+/8ca090ecf9fcb51daaa549bbce830511b62f00aa)) require:

```
WebRTC-Video-H26xPacketBuffer/Enabled
```

for H.264/H.265 RTP reassembly. Without it, inbound RTP stats can show large
`bytesReceived` while `framesDecoded` stays at 0 — exactly the failure mode
seen on SM X910.

`getRtpReceiverCapabilities('video')` listing HEVC only proves **SDP negotiation**
is allowed, not that the H.26x packet path is active.

## Decoder factory (no custom patch required)

`flutter_webrtc` 1.4.1 already wires:

```
org.webrtc.video.CustomVideoDecoderFactory
  → WrappedVideoDecoderFactory (hardware MediaCodec)
  → SoftwareVideoDecoderFactory (fallback)
```

Defined in `MethodCallHandlerImpl.initialize()`. A custom decoder factory patch is
**not** needed unless field-trial fix is insufficient.

Useful diagnostics: log `metrics.video.decoder.name` and negotiated `codecName` from
inbound-rtp stats after connect.

## Fix applied in this repo

1. **Patch script** — `mobile/tooling/apply_flutter_webrtc_patches.sh` adds the H.26x
   field trial to `MethodCallHandlerImpl.java` after every `flutter pub get`.
2. **Runtime H.264 fallback** — if H.265 still stalls after 8s with bytes flowing
   (`ThinkmayClient._tryFallbackToH264`), reconnect with `codec=h264`.
3. **Capability logging** — `resolvePreferredVideoCodec()` logs RTP mime types.

Run after dependency changes:

```bash
cd mobile
flutter pub get
./tooling/apply_flutter_webrtc_patches.sh
```

Then rebuild the APK (hot restart is **not** enough — native init runs once).

## Verification checklist (SM X910)

1. Filter logcat: `Thinkmay:Connect`, `WebRtcBootstrap` (if used), `WebRTC:VIDEO`
2. Confirm establishment log: `codec=h265`
3. After connect, stats should show `dec > 0` and non-zero `dim=` within ~5s
4. Stats overlay decoder line should show a MediaCodec implementation (not empty)
5. If still `dec=0` at 8s, expect `H265 decode stall … retrying H264` then success on H264

## Upstream follow-ups

- [ ] Open PR to `flutter-webrtc/flutter-webrtc`: add Android field trial in
      `MethodCallHandlerImpl.initialize()` (mirror iOS `RTCInitFieldTrialDictionary`)
- [ ] Expose optional `fieldTrials` string in `WebRTC.initialize()` Dart API
- [ ] Update `client_platform_divergence.md` §8.2 — mobile does **not** use browser decoder path

## References

- [flutter-webrtc#1899](https://github.com/flutter-webrtc/flutter-webrtc/issues/1899) — H265 enumerate vs decode
- [flutter-webrtc#862](https://github.com/flutter-webrtc/flutter-webrtc/issues/862) — H265 tracking issue
- [webrtc-sdk/webrtc#184](https://github.com/webrtc-sdk/webrtc/pull/184) — Android H.265 SDK patch
