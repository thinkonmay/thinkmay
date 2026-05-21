# Thinkmay SEO documentation audit with live Google Search Console

_Date: 2026-05-21_

## Scope

This audit reviews the main SEO documentation in `docs/` against the currently connected live Google Search Console property:

- `docs/seo_growth_implementation_plan.md`
- `docs/google_search/seo_health_summary_2026-05-17.md`
- `docs/rybbit/rybbit_seo_combined_analysis_2026-05-17.md`
- `docs/thinkmay_competitor_positioning_memo.md`

The purpose is to determine:

1. what is still accurate;
2. what is stale but still directionally useful;
3. what is missing from the documentation based on current GSC data.

## Live GSC baseline used for this audit

Site: `https://thinkmay.net/`
Window used for live checks: `2026-02-21` to `2026-05-21`

### Brand vs non-brand

- Branded clicks: **52,269**
- Branded impressions: **63,771**
- Branded click share: **80.7%**
- Non-branded clicks: **12,469**
- Non-branded impressions: **92,092**

### Device split

- **Mobile:** 48,493 clicks, 132,662 impressions, 36.55% CTR, position 5.3
- **Desktop:** 24,727 clicks, 211,702 impressions, 11.68% CTR, position 13.3
- **Tablet:** 2,003 clicks, 4,773 impressions, 41.97% CTR, position 5.0

### Country split

- **Vietnam:** 52,168 clicks, 208,064 impressions, 25.07% CTR, position 8.7
- **Indonesia:** 16,639 clicks, 26,886 impressions, 61.89% CTR, position 3.2
- **Malaysia:** 1,156 clicks, 2,454 impressions, 47.11% CTR, position 5.2

### Top category queries in current GSC

- `cloud pc`: 2,363 clicks, 9,005 impressions, 26.24% CTR, position 4.2
- `cloudpc`: 443 clicks, 1,576 impressions, 28.11% CTR, position 2.9
- `thuê cloud pc`: 255 clicks, 1,420 impressions, 17.96% CTR, position 2.4
- `cloud gaming pc`: 203 clicks, 971 impressions, 20.91% CTR, position 12.7
- `cloud gaming`: 156 clicks, 2,207 impressions, 7.07% CTR, position 9.1
- `cloud gaming vietnam`: 145 clicks, 465 impressions, 31.18% CTR, position 1.9

### Key page-level signals

Top page by clicks:
- `https://thinkmay.net/`: 48,832 clicks, 149,414 impressions, 32.68% CTR, position 6.8

Strong market page:
- `https://thinkmay.net/id/`: 14,220 clicks, 24,969 impressions, 56.95% CTR, position 1.9

Major underperformers by impressions:
- `https://thinkmay.net/en/discovery/`: 83,351 impressions, 0.19% CTR, position 14.6
- `https://thinkmay.net/discovery/`: 83,204 impressions, 0.47% CTR, position 11.0
- `https://thinkmay.net/pricing/how-it-works/`: 31,887 impressions, 0.52% CTR, position 1.3
- `https://thinkmay.net/login/`: 40,568 impressions, 1.75% CTR, position 1.1
- `https://thinkmay.net/pricing/`: 42,084 impressions, 1.66% CTR, position 1.6

### Current quick-win / noise queries

High-impression low-CTR opportunities include:
- `cloud gaming asia`
- `cho thuê máy tính chơi game`
- `game đám mây`
- `app chơi game pc trên điện thoại`

But there is also clear **query noise / mismatch** from terms such as:
- `trumbox`
- `trumbox net`
- `trumbox cloud`
- `trumbox cloud gaming`
- `trumbox cloud pc`

This is an important live finding that the current documentation does not emphasize enough.

## Audit summary

### Overall verdict

The SEO documentation is **mostly directionally correct**.

The strongest documents already capture the main truths:
- Thinkmay SEO is healthy but brand-heavy;
- `cloud pc` is the clearest category strength;
- mobile and Indonesia matter a lot;
- discovery pages are underperforming;
- utility/auth pages create SERP noise.

However, the docs need refreshing in three areas:

1. **Current live numbers have shifted slightly** from the 2026-05-17 snapshot.
2. **Indonesia is not just “promising”; it is already one of the site’s strongest organic assets.**
3. **Irrelevant-query contamination is now too visible to ignore** and should be acknowledged in the SEO documentation.

## File-by-file audit

## 1. `docs/seo_growth_implementation_plan.md`

### Verdict

**Strong document. Still broadly accurate.**

### What is still correct

- Brand-heavy diagnosis is still correct.
  - Doc says branded click share is 81.42%; live GSC shows **80.7%**.
- `cloud pc` remains the strongest non-brand/category keyword.
- `cloud gaming` is still weaker than `cloud pc`, but worth pursuing.
- Mobile-first + Vietnam/Indonesia split is still correct.
- `discovery` remains the clearest CTR problem page.
- Utility pages still create SEO noise.

### What is now stale or should be refined

1. Numbers in sections 1, 4, and 5 are now slightly stale because the doc uses a snapshot ending `2026-05-15`.
2. Indonesia should be framed even more strongly as an existing organic strength, not only an opportunity.
3. The plan still underweights the problem of **irrelevant ranking/query overlap**, especially the `trumbox` cluster.
4. The doc should explicitly mention that `/en/discovery/` is even weaker now than the already-bad snapshot suggested.
5. The plan should elevate **commercial rental intent** slightly more, because live GSC confirms `thuê cloud pc` is already meaningful.

### Recommended changes

- Refresh key numbers.
- Add one subsection called **“Query noise / irrelevant rankings”**.
- Add `thuê cloud pc` as a more visible commercial-intent term in the page-priority logic.
- Call out `/id/` as a top-performing organic asset that deserves protection and iteration.

