# Thinkmay SEO Growth Implementation Plan

_Last updated: 2026-05-17_

This plan is based on:

- Google Search Console export: `docs/google_search/https___thinkmay.net_-Performance-on-Search-2026-05-17.xlsx`
- SEO summary: `docs/google_search/seo_health_summary_2026-05-17.md`
- Rybbit export: `docs/rybbit/rybbit.json`
- Rybbit + SEO combined analysis: `docs/rybbit/rybbit_seo_combined_analysis_2026-05-17.md`
- Frontend source inspection: `website/` Next.js app using `next-intl`, locales `vi`, `en`, `id`
- Live GSC validation check on 2026-05-21 via MCP (`https://thinkmay.net/`, 2026-02-21 -> 2026-05-21)

## 1. Executive summary

Thinkmay's SEO is already healthy, but it is still too dependent on branded demand.

Current GSC snapshot, `2026-02-16 -> 2026-05-15`:

- Organic clicks: **78,386**
- Impressions: **337,931**
- Average CTR: **23.20%**
- Impression-weighted average position: **9.8**
- Query rows: **1,000**
- Page rows: **1,000**
- Branded query click share: **81.42%**
- Non-branded clicks: **12,624**

Current Rybbit snapshot, `2026-01-01 -> 2026-05-17`:

- Sessions: **588,931**
- Users: **731,441**
- Pageviews: **4,537,537**
- Pages/session: **7.70**
- Bounce rate: **37.4%**
- Avg session duration: **17m 05s**

Daily joined GSC + Rybbit window, `2026-02-16 -> 2026-05-15`:

- Organic clicks: **78,386**
- Rybbit sessions: **400,893**
- Organic click / session ratio: **19.6%**
- GSC clicks vs sessions correlation: **0.83**
- GSC clicks vs pageviews correlation: **0.90**
- GSC clicks vs bounce correlation: **-0.18**
- GSC clicks vs session duration correlation: **0.39**

Interpretation: SEO is a real traffic driver and does not appear to be low-quality traffic. When organic clicks rise, sessions and pageviews rise strongly, while bounce does not rise. This justifies investing in dedicated SEO landing pages.

Live GSC spot-check on 2026-05-21 still supports the overall diagnosis: branded click share remains about **80.7%**, `cloud pc` remains the clearest category winner, and Indonesia remains a major organic market. The biggest newly-visible gap is **query noise / irrelevant overlap** (for example the `trumbox` cluster), which should be separated from true product-intent opportunities before prioritizing CTR work.

The main strategic move: make Thinkmay own the Vietnam and Indonesia search space for **cloud gaming** and **cloud PC** first, then support those pillars with lower-volume but high-message pages such as **choi game PC tren dien thoai** and **quan net tren may**, then expand into game-specific intent pages like GTA V/FiveM, FC Online, and Black Myth: Wukong.

## 2. Strategic SEO position

Thinkmay has three overlapping search positions. Use all three, but assign them different jobs.

| Positioning | Search role | Product truth | User-facing angle |
|---|---|---|---|
| Cloud gaming | Mainstream acquisition keyword | Users want to play games instantly | Easy to understand, broad demand |
| Cloud PC | Accurate product/category keyword | Thinkmay gives users a full remote PC with data/session continuity | Strong for pricing, specs, serious users |
| Quan net tren may / tiem net tren may | Vietnam-native emotional positioning | Like an internet cafe, but on any device | Relatable, memorable, stronger for brand/social than core SEO demand |

Recommended external message:

> Thinkmay is a cloud PC for gaming — a "quan net tren may" that lets users play PC games on mobile, laptop, or weak devices.

Do not choose only one phrase. Build a topical map where the homepage and core pages reinforce all three.

## 3. Main goals

### 90-day SEO goals

1. Move from brand-led SEO to category-led SEO.
2. Push `cloud pc` from position ~4 into top 1-3.
3. Push `cloud gaming` from position ~9 into top 5 as the primary 90-day goal; treat top 3 as a stretch goal because the head SERP is crowded by larger brands and editorial pages.
4. Create dedicated Vietnamese keyword pages for high-intent terms.
5. Create first serious Indonesian keyword pages because Indonesia already contributes **21.8%** of GSC clicks.
6. Fix low-CTR/high-impression pages such as `/discovery/`, `/en/discovery/`, `/pricing/how-it-works/`, and utility/auth pages.
7. Add analytics events so SEO work can be tied to signup/play/payment outcomes, not only traffic.

### North-star SEO metric

Track weekly:

```text
Non-brand organic clicks -> SEO landing page sessions -> signup -> play/start session -> payment
```

Current export cannot fully track this because Rybbit is aggregate time-series only. See section 13 for tracking requirements.

## 4. Current SEO strengths

### 4.1 Brand dominance

Top branded queries:

| Query | Clicks | Impressions | CTR | Position |
|---|---:|---:|---:|---:|
| thinkmay | 39,542 | 46,446 | 85.14% | 1.0 |
| thinkmay cloud | 3,252 | 3,862 | 84.21% | 1.0 |
| thinkmay cloud pc | 3,183 | 4,138 | 76.92% | 1.0 |
| think may | 2,020 | 2,432 | 83.06% | 1.0 |

