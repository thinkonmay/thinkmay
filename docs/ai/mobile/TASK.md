# Mobile — active work log

Central task tracker for the Flutter app (`mobile/` submodule).  
Update this file when starting or finishing mobile implementation work.

## In progress

- **L-1 startup performance** — splash full preload + parallel `loadAll()` shipped; post-splash UI jank + main-isolate JSON decode remain (2026-06-09)

## Done

- L-1 splash preload UX — gate navigate until all shell data ready; progress bar tracks `bootstrapProgress`; profile gamification + store catalog on splash; `PreloadUseCase.loadAll()` runs 13 API calls in parallel (2026-06-09)
- L-1 startup perf partial — lazy WebRTC plugins, WebP splash assets, dashboard/hero/volume-card build optimizations, `[perf]` startup profiler (2026-06-09)
- L-7 bootstrap gate — `isBootstrapReady` requires full preload (`deferredPreloadComplete`); guest domains-only; authed `loadAll` before `/home` (2026-06-09)
- Advanced settings runtime audit + mic/1080p wiring — `microUrl` on reconnect, `changeResolution` + resize hook; keyboard lock / auto rel mouse / client cursor gaps documented (2026-06-09)
- L-8 advanced settings UI polish — safe-area, slider overflow, toggle contrast, TmSwitch reset sync, §C parity toggles verified (2026-06-09)
- Splash bootstrap PWA parity — guest/authed `bootstrap()`, domains on splash, EasyLoading/splash UX fix (2026-06-09)
- Centralized Claude/Cursor config under `docs/ai/mobile/` (2026-06-09)

## Checklist template

- [x] Product doc updated in `docs/product/` — L-1/L-7 preload: `mobile_sync_checklist.md`, bootstrap spec `01-app-bootstrap-global-state.md`
- [x] Spec updated in `docs/ai/mobile/specs/` — `01-app-bootstrap-global-state.md`, `12-explore-games-store.md`, `API-COVERAGE.md`
- [x] `flutter analyze` clean on touched files
