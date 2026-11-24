# Architecture Decision Records (ADR)

> TL;DR: Danh sách quyết định kiến trúc. Mỗi ADR gồm bối cảnh, các phương án, quyết định, hệ quả.
> Persona áp dụng: *Software Architect* (Agency). Quy tắc: luôn nêu ít nhất 2 phương án và trade-off.
> Thêm ADR mới ở cuối file, đánh số tăng dần. Đổi quyết định thì tạo ADR mới với trạng thái "Supersedes ADR-xxx".

| # | Quyết định | Trạng thái |
|---|---|---|
| 001 | Flutter cho app mobile, native cho watch | Accepted |
| 002 | Supabase + worker TypeScript thay vì backend tự dựng toàn bộ | Accepted |
| 003 | Offline-first, nhắc nhở lập lịch local trên thiết bị | Accepted |
| 004 | AI extraction qua Claude API phía server, structured outputs | Superseded by 010 |
| 005 | Email chuyển tiếp trước, Gmail API sau | Accepted |
| 006 | RevenueCat cho subscription | Accepted |
| 007 | Lặp lại: RFC 5545 RRULE + mở rộng âm lịch | Accepted |
| 008 | Entitlement do server quyết định, client chỉ cache | Accepted |
| 009 | Hàng đợi job bằng pg-boss trên Postgres | Accepted |
| 010 | Trích xuất chạy trên thiết bị, không dùng AI API trả phí | Accepted |

---

## ADR-001: Flutter cho app mobile, native cho watch
**Bối cảnh.** Cần 1 đội nhỏ ship Android + iOS nhanh, UI giống nhau, hiệu năng tốt cho danh sách dài
và lịch. Đồng hồ (watchOS, Wear OS) không framework cross-platform nào hỗ trợ tốt.

**Phương án.**
| | Flutter | React Native (Expo) | Native x2 (Swift + Kotlin) | Kotlin Multiplatform + Compose MP |
|---|---|---|---|---|
| Tốc độ ship 2 nền tảng | Cao | Cao | Thấp | Trung bình |
| Đồng nhất UI | Rất cao (tự vẽ) | Trung bình | Thấp | Cao |
| Tích hợp native (alarm, widget, share ext) | Platform channel, ổn | Native module, ổn | Tốt nhất | Tốt |
| Chia sẻ code với backend TS | Không | Có (TS) | Không | Không |
| Nguồn nhân lực VN | Nhiều | Nhiều | Trung bình | Ít |

**Quyết định.** Flutter cho app chính. watchOS viết SwiftUI, Wear OS viết Jetpack Compose,
giao tiếp với app qua WatchConnectivity / Wearable Data Layer. Widget màn hình chính viết native
(WidgetKit, Glance) và đọc dữ liệu qua `home_widget`.

**Hệ quả.** Phải duy trì 3 codebase UI nhỏ (Flutter + 2 watch). Logic parse dùng chung
(rrule, âm lịch, ngày giờ tiếng Việt) viết bằng Dart trong app và TS trong worker, dùng chung
bộ test fixtures JSON trong `packages/parsers/fixtures/` để 2 bản luôn cho cùng kết quả.

## ADR-002: Supabase + worker TypeScript
**Bối cảnh.** Cần Auth (Google, Apple, email OTP), Postgres quan hệ (đếm giới hạn, quan hệ trip/booking),
lưu file (ảnh, pdf người dùng upload), và tác vụ nền nặng (AI, email, Gmail watch).

**Phương án.** (a) Firebase: Auth tốt, Firestore khó đếm/aggregate và query quan hệ. (b) Tự dựng NestJS + Postgres +
S3: linh hoạt nhưng tốn công vận hành. (c) Supabase cho Auth/DB/Storage/RLS + 1 worker TS cho phần nặng.

