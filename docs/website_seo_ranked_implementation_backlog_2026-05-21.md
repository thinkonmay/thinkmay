# Thinkmay ranked SEO implementation backlog

_Date: 2026-05-21_

Derived from:
- `docs/website_seo_performance_docs_audit_2026-05-21.md`
- `docs/seo_growth_implementation_plan.md`
- live GSC data for `https://thinkmay.net/`
- Rybbit site `12`

This backlog is ranked by expected business impact, speed to value, and confidence.

---

## How to use this backlog

Priority levels:
- **P0** = do next; highest impact / clearest evidence
- **P1** = important after P0
- **P2** = useful expansion work after core fixes land

Scoring logic:
- **Impact** = likely effect on clicks, CTR, signup/play/payment, or trust
- **Confidence** = how strongly current analytics support the fix
- **Effort** = relative build complexity

---

## P0 — highest priority

## 1) Rebuild `discovery` for SEO and performance

**Why this is #1**
- One of the largest impression pools in GSC
- Very weak CTR
- Worst technical performance among audited core pages
- Likely hurting both rankings and conversion quality

**Evidence**
- `/discovery/`: ~83k impressions, ~0.47% CTR, position ~11
- `/en/discovery/`: ~83k impressions, ~0.19% CTR, position ~14.6
- Lighthouse-style check for `/discovery/`:
  - performance ~0.30
  - LCP ~4.22s
  - TBT ~1047ms
  - total bytes ~5.9MB

**Main files**
- `website/app/[locale]/(e-commerce)/discovery/page.tsx`
- any discovery-specific components imported by this page
- `website/app/sitemap.ts`

**Implementation**
- Add static crawlable intro copy above the carousel
- Add text-link blocks to core money pages and key game pages
- Add FAQ section below discovery content
- Reduce page weight and JS cost
- Move non-critical carousels/lists lower on the page
- Review whether heavy assets can be deferred or simplified

**Acceptance criteria**
- materially lower payload and main-thread work
- improved discovery LCP/TBT
- discovery page has crawlable copy, internal links, and FAQ
- GSC CTR improves after recrawl/indexing window

**Impact:** Very high  
**Confidence:** Very high  
**Effort:** Medium

---

## 2) Treat `/en/discovery/` as a separate recovery project

**Why this is #2**
- It is not just weak; it is dramatically weak
- English intent may not match the current page structure or ranking queries
- It may be absorbing crawl/impression budget without meaningful value

**Main files**
- `website/app/[locale]/(e-commerce)/discovery/page.tsx`
- locale-specific metadata/config used for discovery

**Implementation**
- Audit actual English ranking queries against the page promise
- Rewrite title/H1/description for English search intent
- If it still looks low-value after review, consider de-prioritizing or noindexing the English discovery page

**Acceptance criteria**
- explicit decision: recover vs de-prioritize
- if kept indexable, metadata and body copy are English-intent-specific

**Impact:** Very high  
**Confidence:** High  
**Effort:** Low-medium

---

## 3) Build `/cloud-pc/` as the main category money page

**Why this is #3**
- `cloud pc` is the clearest non-brand SEO strength
- It aligns with the product truth better than generic `cloud gaming`
- It can absorb both category and commercial traffic

**Evidence**
- `cloud pc`: strong clicks, strong CTR, page-1 visibility
- `cloudpc` also performs well

**Main files**
- `website/app/[locale]/(e-commerce)/(seo)/cloud-pc/page.tsx`
- `website/components/seo/*` reusable sections
- `website/app/sitemap.ts`

**Implementation**
- Build dedicated landing page with:
  - clear H1
  - Cloud PC explanation
  - pricing CTA
  - mobile/weak-device use cases
  - FAQ
  - internal links to pricing/discovery/game pages
- Add canonical, hreflang, OG, FAQPage, BreadcrumbList, Service/Product schema

**Acceptance criteria**
- page is indexable and in sitemap
- page receives impressions for `cloud pc` cluster
- page drives measurable CTA events

**Impact:** Very high  
**Confidence:** Very high  
**Effort:** Medium

---

