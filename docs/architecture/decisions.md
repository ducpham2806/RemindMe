# Architecture Decision Records (ADR)

> TL;DR: Danh sách quyết định kiến trúc. Mỗi ADR gồm bối cảnh, các phương án, quyết định, hệ quả.
> Quy tắc: luôn nêu ít nhất 2 phương án và trade-off.
> Thêm ADR mới ở cuối file, đánh số tăng dần. Đổi quyết định thì tạo ADR mới với trạng thái "Supersedes ADR-xxx".

| # | Quyết định | Trạng thái |
|---|---|---|
| 001 | Flutter cho app mobile, native cho watch | Accepted |
| 002 | Supabase + worker TypeScript thay vì backend tự dựng toàn bộ | Accepted |
| 003 | Offline-first, nhắc nhở lập lịch local trên thiết bị | Accepted |
| 004 | AI extraction qua Claude API phía server, structured outputs | Superseded by 010 |
| 005 | Email chuyển tiếp trước, Gmail API (chạy trên máy) sau | Accepted (sửa 24/11) |
| 006 | RevenueCat cho subscription | Accepted |
| 007 | Lặp lại: RFC 5545 RRULE + hệ lịch khác (âm lịch VN/TQ/HQ, Hijri) | Accepted (sửa 24/11) |
| 008 | Entitlement do server quyết định, client chỉ cache | Accepted |
| 009 | Hàng đợi job bằng pg-boss trên Postgres | Accepted |
| 010 | Trích xuất chạy trên thiết bị, không dùng AI API trả phí | Accepted |
| 011 | Global ngay từ launch: cấp hỗ trợ locale, 1 region dữ liệu, OS tối thiểu | Accepted |
| 012 | Đường ghi duy nhất là RPC `sync_push` | Accepted |

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
| Nguồn nhân lực (VN và global) | Nhiều | Nhiều | Trung bình | Ít |

**Quyết định.** Flutter cho app chính. watchOS viết SwiftUI, Wear OS viết Jetpack Compose,
giao tiếp với app qua WatchConnectivity / Wearable Data Layer. Widget màn hình chính viết native
(WidgetKit, Glance) và đọc dữ liệu qua `home_widget`.

**Hệ quả.** Phải duy trì 3 codebase UI nhỏ (Flutter + 2 watch). Toàn bộ NLU và trích xuất chỉ có bản Dart (ADR-010).
Worker TS chỉ cần mở rộng lặp (RRULE + hệ lịch) để xuất feed ICS / đồng bộ Google Calendar; bản TS này dùng chung fixtures
`packages/parsers/fixtures/recurrence/` với bản Dart để luôn cho cùng kết quả.

## ADR-002: Supabase + worker TypeScript
**Bối cảnh.** Cần Auth (Google, Apple, email OTP), Postgres quan hệ (đếm giới hạn, quan hệ trip/booking),
lưu file (MIME email, bản gốc tùy chọn), và tác vụ nền (hộp thư email, đồng bộ Google/Notion, push).

**Phương án.** (a) Firebase: Auth tốt, Firestore khó đếm/aggregate và query quan hệ. (b) Tự dựng NestJS + Postgres +
S3: linh hoạt nhưng tốn công vận hành. (c) Supabase cho Auth/DB/Storage/RLS + 1 worker TS cho phần nặng.

**Quyết định.** (c). Supabase managed (region: ADR-011). Worker chạy Cloud Run (hoặc Fly.io) cùng region,
kết nối Postgres trực tiếp. FCM vẫn dùng Firebase (chỉ Messaging + Crashlytics).

**Hệ quả.** RLS là lớp bảo mật chính cho đọc trực tiếp từ app; ghi đi qua RPC `sync_push` (ADR-012). Logic có quyền cao
(webhook, OAuth server-side, hộp thư) chạy trong worker bằng service role. Có thể rời Supabase sau này vì bên dưới là Postgres chuẩn.

## ADR-003: Offline-first, nhắc nhở local
**Bối cảnh.** Nhắc nhở phải kêu đúng giờ kể cả khi mất mạng, server chết, hoặc máy ở chế độ máy bay.
Push từ server không đảm bảo đúng giờ (Doze, APNs throttle).

**Quyết định.** Nguồn sự thật cho lịch kêu là DB local (Drift). App tự lập lịch thông báo local
(Android `AlarmManager.setExactAndAllowWhileIdle` / `setAlarmClock`; iOS `UNCalendarNotificationTrigger`).
Server dùng push chỉ để: đồng bộ thay đổi từ thiết bị khác (silent push), báo email forward mới, và làm "lưới an toàn"
cho iOS khi vượt giới hạn 64 thông báo chờ (xem `reminder-engine.md`).