This shows strong brand recall. Protect this with consistent titles, schema, social profiles, and navigational UX.

### 4.2 Category foothold already exists

Important non-brand/category queries:

| Query | Clicks | Impressions | CTR | Position | Priority |
|---|---:|---:|---:|---:|---|
| cloud pc | 2,412 | 9,284 | 25.98% | 4.1 | Very high |
| cloud gaming | 148 | 2,053 | 7.21% | 9.3 | Very high |
| cloud pc free | 202 | 1,581 | 12.78% | 4.3 | High |
| cloud game | 100 | 1,352 | 7.40% | 9.8 | High |
| cloud gaming pc | 206 | 967 | 21.30% | 12.4 | High |
| pc cloud gaming | 184 | 786 | 23.41% | 6.8 | High |
| cloud pc gaming | 194 | 664 | 29.22% | 10.6 | High |
| thue may tinh online | 84 | 507 | 16.57% | 4.4 | Very high |

Google already sees Thinkmay as relevant. The fastest SEO wins are dedicated pages, stronger internal links, and better page/query matching.

### 4.3 Mobile and Indonesia are validated

GSC device split:

| Device | Clicks | Impressions | CTR | Position | Click share |
|---|---:|---:|---:|---:|---:|
| Mobile | 51,365 | 133,946 | 38.35% | 5.2 | 65.5% |
| Desktop | 24,947 | 199,222 | 12.52% | 13.0 | 31.8% |
| Tablet | 2,074 | 4,763 | 43.54% | 4.8 | 2.6% |

GSC country split:

| Country | Clicks | Impressions | CTR | Position | Click share |
|---|---:|---:|---:|---:|---:|
| Vietnam | 54,813 | 206,511 | 26.54% | 8.4 | 69.9% |
| Indonesia | 17,072 | 26,927 | 63.40% | 3.0 | 21.8% |

This supports a mobile-first Vietnam + Indonesia SEO strategy.

Live GSC validation also shows `https://thinkmay.net/id/` is one of the strongest organic assets on the site, so Indonesia should be treated as an already-performing market, not only a future expansion experiment.

## 5. Current SEO problems

### 5.1 Branded traffic concentration

**81.42%** of query clicks are branded. This is good for brand health but limits scalable search growth.

Risk: if Facebook/TikTok demand slows, SEO may not yet capture enough fresh non-brand demand.

Fix: build high-intent non-brand landing pages under `thinkmay.net`, not separate microsites first.

Also separate true category opportunities from irrelevant-query overlap. Current live GSC shows a meaningful `trumbox` query cluster, which is large enough to distort low-CTR and page-2 opportunity reports if it is mixed with real Cloud PC / Cloud Gaming intent.

### 5.2 Discovery pages have large impressions but weak CTR

| Page | Clicks | Impressions | CTR | Position |
|---|---:|---:|---:|---:|
| `/discovery/` | 393 | 77,266 | 0.51% | 10.1 |
| `/en/discovery/` | 159 | 76,855 | 0.21% | 14.5 |

Likely causes:

- Page title/meta are too generic for queries Google is matching.
- Discovery page may rank for game/category queries but snippet does not promise the searched outcome.
- Content may be mostly carousel/cards, not enough crawlable explanatory copy.
- `/en/discovery/` may be ranking internationally but not matching intent/language strongly.

Fix: add static crawlable intro sections, keyword-specific copy, FAQ, and better metadata. Consider splitting discovery into stronger hub pages.

### 5.3 Pricing/auth/utility pages create SERP noise

Examples:

| Page | Clicks | Impressions | CTR | Position |
|---|---:|---:|---:|---:|
| `/pricing/` | 737 | 44,461 | 1.66% | 1.6 |
| `/login/` | 708 | 42,540 | 1.66% | 1.1 |
| `/pricing/how-it-works/` | 169 | 32,356 | 0.52% | 1.3 |
| `/id/reset-password/` | 6 | 6,680 | 0.09% | 1.5 |
| `/id/privacy/` | 12 | 6,990 | 0.17% | 2.1 |

Some of this is normal navigational search, but reset-password/privacy/legal/register pages probably should not compete for broad SEO visibility.

Fix carefully:

- Keep pricing indexable, but improve title/meta around `bang gia cloud pc`, `thue cloud pc`, `thuê cloud pc`, and `cloud gaming gia re`.
- Consider `noindex` for reset-password, confirm-verification, login-otp, and other private utility pages.
- Keep login indexable only if it captures branded navigational demand cleanly. Otherwise noindex login too and rely on homepage sitelinks.

### 5.4 Current frontend has good basics but lacks an SEO landing-page system

Observed in `website/`:

- Next.js app router.
- Locales: `vi`, `en`, `id` in `website/i18n/routing.ts`.
- Sitemap exists at `website/app/sitemap.ts`.
- Robots exists at `website/public/robots.txt`.
- Metadata exists for home, discovery, pricing, blog, game pages.
- Discovery game detail pages use `VideoGame` schema.
- Blog pages use `BlogPosting` schema.

Missing or weak:

