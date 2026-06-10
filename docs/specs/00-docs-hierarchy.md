# Phân tầng tài liệu — Mobile app

> **Nguồn gốc (canonical):** [`../../docs/product/`](../../docs/product/) trong monorepo Thinkmay.  
> Folder `mobile/specs/` và [`TASK.md`](../TASK.md) chỉ bổ sung **trạng thại implementation Flutter** — không thay product spec.

## Đọc theo thứ tự

| # | Doc (thinkmay/docs) | Dùng khi |
|---|---------------------|----------|
| 1 | [`product/features/gamification.md`](../../docs/product/features/gamification.md) | Profile tab, Stars, missions, leaderboard |
| 2 | [`product/guides/user_doc.md`](../../docs/product/guides/user_doc.md) | Luồng user: payment, usage, profile metrics |
| 3 | [`product/design/thinkmay_mobile_design.md`](../../docs/product/design/thinkmay_mobile_design.md) | UI intent, Settings structure, Figma |
| 4 | [`product/architecture/client_user_flow_contract.md`](../../docs/product/architecture/client_user_flow_contract.md) | Route parity PWA ↔ mobile |
| 5 | [`product/architecture/mobile_sync_checklist.md`](../../docs/product/architecture/mobile_sync_checklist.md) | Checklist 77 mục parity (PWA reference) |
| 6 | [`product/architecture/client_protocol_contract.md`](../../docs/product/architecture/client_protocol_contract.md) | WebRTC, HID, signaling |
| 7 | [`product/architecture/client_platform_divergence.md`](../../docs/product/architecture/client_platform_divergence.md) | Khác biệt cố ý mobile vs PWA |
| 8 | [`product/architecture/mobile_architecture.md`](../../docs/product/architecture/mobile_architecture.md) | Clean Architecture Flutter |

## Doc chỉ trong `mobile/`

| File | Vai trò |
|------|---------|
| [`TASK.md`](../TASK.md) | Công việc active, done log, checklist wire API / remove UI |
| [`specs/API-COVERAGE.md`](./API-COVERAGE.md) | Trạng thái Cubit ↔ API (✅/🟡/🔴) |
| [`specs/<màn>/`](./README.md) | Chi tiết theo màn hình + file path `lib/` |

## Quy tắc sync

1. **Product / protocol thay đổi** → sửa `thinkmay/docs` trước, rồi cập nhật `mobile/specs` + `TASK.md`.
2. **Chỉ wire API / fix bug mobile** → cập nhật `API-COVERAGE.md`, spec màn, `TASK.md`; không duplicate nội dung sang `thinkmay/docs` trừ khi đổi hành vi sản phẩm.
3. **Mâu thuẫn** → **`thinkmay/docs` thắng**; ghi exception trong spec mobile nếu implementation chưa kịp theo.

## Route Profile (hay nhầm)

| | PWA | Mobile target |
|--|-----|---------------|
| Tab Profile (nav) | `/profile` — gamification | Tab `/profile` — [`gamification.md`](../../docs/product/features/gamification.md) |
| Sửa tài khoản | `/setting/profile` | `/update-profile` (từ `/setting`) |

*Cập nhật: 2026-06-07*
