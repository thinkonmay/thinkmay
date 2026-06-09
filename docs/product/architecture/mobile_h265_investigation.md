# Mobile H.265 strategy (Android / iOS)

## Summary

Some Android devices decode H.265 in Chrome but stall in the Flutter app
(`bytesReceived > 0`, `framesDecoded = 0`). Root cause is a **stack gap** between
Chromium WebRTC and `flutter_webrtc` on Android (field trials, packet buffer,
decoder wiring) — not missing hardware decode on the device.

**Current approach (2026-06):** Gate H.265 in advanced settings by RTP capability
detection. Unsupported devices see a disabled toggle and always connect with H.264.
No upstream `flutter_webrtc` patches and no runtime codec fallback.

**Next step (TODO):** Custom `flutter_webrtc` fork with a custom `libwebrtc` build
that matches Chromium H.265 receive behavior on Android.

## Capability detection

| API | Purpose |
|-----|---------|
| `deviceSupportsH265Decode()` | `getRtpReceiverCapabilities('video')` — true if any mime contains `h265` or `hevc` |
| `resolvePreferredVideoCodec()` | Session connect — forces `h264` when caps lack HEVC |
| Advanced settings toggle | Enabled only when `deviceSupportsH265Decode()` is true |
| `RemoteSettingsCubit._load()` | Downgrades saved `preferredCodec` from `h265` → `h264` on unsupported devices |

**Limitation:** RTP caps prove SDP negotiation is allowed, not that decode will
succeed at runtime. Devices that advertise HEVC but fail to decode in
`flutter_webrtc` may still show the toggle until we ship the custom WebRTC build.

## Removed workarounds

| Item | Status |
|------|--------|
| `mobile/tooling/apply_flutter_webrtc_patches.sh` | **Removed** |
| H.26x field-trial patch on `MethodCallHandlerImpl.java` | **Removed** |
| `ThinkmayClient._tryFallbackToH264()` runtime reconnect | **Removed** |

## TODO — custom flutter_webrtc fork

- [ ] Fork `flutter-webrtc/flutter-webrtc` under Thinkmay org
- [ ] Build custom Android `libwebrtc` AAR (webrtc-sdk or Chromium-aligned) with H.26x packet buffer enabled
- [ ] Wire fork in `mobile/pubspec.yaml` (git dependency or private pub)
- [ ] CI: rebuild native artifacts on version bump
- [ ] Re-test SM X910 and other Adreno/Samsung devices that decode H.265 in Chrome
- [ ] Re-enable H.265 toggle for devices that pass decode verification (not just RTP caps)
- [ ] Optional: expose `fieldTrials` in `WebRTC.initialize()` Dart API for diagnostics

## Dependency state

| Component | Version |
|-----------|---------|
| `flutter_webrtc` | `1.4.1` (pubspec) |
| H.265 in plugin changelog | 1.1.0+ via webrtc-sdk |

## References

- [flutter-webrtc#1899](https://github.com/flutter-webrtc/flutter-webrtc/issues/1899) — H265 enumerate vs decode
- [flutter-webrtc#862](https://github.com/flutter-webrtc/flutter-webrtc/issues/862) — H265 tracking issue
- [webrtc-sdk/webrtc#184](https://github.com/webrtc-sdk/webrtc/pull/184) — Android H.265 SDK patch
- [Chromium M136 H.265](https://chromium.googlesource.com/chromium/src/+/8ca090ecf9fcb51daaa549bbce830511b62f00aa) — `WebRTC-Video-H26xPacketBuffer/Enabled`
