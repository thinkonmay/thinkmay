# Artifact Formats

Templates for pipeline documents. All timestamps in skeleton/script are **planning estimates** — final times come from [sync-timing.md](./sync-timing.md).

## Research brief

`research/artifacts/output/research_brief.md`

```markdown
# Research Brief: <Video Title>

## Meta
- **Video idea:** <link>
- **Researched:** <date>

## 1. Product Summary
<story-ready summary>
**Source:** `CLAUDE.md`, ...

## 2. Key Claims (Provable)
| # | Claim | Evidence | Source |

## 3. Differentiators vs Competitors
| Differentiator | Us | Competitors | Source |

## 4. Target Audience Profile
...

## 5. Feature Inventory (Relevant to This Video)
### Feature: <Name>
- **UX flow:** ...
- **Recordable path:** `goto(...) → click(...)`

## 6. Visual Assets Available
| Asset | Path | Description |

## 7. Tone & Voice Guidelines
...

## 8. Things to Avoid
- [ ] ...

## 9. Raw Notes
...
```

## Video skeleton

`planning/artifacts/output/video_skeleton_<lang>.md`

```markdown
# Video: <Title>

## Meta
- **Platform:** YouTube / Website
- **Target length:** 60s (guideline)
- **Aspect ratio:** 16:9 (1920×1080)
- **Audience:** ...
- **Tone:** ...

## Scenes

### Scene 1: Intro (0:00 – 0:04)
**Visual:** Title card
**Narration:** "..."
**Action:** None
**Transition:** Push-slide to A-roll

### Scene 2: Download (0:04 – 0:20)
**Visual:** Landing → Download → Windows hover
**Narration:** "..."
**Action:** goto(/) → click(Download nav) → hover(Windows Download)
```

## Script

`planning/artifacts/output/script_<lang>.md`

```markdown
# Video Script: <Title> (<LANG>)

## Meta
- **Voice:** edge-tts en-US-AriaNeural / vi-VN-HoaiMyNeural
- **Speed:** 1.0
- **Language:** en-us

## Script

### Scene 1
Get lower-latency streaming with the Thinkmay desktop app.

### Scene 2
Start at thinkmay.net and open the Download page.
```

One beat per planned narration clip; final `data-start` values live in `sync-timing.json`.

## Recording / editing metadata

`recording_metadata.md` / `editing_metadata.md`

```markdown
# Recording Metadata

## Source
- **File:** raw_recording.webm
- **Resolution:** 1920x1080
- **Recorded:** <ISO timestamp>

## Timestamps

| Timestamp | Description | Expected (skeleton) |
|-----------|-------------|---------------------|
| 7.67s | Landing page loaded | Scene 2 |
| 33.58s | Clicked: Settings sidebar \| center=1406,786 | Scene 4 |
| 35.12s | Disk popup opened | Scene 4 |
```

Ground truth for QA — every row should be auditable via keyframe extraction.

`Clicked:` rows carry `center=x,y` (viewport px = raw-video px at 1920×1080) — these drive the editor's click ripples and click SFX; "popup/dialog opened/visible" rows drive whoosh SFX. See [sync-timing.md](./sync-timing.md#sync-timingjson-shape).
