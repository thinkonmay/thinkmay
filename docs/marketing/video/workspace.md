# Workspace Structure

Projects live under `marketing/video/` as versioned folders.

## Naming

Format: `<project_name>_v<version>/` (e.g. `windows-desktop-pwa-60s_v1/`)

## Multi-language rule

Each target language gets an **independent native pipeline**:

- Separate Playwright recording (localized UI, inputs, labels)
- Separate `script_<lang>.md`, per-scene TTS, and HyperFrames composition
- **No dubbing** a single recording for other languages

## Directory tree

```
marketing/video/
├── .env                              # Shared secrets (never commit)
│
└── <project_name>_v<version>/
    ├── final_en.mp4                  # Primary deliverables at project root
    ├── final_vi.mp4
    ├── goal.md                       # Readonly task description
    ├── taskchecklist.md
    ├── README.md                     # Re-run commands
    │
    ├── research/artifacts/output/research_brief.md
    ├── planning/artifacts/output/
    │   ├── video_skeleton_en.md
    │   ├── video_skeleton_vi.md
    │   ├── script_en.md
    │   └── script_vi.md
    │
    ├── recording/
    │   ├── scripts/record_en.mjs, record_vi.mjs, record_shared.mjs
    │   └── artifacts/output/<lang>/
    │       ├── raw_recording.webm
    │       └── recording_metadata.md
    │
    ├── editing/
    │   ├── index.html                # Primary language composition (root)
    │   ├── compositions/
    │   │   └── index-vi.html         # Secondary languages (see editing agent)
    │   ├── sync-timing.json
    │   ├── design.md
    │   ├── caption-overrides.json    # Required: `{}` minimum
    │   ├── raw_recording.mp4         # Re-encoded from webm
    │   └── assets/narration-scenes/
    │
    ├── voice/artifacts/output/<lang>/
    ├── assembly/artifacts/output/
    ├── scripts/finalize-output.mjs
    └── assets/
```

## Rules

- Temp files → `<step>/temp/` (gitignored)
- Outputs → `<step>/artifacts/output/`
- Copy inputs into `<step>/artifacts/input/` before each stage
- After render, copy `final_<lang>.mp4` to **project root** via `finalize-output.mjs`

## Documentation location

Pipeline spec: `docs/marketing/video/` (this folder).  
Runtime projects: `marketing/video/<project>/`.