## 4) Build `/thue-may-tinh-online/` and lean into rental intent

**Why this is #4**
- Commercial intent is already validated
- This is likely closer to money than message-led awareness pages
- It supports Cloud PC with clearer transactional framing

**Evidence**
- GSC shows traction around `thuê cloud pc` and related rental intent

**Main files**
- `website/app/[locale]/(e-commerce)/(seo)/thue-may-tinh-online/page.tsx`
- pricing and homepage internal links

**Implementation**
- Build a rental-intent landing page with:
  - plan comparison
  - “buy PC vs rent” framing
  - pricing FAQs
  - links to `/pricing/` and `/cloud-pc/`

**Acceptance criteria**
- page is indexed
- page receives impressions for rental terms
- page becomes a measurable conversion entry point

**Impact:** Very high  
**Confidence:** High  
**Effort:** Medium

---

## 5) Build `/cloud-gaming/`, but keep it acquisition-first

**Why this is #5**
- The keyword matters, but Thinkmay is weaker here than on Cloud PC
- This page should capture broader demand and hand off to the stronger Cloud PC story

**Evidence**
- `cloud gaming` is visible but weaker than `cloud pc`
- live SERP is more competitive and noisier

**Main files**
- `website/app/[locale]/(e-commerce)/(seo)/cloud-gaming/page.tsx`
- reusable SEO components

**Implementation**
- explain cloud gaming simply
- differentiate Thinkmay from catalog-only services
- bridge into “your own Cloud PC” quickly
- target `cloud gaming`, `cloud game`, and supporting variants without overcommitting to weaker modifiers

**Acceptance criteria**
- indexed and in sitemap
- receives impressions for cloud gaming cluster
- clearly routes users toward Cloud PC / pricing / play

**Impact:** High  
**Confidence:** High  
**Effort:** Medium

---

## 6) Protect and expand Indonesia pages

**Why this is #6**
- Indonesia is already a strong organic market, not just a test market
- `/id/` is one of the best-performing pages on the site

**Main files**
- `website/app/[locale]/(e-commerce)/(seo)/id/...`
- `website/i18n/routing.ts`
- homepage/internal links to Indonesian pages if needed

**Implementation**
- build:
  - `/id/cloud-pc/`
  - `/id/cloud-gaming/`
  - `/id/sewa-cloud-pc/`
- keep language natural and commercial, not just literal translation

**Acceptance criteria**
- localized pages are indexable and linked
- Indonesian pages start earning impressions/clicks independently

**Impact:** High  
**Confidence:** Very high  
**Effort:** Medium

---

## 7) Add a proper SEO analytics wrapper and landing-page event taxonomy

**Why this is #7**
- Aggregate engagement is strong, but landing-page attribution is weak
- Current Rybbit event stream is too noisy for clean SEO analysis

**Main files**
- `website/utils/analytics.ts`
- `website/app/[locale]/(e-commerce)/(seo)/**/*`
- `website/backend/actions/background.ts`

**Implementation**
- create a stable wrapper for SEO events
- track:
  - `seo_page_view`
  - `seo_cta_click`
  - `seo_pricing_click`
  - `seo_signup_click`
  - `seo_play_click`
- include props like:
  - `page_type`
  - `primary_keyword`
  - `locale`
  - `slug`
  - `market`

**Acceptance criteria**
- SEO landing pages emit consistent events
- reports can distinguish landing-page traffic from product-process noise

**Impact:** High  
**Confidence:** High  
**Effort:** Low-medium

---

## P1 — important after core wins

## 8) Fix `/pricing/` metadata and content intent

**Why**
- huge impressions
- low CTR
- pricing is commercially important but likely mismatched in snippet/copy

**Main files**
- `website/app/[locale]/(e-commerce)/pricing/page.tsx`

**Implementation**
- improve title/meta
- add pricing FAQ
- link more clearly to Cloud PC and rental pages

**Impact:** High  
**Confidence:** High  
**Effort:** Low

---

## 9) Fix `/pricing/how-it-works/`

**Why**
- very large impression count
- poor CTR
- likely metadata + intent mismatch

