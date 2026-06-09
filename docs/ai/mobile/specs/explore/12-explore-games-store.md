# 12 — Explore, Games & Store

## Overview

Game catalog: Explore tab, separate Store screen, search, game detail. **Explore tab reads preloaded catalog from `GlobalState.games`** (splash `loadAll()`).

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md)

| Component | Status | Backend |
|-----------|--------|---------|
| **Explore tab** | ✅ | `GlobalState.games` ← `FetchStoreUseCase` in splash `loadAll()` |
| **Explore AI search** | ✅ | `SearchStoresUseCase` on demand |
| **Explore search** | 🟡 | Catalog from global; `FetchGenresUseCase` on search screen open |
| **Store** `/store` | ✅ | Supabase `stores` + PB `buckets` (dev harness screen) |
| **Game detail** | 🟡 | Catalog from global; param-driven detail; FC26 demo fallback |
| **Dashboard games** | ✅ | `GlobalState.games` from preload |

---

## Mobile — details

### Explore tab (`explore_cubit.dart`)

`init()` maps `GlobalCubit.state.games` → `ExploreViewModel` — **no network on tab switch**. Subscribes to global stream if games arrive late. `performAiSearch` → `SearchStoresUseCase`.

### Explore search (`explore_search_cubit.dart`)

`_loadGames()` reads `GlobalState.games` only. `FetchGenresUseCase` still called on init for category chips (could move to preload later).

### Store (`store_cubit.dart`)

- Dev/debug screen — manual `fetchStore` / `fetchBuckets` buttons
- Production catalog path is splash preload + Explore tab

### Game detail (`game_detail_cubit.dart`)

`_loadCatalog()` prefers `GlobalCubit.state.games`; fallback `FetchStoreUseCase` if empty.

### Data model `Game`

Supabase returns: `name`, `code_name`, `path_full` (mapped from `header_image`), genres, …

---

## Preload

Store catalog is call **#12** in `PreloadUseCase.loadAll()` parallel batch. JSON decode currently on main isolate — see L-1 in [mobile_sync_checklist.md](../../../product/architecture/mobile_sync_checklist.md).

---

## Website — comparison

| Mobile | Website |
|--------|---------|
| Explore reads global cache | `/store` SSR + client catalog |
| Splash awaits full catalog | Web preload gate |

---

## Remaining

- Persona genre sections (#22) — `FetchRecommendationsUseCase` not wired to Explore UI
- Polished store UX vs PWA (§F checklist)
- Game detail + install flow parity

*Updated: 2026-06-09 — store on splash; Explore tab no fetch on open.*
