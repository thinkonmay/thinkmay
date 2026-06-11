# Pipeline Overview

The orchestrating agent runs: **idea → skeleton → recording → editing → voiceover → final output**, with QA gates after recording, editing, and assembly.

## Toolchain

| Tool | Role |
|------|------|
| **Coding agent** | Orchestration, decision-making |
| **Playwright** | Browser automation for screen recording |
| **Ghost-cursor** | Human-like cursor (version-fragile — see [lessons-learned.md](./lessons-learned.md)) |
| **HyperFrames** | Editing, captions, motion graphics, render |
| **ElevenLabs / OpenAI** | Cloud TTS |
| **edge-tts / Kokoro** | Local TTS fallbacks |
| **Whisper** | Transcription (`hyperframes transcribe`) |
| **ffmpeg** | Re-encode, keyframe extraction, audio mix |

## Pipeline diagram

```mermaid
---
config:
  theme: redux
  layout: dagre
---
flowchart TB
    n8["video_idea.md"] --> n1["video_skeleton.md"]
    n9["Codebase"] --> n1 & n2
    n1 -- "LLM" --> n4["script.md"]
    n1 -- "playwright" --> n2["Raw recording + metadata"]
    n2 -- "hyperframes" --> n3["Edited composition"]
    n4 --> n5["Per-lang scripts"]
    n1 --> n3
    n3 --> n7["final_<lang>.mp4"]
    n5 -- "TTS" --> n6["Per-scene audio"]
    n6 --> n7
    n5 --> n7

    n2 -. "QA" .-> v1{"Recording gate"}
    n3 -. "QA" .-> v2{"Editing gate"}
    n7 -. "QA" .-> v3{"Final audit"}
    v1 -. "retry" .-> n2
    v2 -. "retry" .-> n3
    v3 -. "retry" .-> n3
```

## Environment variables & secrets

Store all credentials in **`marketing/video/.env`** (gitignored):

```env
TM_USERNAME="demo@example.com"
TM_PASSWORD="your_password"
# ELEVEN_LABS_API_KEY="..."
# OPENAI_API_KEY="..."
```

Never commit `.env`. Prefer a **marketing demo account** with generic display name and healthy dashboard state — see [agents/recording.md](./agents/recording.md#account-pre-flight).
