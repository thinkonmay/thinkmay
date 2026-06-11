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

## Step 5: Editing

```bash
# Re-encode (genpts — WebM duration is often N/A)
ffmpeg -y -fflags +genpts -i recording/artifacts/output/en/raw_recording.webm \
  -c:v libx264 -preset fast -r 30 -g 30 -keyint_min 30 -pix_fmt yuv420p \
  -movflags +faststart editing/raw_recording.mp4
ffprobe -v error -show_entries format=duration -of csv=p=0 editing/raw_recording.mp4
# Confirm duration ≈ last metadata timestamp before sync
# Repeat for vi → raw_recording_vi.mp4

# Sync timing (only after encode completes — calibrates script clock → video time)
cd editing
node scripts/build-sync-timing.mjs en
node scripts/build-sync-timing.mjs vi
node scripts/apply-sync-to-html.mjs en
node scripts/apply-sync-to-html.mjs vi
```

Compose or patch `index.html` (+ `compositions/index-vi.html`). See [agents/editing.md](./agents/editing.md) and [sync-timing.md](./sync-timing.md).

Required scenes gate on raw MP4 and pre-render checkpoints before render.

## Step 6: Voice

Per-scene TTS from `sync-timing.json` narration entries. See [agents/voice.md](./agents/voice.md).

```bash
python3 -m edge_tts --voice "en-US-AriaNeural" --text "..." \
  --write-media editing/assets/narration-scenes/scene-02.mp3
ffprobe -v error -show_entries format=duration -of csv=p=0 editing/assets/narration-scenes/scene-02.mp3
```

Wire `data-duration` in HTML from ffprobe output.

## Step 7: Assembly

```bash
cd editing && npm run check && npm run render
npm run check:vi && npm run render:vi   # if Vietnamese
```

## Step 8: Final QA

Follow [agents/qa.md](./agents/qa.md) on `final_<lang>.mp4`. Do not mark complete until final audit passes target verdict level.

Update `taskchecklist.md`: Assembly, QA Final.
