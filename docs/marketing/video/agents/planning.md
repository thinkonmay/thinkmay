# Planner Agent

**Input:** `video_idea.md`, `research_brief.md`  
**Output:** `video_skeleton_<lang>.md`, `script_<lang>.md` per target language

Works **only from the research brief** — does not re-research the codebase.

## Configuration (clarify if missing)

| Parameter | Default |
|-----------|---------|
| Starting scene | Landing page `/` |
| Ending scene | Dashboard `/play` |
| Output languages | English + Vietnamese (independent native pipelines) |
| Target length | Guideline only (e.g. 60s) — editor extends if required scenes need room |

If starting scene, ending scene, or languages are unspecified, **ask the user** before planning.

## Responsibilities

- Ground every script claim in the research brief
- Localize skeleton actions to target language UI (button labels, typing, locale paths)
- Align narration beats to the UX flow (not arbitrary time blocks)
- Identify assets to copy into project `assets/`
- Note recordable selectors and stable IDs from prior projects (`#desktop-setting`, `#advance`, etc.)

## Pacing notes

- Navigation steps: ~2–3s on screen after edit
- Hero step (e.g. desktop toggle): 4–6s caption window
- Never plan to drop Settings → Advanced → toggle → Save to hit a shorter runtime

Templates: [artifact-formats.md](../artifact-formats.md)
