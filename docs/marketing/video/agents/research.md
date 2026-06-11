# Research Agent

**Input:** `video_idea.md` / user prompt  
**Output:** `research/artifacts/output/research_brief.md`

Conduct deep research **before any creative work**. Skipping this produces generic or inaccurate content.

## Research scope

Read and synthesize from these domains (cite sources for every claim):

| Domain | Key files |
|--------|-----------|
| Product identity | `CLAUDE.md`, `docs/product/README.md` |
| Brand & strategy | `docs/marketing/strategy/`, `docs/marketing/research/thinkmay_cloudpc_brand_research.md` |
| Audience | `docs/marketing/research/user_persona.md` |
| Competition | `docs/marketing/strategy/thinkmay_competitor_positioning_memo.md`, `docs/marketing/research/competitor_analysis/` |
| Features & UX | `docs/product/design/`, `docs/product/features/`, `docs/product/architecture/client_user_flow_contract.md` |
| Technical (if needed) | `docs/product/architecture/technical_doc.md` |
| Codebase | `website/` routes, components, `website/public/` assets |

## Output sections

1. Product summary (audience-appropriate language)
2. Key claims (provable, with evidence)
3. Differentiators vs competitors
4. Target audience profile
5. Feature inventory for this video (UX flows, recordable paths)
6. Visual assets (paths)
7. Tone & voice guidelines
8. Things to avoid

> **Rule:** No invented facts. Every claim cites a source file.

Template: [artifact-formats.md](./artifact-formats.md#research-brief)
