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
| **Outro** | **5.0–7.0s** (hard max 8s) | Logo + value line + CTA URL pill, all entered within 1.2s; hold with ambient motion (breathing glow orbs — never fully static); end |

Rules:

- **Total duration = outroStart + outro budget.** Set the composition `data-duration` from this — do not let the outro absorb leftover music or padding. Video must end ≤1s after the outro hold completes.
- `outroStart ≈ (videoDataStart + aRollDuration) − 0.5` (crossfade), per [agents/editing.md](./agents/editing.md).
- Outro must always carry a CTA (URL pill or "Start now"); a logo alone is wasted runtime.
- Intro never exceeds 4.5s — viewers click away; the product UI is the hook.
- For 30s cuts, halve both budgets (intro 2s, outro 3–4s).
