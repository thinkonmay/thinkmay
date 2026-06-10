# Làm việc với Specs

## Phân tầng — thinkmay/docs là gốc

| Loại nội dung | Sửa ở đâu |
|---------------|-----------|
| Product (Stars, missions, user flows, design intent) | [`../../docs/product/`](../../docs/product/) |
| Protocol WebRTC/HID, parity PWA | [`../../docs/product/architecture/`](../../docs/product/architecture/) |
| Trạng thái Cubit, mock API, file `lib/` | `mobile/specs/` + [`API-COVERAGE.md`](./API-COVERAGE.md) |
| Công việc đang làm | [`../TASK.md`](../TASK.md) |

Đọc trước: **[00-docs-hierarchy.md](./00-docs-hierarchy.md)**

## Specs mobile là gì?

Bổ sung **implementation** — không thay PRD. Mỗi spec mobile phải link doc gốc trong `thinkmay/docs`.

**Khi viết/sửa:** doc gốc → `lib/` — **không** chỉ đọc `CLAUDE.md`.

## Khi nào cập nhật?

- **thinkmay/docs** — đổi product, policy, protocol (sửa gốc trước)
- **mobile specs + TASK + API-COVERAGE** — wire API, fix Cubit, đổi hành vi app

## Review PR

1. Product change → `thinkmay/docs`?
2. Mobile change → `specs/` + `API-COVERAGE.md` + `TASK.md`?
3. Parity item → tick [`mobile_sync_checklist.md`](../../docs/product/architecture/mobile_sync_checklist.md)?

## Đọc trước khi code

1. [`00-docs-hierarchy.md`](./00-docs-hierarchy.md)
2. [`TASK.md`](../TASK.md)
3. Spec màn + [`client_protocol_contract.md`](../../docs/product/architecture/client_protocol_contract.md) nếu streaming
