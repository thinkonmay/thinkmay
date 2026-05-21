# Thinkmay website SEO, performance, and docs audit

_Date: 2026-05-21_

## Scope

This audit combines:

- **Google Search Console** data for `https://thinkmay.net/`
- **Rybbit analytics** from site `12` (`official.thinkmay.net` / `dev-thinkmay.netlify.app` configuration)
- **Technical page analysis** using Lighthouse-style on-page checks
- **Documentation review** for `docs/`

## Important note on analytics sources

You confirmed that `official.thinkmay.net` is a correct site because the product uses two domains: `thinkmay.net` and `official.thinkmay.net`.

That makes the current analytics picture coherent:

- **GSC** is available for `https://thinkmay.net/`
- **Rybbit site 12** appears to be the active high-volume analytics property
- sample Rybbit sessions under site 12 show live traffic on hostnames such as:
  - `thinkmay.net`
  - `www.thinkmay.net`

So this audit treats:

- **Search performance** as primarily measured via GSC on `thinkmay.net`
- **engagement / behavior** as primarily measured via Rybbit site `12`

## Executive summary

The website is healthy in demand terms, but uneven in execution.

### Strongest positives

1. **Search demand is real and growing in the right category.**
   `cloud pc` is already a strong non-brand keyword, and rental-intent variants are validated.

2. **Indonesia is not speculative.**
   It is already one of the strongest organic markets.

3. **Homepage and pricing are technically acceptable.**
   Their performance is not elite, but they are not the main bottleneck.

4. **Rybbit confirms the site/product can hold attention.**
   Session duration and pages/session are strong.

### Biggest problems

1. **The site is still heavily brand-led in SEO.**
2. **`/discovery/` and especially `/en/discovery/` are underperforming badly.**
3. **Analytics signal quality looks noisy.**
   The Rybbit event stream appears to contain large amounts of system/process data.
4. **Docs overstate how clean and selective the analytics pipeline is.**

## 1. SEO audit

## 1.1 Search acquisition health

Live GSC baseline, `2026-02-21` to `2026-05-21`:

### Brand vs non-brand

- Branded clicks: **52,269**
- Branded click share: **80.7%**
- Non-branded clicks: **12,469**

Interpretation:
- Search is healthy.
- But it is still too dependent on brand demand.
- The site has category traction, but not yet category ownership.

## 1.2 What Thinkmay already wins

Current strong category/commercial queries:

- `cloud pc`: **2,363 clicks**, **9,005 impressions**, **26.24% CTR**, **position 4.2**
- `cloudpc`: **443 clicks**, **1,576 impressions**, **28.11% CTR**, **position 2.9**
- `thuê cloud pc`: **255 clicks**, **1,420 impressions**, **17.96% CTR**, **position 2.4**
- `cloud gaming vietnam`: **145 clicks**, **465 impressions**, **31.18% CTR**, **position 1.9**

Interpretation:
- **Cloud PC** is the clearest SEO strength.
- **Rental/commercial intent is real**, not hypothetical.
- The site should lean harder into Cloud PC and rental framing before broadening too far.

## 1.3 What is still weak

- `cloud gaming`: **156 clicks**, **2,207 impressions**, **7.07% CTR**, **position 9.1**
- `cloud gaming pc`: **203 clicks**, **971 impressions**, **20.91% CTR**, **position 12.7**

Interpretation:
- Thinkmay is visible on `cloud gaming`, but does not own it.
- `cloud gaming` should remain an acquisition term, but the business should convert users through the stronger Cloud PC narrative.

## 1.4 Country and device fit

### Country split

- Vietnam: **52,168 clicks**, **208,064 impressions**, **25.07% CTR**, **position 8.7**
- Indonesia: **16,639 clicks**, **26,886 impressions**, **61.89% CTR**, **position 3.2**
- Malaysia: **1,156 clicks**, **2,454 impressions**, **47.11% CTR**, **position 5.2**

### Device split

- Mobile: **48,493 clicks**, **132,662 impressions**, **36.55% CTR**, **position 5.3**
- Desktop: **24,727 clicks**, **211,702 impressions**, **11.68% CTR**, **position 13.3**
- Tablet: **2,003 clicks**, **4,773 impressions**, **41.97% CTR**, **position 5.0**

