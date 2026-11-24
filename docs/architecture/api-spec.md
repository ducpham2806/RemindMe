# API spec (worker `/v1`)

> TL;DR: CRUD thường đi thẳng PostgREST của Supabase (RLS). Worker chỉ phục vụ những việc cần quyền cao:
> sync có kiểm quota, import AI, entitlement, tích hợp OAuth, webhook. Auth: `Authorization: Bearer <supabase JWT>`.
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
| POST | `/v1/me/quota/check` | Body `{kind:"appointment", count:3}` → `{allowed, remaining, upsell_reason}` (dùng trước màn Xem lại) |

## Parse & import
| Method | Path | Mô tả |
|---|---|---|
| POST | `/v1/parse/text` | `{text, locale, now, tz}` → `{items:[...], confidence}`. Dùng khi QuickParser không chắc. Tính 0,2 credit AI (làm tròn theo ngày) |
| POST | `/v1/imports` | `{kind, mime, bytes, sha256}` → `{import_id, upload_url, expires_in}`. 402 `quota_exceeded` nếu hết lượt AI. Trùng `sha256` trong 30 ngày → trả kết quả cũ, không tính lượt |
| POST | `/v1/imports/{id}/start` | Bắt đầu xử lý (enqueue `ingest.<kind>`) → `202` |
| GET | `/v1/imports/{id}` | `{status, candidates:[...], warnings, error}` |
| POST | `/v1/imports/{id}/commit` | `{candidates:[{id, accepted, edited_payload, trip_id?}]}` → `{created_item_ids, trip_id}`. Kiểm tra quota lịch hẹn |
| DELETE | `/v1/imports/{id}` | Hủy, xóa file |

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

Loại push (data message): `sync.tickle`, `reschedule`, `import.ready`, `import.failed`, `subscription.changed`, `trip.update` (Phase 3: đổi giờ bay).

## Webhook (không dùng JWT, xác thực bằng chữ ký/secret)
| Path | Nguồn |
|---|---|
| `POST /hooks/revenuecat` | RevenueCat (header Authorization secret) → cập nhật `subscriptions`, push `subscription.changed` |
| `POST /hooks/inbound-email` | Postmark/Cloudflare Email Worker (HMAC) → `email.inbound` job |
| `POST /hooks/gmail-push` | Google Pub/Sub (Gmail `watch`) Phase 3 |
| `POST /hooks/gcal-push` | Google Calendar push notification channel |

## Mã lỗi chuẩn
`unauthenticated` 401, `forbidden` 403, `not_found` 404, `quota_exceeded` 402 (kèm `details.key`, `limit`, `used`),
`invalid` 422, `conflict` 409, `rate_limited` 429, `upstream_error` 502, `internal` 500.

## Rate limit
Mặc định 60 req/phút/user; `/v1/imports` 10/phút; `/v1/parse/text` 30/phút.
