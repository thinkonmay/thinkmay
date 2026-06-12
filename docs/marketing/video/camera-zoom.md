# Camera Zoom Guide

How to zoom/pan the A-roll (`#video-wrap`) so the camera lands **exactly on the element the user must look at** — deterministically, without eyeballing.

**Never guess zoom coordinates.** Every zoom must be derived from a measured target position in the raw MP4 (or, better, a bounding box captured at record time — see [agents/review.md](./agents/review.md)).

## The math (memorize this)

The A-roll video fills the 1920×1080 frame. GSAP transforms use `transformOrigin: "50% 50%"` (default), i.e. center `c = (960, 540)`.

To center a target point `(tx, ty)` (in raw-video pixel coords) at scale `s`:

```
x = (960 - tx) × s
y = (540 - ty) × s
```

Then **clamp** so the video edges never expose the background:

```
x ∈ [960 × (1 - s),  960 × (s - 1)]
y ∈ [540 × (1 - s),  540 × (s - 1)]
```

Worked example (`disk-upgrade-60s_v1`, Disk button at `(1406, 786)`, `s = 1.25`):

```
x = (960 − 1406) × 1.25 = −557.5  → clamped to 960 × (1 − 1.25) = −240
y = (540 − 786)  × 1.25 = −307.5  → within [−300, 300]? No: limit is ±135… see rule below
```

### Clamp displacement rule

If clamping moves the target more than **25% of screen width/height away from center**, the scale is too low to frame that target — **increase `s`** and recompute. A corner target at `s = 1.25` cannot be centered; at `s = 1.6` it usually can.

```
displacement_x = |x_ideal − x_clamped| / s     # in raw-video px
if displacement_x > 480 or displacement_y > 270 → increase s by 0.15 and retry
```

## Target selection: zoom to intention, not to position

Zoom must communicate *what the user should do next*. Pick the target by intent:

| Beat | Target | Bad target |
|------|--------|------------|
| "Click X" caption | The X button **and its immediate container** (the whole VM card, not just the button) | The button alone if cropping cuts the card's text |
| Form fill | The form fields being typed into | The whole page at 1.0× (dead air) |
| Pricing/feature callout | The pricing row / feature block | A zoom that opens before the element exists on screen |
| Result confirmation | The changed element (e.g. selected 400GB row) | Static popup-wide framing |

### Framing rules

1. **Never cut text mid-glyph at frame edges.** If the target's parent container (card, modal, panel) has visible text, the zoom rectangle must contain the whole container or crop at genuine whitespace. *(`disk-upgrade-60s_v1` failure: dashboard zoom cut "Volume ID…" / "Played 24.7/67" mid-character at the left edge — looks broken.)*
2. **Target in the center third.** After clamping, the target must sit within the middle ⅓ of the screen horizontally and vertically (or increase `s`, see above).
3. **Respect the caption safe area.** The caption pill occupies roughly `y ∈ [880, 1010]` on screen. The target element must not land under it. If the caption names an option list (e.g. "Choose 400GB"), no *interactive option* may be occluded by the pill — shift `y` or shorten the caption.
4. **Scale range 1.15–1.6.** Below 1.15 the zoom reads as drift; above 1.6 the upscaled 1080p footage gets soft.
5. **One intention per zoom.** Don't pan between two targets in one move; zoom out to 1.0 and re-zoom.

## Timing rules

- **Lead the click, don't chase it.** Start the zoom ~0.5–0.8s *before* the click event so the viewer sees the cursor arrive.
- **Transition: 0.6–0.8s**, `power2.out` / `power3.out`.
- **Hold ≥ 2s** at zoomed state — shorter holds feel accidental.
- **Reset to `scale: 1.0, x: 0, y: 0`** (`power2.inOut`) when the action completes or before any scene transition. Never carry a zoom into the outro crossfade.
- Use `overwrite: "auto"` on every `#video-wrap` tween — overlapping zoom/reset tweens are a lint warning and a real render hazard.

## Workflow (mandatory, per zoom)

### 1. Get target coordinates

**Preferred — recorded bounding box:** the recording script captures `boundingBox()` at each `mark()` (see [agents/recording.md](./agents/recording.md)). Use the box center from `recording_metadata.md`. These are viewport CSS px = raw-video px (viewport is 1920×1080).

**Fallback — measure a frame:** extract the raw-MP4 frame at the action's video-calibrated time and measure the target's pixel position:

```bash
ffmpeg -y -ss <video_time> -i editing/raw_recording.mp4 -frames:v 1 -update 1 /tmp/zoom-target.png
# Open the PNG, read the target's (tx, ty) center and its container's bounding box
```

### 2. Compute and clamp

Apply the formulas above. Record the numbers **as a comment in the composition** so the next agent can audit them:

```javascript
// Zoom: Disk button. Target (1406, 786) from metadata bbox, s=1.4
// x = (960-1406)*1.4 = -624 → clamp [-384, 384] → -384 (displacement 171px ✓ < 480)
// y = (540-786)*1.4  = -344 → clamp [-216, 216] → -216 (displacement 91px ✓)
tl.to("#video-wrap", { scale: 1.4, x: -384, y: -216,
  duration: 0.7, ease: "power2.out", overwrite: "auto" }, 20.4);
```

### 3. Verify against rendered pixels

After render (or `hyperframes preview` screenshot), extract a frame mid-hold and check:

```bash
ffmpeg -y -ss <hold_mid_time> -i final_en.mp4 -frames:v 1 -update 1 /tmp/zoom-verify.png
```

- [ ] Target element in center third
- [ ] No text cut mid-glyph at any frame edge
- [ ] No background visible at video edges
- [ ] Caption pill not covering the target or sibling interactive options

A zoom that fails any check is an editing-gate failure — fix coordinates and re-render. Do not ship "close enough" framing.