Interpretation:
- The mobile-first story is strongly validated.
- Indonesia is already a major organic asset.
- SEO work should continue to prioritize **mobile landing-page quality** and **Indonesia-localized expansion**.

## 1.5 Page-level SEO issues

### Biggest underperformers by impressions

- `/en/discovery/`: **83,351 impressions**, **0.19% CTR**, **position 14.6**
- `/discovery/`: **83,204 impressions**, **0.47% CTR**, **position 11.0**
- `/pricing/how-it-works/`: **31,887 impressions**, **0.52% CTR**, **position 1.3**
- `/login/`: **40,568 impressions**, **1.75% CTR**, **position 1.1**
- `/pricing/`: **42,084 impressions**, **1.66% CTR**, **position 1.6**

Interpretation:
- **Discovery** is the biggest SEO product page problem.
- **English discovery** is especially weak and may be attracting impressions without matching intent.
- **Pricing/login/how-it-works** are creating SERP noise and should be handled more deliberately.

## 1.6 Query-quality issue

Current GSC also shows visible **irrelevant or weak-fit query clusters**, especially:

- `trumbox`
- `trumbox net`
- `trumbox cloud`
- `trumbox cloud gaming`
- `trumbox cloud pc`

Interpretation:
- Not every high-impression/low-CTR keyword is a real opportunity.
- Some are likely inherited, mismatched, or irrelevant rankings.
- Query cleanup needs to be part of the SEO workflow, not just page optimization.

## 1.7 Indexing and technical search basics

GSC checks:

- Sitemap: `https://thinkmay.net/sitemap.xml`
  - processed successfully
  - no errors
  - no warnings
- Homepage `https://thinkmay.net/`
  - submitted and indexed
  - indexing allowed
  - robots allowed
  - canonical matches
  - rich results pass
- Discovery page `https://thinkmay.net/discovery/`
  - submitted and indexed
  - indexing allowed
  - robots allowed
  - canonical matches
  - rich results pass

Interpretation:
- Indexing is **not** the main issue.
- Ranking/CTR/intent alignment is the issue.

## 2. Performance and UX audit

## 2.1 Rybbit engagement overview (site 12)

Overview returned:

- Sessions: **612,566**
- Users: **380,815**
- Pageviews: **4,692,210**
- Pages/session: **7.66**
- Bounce rate: **37.55%**
- Avg session duration: **~16m 59s**

Interpretation:
- Engagement is strong at the site/product level.
- However, because many sessions clearly include app/product flows (`/play/`, `/login/`, `/payment/`, `/remote/`), these aggregate engagement metrics should not be treated as pure landing-page quality signals.

## 2.2 Sample session behavior

Recent session samples show:

- homepage -> `/remote/`
- homepage -> `/payment/`
- `/play/` -> `/login/`
- direct, referral, and organic entry paths
- both anonymous and identified users

Interpretation:
- The website is tightly mixed with the product app journey.
- This is commercially good, but analytically messy.
- SEO landing pages need their own cleaner event and funnel reporting.

## 2.3 Technical page performance

### Homepage (`https://thinkmay.net/`)

Lighthouse-style results:
- Performance: **0.71**
- SEO: **1.00**
- Accessibility: **0.93**
- LCP: **2.66s**
- TBT: **8.5ms**
- Total bytes: **~1.45MB**

Read:
- acceptable
- not elite, but not the biggest bottleneck

### Discovery (`https://thinkmay.net/discovery/`)

Lighthouse-style results:
- Performance: **0.30**
- SEO: **1.00**
- Accessibility: **0.83**
- LCP: **4.22s**
- TBT: **1047ms**
- Interactive: **6.57s**
- Total bytes: **~5.92MB**
- Server response time: **1244ms**

Read:
- this page is a serious performance problem
- it is also already the main SEO CTR problem
- that makes `discovery` the clearest combined SEO + UX priority

### Pricing (`https://thinkmay.net/pricing/`)

Lighthouse-style results:
- Performance: **0.72**
- SEO: **1.00**
- Accessibility: **0.91**
- LCP: **2.43s**
- TBT: **9ms**
- Total bytes: **~1.09MB**

Read:
- acceptable
- pricing is more of a SERP-intent/snippet problem than a raw performance problem

## 2.4 Locale / redirect observation