- No dedicated static SEO landing-page route group for keyword pages.
- Sitemap routes do not include future keyword landing pages.
- `robots.txt` disallows product app routes but not all auth/private routes.
- `pricing/how-it-works` uses static metadata with non-localized canonical and placeholder OG image comments.
- Root structured data includes `AggregateRating` hardcoded. This can be risky if not backed by visible, verifiable review data.
- Organization/Service/Store schema can be improved into cleaner WebSite + Organization + Product/Service schemas.
- Rybbit tracking is present in source, but SEO-specific event instrumentation is still too implicit and should be wrapped/standardized for cleaner analysis.

## 6. URL architecture recommendation

### 6.1 Do not start with separate exact-match domains

Avoid starting with domains like:

```text
cloudgaming.vn.com
cloudpc.vn.com
```

Why:

- Splits authority away from `thinkmay.net`.
- Looks less trustworthy than the main brand.
- Harder to maintain and localize.
- May be treated as a thin exact-match microsite.
- Weakens brand recall.

Use exact-match domains only later for campaigns or redirects:

```text
cloudgaming.vn -> 301 -> https://thinkmay.net/cloud-gaming/
cloudpc.vn -> 301 -> https://thinkmay.net/cloud-pc/
```

### 6.2 Recommended core URL structure

Use main domain first:

```text
/ cloud-pc /
/ cloud-gaming /
/ choi-game-pc-tren-dien-thoai /
/ thue-may-tinh-online /
/ quan-net-tren-may /
```

In real URLs without spaces:

```text
https://thinkmay.net/cloud-pc/
https://thinkmay.net/cloud-gaming/
https://thinkmay.net/choi-game-pc-tren-dien-thoai/
https://thinkmay.net/thue-may-tinh-online/
https://thinkmay.net/quan-net-tren-may/
```

English:

```text
https://thinkmay.net/en/cloud-pc/
https://thinkmay.net/en/cloud-gaming/
https://thinkmay.net/en/play-pc-games-on-phone/
```

Indonesian:

```text
https://thinkmay.net/id/cloud-pc/
https://thinkmay.net/id/cloud-gaming/
https://thinkmay.net/id/main-game-pc-di-hp/
https://thinkmay.net/id/sewa-cloud-pc/
```

### 6.3 Game-specific URL structure

Vietnamese:

```text
/choi-gta-v-tren-dien-thoai/
/choi-gta-v-online-tren-cloud-pc/
/choi-fivem-tren-dien-thoai/
/choi-fc-online-tren-dien-thoai/
/choi-black-myth-wukong-tren-dien-thoai/
/choi-game-aaa-tren-dien-thoai/
```

Indonesian:

```text
/id/main-gta-v-di-hp/
/id/main-fivem-di-hp/
/id/main-fc-online-di-hp/
/id/main-black-myth-wukong-di-hp/
/id/main-game-pc-berat-di-hp/
```

Important trademark rule: do not imply official partnership with Rockstar, EA, Riot, Game Science, or other publishers. Use wording like:

> Thinkmay gives you access to a cloud PC that can run games such as GTA V, depending on game ownership, availability, and account requirements.

For Riot titles, be especially careful because anti-cheat and support limitations can create product risk.

## 7. Content hub plan

Build a hub-and-spoke system.

```text
/cloud-gaming/
  -> /choi-gta-v-tren-dien-thoai/
  -> /choi-fc-online-tren-dien-thoai/
  -> /choi-black-myth-wukong-tren-dien-thoai/
  -> /cloud-gaming-free/
  -> /choi-game-aaa-tren-dien-thoai/

/cloud-pc/
  -> /thue-may-tinh-online/
  -> /may-tinh-cau-hinh-cao-online/
  -> /quan-net-tren-may/
  -> /cloud-pc-free/
```

Each page should link back to:

- Homepage
- Pricing
- Discovery/game library
- Register/play CTA
- Related keyword pages
- Relevant blog posts

## 8. Page templates

### 8.1 Core keyword landing page template

Use this for `/cloud-pc/`, `/cloud-gaming/`, `/thue-may-tinh-online/`, etc.

Required sections:

1. Hero
   - One clear H1 with exact primary keyword.
   - One sentence product promise.
   - Primary CTA: Start/play now.
   - Secondary CTA: See pricing or explore games.
2. Problem
   - Weak laptop/mobile device cannot run PC games.
   - Downloads/storage/configuration are painful.
   - Gaming PC/cyber cafe is expensive or inconvenient.
3. Solution
   - Thinkmay Cloud PC gives a remote gaming PC in the browser.
   - Works on mobile/laptop/Mac.
   - No high-end hardware needed.
4. Use cases
   - Play AAA games.
   - Play on mobile.
   - Use weak laptop.
   - Try games before buying hardware.
5. Recommended plans
   - Standard for most users.
   - Performance for demanding games.
   - Link to pricing.
6. Game examples
   - GTA V/FiveM, FC Online, Black Myth: Wukong, etc.
   - Keep claims qualified.
7. Latency/geography
   - Best in Vietnam, especially Hanoi/HCMC.
   - Indonesia expansion: Jakarta if relevant.
8. FAQ
   - 5-8 questions using exact search language.
9. Internal links
   - Related pages and game pages.
10. JSON-LD
   - `FAQPage`
   - `Service` or `Product`
   - `BreadcrumbList`

