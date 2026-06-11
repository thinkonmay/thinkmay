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
| ElevenLabs | Premium quality; needs `ELEVEN_LABS_API_KEY` |
| OpenAI TTS | `OPENAI_API_KEY` |
| Kokoro | Offline; requires Python ≥3.10 |

## Transcription

Optional per-scene or combined: `npx hyperframes transcribe` → word-level timestamps for caption fine-tuning. Walkthroughs still anchor to `sync-timing.json` from recording metadata.

## Sync rule

Narration `data-start` must match the corresponding caption window in `sync-timing.json` (±0.1s). If narration begins before the prior caption ends, fix caption `end` times first.
