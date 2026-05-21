# Thinkmay Rybbit + SEO Combined Analysis — 2026-05-17

Rybbit file: `C:\thinkmay\docs\marketing\analytics\rybbit\rybbit.json`
GSC file: `C:\thinkmay\docs\marketing\analytics\google_search\https___thinkmay.net_-Performance-on-Search-2026-05-17.xlsx`
Joined daily CSV: `C:\thinkmay\docs\marketing\analytics\rybbit\daily_rybbit_gsc_join_2026-05-17.csv`

## 1. Data coverage

- Rybbit rows: **137** daily/hourly rows from **2026-01-01 → 2026-05-17**.
- GSC daily rows: **89** from **2026-02-16 → 2026-05-15**.
- Overlapping dates used for combined daily analysis: **89** from **2026-02-16 → 2026-05-15**.
- Caveat: the Rybbit export provided here is time-series aggregate only. It does **not** include landing-page/referrer/source rows, so exact URL-level engagement matching is not possible from this file alone. The page-level SEO diagnosis below uses GSC pages plus site-wide Rybbit behavior.

## 2. Rybbit site health

- Total sessions in Rybbit export: **588,931**
- Total users: **731,441**
- Total pageviews: **4,537,537**
- Weighted pages/session: **7.70**
- Weighted bounce rate: **37.4%**
- Weighted session duration: **17m 05s**

Interpretation: engagement is unusually strong for a marketing site. High pages/session and long session duration likely mean many sessions are using product/app flows, not just reading landing pages. That is good commercially, but it means SEO landing-page quality should be judged with segmented reports later, not only this aggregate.

## 3. Overlap: SEO traffic vs site behavior

- Overlap GSC clicks: **78,386**
- Overlap GSC impressions: **337,931**
- Overlap Rybbit sessions: **400,893**
- Organic clicks / total sessions ratio: **19.6%**
- Overlap pages/session: **7.61**
- Overlap bounce rate: **37.1%**
- Overlap session duration: **16m 55s**

Daily correlations on overlapping dates:
|Signal pair|Correlation|
|---|---|
|GSC clicks vs sessions|0.83|
|GSC impressions vs sessions|-0.46|
|GSC clicks vs pageviews|0.90|
|GSC position vs CTR|-0.90|
|GSC clicks vs bounce rate|-0.18|
|GSC clicks vs session duration|0.39|


How to read this: correlation near +1 means the two move together day by day; near 0 means weak daily relationship. If organic clicks strongly correlate with sessions/pageviews, SEO is a major traffic driver. If click spikes correlate with bounce/session-duration drops, SEO may be bringing lower-intent traffic.

## 4. Best traffic days

Top days by Rybbit sessions:
|Date|Sessions|Users|Pageviews|P/session|Bounce|Duration|GSC clicks|
|---|---|---|---|---|---|---|---|
|2026-03-05|6,143|7,486|55,959|9.11|34.7%|15m 36s|1,473|
|2026-02-19|6,036|7,661|52,485|8.70|39.5%|18m 30s|1,244|
|2026-03-01|5,967|7,676|56,892|9.53|34.1%|20m 35s|1,299|
|2026-02-21|5,806|7,367|44,649|7.69|41.2%|18m 11s|1,187|
|2026-03-06|5,778|7,176|51,974|9.00|35.8%|18m 10s|1,355|
|2026-03-07|5,767|7,395|50,492|8.76|37.7%|16m 46s|1,403|
|2026-02-20|5,756|7,294|46,772|8.13|39.1%|18m 08s|1,168|
|2026-02-18|5,712|7,160|46,567|8.15|41.4%|16m 38s|1,303|
|2026-03-08|5,679|7,098|48,966|8.62|35.9%|16m 48s|1,038|
|2026-02-22|5,677|7,300|46,017|8.11|38.5%|18m 16s|933|

Top days by GSC organic clicks:
|Date|GSC clicks|Impr.|CTR|Pos.|Sessions|Bounce|Duration|
|---|---|---|---|---|---|---|---|
|2026-02-28|1,650|3,803|43.39%|4.5|5,667|35.8%|18m 19s|
|2026-03-02|1,563|3,214|48.63%|5.0|5,296|31.5%|19m 60s|
|2026-03-05|1,473|2,990|49.26%|4.5|6,143|34.7%|15m 36s|
|2026-03-07|1,403|2,987|46.97%|4.8|5,767|37.7%|16m 46s|
|2026-03-06|1,355|2,929|46.26%|4.2|5,778|35.8%|18m 10s|
|2026-03-03|1,305|3,082|42.34%|5.8|5,380|32.8%|18m 09s|
|2026-02-18|1,303|3,178|41.00%|6.0|5,712|41.4%|16m 38s|
|2026-03-01|1,299|3,099|41.92%|5.8|5,967|34.1%|20m 35s|
|2026-03-04|1,295|2,702|47.93%|4.2|5,660|33.9%|18m 03s|
|2026-02-19|1,244|3,040|40.92%|6.0|6,036|39.5%|18m 30s|