**Quyết định.** (c). Supabase managed (region Singapore, gần VN). Worker chạy Cloud Run (hoặc Fly.io),
kết nối Postgres trực tiếp. FCM vẫn dùng Firebase (chỉ Messaging + Crashlytics).

**Hệ quả.** RLS là lớp bảo mật chính cho truy cập trực tiếp từ app. Logic có quyền cao (entitlement, AI)
chỉ chạy trong worker bằng service role. Có thể rời Supabase sau này vì bên dưới là Postgres chuẩn.

## ADR-003: Offline-first, nhắc nhở local
**Bối cảnh.** Nhắc nhở phải kêu đúng giờ kể cả khi mất mạng, server chết, hoặc máy ở chế độ máy bay.
Push từ server không đảm bảo đúng giờ (Doze, APNs throttle).

**Quyết định.** Nguồn sự thật cho lịch kêu là DB local (Drift). App tự lập lịch thông báo local
(Android `AlarmManager.setExactAndAllowWhileIdle` / `setAlarmClock`; iOS `UNCalendarNotificationTrigger`).
Server dùng push chỉ để: đồng bộ thay đổi từ thiết bị khác (silent push), nhắc qua email, và làm "lưới an toàn"
cho iOS khi vượt giới hạn 64 thông báo chờ (xem `reminder-engine.md`).

**Hệ quả.** Cần thuật toán sync và giải quyết xung đột (`system-architecture.md` mục Sync).
Cần xử lý reboot, đổi múi giờ, đổi giờ hệ thống, app bị OEM kill.

## ADR-004: AI extraction phía server (Superseded by ADR-010)
**Bối cảnh.** Đọc vé/booking từ ảnh, pdf, xlsx, email cần LLM đa phương thức. Key không được nằm trong app.

**Phương án.** (a) On-device OCR + rule: rẻ, riêng tư, kém với layout lạ. (b) Gửi thẳng ảnh/pdf cho Claude: chính xác,
tốn phí. (c) Lai: tiền xử lý rẻ (pdf text layer, parse xlsx, đọc `.pkpass`, `.ics`, JSON-LD trong email),
chỉ gọi LLM khi cần.

**Quyết định.** (c). Mặc định `claude-opus-5-5` với `output_config.format` (JSON schema) và `fallbacks: "default"`.
Model cấu hình theo route trong bảng `ai_routes` để chủ sản phẩm tự cân bằng chi phí/chất lượng
(ví dụ có thể đổi sang `claude-sonnet-5-5` hoặc `claude-haiku-5-5` cho route xlsx đơn giản sau khi đo bằng eval).

**Hệ quả.** Phải có eval set (ảnh vé thật đã ẩn danh) trước khi đổi model. Mọi kết quả AI đi qua màn hình
"Xem lại" để người dùng xác nhận, không tự tạo nhắc nhở khi độ tin cậy thấp.

## ADR-005: Email chuyển tiếp trước, Gmail API sau
**Bối cảnh.** Đọc Gmail cần scope `gmail.readonly`, thuộc nhóm *restricted*: Google bắt thẩm định bảo mật
(CASA) hằng năm, tốn thời gian và chi phí. TripIt thành công với mô hình "forward email tới plans@...".

**Quyết định.** MVP: mỗi user có địa chỉ riêng `u-<token>@in.remindme.app`, người dùng forward email booking
hoặc tạo filter tự động forward. Phase 3: Gmail API (OAuth, chỉ đọc email khớp bộ lọc booking) sau khi qua CASA.
Google Calendar (scope sensitive, không cần CASA) làm ở Phase 2.

## ADR-006: RevenueCat cho subscription
**Phương án.** (a) Tự xử lý StoreKit 2 + Play Billing + server notifications. (b) RevenueCat (miễn phí tới ngưỡng doanh thu
nhất định, sau đó lấy % doanh thu; kiểm tra lại bảng giá hiện tại). **Quyết định.** (b) cho tốc độ; webhook RevenueCat ghi vào bảng
`subscriptions`, server tính `entitlements`. Có thể tự làm sau nếu phí đáng kể.

