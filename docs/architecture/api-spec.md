# API spec

> TL;DR: **Đường ghi duy nhất** là RPC Postgres `sync_push` (gọi qua PostgREST `/rest/v1/rpc/...`), nơi kiểm quota (ADR-012).
> Bảng đồng bộ chỉ đọc qua PostgREST (RLS). Worker (`/v1`) chỉ phục vụ việc cần quyền cao: entitlement, hộp thư email, OAuth server-side,
> push, webhook. Worker không đọc nội dung tài liệu. Auth: `Authorization: Bearer <supabase JWT>`.
> Lỗi: `{ "error": { "code": "quota_exceeded", "message": "...", "details": {...} } }`.

## 1. Sync (RPC Postgres, `SECURITY DEFINER`, kiểm `auth.uid()`)
| RPC | Mô tả |
|---|---|
| `profile_init(ui_locale, region, home_tz, display_name?)` | Gọi 1 lần lúc onboarding (sau đăng nhập ẩn danh). Tạo profile + Inbox; gọi lại không đổi gì. `sync_push` trả lỗi `profile_missing` nếu chưa gọi |
| `sync_push(device_id text, mutations jsonb)` | ≤ 200 mutation `{table, id, op: upsert\|delete, payload, field_clock, base_clock?}`. Mỗi mutation chạy trong subtransaction riêng (1 cái lỗi không hỏng cả batch), merge LWW theo `field_clock`, kiểm quota (data-model §4). `recurrences`/`booking_details` khóa theo `item_id`; `occurrence_log` theo `(item_id, occurrence_at)` trong payload. `base_clock.notes` = clock của notes lúc bắt đầu sửa, để phát hiện sửa đồng thời. Trả mảng cùng thứ tự `[{table, id, key, status: ok\|conflict\|quota_exceeded\|invalid, version, server_row, error?, details?}]`; `server_row` là hàng sau merge để client ghi đè bản local. `error` của conflict: `notes_conflict`, `deleted` |
| `sync_pull(since bigint, lim int default 500)` | Trả mọi hàng có `version > since` của user, gồm tombstone; `{rows:{items:[],reminders:[],...}, next_since, has_more}` |
| `session_status(device_id?, platform?, device_class?)` | Trạng thái phiên của JWT hiện tại: `{state: unclaimed\|active\|ended, end_reason, ended_at, replaced_by:{platform, device_model, device_class, country, signed_in_at}, will_replace:[...], max_active_devices, max_devices_per_class}`. `will_replace` (chỉ khi chưa claim) = các máy sẽ bị đăng xuất nếu máy này claim với loại thiết bị đã cho. Gọi được cả khi phiên đã bị đá |
| `session_claim(device_id, device jsonb)` | Gọi ngay sau đăng nhập + `profile_init` (ADR-013). `device` = `{platform: ios\|ipados\|android\|web\|macos\|windows\|linux, device_class: phone\|tablet, device_model, os_version, app_version, locale, tz}`; IP/quốc gia lấy từ header. Kết thúc phiên vượt `max_active_devices` / `max_devices_per_class`, trả `{session_id, replaced:[{device_id, platform, device_model, last_seen_at}]}`. Phiên đã bị đá gọi lại → `session_revoked` |
| `session_end(session_id?)` | Đăng xuất phiên hiện tại (mặc định) hoặc phiên khác của mình |
| `quota_status()` | `{plan, period_end, limits:{...}, usage:{...}, features:{feature_watch_app:1,...}}` (giá trị seed ở `pricing-entitlements.md` §2) |
Trigger trên bảng đồng bộ chặn mọi ghi không đi qua `sync_push` (trừ service role).
**Phiên (ADR-013):** `sync_push`, `sync_pull`, `quota_status` và RLS mọi bảng của user chỉ chấp nhận JWT có `session_id` đang `active`.
Không thì HTTP 403 với message `session_not_claimed` (chưa gọi `session_claim`) hoặc `session_revoked` (đã đăng nhập ở thiết bị khác):
app gọi `session_status()` để lấy thông tin thiết bị mới, hủy toàn bộ thông báo đã lập lịch, đăng xuất (UX §3.7). Bảng đọc qua PostgREST trả rỗng.
Lịch sử đăng nhập: `GET /rest/v1/user_sessions?order=created_at.desc` (RLS, chỉ phiên đang hoạt động đọc được).

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
Loại push (data message): `sync.tickle`, `reschedule`, `inbox.new`, `packs.updated` (mẫu, gói NLU, ngày lễ), `subscription.changed`, `trip.update` (Phase 3),
`session.revoked` (job `session.notify_revoked` quét `user_sessions` có `end_reason in ('replaced','plan_limit')` và `revoke_notified_at is null`, push tới `fcm_token` của thiết bị cũ,
rồi xóa `fcm_token` đó và ghi `revoke_notified_at`). Mọi endpoint worker kiểm `session_id` của JWT còn `active` như RPC.

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
`session_revoked` / `session_not_claimed` 403, `rate_limited` 429, `upstream_error` 502, `internal` 500. Mã lỗi là key; thông điệp hiển thị do app dịch theo locale.
Rate limit: 60 req/phút/user cho worker; `sync_push` 30 lần/phút/thiết bị; giới hạn email inbound ở `on-device-extraction.md` §8.