**Hệ quả.** Cần thuật toán sync và giải quyết xung đột (`system-architecture.md` mục Sync).
Cần xử lý reboot, đổi múi giờ, đổi giờ hệ thống, app bị OEM kill.

## ADR-004: AI extraction phía server (Superseded by ADR-010)
Từng chọn gọi Claude API phía server để đọc ảnh/pdf/email (có bảng `ai_routes`, quota AI). Đã thay bằng ADR-010; không còn bảng hay endpoint nào của thiết kế này.

## ADR-005: Email chuyển tiếp trước, Gmail API sau
**Bối cảnh.** Đọc Gmail cần scope `gmail.readonly`, thuộc nhóm *restricted*: Google bắt thẩm định bảo mật
(CASA) hằng năm, tốn thời gian và chi phí. TripIt thành công với mô hình "forward email tới plans@...".

**Quyết định.** MVP: mỗi user có địa chỉ riêng `u-<token>@in.remindme.app`, người dùng forward email booking
hoặc tạo filter tự động forward. Phase 3: Gmail API với OAuth **trên máy** (token chỉ trong Keychain/Keystore), máy tự đọc email khớp bộ lọc
booking và xử lý cục bộ, server không thấy token hay nội dung. Kiểm tra lại với Google xem cách này có cần CASA không (yêu cầu thẩm định
phụ thuộc việc dữ liệu restricted có qua server hay không). Google Calendar (scope sensitive, không cần CASA) làm ở Phase 2.

## ADR-006: RevenueCat cho subscription
**Phương án.** (a) Tự xử lý StoreKit 2 + Play Billing + server notifications. (b) RevenueCat (miễn phí tới ngưỡng doanh thu
nhất định, sau đó lấy % doanh thu; kiểm tra lại bảng giá hiện tại). **Quyết định.** (b) cho tốc độ; webhook RevenueCat ghi vào bảng
`subscriptions`, server tính `entitlements`. Có thể tự làm sau nếu phí đáng kể.

## ADR-007: Lặp lại RRULE + hệ lịch khác
**Quyết định.** Lưu quy tắc lặp dạng RRULE (RFC 5545) để tương thích Google Calendar/ICS. Hệ lịch khác dùng `recurrences.kind = 'calendar'`
với `calendar = {system, month, day, leap}` (`system`: `lunar_vi`, `lunar_zh`, `lunar_ko`, `hijri`; cột cụ thể ở `data-model.md`).
Âm lịch VN/TQ/HQ dùng chung 1 thuật toán âm dương, tham số múi giờ UTC+7/+8/+9 (vì vậy có năm lệch nhau). Hijri theo Umm al-Qura.
Khi xuất ra Google Calendar/ICS, sự kiện theo hệ lịch khác được trải phẳng thành các lần xuất hiện cụ thể trong 2 năm tới.
Chi tiết thực thi: `reminder-engine.md` §4; danh sách hệ lịch theo thị trường: `i18n-l10n.md` §5.

## ADR-008: Entitlement phía server
**Quyết định.** Bảng `plan_entitlements` giữ giới hạn từng gói. Kiểm tra giới hạn ở 2 nơi: client (UX, chặn sớm, hiện paywall)
và server (trong RPC `sync_push` + trigger dự phòng, ADR-012) để chống lách. Client cache entitlement 24h, dùng được khi offline;
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

## ADR-011: Global ngay từ launch
**Bối cảnh.** Chủ dự án nhắm thị trường toàn cầu từ đầu, không chỉ Việt Nam. Đội nhỏ không thể làm "đầy đủ" mọi ngôn ngữ cùng lúc.

**Phương án.** (a) VN trước, global sau (thiết kế cũ): rẻ nhưng nợ kỹ thuật i18n lớn. (b) Mọi ngôn ngữ ngang nhau: quá sức đội nhỏ.
(c) Global từ launch với **cấp hỗ trợ** theo locale (A/B/C) và cổng chất lượng.

**Quyết định.** (c). Chi tiết: `i18n-l10n.md`. Kèm theo:
- **Dữ liệu**: 1 region Supabase chính ở launch, chọn theo nơi có nhiều người dùng trả phí dự kiến nhất (chốt sau nghiên cứu thị trường Phase 0).
  Offline-first nên độ trễ không ảnh hưởng UX. Chuyển dữ liệu xuyên biên giới bằng SCC/DPA. `profiles` có sẵn cột để sau này tách project EU
  (data residency) khi doanh thu EU hoặc khách hàng doanh nghiệp yêu cầu.