### 8.2 Game intent page template

Use this for GTA V, FC Online, Black Myth: Wukong, etc.

Required sections:

1. H1: `Choi [Game] tren dien thoai / laptop cau hinh yeu bang Thinkmay`
2. Can you play it on Thinkmay?
3. What you need:
   - Thinkmay account
   - Game ownership/account where applicable
   - Stable internet
   - Controller/keyboard/mouse if needed
4. Recommended plan
5. Expected experience
   - FPS/resolution if measured
   - Network/latency note
6. Known limitations
   - Anti-cheat/account/game availability caveats
   - Do not overpromise
7. Setup steps
8. FAQ
9. CTA to start
10. Related games

### 8.3 Discovery page improvement template

Current `/discovery/` is probably too card/carousel-heavy for SEO. Add static, crawlable copy above/below the carousel:

- H1: `Kho game Cloud PC tren Thinkmay`
- Intro paragraph targeting `cloud gaming`, `choi game PC tren dien thoai`, `game PC cau hinh cao`.
- Genre summary links.
- Top games block with text links, not only cards.
- FAQ around playing cloud games.
- Internal links to `/cloud-gaming/`, `/cloud-pc/`, game pages, and pricing.

## 9. First 20 pages to build or improve

### Phase 1: core category pages

| Priority | URL | Primary keyword | Secondary keywords | Intent |
|---:|---|---|---|---|
| 1 | `/cloud-pc/` | cloud pc | cloud pc vietnam, thue cloud pc, pc cloud | Category/money |
| 2 | `/cloud-gaming/` | cloud gaming | cloud game, cloud gaming pc, cloud gaming vietnam | Category/money |
| 3 | `/choi-game-pc-tren-dien-thoai/` | choi game pc tren dien thoai | choi game tren dien thoai, game pc mobile | Supporting high-intent mobile page; message-fit is strong, exact-match demand is low |
| 4 | `/thue-may-tinh-online/` | thue may tinh online | thue pc online, thue may tinh cau hinh cao | High-intent commercial |
| 5 | `/quan-net-tren-may/` | quan net tren may | tiem net tren may, cloud cyber cafe | Brand/category support, stronger for messaging than proven SEO demand |

### Phase 2: game pages

| Priority | URL | Primary keyword | Notes |
|---:|---|---|---|
| 6 | `/choi-gta-v-tren-dien-thoai/` | choi gta v tren dien thoai | Strong user intent, mobile angle |
| 7 | `/choi-fivem-tren-dien-thoai/` | choi fivem tren dien thoai | Related to GTA V Online/FiveM demand |
| 8 | `/choi-fc-online-tren-dien-thoai/` | choi fc online tren dien thoai | Use caveats for online competitive quality |
| 9 | `/choi-black-myth-wukong-tren-dien-thoai/` | choi black myth wukong tren dien thoai | Strong high-end game angle |
| 10 | `/choi-game-aaa-tren-dien-thoai/` | choi game aaa tren dien thoai | Broad supporting page |

### Phase 3: Indonesian pages

| Priority | URL | Primary keyword | Notes |
|---:|---|---|---|
| 11 | `/id/cloud-gaming/` | cloud gaming | Keep if Indonesian users search English keyword |
| 12 | `/id/cloud-pc/` | cloud pc | Keep if Indonesian users search English keyword |
| 13 | `/id/main-game-pc-di-hp/` | main game pc di hp | Mobile intent |
| 14 | `/id/sewa-cloud-pc/` | sewa cloud pc | Commercial intent |
| 15 | `/id/main-gta-v-di-hp/` | main gta v di hp | Game intent |

### Phase 4: improve existing pages

| Priority | URL | Problem | Action |
|---:|---|---|---|
| 16 | `/discovery/` | Huge impressions, 0.51% CTR | Add SEO copy, title/meta, text links |
| 17 | `/en/discovery/` | Huge impressions, 0.21% CTR | Rewrite English intent or noindex if low-value |
| 18 | `/pricing/` | High impressions, low CTR | Improve commercial title/meta and FAQ |
| 19 | `/pricing/how-it-works/` | 32k impressions, 0.52% CTR | Fix metadata, canonical, content intent |
| 20 | `/blog/choi-game-aaa-dien-thoai/` | Ranking opportunity | Update and internally link to new mobile page |

## 10. Frontend implementation plan

### 10.1 Add an SEO landing-page route group

Recommended source structure:

```text
website/
  app/
    [locale]/
      (e-commerce)/
        (seo)/
          cloud-pc/
            page.tsx
          cloud-gaming/
            page.tsx
          choi-game-pc-tren-dien-thoai/
            page.tsx
          thue-may-tinh-online/
            page.tsx
          quan-net-tren-may/
            page.tsx
```

For English/Indonesian slug differences, use explicit route folders where needed:

```text
app/[locale]/(e-commerce)/(seo)/play-pc-games-on-phone/page.tsx
app/[locale]/(e-commerce)/(seo)/main-game-pc-di-hp/page.tsx
app/[locale]/(e-commerce)/(seo)/sewa-cloud-pc/page.tsx
```

