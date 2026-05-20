# Thinkmay Docs

This folder contains product, technical, marketing, research, analytics, and SEO documentation for Thinkmay.

## Main folders

- `competitor_analysis/` - competitor research reports and generated competitor screenshots.
- `snapshots/` - generated screenshots, DOM captures, and local runtime captures from audits/research.
- `google_search/` - Google Search Console analysis scripts/reports. Raw exports are ignored by Git.
- `rybbit/` - Rybbit analysis scripts/reports. Raw exports are ignored by Git.
- `images/` - curated documentation images.
- `db/` - local database schema/dumps. Ignored by Git because it may contain sensitive schema or operational data.

## Git hygiene

Curated Markdown reports are intended to be commit-safe after review. Generated captures, raw analytics exports, database dumps, local screenshots, and environment/secrets files are ignored in the repository `.gitignore`.

Before committing, run:

```powershell
git status --short --ignored docs .gitignore
```

Check that only curated docs/scripts/README files are staged, not raw `.xlsx`, `.csv`, `.json`, screenshots, DB dumps, or secrets.
