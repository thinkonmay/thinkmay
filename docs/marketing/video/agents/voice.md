# Voice Agent

**Input:** `script_<lang>.md`, `sync-timing.json`  
**Output:** Per-scene MP3s, optional `transcript.json`

**Skills:** `hyperframes-media`

## Per-scene audio (mandatory for walkthroughs)

Generate **one MP3 per narration entry** in `sync-timing.json`, not one file for the whole video.

```bash
python3 -m edge_tts --voice "en-US-AriaNeural" \
  --text "Start at thinkmay.net and open the Download page." \
  --write-media editing/assets/narration-scenes/scene-02.mp3
```

Vietnamese example: `vi-VN-HoaiMyNeural` → `assets/narration-scenes/vi/scene-02.mp3`

## Duration wiring

For each clip:

```bash
ffprobe -v error -show_entries format=duration -of csv=p=0 scene-02.mp3
```

Set `<audio data-duration="...">` to **≥ ffprobe value**. Never shorten to fix track overlap — use different `data-track-index` instead.

## TTS options

| Option | When |
|--------|------|
| edge-tts | Default free path; use `python3 -m edge_tts` if CLI not on PATH |
| ElevenLabs | Premium quality; needs `ELEVEN_LABS_API_KEY` in `marketing/video/.env`. **Always use the most powerful model (`eleven_multilingual_v2`) for rich lifelike voices.** Supports pronunciation dictionaries. Use `ELEVEN_LABS_VOICE_ID=CwhRBWXzGAHq8TQ4Fs17` (Roger) or another voice your plan allows. Script: `marketing/video/scripts/generate-narration.mjs` |
| OpenAI TTS | `OPENAI_API_KEY` |
| Kokoro | Offline; requires Python ≥3.10 and working `kokoro-onnx` |
| macOS `say` | Fallback when Kokoro/edge-tts unavailable — `say -o clip.aiff` then ffmpeg to MP3; verify with `ffprobe` |

## ElevenLabs (project script)

From the video project root (after `sync-timing.json` exists):

```bash
node ../scripts/generate-narration.mjs en
node ../scripts/generate-narration.mjs vi
# fallback if API fails:
node ../scripts/generate-narration.mjs en --provider=edge
```

Optional in `marketing/video/.env`:

```env
ELEVEN_LABS_API_KEY="..."
ELEVEN_LABS_VOICE_ID="CwhRBWXzGAHq8TQ4Fs17"
ELEVEN_LABS_PRONUNCIATION_DICTIONARY_ID="your_dictionary_id"
ELEVEN_LABS_PRONUNCIATION_DICTIONARY_VERSION_ID="version_id"
```

Then refresh durations and HTML:

```bash
node editing/scripts/build-sync-timing.mjs en
node editing/scripts/apply-sync-to-html.mjs en
```

## Transcription

Optional per-scene or combined: `npx hyperframes transcribe` → word-level timestamps for caption fine-tuning. Walkthroughs still anchor to `sync-timing.json` from recording metadata.

## Sync rule

Narration `data-start` must match the corresponding caption window in `sync-timing.json` (±0.1s). If narration begins before the prior caption ends, fix caption `end` times first.