If you want one logical page with localized slugs, define path mappings in `next-intl` navigation later. For speed, explicit route folders are simpler.

### 10.2 Create reusable SEO components

Add:

```text
website/components/seo/SeoLandingPage.tsx
website/components/seo/SeoHero.tsx
website/components/seo/SeoFAQ.tsx
website/components/seo/SeoInternalLinks.tsx
website/components/seo/SeoPlanCards.tsx
website/components/seo/JsonLd.tsx
```

Recommended props:

```ts
type SeoPageConfig = {
  locale: 'vi' | 'en' | 'id';
  slug: string;
  title: string;
  description: string;
  h1: string;
  heroSubtitle: string;
  primaryKeyword: string;
  secondaryKeywords: string[];
  sections: Array<{ heading: string; body: string | React.ReactNode }>;
  faqs: Array<{ question: string; answer: string }>;
  relatedLinks: Array<{ href: string; label: string }>;
  cta: { label: string; href: string };
};
```

### 10.3 Metadata requirements for every SEO page

Each page should implement `generateMetadata` with:

- `title`
- `description`
- `alternates.canonical`
- `alternates.languages`
- OpenGraph title/description/url/images
- Twitter card

Example title style:

```text
Cloud PC la gi? Thue may tinh cloud de choi game tren dien thoai | Thinkmay
```

Keep titles around 50-65 characters when possible, but prioritize clarity.

### 10.4 JSON-LD requirements

Every SEO landing page should include:

- `BreadcrumbList`
- `FAQPage`
- `Service` or `Product`

For game pages add:

- `VideoGame` only for the game entity if the page is truly about that game.
- `FAQPage`
- `BreadcrumbList`

Do not use fake ratings. Current root layout has hardcoded `AggregateRating`. Keep it only if the rating count/value are verifiable and visible to users.

### 10.5 Sitemap update

Update `website/app/sitemap.ts` to include static SEO routes.

Add routes:

```ts
const seoRoutes = [
  '/cloud-pc',
  '/cloud-gaming',
  '/choi-game-pc-tren-dien-thoai',
  '/thue-may-tinh-online',
  '/quan-net-tren-may',
  '/choi-gta-v-tren-dien-thoai',
  '/choi-fivem-tren-dien-thoai',
  '/choi-fc-online-tren-dien-thoai',
  '/choi-black-myth-wukong-tren-dien-thoai'
];
```

Set priority:

- `/cloud-pc/`: `0.95`
- `/cloud-gaming/`: `0.95`
- mobile/game intent pages: `0.8`
- game-specific pages: `0.75`

Set change frequency: `weekly`.

### 10.6 Robots/noindex plan

Current `public/robots.txt` disallows product app routes but does not disallow all auth/private routes.

Consider adding disallow or page-level noindex for:

```text
/login-otp/
/reset-password/
/confirm-reset-password/
/confirm-verification/
/debug/
/share/   # only if referral pages should not index
```

For localized versions:

```text
/en/login-otp/
/en/reset-password/
/en/confirm-reset-password/
/en/confirm-verification/
/id/login-otp/
/id/reset-password/
/id/confirm-reset-password/
/id/confirm-verification/
```

Better than robots-only: add `robots: { index: false, follow: false }` metadata on private/auth pages so Google can see the noindex if it crawls them. Do not block via robots if you need Google to see `noindex`.

### 10.7 Discovery page fixes

Current file:

```text
website/app/[locale]/(e-commerce)/discovery/page.tsx
```

Add before the carousel:

- Localized H1.
- 150-250 words of static copy.
- Text links to core SEO pages.

Add after game/genre carousels:

- FAQ section.
- Related category links.
- JSON-LD `FAQPage` + `CollectionPage` improvements.

Suggested Vietnamese H1:

```text
Kho game Cloud PC tren Thinkmay
```

Suggested Vietnamese intro:

```text
Kham pha cac tua game PC cau hinh cao co the choi tren dien thoai, laptop yeu hoac Mac thong qua Thinkmay Cloud PC. Ban co the bat dau nhanh tren trinh duyet, chon goi phu hop va trai nghiem cac game AAA, game online, game indie va game Viet hoa ma khong can dau tu dan PC gaming rieng.
```

### 10.8 Pricing page fixes

Current file:

```text
website/app/[locale]/(e-commerce)/pricing/page.tsx
```

Improve metadata per locale.

Vietnamese title options:

```text
Bang gia Cloud PC Thinkmay - Thue may choi game tu 29k
```

Vietnamese description:

```text
Xem bang gia thue Cloud PC Thinkmay choi game tren dien thoai, laptop va Mac. Chon goi Linh Hoat, Tieu Chuan hoac Hieu Nang theo nhu cau.
```

Add pricing FAQ:

- Goi nao phu hop de choi GTA V/FiveM?
- Goi nao phu hop de choi Black Myth: Wukong?
- Co the choi tren dien thoai khong?
- Du lieu/game co duoc luu khong?
- Can mang bao nhieu Mbps?

### 10.9 Pricing how-it-works page fixes

Current file:

```text
website/app/[locale]/(e-commerce)/pricing/how-it-works/page.tsx
```

Issues:

- Static metadata is not localized.
- Canonical lacks trailing slash and locale handling.
- OG image has placeholder comment.
- Content says `Cloud Gaming Viet Nam`, but page is service/pricing detail.
- Mentions `Cập nhật mới nhất 11/2025`; verify if current.

Fix:

- Convert static `metadata` to `generateMetadata({ params })`.
- Add localized canonical.
- Use actual OG image.
- Add FAQPage JSON-LD.
- Link to `/cloud-pc/`, `/cloud-gaming/`, `/pricing/`.

## 11. Content briefs for first five pages

### 11.1 `/cloud-pc/`

Primary keyword: `cloud pc`

Search intent: understand/rent/use a cloud PC for gaming or work.

Title:

```text
Cloud PC Thinkmay - Thue may tinh cau hinh cao tren may
```

H1:

```text
Cloud PC choi game va lam viec tren moi thiet bi
```

Required terms:

- cloud pc
- thue cloud pc
- thue may tinh online
- may tinh cau hinh cao online
- choi game tren cloud pc
- RTX 5060Ti / RTX GPU where accurate

CTA:

```text
Dung thu Cloud PC tu 29k
```

FAQ:

1. Cloud PC la gi?
2. Thinkmay Cloud PC khac gi cloud gaming?
3. Co the choi game PC tren dien thoai khong?
4. Du lieu cua toi co duoc luu khong?
5. Nen chon goi nao de choi game nang?
6. Can mang bao nhieu de choi muot?

### 11.2 `/cloud-gaming/`

Primary keyword: `cloud gaming`

Search intent: play games without owning powerful hardware.

Title:

```text
Cloud Gaming Thinkmay - Choi game PC tren dien thoai, laptop
```

H1:

```text
Cloud Gaming cho game PC cau hinh cao tren moi thiet bi
```

Required terms:

- cloud gaming
- cloud game
- cloud gaming vietnam as a minor supporting modifier, not the page's main bet
- choi game pc tren dien thoai
- khong can tai game
- khong can may cau hinh cao

FAQ:

1. Cloud gaming la gi?
2. Thinkmay co phai cloud gaming khong?
3. Co can cai game khong?
4. Co choi duoc tren dien thoai khong?
5. Game online co muot khong?
6. Nen dung goi nao?

### 11.3 `/choi-game-pc-tren-dien-thoai/`

Primary keyword: `choi game pc tren dien thoai`

Search intent: mobile user wants to play PC games.

Priority note: this is a strong conversion/supporting page because the message matches Thinkmay well, but exact-match keyword demand is much smaller than `cloud gaming` or `cloud pc`.

Title:

```text
Choi game PC tren dien thoai bang Cloud PC Thinkmay
```

H1:

```text
Choi game PC tren dien thoai ma khong can may tinh manh
```

Required sections:

- Works on Android/iOS browser where true.
- Recommended controls.
- Latency expectations.
- Best games for mobile.
- CTA to play.

### 11.4 `/thue-may-tinh-online/`

Primary keyword: `thue may tinh online`

Search intent: commercial rental.

Title:

```text
Thue may tinh online cau hinh cao de choi game va lam viec
```

Angle:

- More commercial.
- Explain pricing and plan choice.
- Compare to buying a gaming PC or going to cyber cafe.

### 11.5 `/quan-net-tren-may/`

Primary keyword: `quan net tren may`

Search intent: category creation / relatable positioning.

Priority note: treat this as a branding and internal-linking page first; current keyword research supports the framing strongly as messaging, but not yet as a top-volume SEO term.

Title:

```text
Quan net tren may - Choi game PC o bat cu dau voi Thinkmay
```

Angle:

- Emotional, Vietnamese-native.
- Great for internal links and social campaigns.
- Use friendly language, not too technical.

## 12. Game-specific page briefs

### 12.1 GTA V / FiveM

URLs:

```text
/choi-gta-v-tren-dien-thoai/
/choi-fivem-tren-dien-thoai/
```

Content requirements:

- Explain that users may need their own Rockstar/Steam/Epic account where applicable.
- Mention cloud PC access, not official GTA streaming.
- Explain controls on mobile.
- Link to pricing and cloud gaming page.
- Add FAQ:
  - Co choi GTA V tren dien thoai duoc khong?
  - Co choi FiveM duoc khong?
  - Can mang bao nhieu?
  - Co can mua game khong?

### 12.2 FC Online

URL:

```text
/choi-fc-online-tren-dien-thoai/
```

Caution:

- Online competitive games are sensitive to latency.
- Be honest: best experience requires stable network and nearby server.
- Avoid guaranteeing competitive performance.

### 12.3 Black Myth: Wukong

URL:

```text
/choi-black-myth-wukong-tren-dien-thoai/
```

Angle:

- High-end AAA game.
- Strong argument for cloud PC because local devices may be too weak.
- Include recommended plan and performance caveats.

## 13. Analytics and measurement plan

### 13.1 Required Rybbit exports next time

Ask/export:

- Landing page / path
- Referrer/source/medium, especially Google organic
- Country
- Device
- Sessions
- Users
- Bounce rate
- Session duration
- Pages/session
- Events/conversions:
  - signup
  - login
  - pricing_click
  - play_click
  - start_cloud_pc
  - payment_start
  - payment_success