## 5. Friction days to inspect

High-bounce days with >=100 sessions:
|Date|Sessions|Bounce|P/session|Duration|GSC clicks|
|---|---|---|---|---|---|
|2026-04-10|4,683|44.8%|5.93|13m 30s|794|
|2026-04-09|4,497|43.0%|5.91|14m 21s|645|
|2026-04-13|4,368|42.6%|6.15|15m 52s|691|
|2026-04-11|5,011|41.8%|6.45|14m 44s|834|
|2026-03-21|4,618|41.5%|6.55|17m 01s|839|
|2026-02-18|5,712|41.4%|8.15|16m 38s|1,303|
|2026-02-21|5,806|41.2%|7.69|18m 11s|1,187|
|2026-04-14|4,126|40.5%|5.96|13m 38s|666|
|2026-02-25|4,565|40.0%|8.01|17m 24s|812|
|2026-02-26|4,432|39.8%|7.80|17m 46s|851|

Lowest-engagement days with >=100 sessions:
|Date|Sessions|Bounce|P/session|Duration|GSC clicks|
|---|---|---|---|---|---|
|2026-04-10|4,683|44.8%|5.93|13m 30s|794|
|2026-04-14|4,126|40.5%|5.96|13m 38s|666|
|2026-05-15|4,036|38.9%|6.30|13m 52s|863|
|2026-05-10|4,436|37.4%|6.87|13m 55s|762|
|2026-04-22|3,678|38.0%|6.38|14m 02s|604|
|2026-04-05|5,656|38.0%|6.90|14m 02s|895|
|2026-04-17|4,167|39.4%|7.03|14m 09s|717|
|2026-05-14|3,730|37.4%|7.07|14m 11s|743|
|2026-05-06|3,864|34.3%|7.01|14m 15s|666|
|2026-04-08|4,318|37.6%|7.76|14m 16s|804|


## 6. SEO pages to connect with engagement work

Top GSC pages by clicks:
|Page|Clicks|Impr.|CTR|Pos.|
|---|---|---|---|---|
|https://thinkmay.net/|52,187|154,550|33.77%|6.7|
|https://thinkmay.net/id/|14,323|25,256|56.71%|1.9|
|https://thinkmay.net/en/|4,940|18,331|26.95%|2.4|
|https://thinkmay.net/pricing/|737|44,461|1.66%|1.6|
|https://thinkmay.net/login/|708|42,540|1.66%|1.1|
|https://thinkmay.net/en/login/|554|23,692|2.34%|1.4|
|https://thinkmay.net/discovery/|393|77,266|0.51%|10.1|
|https://thinkmay.net/en/play/|279|25,131|1.11%|1.5|
|https://thinkmay.net/id/login/|254|13,807|1.84%|1.3|
|https://thinkmay.net/en/?next=/play/|233|19,336|1.21%|2.2|
|https://thinkmay.net/id/pricing/|198|17,037|1.16%|1.5|
|https://thinkmay.net/discovery/dredge/|193|1,355|14.24%|7.2|

Low-CTR pages with high impressions:
|Page|Clicks|Impr.|CTR|Pos.|
|---|---|---|---|---|
|https://thinkmay.net/id/reset-password/|6|6,680|0.09%|1.5|
|https://thinkmay.net/id/contact/|3|2,337|0.13%|2.3|
|https://thinkmay.net/id/privacy/|12|6,990|0.17%|2.1|
|https://thinkmay.net/reset-password/|4|2,332|0.17%|1.5|
|https://thinkmay.net/en/discovery/|159|76,855|0.21%|14.5|
|https://thinkmay.net/id/legal/|3|1,385|0.22%|3.0|
|https://thinkmay.net/id/register/|21|5,735|0.37%|1.0|
|https://thinkmay.net/legal/|7|1,616|0.43%|3.2|
|https://thinkmay.net/discovery/|393|77,266|0.51%|10.1|
|https://thinkmay.net/pricing/how-it-works/|169|32,356|0.52%|1.3|
|https://thinkmay.net/en/faq/|28|5,256|0.53%|3.3|
|https://thinkmay.net/faq/|111|18,764|0.59%|1.5|