## 2. `docs/google_search/seo_health_summary_2026-05-17.md`

### Verdict

**Still accurate as a dated snapshot, but should be read as historical rather than current.**

### What is still correct

- The document correctly identifies:
  - strong branded demand;
  - strong `cloud pc` visibility;
  - weak discovery CTR;
  - mobile and Indonesia strength.

### What is stale

Because it is a fixed export summary, the exact numbers have drifted:

- branded click share: **81.42%** in the doc vs **80.7%** live;
- `cloud pc` clicks: **2,412** in the doc vs **2,363** live in the current 90-day window;
- `cloud gaming` clicks: **148** in the doc vs **156** live;
- page impressions/clicks shifted slightly across homepage, discovery, pricing, and login pages.

These are not contradictions; they are normal date-window drift.

### What is missing

The current live picture suggests a more important missing section:

- **irrelevant or inherited query clusters** like `trumbox` that can distort opportunity reports.

### Recommended changes

- Keep this file as a dated export-based summary.
- Add a short header note saying it is a **point-in-time snapshot** and should be compared with live GSC before strategic decisions.

## 3. `docs/rybbit/rybbit_seo_combined_analysis_2026-05-17.md`

### Verdict

**Directionally good, but partially constrained by its aggregate Rybbit export.**

### What is still correct

- The combined analysis correctly concludes that:
  - SEO acquisition is healthy;
  - discovery pages need attention;
  - pricing/login pages create search noise;
  - mobile and Indonesia are important.

### What should be refined

1. The file correctly warns that URL-level joins are limited by the export. That caveat should stay.
2. The document should now acknowledge that GSC is surfacing **query-quality issues**, not only page-quality issues.
3. Since the live GSC data now confirms very strong `/id/` performance, the Indonesia point should be upgraded from “worth segmenting” to “already a major organic winner.”

### Recommended changes

- Add a note that future combined analysis must include a **query cleanup / relevance check**.
- Separate:
  - pages with weak CTR but good intent fit;
  - pages ranking for the wrong query families.

## 4. `docs/thinkmay_competitor_positioning_memo.md`

### Verdict

**Supported by live GSC overall.**

### What is still correct

The memo says:
- Thinkmay is stronger on **Cloud PC** than generic **cloud gaming**;
- `cloud gaming` should be used for reach, while `Cloud PC` explains the actual product;
- `quán net trên mây` is stronger as a brand/message frame than as proven search demand.

The live GSC data supports this:
- `cloud pc` is a major non-brand winner;
- `cloud gaming` is visible but weaker;
- `cloud gaming vietnam` performs surprisingly well, but remains a smaller term than `cloud pc`.

### What should be refined

1. The memo may slightly understate how strong current **Indonesia SEO performance** already is.
2. The memo should mention that current live GSC also validates a more commercial rental cluster around `thuê cloud pc`.

### Recommended changes

- Add one short note that GSC confirms not only category interest, but also real traction for rental-intent variants.

## Main findings the docs already get right

1. **Thinkmay is brand-heavy but not brand-only.**
2. **`cloud pc` is the clearest existing SEO moat.**
3. **Mobile is the main SEO surface.**
4. **Indonesia is strategically important.**
5. **Discovery pages are the biggest page-level CTR problem.**
6. **Utility/auth pages consume too much SERP real estate.**

## Main findings the docs underplay or miss

1. **Irrelevant-query contamination is now a real documentation gap.**
   - The `trumbox` cluster is too large to ignore.
   - This can waste optimization effort if not separated from real product-intent queries.

2. **Indonesia’s current SEO strength deserves more prominence.**
   - `/id/` is one of the strongest pages on the site, not just a future bet.

3. **Commercial rental intent is a stronger live signal than some message-led phrase targets.**
   - `thuê cloud pc` currently looks more validated than some broader aspirational keyword concepts.

4. **English discovery performance is extremely weak.**
   - `/en/discovery/` should likely be treated as a specific recovery project, not just an example of mild underperformance.

## Recommended documentation updates

### High priority

1. Update `docs/seo_growth_implementation_plan.md` with refreshed live GSC numbers.
2. Add a new section on **query relevance / query noise**.
3. Explicitly call out `/id/` as a protected high-performing asset.
4. Increase emphasis on `thuê cloud pc` / rental-intent keywords.
5. Mark `docs/google_search/seo_health_summary_2026-05-17.md` as a dated snapshot.

### Medium priority

6. Add a note in the combined Rybbit+SEO analysis that aggregate engagement data is not enough to distinguish good rankings from wrong-query rankings.
7. Add a short live-GSC confirmation note to `docs/thinkmay_competitor_positioning_memo.md` that Cloud PC remains the strongest category position.

## Recommended strategic interpretation

If the docs are meant to guide execution today, the clearest live priorities are:

1. Protect and expand **`cloud pc`** authority.
2. Build/strengthen **commercial rental-intent pages**.
3. Fix **`/discovery/`** and especially **`/en/discovery/`**.
4. Reduce or isolate **utility-page SERP noise**.
5. Treat **Indonesia** as a current growth engine, not only a secondary experiment.
6. Audit and clean up **irrelevant query overlap** before over-investing in CTR optimizations.

## Bottom line

The SEO docs are **mostly good and mostly current**, especially the strategic logic in `docs/seo_growth_implementation_plan.md:15`, `docs/seo_growth_implementation_plan.md:49`, and `docs/seo_growth_implementation_plan.md:121`.

The biggest issue is not that the docs are wrong.
The biggest issue is that they now need one more layer of realism from live GSC:

- stronger emphasis on Indonesia,
- stronger emphasis on rental intent,
- and explicit handling of irrelevant query noise.