### 13.2 Add frontend SEO events

Source search now shows explicit `rybbit` calls in `website/`, but Thinkmay should still add a wrapper so SEO/business events have a cleaner and more stable taxonomy.

Create:

```text
website/utils/analytics.ts
```

Example interface:

```ts
export function trackSeoEvent(event: string, props: Record<string, unknown>) {
  if (typeof window === 'undefined') return;
  const w = window as any;
  if (typeof w.rybbit?.event === 'function') {
    w.rybbit.event(event, props);
  } else if (typeof w.rybbit === 'function') {
    w.rybbit(event, props);
  }
}
```

Track on SEO pages:

```text
seo_page_view
seo_cta_click
seo_pricing_click
seo_game_click
seo_signup_click
seo_play_click
```

Include props:

```ts
{
  page_type: 'seo_landing' | 'game_landing' | 'pricing' | 'discovery',
  primary_keyword: 'cloud pc',
  locale: 'vi',
  slug: 'cloud-pc',
  market: 'vietnam'
}
```

### 13.3 Weekly dashboard

Create a weekly join:

```text
GSC query/page export + Rybbit landing page export
```

Dashboard columns:

| URL | Primary keyword | GSC clicks | Impressions | CTR | Position | Sessions | Bounce | Duration | Signup | Play | Payment |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|

Priority rule:

1. High impressions + low CTR = rewrite title/meta/snippet.
2. High clicks + high bounce = fix landing page intent/UX.
3. High engagement + low impressions = build internal links and more content.
4. High signup/payment = build more pages in that cluster.

## 14. Internal linking plan

### 14.1 Homepage

Current homepage H1 is strong emotionally: `Tiem net tren may`.

Add visible links from homepage sections to:

- `/cloud-pc/`
- `/cloud-gaming/`
- `/choi-game-pc-tren-dien-thoai/`
- `/pricing/`
- `/discovery/`

Anchor examples:

```text
Cloud PC la gi?
Choi game PC tren dien thoai
Bang gia thue Cloud PC
Kho game Cloud Gaming
```

### 14.2 Discovery page

Add links to:

- `/cloud-gaming/`
- `/choi-game-pc-tren-dien-thoai/`
- game-specific pages
- genre pages if created later

### 14.3 Pricing page

Add links to:

- `/cloud-pc/`
- `/thue-may-tinh-online/`
- `/cloud-gaming/`
- `/pricing/how-it-works/`

### 14.4 Blog pages

Update existing blog posts to link to new money pages.

Known ranking opportunities:

- `/blog/build-gaming-pc-vs-cloud-pc-thinkmay/`
- `/blog/choi-game-aaa-dien-thoai/`
- `/blog/choi-gta-v-tren-macbook/`

Add contextual links from these to:

- `/cloud-pc/`
- `/cloud-gaming/`
- `/choi-game-pc-tren-dien-thoai/`
- `/choi-gta-v-tren-dien-thoai/`

## 15. Technical SEO checklist

### 15.1 Canonicals and hreflang

For each localized page:

- Vietnamese default canonical: `https://thinkmay.net/{slug}/`
- English canonical: `https://thinkmay.net/en/{slug}/`
- Indonesian canonical: `https://thinkmay.net/id/{slug}/`

Add `alternates.languages`:

```ts
languages: {
  'vi-VN': 'https://thinkmay.net/cloud-pc/',
  'en-US': 'https://thinkmay.net/en/cloud-pc/',
  'id-ID': 'https://thinkmay.net/id/cloud-pc/',
  'x-default': 'https://thinkmay.net/cloud-pc/'
}
```

For pages where slugs differ by language, make sure hreflang points to the correct localized slug, not just the same path under `/id/`.

### 15.2 Metadata quality rules

Every indexable page needs:

- Unique title.
- Unique description.
- One H1.
- Canonical.
- OpenGraph image.
- Clear CTA.
- Internal links.

Avoid:

- Generic fallback metadata like slug as title/description.
- Placeholder OG image comments.
- Hardcoded outdated dates.
- Overclaiming FPS/latency/4K unless measured.

### 15.3 Schema rules

Use schema where useful:

- Homepage: `Organization`, `WebSite`, `Service`.
- Pricing: `Product` or `Service` + `OfferCatalog`.
- FAQ blocks: `FAQPage`.
- Blog: `BlogPosting`.
- Game pages: `VideoGame` + `FAQPage` + `BreadcrumbList`.

Review current hardcoded aggregate rating in root layout. Only keep if visible and verifiable.

### 15.4 Index management

Recommended noindex:

- Reset password
- Confirm reset password
- Confirm verification
- Login OTP
- Debug
- Internal app pages already blocked/disallowed

Potential noindex after review:

- Login page if it creates too much search noise.
- Register page if CTR remains very low and it does not help sitelinks.
- Legal/privacy/contact pages should usually stay indexable but not optimized for broad terms.

### 15.5 Performance

Because mobile is 65.5% of SEO clicks:

- Keep landing pages mostly server-rendered/static.
- Avoid heavy carousels above the fold on SEO pages.
- Use optimized images with defined width/height.
- Keep hero LCP image small and compressed.
- Lazy-load non-critical sections.
- Test mobile Core Web Vitals before publishing.