## ADR-007: Lặp lại RRULE + âm lịch
**Quyết định.** Lưu quy tắc lặp dạng RRULE (RFC 5545) để tương thích Google Calendar/ICS.
Thêm `recurrence_kind = 'lunar'` với cấu trúc riêng (`{lunar_month, lunar_day, leap_policy}`) cho giỗ, rằm, mùng 1.
Thuật toán đổi âm-dương theo lịch Việt Nam (múi giờ UTC+7, khác lịch Trung Quốc ở vài năm). Khi đồng bộ ra Google Calendar,
sự kiện âm lịch được "trải phẳng" thành các lần xuất hiện cụ thể trong 2 năm tới.

## ADR-008: Entitlement phía server
**Quyết định.** Bảng `plan_entitlements` giữ giới hạn từng gói. Kiểm tra giới hạn ở 2 nơi: client (UX, chặn sớm, hiện paywall)
và server (RPC `can_create(kind)` + trigger Postgres) để chống lách. Client cache entitlement 24h, dùng được khi offline;
khi offline vượt giới hạn, item tạo ra ở trạng thái `pending_quota` và bị từ chối khi sync nếu vẫn vượt.

## ADR-009: pg-boss
**Phương án.** Redis + BullMQ, Cloud Tasks, pg-boss. **Quyết định.** pg-boss: không thêm hạ tầng, job transactional cùng dữ liệu.
Chuyển sang hàng đợi chuyên dụng khi vượt ~50 job/giây ổn định.

## ADR-010: Trích xuất chạy trên thiết bị, không dùng AI API trả phí
**Trạng thái.** Accepted, supersedes ADR-004.

**Bối cảnh.** Chủ dự án không muốn chi phí biến đổi theo số lần import: người dùng (hoặc bot) có thể cố tình spam ảnh/file,
mỗi lần gọi LLM đám mây là một khoản tiền. Ngoài ra dữ liệu booking/y tế rời khỏi máy là rủi ro quyền riêng tư.

**Phương án.**
| | (a) LLM đám mây + quota chặt | (b) Server tự host OCR/model | (c) Trên thiết bị: decoder + OCR của OS + luật/mẫu, LLM của OS tùy chọn |
|---|---|---|---|
| Chi phí theo lượt | Có (~550đ/import) | CPU/GPU server tăng theo tải | 0 |
| Rủi ro spam | Phải chặn bằng quota/rate limit | Vẫn tốn tài nguyên | Chỉ tốn pin máy người spam |
| Độ chính xác với bố cục lạ | Cao | Trung bình | Trung bình (bù bằng màn Xem lại + mẫu) |
| Độ chính xác với nhà cung cấp quen | Cao | Cao | Cao (mẫu chuyên biệt) |
| Offline | Không | Không | Có |
| Quyền riêng tư | Dữ liệu ra bên thứ ba | Dữ liệu lên server mình | Dữ liệu không rời máy |
| Công sức dev | Thấp | Cao (vận hành) | Trung bình-cao (viết và bảo trì mẫu) |

**Quyết định.** (c). Chi tiết: `on-device-extraction.md`. Server chỉ còn làm hộp thư email (lưu MIME, push về máy),
phát mẫu nhà cung cấp qua CDN tĩnh có chữ ký, sync và entitlement.

**Hệ quả.** Cần đầu tư bộ mẫu cho top nhà cung cấp VN và eval set ≥ 300 mẫu ngay Phase 0. Tài liệu bố cục lạ sẽ cần người dùng
sửa nhiều hơn, nên màn Xem lại phải sửa được nhanh. Giới hạn import của gói Free giờ chỉ là đòn bẩy bán hàng, không còn để bảo vệ chi phí.
Nếu sau này cần LLM đám mây cho một tính năng trả phí, phải có ADR mới kèm quota cứng và tính chi phí.
