# Thinkmay analytics research

_Last updated: 2026-05-16. Scope: local repo/config/docs inspection only. I did not access live dashboards or expose secrets._

## Executive summary

Thinkmay already has the raw ingredients for much better retention analytics than the current headline metrics. The strongest confirmed stack is:

1. **Rybbit / website analytics**: loaded from the website through a configurable tracking script, with logged-in user identification and custom events for page entry plus launched/closed applications.
2. **Behavior/persona pipeline**: worker daemon reads Rybbit sessions/events, combines them with Supabase payment history, asks an LLM to classify usage/renewal behavior, stores the result in PocketBase `persona`, and clusters cohorts for marketing email drafts.
3. **Control-console/product state**: PocketBase + Supabase expose subscription, usage, heatmap, volume/session, app-access, recommendation, wallet/payment, mail and gamification state. This is the best source for activation and retention metrics.
4. **Grafana/Prometheus/Node Exporter**: confirmed operational observability stack. It can explain session quality/latency/smoothness indirectly through machine/process metrics and spawned/closed app events, but it is not a full marketing funnel tool by itself.

The biggest gap is not “lack of tools”; it is **joining the tools into founder/product questions**: visitor -> signup -> first CloudPC session -> first paid plan -> first game/app launched -> day-7/day-30 usage -> renewal. That join seems feasible with the existing IDs and tables, especially if Rybbit `user_id` is PocketBase user ID and Supabase/PocketBase can map that to email/subscription.

## Evidence map

| Area | Confirmed source | What it captures | Main value | Confidence |
|---|---|---|---|---|
| Website analytics | `website/app/[locale]/layout.tsx`, `website/rybbit.d.ts`, `backend/actions/background.ts` | Page views, logged-in user ID, `page_entry`, app process spawned/closed events | Funnel, device/browser/OS, game/app interest and behavior | High |
| Rybbit backend stack | `compose/rybbit.yaml`, `.env` keys seen redacted | Rybbit ClickHouse + Postgres + backend/client services | Website/session analytics storage and UI | High |
| User behavior/persona | `worker/daemon/analytics/rybbit/*`, `pocketbase/db.go`, `pocketbase/pocketbase.go` | Sessions/events + payment history -> usage summary, renewal probability, top apps, persona, recommendations | Retention segmentation and CRM | High |
| Control console / product DB | Supabase SQL docs, website reducers/components, PocketBase hooks | Subscriptions, plans, payment requests, total usage, heatmap, VM snapshots, volume/session state, mail | Activation/retention/source-of-truth business metrics | High |
| Grafana/Prometheus | `compose/monitoring.yaml`, `analytics/node-exporter/analytics.go` | Infra/process metrics, top processes, process spawned/closed events | Reliability, smoothness, game/app launch validation | Medium-high |
| Kafka/community | `compose/kafka.yaml`, `compose/community.yaml` | Event/message infra exists | Could support async analytics/community attribution, not proven as funnel source | Medium-low |
| “woovershirt” | Repo search found no matching vendor/name | Unclear term/tool; likely typo/internal nickname or not committed | Needs live/system access or corrected spelling | Low |
| “Rebid” | Repo evidence says Rybbit, not Redash/Rebid | Likely refers to Rybbit website analytics | Treat as Rybbit unless founder confirms separate tool | Medium |

## Confirmed website analytics path

The website includes a generic tracking script hook:

- `NEXT_PUBLIC_TRACKING_SCRIPT_URL`
- `NEXT_PUBLIC_TRACKING_SITE_ID`
- `NEXT_PUBLIC_TRACKING_API_KEY`

Loaded in `website/app/[locale]/layout.tsx` as a lazy script with `data-site-id` and `data-api-key`.

The TypeScript declaration `website/rybbit.d.ts` confirms the expected browser API:

- `window.rybbit.pageview()`
- `window.rybbit.event(name, properties)`
- `window.rybbit.identify(userId)`
- `window.rybbit.clearUserId()`
- `window.rybbit.getUserId()`
- `window.rybbit.trackOutbound(...)`

`website/backend/actions/background.ts` confirms Thinkmay identifies the logged-in user and emits product events:

- `window.rybbit.identify(id)` where `id` is the current website/PocketBase user ID.
- `window.rybbit.event('page_entry', { params })` after preload.
- On log lines starting `spawned:` or `closed:`, it emits an event named after the process/app path with `{ content: 'spawned' | 'closed' }`.
- It treats `spawned` logs containing `Steam\steamapps\common\` as game-running evidence.

This means Rybbit can answer much more than traffic count. It can segment:

- anonymous visitor behavior before signup,
- logged-in behavior after `identify`,
- device/browser/OS from Rybbit sessions,
- landing/search/payment/dashboard page flow,
- launched applications/games and closes,
- first successful game/app launch after signup or payment.

There is also Facebook Pixel PageView in `layout.tsx`. That helps paid acquisition measurement, but it is not enough for retention; Rybbit + control-console joins matter more.

## Confirmed Rybbit/persona behavior pipeline

The worker daemon has a dedicated Rybbit analytics module. It is not just a dashboard; it is a retention/persona engine.

### Data read from Rybbit

`getEventHistory(uid)` calls Rybbit APIs:

- `GET /api/sites/{siteID}/sessions?user_id={uid}`
- `GET /api/sites/{siteID}/sessions/{sessionID}`

Session fields used:

- `session_id`
- `language`
- `device_type`
- `browser`
- `operating_system`
- `session_start`
- `session_end`

Event fields used:

- `timestamp`
- `pathname`
- `hostname`
- `querystring`
- `page_title`
- `referrer`
- `type`
- `event_name`
- `props`

The code filters to `custom_event`, ignores blacklisted events, and ignores events where `props.content == 'closed'`. So current persona analysis focuses on positive/active launched app signals rather than closed events.

### Data combined with payments

`GetPersona(uid)` runs Rybbit event history and Supabase payment history in parallel. Payment history is fetched through Supabase RPC:

- `get_payment_history_by_userid(userid)`

That RPC maps PocketBase user ID -> email through the cluster PocketBase API, then returns payment history for the email.

Persona output includes:

- `usage_summary.user_batch`
- `usage_summary.frequency`
- `usage_summary.usage_habbit` [typo in code]
- `usage_summary.renewal_behavior`
- `usage_summary.renewal_probability`
- `usage_summary.top_apps`
- `user_profile.objective`
- `user_profile.gamer_type`
- `user_profile.persona`
- `game_recommendations`

### Persistence and automation

PocketBase initializes Rybbit if config contains Rybbit URL/credential/site plus Gemini credentials. It stores persona output in the PocketBase `persona` collection via `UpdatePersona(uid)`, saving:

- `summary`
- `profile`
- `recommendations`

A cron job `update persona` runs every minute, selecting up to 20 users with volumes older than one day whose persona is missing or older than seven days. It updates users in batches of 10.

Another cron job `draft batch email` runs daily and calls:

- `ClusterizeUserBatch('hour1', now-3d, now-2d)`
- filters out users with `disableEM`
- drafts cluster-specific email copy through the LLM
- sends/stores marketing mail flow through PocketBase mail logic.

This is already a strong retention CRM foundation. The immediate improvement is to make its outputs auditable: count how many users fall into each persona/renewal-probability bucket and compare against real renewal.

## Confirmed control-console and product data

The control console/product DB should be treated as the business source of truth for activation, paid conversion, renewals, and usage.

### Supabase / Postgres stack

`compose/supabase.yaml` defines Supabase Studio on host port `4000`, PostgREST, Postgres Meta, and Postgres DB. Docker is not available in this shell, so I could not open the local dashboard, but the compose and SQL export are present.

Important confirmed tables/functions from `docs/db/global.sql`:

- `subscriptions`: user email, created time, ended/cancelled/cleaned/allocated timestamps, cluster, total usage, total data credit, usage limit.
- `payment_request`: subscription, plan, transaction, pocket, verified time, discount, total usage, data credit.
- `plans`: name, policy, price, metadata, active, total days, total hours, credit.
- `transactions`: status, currency, provider, amount, email, metadata.
- `pockets` and `pocket_deposits`: wallet/deposit data.
- `user_v2`: email, volume ID, cluster ID.
- `vm_snapshoot_v4`: created time, session ID, volume ID, node, cluster ID, email, size.
- `generic_events`: timestamp, name, type, JSON value. I did not find active inserts in the inspected worker code, so treat it as available but not confirmed populated.

Important RPCs:

- `get_subscription_v3(email)` returns current subscription state: cluster, created/ended, total usage, usage limit, plan name, next plan, auto extend, expiration state.
- `get_user_heatmap(target_email)` builds daily usage for the last 365 days from `vm_snapshoot_v4`, assuming every snapshot row represents 5 minutes (`COUNT(*) * 5 / 60`).
- `snapshoot_v6()` calls `globalproxy:50050` to discover active sessions and inserts into `vm_snapshoot_v4`.
- `get_cohort_personas(start, end, plan)` selects first verified payment cohorts by plan and joins persona summaries/profiles from cluster PocketBase.
- `get_payment_history_by_userid(userid)` maps PocketBase ID to email and returns payment history.

### Website/control console UI usage

The website reducer fetches:

- `get_subscription_v3`
- `get_user_heatmap`
- wallet/payment info
- addon charges
- quests/missions
- recommendations
- mails
- domains/workers/configuration

The profile/dashboard UI displays:

- total usage and usage limit,
- remaining hours,
- activity heatmap,
- player stats/gamification,
- subscription/addon status.

This means the data needed for a retention dashboard is already exposed through the same APIs used by the customer UI.

## Confirmed Grafana/Prometheus operational analytics

`compose/monitoring.yaml` defines:

- `grafana`
- `prometheus`
- provisioning from `volumes/grafana/grafana.ini` and `volumes/grafana/prometheus.yml`

The daemon also has a `node-exporter` analytics package that:

- polls a Prometheus/node-exporter endpoint every 10 seconds,
- parses `windows_process_cpu_time_total`, `windows_process_working_set_bytes`, and `windows_process_info`,
- groups top processes by CPU/RAM,
- tracks executable paths,
- emits `spawned` and `closed` events when process paths appear/disappear,
- forwards analytics events into the user session/log queue as `spawned:<path>` or `closed:<path>`.

Those forwarded events are then captured by the website and sent to Rybbit. This is the bridge between operational process telemetry and user behavior analytics.

Grafana should be used for:

- node/GPU/CPU/RAM pressure,
- process-level resource usage,
- session stability,
- time windows where latency/smoothness complaints likely happen,
- capacity planning by cluster/city,
- debugging app launch/close behavior.

Rybbit/control-console should be used for:

- funnel,
- mobile vs desktop behavior,
- game/app preference,
- persona/renewal segments,
- payment/retention cohorts.

## What “woovershirt” probably means

I searched the local repo for:

- `woovershirt`
- `woover`
- `woopra`
- `wovershirt`
- `wovershift`
- `session replay`
- `heatmap`
- behavior-related terms

No confirmed vendor/tool named `woovershirt` exists in the inspected repo. The only confirmed “behavior understanding” implementation is Rybbit + LLM persona + usage heatmap/control-console data.

Possible interpretations:

1. A typo or nickname for an external behavior analytics/session replay product that is not committed to the repo.
2. A private dashboard/service configured outside the repo.
3. The founder may have meant the existing Rybbit/persona/control-console stack.

Recommendation: until the exact tool name is confirmed, do not rely on it for analysis. Use Rybbit + control console as the verified behavior layer.

## Recommended analytics questions to answer next

### 1. Month-2 retention diagnosis

Join first verified payment cohort to usage behavior:

- first payment date,
- plan name,
- total hours used in days 0-1, 2-7, 8-30,
- first game/app launched,
- number of distinct active days,
- mobile vs desktop Rybbit device type,
- browser/OS,
- renewal/payment in next cycle.

Key cuts:

- mobile vs desktop renewal,
- Vietnam vs Indonesia/language/timezone proxy,
- Standard vs Performance vs hour1/trial,
- first-session duration buckets: 0, <10m, 10-30m, 30-120m, 2h+,
- launched-game vs no-launched-game,
- story-game users vs online/competitive users,
- high usage but no renewal vs low usage no renewal.

### 2. Native app business case

Use existing data to prove whether native app should be priority:

- device_type = mobile share among visitors, signups, paid users, retained users,
- mobile first-session success rate,
- mobile payment conversion,
- mobile day-7 activity,
- mobile renewal rate,
- mobile support/smoothness complaint rate if tickets exist,
- mobile launched-game distribution.

If mobile has high acquisition but weak first successful session or weak renewal, native app likely has direct retention ROI.

### 3. Game discovery churn

From Rybbit app events and persona `top_apps`:

- users who launch exactly one story game and churn,
- users who launch 2+ games and renew,
- users who launch Black Myth/GTA/FiveM/FC Online and renewal by game,
- users who search or view discovery/store pages but never launch,
- recommendation email recipients vs later launches/renewals.

### 4. Session quality / smoothness

From Grafana/Prometheus + `vm_snapshoot_v4` + app events:

- session start -> first app spawned delay,
- app spawned -> closed within <5 minutes rate,
- high CPU/RAM pressure during early-close sessions,
- cluster/node differences,
- time-of-day congestion,
- node process crash or app close patterns.

This directly connects to the founder-observed churn reason: latency/smoothness.

### 5. Pricing and plan retention

From `payment_request`, `plans`, `subscriptions`:

- first plan by user,
- next plan / auto extend,
- renewal count,
- total paid amount,
- usage before renewal,
- out-of-time vs out-of-day expiration,
- plan upgrade/downgrade patterns.

This should validate whether Standard is only best-selling or also best-retaining, and whether Performance has better LTV despite smaller volume.

## Suggested dashboard structure

### Founder dashboard

- Revenue this month / paid users / ARPPU.
- New paid users by day and plan.
- Month-2 renewal by acquisition cohort.
- Mobile vs desktop: signup, paid conversion, first successful session, renewal.
- Top games/apps by paid users and by retained users.
- Indonesia vs Vietnam behavior proxy: language, country if available in Rybbit, timezone/referrer.
- Churn warning: users with low renewal probability, no session in 7 days, or app closed quickly.

### Product/retention dashboard

- Activation funnel: signup -> volume allocated -> first session snapshot -> first app spawned -> 30+ min play -> paid -> renewed.
- Time to first successful play.
- Day-1 / day-7 / day-30 active paid users.
- Heatmap activity by cohort.
- Persona buckets: gamer type, objective, renewal probability.
- Game recommendation opportunity: top single-game churners and recommended next games.

### Ops/session-quality dashboard

- Active sessions by cluster/node.
- CPU/RAM/GPU if exposed in Prometheus.
- Process spawn/close stream by app/game.
- Early close/crash-like patterns.
- Cluster/node with worst early-close rates.
- Capacity pressure vs renewal/churn cohorts.

## Data-model joins that matter

The central join should be:

1. PocketBase user ID -> email via PocketBase users collection.
2. Email -> Supabase `subscriptions`, `payment_request`, `transactions`, `user_v2`.
3. Email -> `vm_snapshoot_v4` usage heatmap/session snapshots.
4. PocketBase user ID -> Rybbit `user_id` sessions/events.
5. Rybbit spawned/closed app event names -> game/app names, then optional `stores`/Steam metadata.
6. Persona collection -> summary/profile/recommendations by user.

The repo already implements pieces of this join in `get_payment_history_by_userid`, `get_cohort_personas`, and the Rybbit persona code.

## Gaps and risks

- I could not access live dashboards because Docker is unavailable in this shell and no local Rybbit/Grafana ports were listening.
- `web_search` is unavailable, so external vendor lookup for “woovershirt” was not possible here.
- The website tracking script URL is configured by env; no website `.env` file was present in the inspected checkout, so I confirmed code support but not the production script URL.
- `generic_events` exists, but I did not find active local code writing to it.
- Rybbit custom event names currently appear to be raw process paths. This is useful but messy; normalize to app/game IDs/names for cleaner dashboards.
- Persona analysis depends on an LLM. Use it for segmentation and recommendations, but validate against real renewal/payment outcomes before trusting `renewal_probability`.
- `usage_habbit` is misspelled in code/schema. Not harmful, but it will leak into JSON contracts and dashboards.

## Highest-impact next actions

1. **Build one retention cohort query/table** from Supabase + Rybbit export:
   - first payment date, plan, device type, first app, active days, total hours, renewed yes/no.
2. **Normalize Rybbit app events**:
   - map raw process paths to game/app names and Steam IDs where possible.
3. **Add/verify explicit funnel events**:
   - signup started/completed, pricing viewed, payment started, payment success, dashboard loaded, stream connected, first input, first app launched, app closed, reconnect, error.
4. **Compare persona prediction to real renewal**:
   - `renewal_probability` vs actual next payment.
5. **Make mobile-vs-desktop retention the first dashboard slice**:
   - because founder data says 70-80% mobile, and no native app is likely a retention bottleneck.
6. **Use Grafana for session-quality overlays**:
   - identify whether churn cohorts had more early closes, resource pressure, or bad cluster/time windows.

## Bottom line

Thinkmay does not need another analytics tool before asking better questions. The current stack already supports a strong retention analytics system:

- **Rybbit**: who came, on what device, what pages/events/apps they touched.
- **Control console/Supabase/PocketBase**: who paid, what plan, how much they used, whether they renewed.
- **Persona pipeline**: why they might renew/churn and what to recommend.
- **Grafana/Prometheus**: whether the machine/session experience was good enough.

The most valuable research work now is to join these into one cohort dataset and prove which retention lever is biggest: mobile native app, game discovery, session smoothness, plan/pricing, or Indonesia localization.