- **OS tối thiểu**: iOS 17+ (Vision `VNRecognizeTextRequest`, SFSpeechRecognizer; tính năng iOS 18/26/27 bật theo khả dụng), Android 8.0 (API 26)+.
- **Không phát hành ở Trung Quốc đại lục** ở launch (không có FCM/Google Play services, cần đăng ký ICP).
- **Điều kiện xem lại ADR-010**: nếu eval tài liệu không có mẫu ở các thị trường đợt 1 dưới 60% trường đúng sau Phase 1, chủ dự án quyết
  có thêm một tầng LLM đám mây chỉ cho gói Plus với quota cứng hay không (cần ADR mới).

**Hệ quả.** Mọi tài liệu và code không được giả định locale, múi giờ, định dạng hay đồng tiền mặc định. NLU, mẫu tài liệu, ngày lễ là gói dữ liệu theo locale.

## ADR-012: Đường ghi duy nhất là RPC `sync_push`
**Bối cảnh.** App có thể ghi thẳng qua PostgREST (RLS) hoặc qua sync. Hai đường ghi thì quota và merge xung đột có thể bị lách.

**Phương án.** (a) Ghi PostgREST + trigger kiểm quota: đơn giản nhưng logic merge LWW nằm rải rác. (b) Endpoint sync trong worker:
thêm một hop mạng và phụ thuộc worker. (c) RPC Postgres `sync_push`/`sync_pull` (`SECURITY DEFINER`) là đường ghi duy nhất; PostgREST chỉ đọc.

**Quyết định.** (c). Policy RLS chỉ cho `SELECT` trên bảng đồng bộ; trigger từ chối ghi không đến từ `sync_push` (trừ service role).
Quota và merge theo `field_clock` nằm trong 1 transaction. Spec: `api-spec.md` §1.

**Hệ quả.** Logic sync viết bằng PL/pgSQL (hoặc plv8), test bằng pgTAP. Worker không nằm trên đường ghi, nên worker sập không ảnh hưởng sync.

## ADR-013: Một tài khoản chỉ hoạt động trên 1 thiết bị tại một thời điểm
**Bối cảnh.** Chủ dự án yêu cầu: đăng nhập ở thiết bị mới thì thiết bị cũ bị đăng xuất; lưu lịch sử đăng nhập (thiết bị, thời gian...).
Lý do: chống chia sẻ tài khoản Plus, người dùng biết ngay khi tài khoản bị dùng ở nơi khác, tránh nhắc kêu trùng trên nhiều máy.
JWT Supabase sống ~1 giờ, nên chỉ xóa phiên GoTrue thì thiết bị cũ vẫn đọc/ghi được tới khi token hết hạn.

**Phương án.** (a) Chỉ gọi admin API đăng xuất phiên cũ: còn cửa sổ tới 1 giờ, và token chưa hết hạn vẫn dùng được. (b) Kiểm phiên ở worker:
không phủ đường đọc PostgREST và `sync_push`. (c) Bảng `user_sessions` khóa theo claim `session_id` của JWT. RLS và mọi RPC chỉ chấp nhận
phiên `active`. Đăng nhập mới gọi `session_claim` để kết thúc phiên cũ.

**Quyết định.** (c). Số thiết bị cho phép là entitlement `max_active_devices` (Free 1, Plus 1, đổi được trong `plan_entitlements`, không hard-code).
Đồng hồ và widget đi theo điện thoại nên không tính là thiết bị. Phiên đã bị đá không tự claim lại được: người dùng phải đăng nhập lại để có `session_id` mới.
Lịch sử đăng nhập lưu ở cùng bảng: thiết bị, nền tảng, phiên bản, IP, quốc gia, thời điểm đăng nhập/hoạt động cuối/kết thúc, lý do kết thúc.
SQL: `supabase/migrations/20261124000006_single_device_sessions.sql`. Spec: `api-spec.md` §1.

**Sửa đổi 1 (24/11/2026, chủ dự án duyệt).** Plus đăng nhập đồng thời trên nhiều loại thiết bị: thêm entitlement `max_devices_per_class`
và cột `device_class` (`phone`|`tablet`|`computer`; web/desktop luôn là `computer`). Free 1 thiết bị; Plus tổng 3, mỗi loại 1. Khi vượt: giữ máy mới +
các máy hoạt động gần nhất, kết thúc phần còn lại. Hạ gói thì trigger trên `subscriptions` cắt về giới hạn mới (`end_reason='plan_limit'`).
SQL: `supabase/migrations/20261124000007_plus_multi_device.sql`.