The on-page performance checks resolved:
- `https://thinkmay.net/` -> `https://thinkmay.net/en/`
- `https://thinkmay.net/discovery/` -> `https://thinkmay.net/en/discovery/`
- `https://thinkmay.net/pricing/` -> `https://thinkmay.net/en/pricing/`

This suggests locale/redirect behavior that deserves careful review alongside canonical and hreflang logic.

Interpretation:
- It may be correct behavior for some users/agents.
- But it increases the chance of intent mismatch or weaker English performance if not managed carefully.
- It is likely related to why `/en/discovery/` has such poor SERP performance.

## 3. Analytics quality audit

## 3.1 Rybbit MCP health

Working endpoints:
- site details
- overview
- session list
- event names

Broken or outdated endpoints (404 in MCP/API path used here):
- get sites
- live visitors
- metrics breakdowns
- overview timeseries
- error names

Interpretation:
- Rybbit analytics is usable, but the MCP integration is only partially aligned with the current API.
- That limits how much dimensional analysis can be done automatically right now.

## 3.2 Event quality issue

Rybbit event-name output preview included many system/process-like events such as:

- `chrome`
- `svchost`
- `updater`
- `dllhost`
- `conhost`
- `WmiPrvSE`
- `RuntimeBroker`
- `steamwebhelper`

Interpretation:
- This is a major analytics quality concern.
- The event stream appears too noisy for clean persona or SEO-conversion analysis unless normalized/filter-cleaned.
- It weakens confidence in any documentation that says the telemetry layer strictly excludes system/background activity.

## 4. Docs audit

## 4.1 Docs that are mostly correct

The SEO docs are broadly directionally sound:

- `docs/marketing/seo/seo_growth_implementation_plan.md`
- `docs/marketing/analytics/google_search/seo_health_summary_2026-05-17.md`
- `docs/marketing/analytics/rybbit/rybbit_seo_combined_analysis_2026-05-17.md`
- `docs/marketing/strategy/thinkmay_competitor_positioning_memo.md`

They correctly emphasize:
- brand-heavy SEO
- Cloud PC strength
- mobile-first traffic
- Indonesia importance
- discovery-page weakness

## 4.2 Docs that now look too strong or too clean

The bigger concern is analytics/privacy wording in docs such as:

- `docs/product/guides/data_privacy.md`
- `docs/product/guides/user_doc.md`
- `docs/employee/playbooks/employee_doc.md`

These documents say or strongly imply that analytics:
- strictly blacklist system processes
- ignore background tasks and utilities
- only listen to high-intent apps

But the live Rybbit event-name output preview suggests that system/process-like events are still heavily present.

Interpretation:
- The docs may describe the intended design, not the current real output.
- As written, they sound too absolute.
- They should be softened or verified before being treated as user-facing trust claims.

## 4.3 Documentation gap

The docs now need stronger acknowledgment of:

1. **query noise / irrelevant rankings**
2. **analytics event normalization debt**
3. **the gap between aggregate engagement health and landing-page attribution clarity**

## 5. Priority actions

## Immediate priorities

1. **Fix `/discovery/` performance and SEO copy first**
   - slowest important page
   - one of the largest impression pools
   - terrible CTR

2. **Fix `/en/discovery/` or de-prioritize it**
   - extremely high impressions
   - almost no CTR
   - likely intent/locale mismatch

3. **Lean harder into Cloud PC + rental intent**
   - `cloud pc`
   - `cloudpc`
   - `thuê cloud pc`

4. **Protect and expand Indonesia**
   - `/id/` is already a top-performing page
   - localized commercial/category paths should be a priority

5. **Clean the analytics event taxonomy**
   - normalize raw process events
   - separate system/background noise from real app/game intent
   - otherwise persona and funnel analysis remain noisy

## Secondary priorities

6. Review whether locale redirects are helping or hurting discovery/indexation and CTR.
7. Reduce SERP noise from utility pages where appropriate.
8. Add better page-level event tracking for SEO landing pages specifically.

## Bottom line

The website has **real search demand, strong category footing, and strong engagement**, but the execution is uneven.

The clearest business-level conclusion is:

> **Thinkmay already wins more on Cloud PC and rental-style intent than on generic Cloud Gaming, and the next gains will come from fixing discovery pages, protecting Indonesia, and cleaning analytics signal quality.**

The clearest documentation-level conclusion is:

> **The SEO docs are mostly good, but the analytics/privacy docs currently look cleaner than the live event stream suggests.**