Page ranking opportunities: pages with >=1,000 impressions and position 4–20:
|Page|Clicks|Impr.|CTR|Pos.|
|---|---|---|---|---|
|https://thinkmay.net/|52,187|154,550|33.77%|6.7|
|https://thinkmay.net/discovery/|393|77,266|0.51%|10.1|
|https://thinkmay.net/en/discovery/|159|76,855|0.21%|14.5|
|https://thinkmay.net/blog/build-gaming-pc-vs-cloud-pc-thinkmay/|34|2,309|1.47%|7.2|
|https://thinkmay.net/en/pricing/how-it-works/|28|1,760|1.59%|4.3|
|https://thinkmay.net/blog/choi-game-aaa-dien-thoai/|62|1,704|3.64%|5.3|
|https://thinkmay.net/discovery/dredge/|193|1,355|14.24%|7.2|
|https://thinkmay.net/blog/choi-gta-v-tren-macbook/|50|1,266|3.95%|6.3|


## 7. Country and device fit

GSC countries:
|Country|Clicks|Impr.|CTR|Pos.|Click share|
|---|---|---|---|---|---|
|Vietnam|54,813|206,511|26.54%|8.4|69.9%|
|Indonesia|17,072|26,927|63.40%|3.0|21.8%|
|Malaysia|1,162|2,388|48.66%|4.9|1.5%|
|Brazil|435|4,514|9.64%|15.6|0.6%|
|Japan|344|2,093|16.44%|7.0|0.4%|
|Philippines|328|1,769|18.54%|11.5|0.4%|
|United States|325|31,257|1.04%|9.1|0.4%|
|Iraq|318|3,628|8.77%|24.4|0.4%|
|Singapore|278|1,229|22.62%|5.9|0.4%|
|Cambodia|247|549|44.99%|7.7|0.3%|

GSC devices:
|Device|Clicks|Impr.|CTR|Pos.|Click share|
|---|---|---|---|---|---|
|Mobile|51,365|133,946|38.35%|5.2|65.5%|
|Desktop|24,947|199,222|12.52%|13.0|31.8%|
|Tablet|2,074|4,763|43.54%|4.8|2.6%|


Read: mobile is the primary SEO surface, and Indonesia is already a meaningful organic market. Rybbit aggregate engagement should be segmented by country/device next; if Indonesian/mobile bounce is good, build Indonesian keyword pages aggressively. If not, improve localization and mobile onboarding before scaling SEO content.

## 8. Combined diagnosis

1. **SEO acquisition is healthy, but brand-led.** GSC shows strong branded demand and good category rankings. Rybbit shows the site/product can hold attention once users arrive.
2. **The biggest missing view is landing-page engagement by URL/source.** The current Rybbit export proves aggregate health, but cannot tell whether `/cloud-pc/`, `/pricing/`, `/discovery/`, etc. convert or bounce.
3. **Discovery pages need attention.** GSC shows huge impressions and very low CTR for discovery pages. If Rybbit page-level data later shows weak engagement too, these should be redesigned or retitled around game/search intent.
4. **Pricing/login pages create search noise.** They rank and get impressions but CTR is low. These may be navigational/support queries, or Google showing utility pages for broad searches. Consider noindex only if they harm SERP quality, but first inspect query/page pairs in GSC.
5. **Mobile-first SEO is validated.** GSC mobile clicks dominate, and Thinkmay product-market fit is mobile-heavy. New keyword pages should be designed for phone users first: fast, direct, Vietnamese/Indonesian language, clear “play now” CTA.
6. **Query relevance needs its own check.** Later live GSC review showed a visible `trumbox` query cluster, which means the combined workflow should separate true product-intent keywords from irrelevant or inherited rankings before deciding what to optimize.

## 9. Recommended next exports

To make the combined analysis much sharper, export these from Rybbit if possible:

- Landing page / path: sessions, users, bounce rate, session duration, pageviews
- Referrer or source/medium, especially Google organic
- Country + device breakdown with engagement metrics
- Event/conversion metrics: signup, login, pricing click, play/start session, payment
- Same date range as GSC: 2026-02-16 → 2026-05-15

## 10. Practical next actions

1. Build dedicated pages under `thinkmay.net` for `cloud pc`, `cloud gaming`, `chơi game PC trên điện thoại`, and game-specific pages like GTA V/FiveM and FC Online.
2. Add UTM or event tracking to SEO landing-page CTAs: `signup`, `pricing`, `play`, `install`, `discord/support`.
3. Create a weekly dashboard joining GSC URL/query data with Rybbit landing-page engagement.
4. Prioritize pages that have both high GSC impressions and weak CTR/engagement.
5. Segment Vietnam vs Indonesia and mobile vs desktop before deciding which language/market pages to scale.
6. Add a query-cleanup step to the weekly workflow so irrelevant clusters do not compete with real Cloud PC / Cloud Gaming opportunities.