## 16. Content quality and compliance rules

### 16.1 Avoid unsupported claims

Do not claim:

- Guaranteed zero latency.
- Guaranteed 4K/240fps for all games/users.
- Anti-cheat bypass or VM hiding.
- Official partnership with game publishers.

Use qualified language:

```text
Trai nghiem phu thuoc vao goi dich vu, khu vuc may chu, duong truyen internet va yeu cau cua tung tua game.
```

### 16.2 Game ownership and account wording

Use:

```text
Mot so tua game co the yeu cau ban so huu game hoac dang nhap tai khoan nha phat hanh rieng.
```

### 16.3 Online competitive games

For FC Online/Riot-like titles:

- Explain stable network requirement.
- Do not guarantee competitive latency.
- Add support caveats.

## 17. 30/60/90-day roadmap

### Days 1-7: Foundation

- [ ] Add SEO route group and reusable landing page components.
- [ ] Add `/cloud-pc/` and `/cloud-gaming/` Vietnamese pages.
- [ ] Update sitemap with new pages.
- [ ] Add page-level JSON-LD helpers.
- [ ] Fix `pricing/how-it-works` metadata and canonical.
- [ ] Add noindex metadata for private auth pages.
- [ ] Add analytics wrapper and CTA events.

### Days 8-30: Category expansion

- [ ] Publish `/choi-game-pc-tren-dien-thoai/`.
- [ ] Publish `/thue-may-tinh-online/`.
- [ ] Publish `/quan-net-tren-may/`.
- [ ] Improve `/discovery/` with crawlable SEO copy and FAQ.
- [ ] Improve `/pricing/` FAQ and commercial copy.
- [ ] Update internal links from homepage, pricing, discovery, and ranking blog posts.
- [ ] Re-export GSC after indexing starts.

### Days 31-60: Game intent pages

- [ ] Publish `/choi-gta-v-tren-dien-thoai/`.
- [ ] Publish `/choi-fivem-tren-dien-thoai/`.
- [ ] Publish `/choi-fc-online-tren-dien-thoai/`.
- [ ] Publish `/choi-black-myth-wukong-tren-dien-thoai/`.
- [ ] Add related-game internal linking blocks.
- [ ] Add measured performance notes where available.

### Days 61-90: Indonesia and optimization

- [ ] Publish `/id/cloud-gaming/`.
- [ ] Publish `/id/cloud-pc/`.
- [ ] Publish `/id/main-game-pc-di-hp/`.
- [ ] Publish `/id/sewa-cloud-pc/`.
- [ ] Export Rybbit landing-page/source/device/country data.
- [ ] Build weekly SEO funnel dashboard.
- [ ] Rewrite titles/meta for pages with high impressions and CTR below expected.
- [ ] Expand winning clusters based on signup/play/payment conversion.

## 18. Acceptance criteria

### Technical acceptance

- [ ] `npm run build` passes in `website/`.
- [ ] Sitemap includes new SEO pages.
- [ ] New pages have canonical + hreflang.
- [ ] New pages have `FAQPage` and `BreadcrumbList` JSON-LD.
- [ ] Auth/private pages have `noindex` metadata or are intentionally disallowed.
- [ ] No unsupported claims are introduced.

### SEO acceptance

Within 4-8 weeks after publication:

- [ ] New pages are indexed.
- [ ] `/cloud-pc/` receives impressions for `cloud pc` and related queries.
- [ ] `/cloud-gaming/` receives impressions for `cloud gaming`, `cloud game`, related queries.
- [ ] Discovery page CTR improves from **0.51%**.
- [ ] `/en/discovery/` CTR improves from **0.21%** or is de-prioritized/noindexed if irrelevant.
- [ ] Non-brand clicks increase from **12,624** baseline.

### Business acceptance

- [ ] SEO landing pages have measurable signup/play/payment events.
- [ ] At least one new keyword page produces paid users or strong activation.
- [ ] Vietnam remains dominant while Indonesia SEO starts growing independently.

## 19. Immediate recommended implementation order

If engineering bandwidth is limited, do this exact order:

1. `/cloud-pc/`
2. `/cloud-gaming/`
3. Sitemap update
4. Homepage internal links to both pages
5. Rybbit CTA event tracking
6. `/thue-may-tinh-online/`
7. `/choi-game-pc-tren-dien-thoai/`
8. Discovery page SEO copy + FAQ
9. Pricing page FAQ + title/meta rewrite
10. GTA V/FiveM page
11. Indonesian `/id/cloud-gaming/` and `/id/cloud-pc/`

This order balances fastest ranking upside with strongest product-market fit.

## 20. Final recommendation

Thinkmay should not treat SEO as a blog-only channel. The strongest opportunity is a **programmatic but high-quality landing-page system** connected to real product behavior:

```text
Category pages -> mobile intent pages -> game intent pages -> pricing/play/signup
```

The analytics already support this bet: SEO clicks correlate strongly with sessions and pageviews, while bounce does not worsen. Build the pages under `thinkmay.net`, keep the content honest and mobile-first, instrument every CTA, and use weekly GSC + Rybbit joins to decide which clusters deserve more pages.
