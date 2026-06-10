# 17 — Error Handling & Support

## Tổng quan

Danh sách thông báo lỗi, terms, màn success dùng chung.

---

## Trạng thái API

> [API-COVERAGE.md](../API-COVERAGE.md)

| Màn hình | Trạng thái | Chi tiết |
|----------|------------|----------|
| Error list | 🔴 | `ErrorCubit.fetchErrorMessage` gọi use case nhưng **`ErrorServiceImpl` return `[]`** — chưa implement RPC `get_error_message` |
| Terms | ⚪ | Static |
| `TmSuccessScreen` | ⚪ | UI only |

**Chưa hoàn thiện** — error list luôn rỗng dù có wiring.

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

Endpoint constant có: `Endpoint.getErrorMessage` — chưa dùng trong service.

---

## Liên kết

- [18-backend-integration](../18-backend-integration.md)
