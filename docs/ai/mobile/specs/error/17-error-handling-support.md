# 17 — Error Handling & Support

## Overview

Error message list, terms, shared success screen.

---

## API status

> [API-COVERAGE.md](../API-COVERAGE.md)

| Screen | Status | Details |
|--------|--------|---------|
| Error list | 🔴 | `ErrorCubit.fetchErrorMessage` calls use case but **`ErrorServiceImpl` returns `[]`** — RPC `get_error_message` not implemented |
| Terms | ⚪ | Static |
| `TmSuccessScreen` | ⚪ | UI only |

**Not complete** — error list always empty despite wiring.

**File:** `lib/data/network/error/error_service.dart`

```dart
Future<List<ErrorMessage>> fetchErrorMessage() async {
  return [];
}
```

---

## Mobile

| File | Path |
|------|------|
| UI | `error_list_screen.dart` |
| Cubit | `error_cubit.dart` |

Endpoint constant exists: `Endpoint.getErrorMessage` — not used in service yet.

---

## Links

- [18-backend-integration](../18-backend-integration.md)
