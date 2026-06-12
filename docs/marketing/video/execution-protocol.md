# Execution Protocol

Step-by-step pipeline. Read [workspace.md](./workspace.md) for directory layout.

## Step 1: Initialize workspace

```bash
export PROJECT_DIR="marketing/video/<project_name>_v1"

for lang in en vi; do
  mkdir -p $PROJECT_DIR/{recording,editing,voice,assembly}/artifacts/{input,output}/$lang
  mkdir -p $PROJECT_DIR/{recording,editing,voice,assembly}/temp/$lang
done
mkdir -p $PROJECT_DIR/{research,planning}/{artifacts/{input,output},temp}
mkdir -p $PROJECT_DIR/editing/compositions $PROJECT_DIR/editing/assets/narration-scenes/vi
mkdir -p $PROJECT_DIR/assets $PROJECT_DIR/recording/scripts $PROJECT_DIR/scripts

echo "temp/" > $PROJECT_DIR/.gitignore
echo "renders/" >> $PROJECT_DIR/editing/.gitignore
```

Create `goal.md`, `taskchecklist.md`, `README.md`. Ensure `marketing/video/.env` exists.

## Step 2: Research

Follow [agents/research.md](./agents/research.md). Output `research_brief.md`. Update checklist.

Clarify if missing: starting scene, ending scene, target languages.

## Step 3: Planning

Follow [agents/planning.md](./agents/planning.md). Output skeleton + script per language.

## Step 4: Recording

Follow [agents/recording.md](./agents/recording.md).

```bash
cd recording && npm install && npm run record
```

Per language: `record:en`, `record:vi`. **Raw footage gate** (landing + dashboard ending in MP4) before editing.

## Step 4.5: Frame review (VLM round)

Follow [agents/review.md](./agents/review.md) on the re-encoded MP4. Extract keyframes at every metadata event (video-calibrated) plus a 2s grid, evaluate each frame, and append the `## Frame review` section to `recording_metadata.md`:

- Verify/correct every event time against actual pixels
- Record target `(tx, ty)` + bbox for every zoom/caption beat
- Flag `DEAD_AIR` spans and anomalies (PII, error cards)

PII or wrong-flow findings here → **re-record now** (cheapest failure point). Editing must not start without this section.

## Step 5: Editing

**Run from the project root** (`marketing/video/<slug>/`), not from `editing/`.

Preferred — full pipeline with automated gates:

```bash
node scripts/run-pipeline.mjs en
# VI: node scripts/run-pipeline.mjs vi
```

Or step-by-step:

```bash
# Re-encode (genpts — WebM duration is often N/A). Near-lossless: crf 14 @ 60fps
ffmpeg -y -fflags +genpts -i recording/artifacts/output/en/raw_recording.webm \
  -c:v libx264 -preset medium -crf 14 -r 60 -g 60 -keyint_min 60 -pix_fmt yuv420p \
  -movflags +faststart editing/raw_recording.mp4
ffprobe -v error -show_entries format=duration -of csv=p=0 editing/raw_recording.mp4

node scripts/verify-raw-footage.mjs en      # manual: inspect check-end.png
node scripts/gate-metadata.mjs en           # fail if Clicked: rows lack center=
node editing/scripts/build-sync-timing.mjs en
node scripts/gate-sync.mjs en               # fail if clicks[] missing x/y
node editing/scripts/apply-sync-to-html.mjs en
```

Compose or patch `index.html` (+ `compositions/index-vi.html`). See [agents/editing.md](./agents/editing.md) and [sync-timing.md](./sync-timing.md).

Required scenes gate on raw MP4 and pre-render checkpoints before render.

## Step 6: Voice

Per-scene TTS from `sync-timing.json` narration entries. See [agents/voice.md](./agents/voice.md).

```bash
node ../scripts/generate-narration.mjs en   # from project root
node editing/scripts/build-sync-timing.mjs en   # re-run after MP3 durations known
node scripts/gate-sync.mjs en --after-tts       # fail if VO exceeds outroStart
node editing/scripts/apply-sync-to-html.mjs en
```

Keep narration lines short for footage under ~40s — `gate-sync --after-tts` catches VO that runs past the outro.

## Step 7: Assembly

```bash
cd editing && npm run check && npm run render
npm run check:vi && npm run render:vi   # if Vietnamese
```

Render scripts are pinned to `--quality high --fps 60` (maximum fidelity HyperFrames offers). `finalize-output.mjs` **copies** the render to `final_<lang>.mp4` — never re-encode/transcode the rendered file in any later step.

Before render, confirm the soundscape is wired: music bed (`data-volume ≤ 0.15`) spanning the composition, click SFX + popup whooshes generated between the `<!-- sfx:start/end -->` markers ([brand-design.md](./brand-design.md#soundscape-mandatory-for-shipped-tutorials)).

## Step 8: Final QA

Follow [agents/qa.md](./agents/qa.md) on `final_<lang>.mp4`. Do not mark complete until final audit passes target verdict level.

Update `taskchecklist.md`: Assembly, QA Final.
