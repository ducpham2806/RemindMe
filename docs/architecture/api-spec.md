# API spec (worker `/v1`)

> TL;DR: CRUD thường đi thẳng PostgREST của Supabase (RLS). Worker chỉ phục vụ những việc cần quyền cao:
> sync có kiểm quota, entitlement, hộp thư email, tích hợp OAuth, webhook. Worker không đọc nội dung tài liệu. Auth: `Authorization: Bearer <supabase JWT>`.
> Lỗi theo dạng `{ "error": { "code": "quota_exceeded", "message": "...", "details": {...} } }`.

## Sync
| Method | Path | Mô tả |
|---|---|---|
| POST | `/v1/sync/push` | Body `{device_id, mutations:[{table,id,op,payload,client_updated_at}]}` (≤ 200). Trả `{results:[{id,status:"ok"|"conflict"|"quota_exceeded"|"invalid", version, server_row?}]}` |
| GET | `/v1/sync/pull?since=<version>&limit=500` | Trả `{rows:{items:[],reminders:[],...}, next_since, has_more}` |

## Entitlement & quota
| Method | Path | Mô tả |
|---|---|---|
| GET | `/v1/me/entitlements` | `{plan:"free", period_end, limits:{max_reminders_per_day:10,...}, usage:{...}, features:{watch_app:false,...}}` |
| POST | `/v1/me/quota/check` | Body `{kind:"appointment", count:3}` → `{allowed, remaining, upsell_reason}` (tùy chọn khi online; offline dùng entitlement cache) |

## Import (metadata) & hộp thư email
Phân tích file chạy hoàn toàn trên máy (ADR-010), nên **không có endpoint nhận file để phân tích** và không có endpoint parse text.
Bảng `imports` đồng bộ qua sync như bảng thường (dedupe theo `sha256` giữa các thiết bị).

| Method | Path | Mô tả |
|---|---|---|
| GET | `/v1/mailbox?since=<ts>` | Danh sách email forward chờ xử lý `{id, from, received_at, bytes, download_url}` (signed URL 10 phút) |
| POST | `/v1/mailbox/{id}/ack` | Máy đã xử lý xong, server xóa MIME ngay (không chờ TTL) |
| POST | `/v1/originals` | (Plus, "Giữ bản gốc") xin signed URL để lưu bản gốc; kiểm `max_originals_mb` |
| GET | `https://cdn.remindme.app/templates/manifest.json` | Danh sách mẫu nhà cung cấp `{id, version, url, sig}`; file tĩnh, app tải khi có Wi-Fi hoặc mỗi 24h |

## Tích hợp
| Method | Path | Mô tả |
|---|---|---|
| GET | `/v1/integrations` | Danh sách đã kết nối |
| POST | `/v1/integrations/{provider}/connect` | Trả URL OAuth (PKCE). provider: `google_calendar`, `gmail`, `microsoft`, `notion` |
| GET | `/v1/integrations/{provider}/callback` | OAuth callback, lưu token vào Vault, enqueue sync đầu tiên |
| POST | `/v1/integrations/{id}/sync` | Đồng bộ ngay |
| DELETE | `/v1/integrations/{id}` | Thu hồi token phía provider + xóa |
| GET | `/v1/me/inbound-email` | `{address:"u-8f3k2@in.remindme.app"}` + hướng dẫn tạo filter Gmail |
| POST | `/v1/me/calendar-feed/rotate` | Đổi token feed ICS |
| GET | `/ics/{token}.ics` | Feed ICS công khai theo token (chỉ đọc, gói trả phí) |

## Thiết bị & push
| Method | Path | Mô tả |
|---|---|---|
| PUT | `/v1/devices/{device_id}` | `{platform, fcm_token, tz, app_version, oem}` |
| DELETE | `/v1/devices/{device_id}` | Đăng xuất thiết bị |

Loại push (data message): `sync.tickle`, `reschedule`, `inbox.new` (có email forward mới), `templates.updated`, `subscription.changed`, `trip.update` (Phase 3: đổi giờ bay).

## Webhook (không dùng JWT, xác thực bằng chữ ký/secret)
| Path | Nguồn |
|---|---|
| `POST /hooks/revenuecat` | RevenueCat (header Authorization secret) → cập nhật `subscriptions`, push `subscription.changed` |
| `POST /hooks/inbound-email` | Postmark/Cloudflare Email Worker (HMAC) → kiểm rate limit/kích thước → lưu MIME vào `mailbox_messages` → push `inbox.new` |
| `POST /hooks/gmail-push` | Google Pub/Sub (Gmail `watch`) Phase 3 |
| `POST /hooks/gcal-push` | Google Calendar push notification channel |

## Mã lỗi chuẩn
`unauthenticated` 401, `forbidden` 403, `not_found` 404, `quota_exceeded` 402 (kèm `details.key`, `limit`, `used`),
`invalid` 422, `conflict` 409, `rate_limited` 429, `upstream_error` 502, `internal` 500.

## Rate limit
Mặc định 60 req/phút/user; `/v1/originals` 10/phút; email inbound 30 email/ngày/user.