**Hệ quả.** Free mất tính năng dùng song song điện thoại + tablet; đây là lý do nâng cấp Plus (paywall `paywall_devices`).
Loại thiết bị do app báo (trừ web/desktop), nên người dùng có thể khai tablet thành điện thoại: chấp nhận, giới hạn tổng vẫn giữ.
Plus "máy tính" cần web app hoặc desktop app, hiện ở Phase 4 (`plan/implementation-plan.md`).
Thiết bị bị đá có thể còn thay đổi chưa đồng bộ: giữ trong outbox, đẩy lên khi đăng nhập lại đúng tài khoản; tài khoản khác đăng nhập vào máy đó thì
cảnh báo trước khi xóa dữ liệu local (`uiux/ux-flows-and-screens.md` §3.7). Thiết bị offline vẫn có thể kêu nhắc đã lập lịch cho tới khi online lại.
IP là dữ liệu cá nhân: lưu 90 ngày, lịch sử 12 tháng (`security-privacy.md` §6).

## ADR-014: Một codebase Flutter cho mọi nền tảng, máy tính (macOS + Windows) ở Phase 4
**Bối cảnh.** Plus hứa đăng nhập trên điện thoại, tablet và máy tính (ADR-013). Chủ dự án chọn: paywall tạm ghi "máy tính: sắp có";
máy tính có thể là app PC/MacBook chứ không chỉ web. Cần quyết công nghệ từ bây giờ để sau này thêm desktop không phải viết lại.

**Phương án.** (a) Flutter desktop (macOS, Windows) cùng codebase với mobile. (b) Web app riêng (Next.js): phải viết lại UI và logic sync/NLU.
(c) Native riêng (SwiftUI, WinUI): chi phí x2, không dùng lại được Dart.

**Quyết định.** (a). Một project Flutter `apps/client` (Android, iOS, iPadOS lúc launch; thêm `macos`, `windows` ở Phase 4, web sau đó).
Logic nằm trong package Dart thuần, tính năng nền tảng sau interface + `PlatformCapabilities`, layout thích ứng từ S1 (`architecture/multi-platform.md` §2).
Paywall đọc remote config `desktop_client_available` để bỏ chữ "sắp có" khi phát hành.

**Hệ quả.** S1 tốn thêm ~2-3 ngày dựng cấu trúc package và layout thích ứng; đổi lại Phase 4 desktop ước ~5 tuần thay vì làm app mới.
Windows không có SDK RevenueCat nên không bán trong app Windows (mua trên điện thoại/web, quyền theo tài khoản). Windows không có FCM:
dùng Realtime khi app mở. Có thể cho app iPad chạy trên Mac Apple Silicon từ Phase 2 như bước đệm.

## ADR-015: Decoder T0 cho MIME, csv/xlsx, Markdown tự viết, không dùng `enough_mail`/`excel`/`csv`/`markdown`
**Bối cảnh.** `on-device-extraction.md` §13 dự kiến 4 package này. Decoder chạy trong isolate, phải Dart thuần (chạy cả desktop/web, ADR-014)
và mỗi package kéo thêm phụ thuộc bắc cầu (`enough_mail` kèm crypto, event bus, `intl`) trong khi app chỉ cần đọc, không gửi email hay ghi file.

**Quyết định.** Tự viết phần đọc trong `packages/parsers/lib/src/decoders/`: MIME (multipart lồng, base64, quoted-printable, RFC 2047/2231,
UTF-8/Latin-1/windows-1252), csv (RFC 4180, đoán dấu phân cách và mã hóa), xlsx (`archive` + `xml`, đã có trong lockfile), Markdown theo dòng
(checkbox, heading, Obsidian Tasks). Từ điển cột bảng nằm trong gói ngôn ngữ (`table:` của `nlu/packs/<lang>.yaml`).

**Hệ quả.** Không thêm phụ thuộc mới ngoài `xml`; phần đọc nằm trong tầm kiểm soát và có test riêng. Phải tự lo trường hợp hiếm:
charset cũ khác (windows-1258, Shift_JIS, GB2312) đang rơi về UTF-8 rồi windows-1252, công thức xlsx chỉ lấy giá trị đã lưu, Markdown không dựng cây CommonMark đầy đủ.
Nếu mẫu thật cho thấy lỗi nhiều ở các chỗ này thì xét lại từng package riêng.