**Main files**
- `website/app/[locale]/(e-commerce)/pricing/how-it-works/page.tsx`

**Implementation**
- localize metadata via `generateMetadata`
- correct canonical/hreflang
- remove stale/placeholder metadata patterns
- add FAQPage schema

**Impact:** High  
**Confidence:** High  
**Effort:** Low-medium

---

## 10) Add noindex / index-management cleanup for auth and utility pages

**Why**
- login and utility routes create SERP noise
- some may be fine navigationally, others should not compete for index space

**Main files**
- auth pages under `website/app/[locale]/(auth)/...`
- metadata helpers
- `website/public/robots.txt`

**Implementation**
- review and apply page-level noindex where appropriate
- do not rely only on robots if Google needs to see `noindex`

**Impact:** Medium-high  
**Confidence:** High  
**Effort:** Low

---

## 11) Review locale redirect and canonical behavior

**Why**
- external page analysis resolved routes to `/en/` variants
- this may be harmless, or it may contribute to English mismatch and weaker SEO on some paths

**Main files**
- locale middleware/routing config
- metadata canonicals/hreflang

**Implementation**
- confirm homepage/discovery/pricing locale behavior for bots and users
- confirm canonical/hreflang consistency against redirected paths

**Impact:** Medium-high  
**Confidence:** Medium  
**Effort:** Medium

---

## 12) Clean Rybbit event normalization / background-process noise

**Why**
- live event stream preview includes many system/process-like names
- this weakens trust in persona and conversion analysis
- it also creates documentation risk

**Main files**
- `worker/daemon/analytics/rybbit/*`
- any blacklist/normalization logic tied to emitted events
- `website/backend/actions/background.ts`

**Implementation**
- normalize process-path events into app/game classes
- suppress obvious system/background noise
- separate user-interest events from machine-noise events

**Impact:** High  
**Confidence:** Medium-high  
**Effort:** Medium-high

---

## P2 — expansion and leverage work

## 13) Build game-intent pages after category pages are live

Priority order:
1. `/choi-gta-v-tren-dien-thoai/`
2. `/choi-fivem-tren-dien-thoai/`
3. `/choi-fc-online-tren-dien-thoai/`
4. `/choi-black-myth-wukong-tren-dien-thoai/`

**Why**
- these are strong expansion pages
- but they should come after the category and rental pages are in place

**Impact:** Medium-high  
**Confidence:** Medium  
**Effort:** Medium

---

## 14) Add homepage and blog internal-linking upgrades

**Why**
- current authority needs to be routed into the new money pages
- strong pages can accelerate new-page discovery and ranking

**Main files**
- homepage sections
- ranking blog posts already identified in docs

**Impact:** Medium  
**Confidence:** High  
**Effort:** Low

---

## 15) Create a weekly query cleanup workflow

**Why**
- not every page-2 keyword is a real opportunity
- current GSC shows mismatch/noise clusters

**Implementation**
- every weekly SEO review should separate:
  - real product-intent opportunities
  - irrelevant inherited rankings
  - navigational utility-page noise

**Impact:** Medium  
**Confidence:** Very high  
**Effort:** Low

---

## Recommended execution order

If only a few things can be done next, do them in this order:

1. Rebuild `/discovery/`
2. Decide recover vs de-prioritize for `/en/discovery/`
3. Build `/cloud-pc/`
4. Build `/thue-may-tinh-online/`
5. Build `/cloud-gaming/`
6. Protect and expand Indonesia pages
7. Add SEO analytics wrapper
8. Fix `/pricing/`
9. Fix `/pricing/how-it-works/`
10. Clean event normalization

---

## Success metrics to watch

### SEO
- non-brand clicks
- impressions and CTR for `cloud pc`, `thuê cloud pc`, `cloud gaming`
- discovery CTR improvement
- `/id/` and Indonesian landing page growth

### Product/engagement
- landing-page sessions
- signup clicks
- play/start clicks
- payment starts/successes

### Analytics quality
- lower noise in event taxonomy
- cleaner app/game event naming
- easier segmentation by landing page and intent
