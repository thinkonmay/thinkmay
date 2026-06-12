# Brand & Design Rules

- Follow project `editing/design.md` (colors, fonts, motion)
- If missing, use HyperFrames house-style defaults or ask for mood/brand inputs
- Copy logos from `website/public/` into project `editing/assets/`
- Caption pills: dark background (`rgba(4,10,12,0.92)`), **white text** (`color: #fff` set directly on the pill, not on child spans), Cyber Green accent (`#00E8A8`, `#5FE9D0`), Outfit bold
- Intro/outro: deep background `#071F1C`
- All motion intentional — entrance animations on title cards and captions
- Maintain 1920×1080 sharpness; no lazy default fonts/colors

Project-level `design.md` overrides these defaults for a specific video.

## Intro / outro scene standards (60s tutorials)

Static logo cards burn runtime. `disk-upgrade-60s_v1` shipped an 18.8s outro — 34% of the video frozen on one card. These are hard budgets:

| Scene | Duration | Content beats |
|-------|----------|---------------|
| **Intro** | **3.0–4.5s** | Logo visible ≤0.5s; "TUTORIAL" kicker + title by ~1.5s; depth-scale handoff to A-roll at 3.0–4.5s |
| **Outro** | **3.0–4.5s on screen** | Logo + value line + CTA URL pill, all entered within ~1s; brief hold with ambient motion (breathing glow orbs — never fully static); fade ends **at** composition end |

Rules:

- **Total duration = outroStart + outro budget.** Derive the composition `data-duration` from the A-roll end (`build-sync-timing.mjs` does this) — never use a fixed 55/60s floor. A fixed floor leaves a **black tail** after the outro, which is a QA hard fail (`disk-upgrade-60s_v1` VI: ~9s of black at 51–60s).
- The outro CTA voice line starts at `outroStart + ~0.7s` — never anchored to `DURATION − 5` or any fixed timestamp.
- `outroStart ≈ (videoDataStart + aRollDuration) − 0.5` (crossfade), per [agents/editing.md](./agents/editing.md).
- Outro must always carry a CTA (URL pill or "Start now"); a logo alone is wasted runtime.
- Intro never exceeds 4.5s — viewers click away; the product UI is the hook.
- For 30s cuts, halve the intro budget (2s); outro stays 3s minimum.

## Soundscape (mandatory for shipped tutorials)

Voice-only mixes read as amateur. Every final video carries three audio layers:

| Layer | Asset | Track | Volume |
|-------|-------|-------|--------|
| Narration | per-scene MP3s | 2 (+3 outro CTA) | 1.0 |
| Music bed | `assets/audio/music-bed.mp3` — low-volume upbeat tech/corporate; template ships a synthesized placeholder, replace with a licensed track when available | 5 | ≤ 0.15 |
| Click SFX | `assets/audio/sfx-click.mp3` at every recorded click | 6 | ~0.5 |
| Popup whoosh | `assets/audio/sfx-whoosh.mp3` when popups/dialogs open | 7 | ~0.35 |

SFX placement is automated: `build-sync-timing.mjs` emits `clicks`/`popups` arrays from recording marks and `apply-sync-to-html.mjs` writes the `<audio>` tags. The music bed spans `0 → data-duration` and fades with the outro.
