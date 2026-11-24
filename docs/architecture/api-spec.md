# API spec

> TL;DR: **Đường ghi duy nhất** là RPC Postgres `sync_push` (gọi qua PostgREST `/rest/v1/rpc/...`), nơi kiểm quota (ADR-012).
> Bảng đồng bộ chỉ đọc qua PostgREST (RLS). Worker (`/v1`) chỉ phục vụ việc cần quyền cao: entitlement, hộp thư email, OAuth server-side,
> push, webhook. Worker không đọc nội dung tài liệu. Auth: `Authorization: Bearer <supabase JWT>`.
> Lỗi: `{ "error": { "code": "quota_exceeded", "message": "...", "details": {...} } }`.

## 1. Sync (RPC Postgres, `SECURITY DEFINER`, kiểm `auth.uid()`)
| RPC | Mô tả |
|---|---|
| `sync_push(device_id text, mutations jsonb)` | ≤ 200 mutation `{table, id, op, payload, field_clock}`. Áp dụng trong 1 transaction, merge LWW theo `field_clock`, kiểm quota (data-model §4). Trả `[{id, status: ok\|conflict\|quota_exceeded\|invalid, version, server_row?}]` |
| `sync_pull(since bigint, lim int default 500)` | Trả mọi hàng có `version > since` của user, gồm tombstone; `{rows:{items:[],reminders:[],...}, next_since, has_more}` |
| `quota_status()` | `{plan, period_end, limits:{...}, usage:{...}, features:{feature_watch_app:1,...}}` (giá trị seed ở `pricing-entitlements.md` §2) |
Trigger trên bảng đồng bộ chặn mọi ghi không đi qua `sync_push` (trừ service role).

## 2. Worker `/v1`
### Hộp thư email & bản gốc
| Method | Path | Mô tả |
|---|---|---|
| GET | `/v1/mailbox?since=<ts>` | Email forward chờ xử lý `{id, from, received_at, bytes, download_url}` (signed URL 10 phút) |
| POST | `/v1/mailbox/{id}/ack` | Máy đã xử lý xong, server xóa MIME ngay |
| GET | `/v1/me/inbound-email` | `{address}` + hướng dẫn tạo filter theo locale |
| POST | `/v1/originals` | (Plus) signed URL để lưu bản gốc; kiểm `max_originals_mb` |

### Tích hợp có token phía server
`provider` ∈ `google_calendar`, `google_tasks`, `microsoft`, `notion` (khớp `integrations.provider`). Gmail chạy trên máy (Phase 3), không có ở đây.
| Method | Path | Mô tả |
|---|---|---|
| GET | `/v1/integrations` | Danh sách đã kết nối |
| POST | `/v1/integrations/{provider}/connect` | URL OAuth (PKCE) |
| GET | `/v1/integrations/{provider}/callback` | Lưu token vào Vault, enqueue sync đầu tiên |
| POST | `/v1/integrations/{id}/sync` | Đồng bộ ngay |
| DELETE | `/v1/integrations/{id}` | Thu hồi token phía provider + xóa |
| POST | `/v1/me/calendar-feed/rotate` | Đổi token feed ICS (Plus, Phase 2) |
| GET | `/ics/{token}.ics` | Feed ICS chỉ đọc |

### Thiết bị & push
| Method | Path | Mô tả |
|---|---|---|
| PUT | `/v1/devices/{device_id}` | `{platform, fcm_token, tz, locale, app_version, oem, scheduled_until, receives_reminders}` |
| DELETE | `/v1/devices/{device_id}` | Đăng xuất thiết bị |
Loại push (data message): `sync.tickle`, `reschedule`, `inbox.new`, `packs.updated` (mẫu, gói NLU, ngày lễ), `subscription.changed`, `trip.update` (Phase 3).

### Dữ liệu tĩnh trên CDN (không qua worker)
`https://cdn.remindme.app/packs/manifest.json` liệt kê `{type: template|nlu|holiday|ocr_model|voice_model, id, version, url, sha256, sig}`.
App tải khi có Wi-Fi hoặc mỗi 24h, xác minh chữ ký (`security-privacy.md` §2).

## 3. Webhook (không dùng JWT, xác thực bằng chữ ký/secret)
| Path | Nguồn |
|---|---|
| `POST /hooks/revenuecat` | RevenueCat → cập nhật `subscriptions`, push `subscription.changed` |
| `POST /hooks/inbound-email` | Postmark/Cloudflare (HMAC) → kiểm tra theo `on-device-extraction.md` §8 → lưu `mailbox_messages` → push `inbox.new` |
| `POST /hooks/gcal-push` | Google Calendar push channel (Phase 2) |

## 4. Mã lỗi & rate limit
`unauthenticated` 401, `forbidden` 403, `not_found` 404, `quota_exceeded` 402 (`details.key`, `limit`, `used`), `invalid` 422, `conflict` 409,
`rate_limited` 429, `upstream_error` 502, `internal` 500. Mã lỗi là key; thông điệp hiển thị do app dịch theo locale.
Rate limit: 60 req/phút/user cho worker; `sync_push` 30 lần/phút/thiết bị; giới hạn email inbound ở `on-device-extraction.md` §8.
