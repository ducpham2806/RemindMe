# Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ

> TL;DR: Thông báo được lập lịch local. iOS giới hạn 64 thông báo chờ, nên dùng *rolling window*.
> Android dùng exact alarm và phải chống OEM kill. Lặp lại theo RRULE + âm lịch. Đồng hồ nhận thông báo mirror
> có action, app watch riêng ở Phase 2.

## 1. Rolling window scheduler
Hàm trung tâm: `ReminderScheduler.reschedule()` (Dart), gọi khi: app mở, sau mỗi thay đổi item/reminder,
sau sync pull, khi nhận silent push, BGAppRefresh/WorkManager, `BOOT_COMPLETED`, `TIMEZONE_CHANGED`, `TIME_SET`,
**đổi ngôn ngữ app** (nội dung thông báo đã lập lịch là chuỗi đã dịch, nên phải lập lại) và đổi định dạng 12/24h.

```
1. occurrences = expand(all active reminders, from=now, to=now+HORIZON)   # HORIZON = 14 ngày
2. sort theo occurrence_at; lấy N đầu tiên                                # iOS N = 60 (chừa 4 slot), Android N = 500
3. diff với bảng scheduled_notifications:
     - cái thừa: cancel; cái thiếu: schedule; cái đổi giờ/nội dung: cancel + schedule
4. nếu bị cắt (còn occurrence sau N), chỉ iOS:
     - xin BGAppRefreshTask với earliestBeginDate = occurrence thứ N - 6h
     - server gửi silent push "reschedule" khi biết client sắp hết slot (dựa trên devices.last_seen_at)
     - dùng 1 trong 4 slot chừa lại cho thông báo dự phòng ngay sau occurrence thứ N:
       "Mở RemindMe để tiếp tục nhận nhắc nhở" (chỉ kêu nếu 2 cách trên đều thất bại)
   Android: giới hạn cao nên ít khi cắt, vẫn giữ HORIZON để giảm số alarm.
5. ghi telemetry: số đã lập lịch, occurrence xa nhất.
```
ID thông báo xác định (deterministic): `hash(reminder_id + occurrence_at)` để diff ổn định và tránh trùng.

**Code (S3):** `packages/data/lib/src/reminders/` (`planner.dart` hàm thuần + `expandOccurrences` dùng chung với màn Hôm nay;
`scheduler.dart` đọc DB, diff với `scheduled_notifications`; `actions.dart` nút Xong/Hoãn), `packages/core/lib/src/tz.dart` (giờ tường ↔ UTC).
App: `apps/client/lib/data/reminder_binding.dart` (lập lại khi DB đổi, app mở lại, đổi ngôn ngữ/12-24h; hỏi quyền 1 lần khi có nhắc đầu tiên),
`lib/platform/local_notifications.dart` (adapter `flutter_local_notifications`), `lib/platform/notification_background.dart` (nút bấm khi app tắt).
FNV-1a 32 bit, lấy 31 bit dương (Android dùng int32). Khóa của lần cả ngày là 00:00 theo múi giờ, giờ kêu là giờ mặc định của người dùng.

## 2. Android
| Việc | Cách làm |
|---|---|
| Exact alarm | Android 12+: `SCHEDULE_EXACT_ALARM` (người dùng cấp, mặc định bị từ chối từ Android 14 với app mới). Kiểm tra `canScheduleExactAlarms()`, nếu không có thì mở màn cài đặt với giải thích. Không dùng `USE_EXACT_ALARM` trừ khi Play chấp nhận app là "lịch/báo thức" (rủi ro review) |
| Nhắc quan trọng | `AlarmManager.setAlarmClock()` (hiện icon đồng hồ, miễn Doze). Thường: `setExactAndAllowWhileIdle()` |
| Kiểu báo thức (full-screen) | `USE_FULL_SCREEN_INTENT` từ Android 14 chỉ cho app báo thức/gọi điện; fallback: thông báo heads-up ưu tiên cao + âm thanh dài |
| Kênh thông báo | `reminders_default`, `reminders_alarm`, `travel` (gần giờ bay), `digest`, `sync_silent` |
| Khởi động lại | `RECEIVE_BOOT_COMPLETED` → `reschedule()`; cũng nghe `TIMEZONE_CHANGED`, `TIME_SET`, `MY_PACKAGE_REPLACED` |
| OEM kill | Phát hiện hãng (`Build.MANUFACTURER`), onboarding hướng dẫn tắt tối ưu pin/tự khởi động cho Xiaomi/Redmi, Oppo/Realme, Vivo, Samsung, Huawei (tham khảo dontkillmyapp.com). Telemetry `late_fire_ms` theo OEM |
| Quyền thông báo | Android 13+: `POST_NOTIFICATIONS` runtime, hỏi sau khi người dùng tạo nhắc đầu tiên (priming screen) |

Plugin: `flutter_local_notifications` + method channel riêng cho `setAlarmClock` và kiểm tra exact alarm.

## 3. iOS
| Việc | Cách làm |
|---|---|
| Giới hạn | Tối đa 64 thông báo local chờ mỗi app, nên dùng rolling window ở mục 1 |
| Mức gián đoạn | `.timeSensitive` cho nhắc quan trọng/chuyến đi (cần capability Time Sensitive Notifications); `.active` mặc định |
| Critical alert | Chỉ khi Apple cấp entitlement (cân nhắc cho nhắc uống thuốc). Không phụ thuộc vào nó |
| Action | `UNNotificationCategory` với Done/Snooze 10'/Snooze 1h/Open; xử lý trong `didReceive` khi background |
| Live Activities | Phase 3 (cùng trạng thái chuyến bay): đếm ngược tới giờ bay/check-in trên Lock Screen và Dynamic Island (ActivityKit, cập nhật qua push) |
| Nạp lại | `BGAppRefreshTask` + silent push (`content-available: 1`, không đảm bảo, chỉ là lưới an toàn) |

## 4. Lặp lại (recurrence)
- Thư viện: Dart `rrule` (pub.dev) trong app, bọc trong `packages/core/lib/src/recurrence.dart` (tính trên giờ tường `CivilDateTime`, đổi UTC theo tz ở tầng nhắc); TS `rrule` (npm) trong worker chỉ để xuất ICS/Google Calendar. Fixtures chung `packages/parsers/fixtures/recurrence/` (chưa tạo: làm khi có worker).
- Mẫu UI: hằng ngày, các ngày trong tuần, mỗi N ngày/tuần/tháng, ngày X hằng tháng, thứ N cuối tháng, hằng năm,
  **ngày làm việc** (cuối tuần + ngày lễ của `workdays_region`, `i18n-l10n.md` §5),
  **sau khi hoàn thành N ngày** (`kind = 'after_completion'`, `interval_days = N`: không phải RRULE).
- **Hệ lịch khác** (`kind = 'calendar'`, ADR-007): âm lịch VN/TQ/HQ (thuật toán âm dương, tham số UTC+7/+8/+9), Hijri (Phase 2).
  Code: `packages/core/lib/src/lunar.dart` (thuật toán Hồ Ngọc Đức). Tháng nhuận: `leap: 'skip'` (mặc định, không kêu trong tháng nhuận) | `'both'` (kêu cả tháng thường và tháng nhuận).
  Ngày 30 ở tháng thiếu (29 ngày) kêu ngày 29. Lịch hiển thị ngày phụ dưới ngày dương khi người dùng bật hệ lịch đó.
- Ngoại lệ: `exdates` cho "bỏ qua lần này"; sửa "chỉ lần này" thì tạo item con với `source_ref = <series_id>:<occurrence>`.
- Hoàn thành 1 lần của chuỗi: ghi `occurrence_log` (không đóng cả chuỗi).
- Màn Hôm nay hiện **từng lần** của chuỗi rơi vào ngày đó; lần của ngày trước bị bỏ lỡ không dồn vào Quá hạn (tránh chuỗi hằng ngày chất đống).

## 5. Múi giờ, DST và du lịch (nguồn chuẩn cho quy tắc thời gian)
**Cố định hay trôi theo giờ địa phương** (`items.time_mode`):
| Loại | Mặc định | Ý nghĩa |
|---|---|---|
| `habit`, task lặp ("8h sáng mỗi ngày") | `floating` | Kêu 08:00 theo múi giờ nơi người dùng đang đứng, kể cả khi đi du lịch |
| `event`, `appointment`, `booking` | `fixed` | Gắn với `tz` của sự kiện; hiển thị cả giờ địa phương sự kiện và giờ hiện tại của người dùng nếu khác |
| Item cả ngày, khách sạn chỉ có ngày | (dùng `start_date`/`end_date`) | Không có giờ, nhắc theo giờ mặc định của người dùng (ví dụ 09:00) tại múi giờ đang đứng |

**DST** (Việt Nam không có DST, thị trường global thì có):
- Giờ **không tồn tại** (ngày chuyển sang giờ mùa hè, ví dụ 02:30): kêu ở thời điểm hợp lệ kế tiếp (03:00), hiện ghi chú trong item.
- Giờ **lặp 2 lần** (ngày lùi giờ, 01:30 hai lần): kêu ở lần đầu, không kêu lần hai.
- Chuỗi lặp giữ **giờ địa phương** qua DST (theo `tz` của chuỗi hoặc tz hiện tại nếu `floating`), không giữ khoảng 24h tuyệt đối.
- tzdata: lập lịch bằng tz của OS; tính toán trong Dart bằng package `timezone`, cập nhật tzdata mỗi bản phát hành.
- Đổi `home_tz` (chuyển nơi ở): chỉ ảnh hưởng item tạo sau đó và cách đếm quota/ngày; không dời item `fixed` đã có.
- Test bắt buộc: `America/New_York`, `Europe/London`, `Australia/Sydney` (DST ngược mùa), `Asia/Kolkata` (+5:30), `Asia/Kathmandu` (+5:45),
  `Pacific/Chatham` (+12:45), `Asia/Ho_Chi_Minh`, và một ngày chuyển DST của mỗi vùng có DST.

**Chuyến bay**: `starts_at` theo giờ địa phương sân bay đi (`origin.tz`), `ends_at` theo `destination.tz`; hiển thị cả 2.
Bảng IATA → tz: toàn bộ dữ liệu mở OurAirports, đóng gói vào app.

**Nhắc mặc định khi tạo booking** (người dùng sửa được; mỗi cái tính vào quota nhắc/ngày; có thể khác nhau theo thị trường qua gói dữ liệu):
| Loại | Nhắc mặc định |
|---|---|
| Bay nội địa | 24h trước (check-in online), 3h trước, 2h trước "ra sân bay" |
| Bay quốc tế | 24h, 4h, 3h trước |
| Tàu/xe | 2h trước, 30' trước |
| Khách sạn | 18:00 hôm trước check-in, 1h trước giờ check-out |
| Khám bệnh | 1 ngày trước (nhắc mang giấy tờ/nhịn ăn nếu có trong ghi chú), 1h trước |
| Việc/sự kiện có giờ hoặc ngày tạo từ Quick Add | Đúng giờ (chip 🔔 trong UX §2.2), sửa ở màn chi tiết; mốc có sẵn: đúng giờ, 10', 30', 1h, 1 ngày trước |

## 6. Đồng hồ thông minh
| Giai đoạn | Apple Watch | Wear OS | Đồng hồ khác (Xiaomi, Huawei, Garmin, Samsung Tizen cũ) |
|---|---|---|---|
| Phase 1 | Thông báo iPhone tự mirror; action category hiện trên watch | Thông báo bridge tự động; thêm `WearableExtender` action | Mirror qua app của hãng; chỉ hiện text, nên tiêu đề phải ngắn, rõ, chứa giờ |
| Phase 2 | App SwiftUI: danh sách Hôm nay, chuyến sắp tới, complication (WidgetKit), thêm nhanh bằng giọng nói; WatchConnectivity `transferUserInfo` | App Compose + Tile "Hôm nay" + Complication; Data Layer `DataClient` | (không có) |

Quy tắc nội dung thông báo (watch hiển thị ít): giờ theo định dạng vùng + tiêu đề, dòng 2 là ngữ cảnh. Chuỗi lấy từ ARB với giới hạn độ dài
(`i18n-l10n.md` §7), dịch theo ngôn ngữ app **tại thời điểm lập lịch**.
Ví dụ: vi `⏰ 08:00 Uống thuốc huyết áp` / `Còn 2 lần hôm nay`; en-US `⏰ 8:00 AM Take blood pressure pill` / `2 more today`.
Chuyến bay: `✈ VN245 SGN→HAN 10:30 · Gate 12`, action "Mở vé"/"Open ticket".

## 7. Telemetry
Tên event và thuộc tính: `docs/product/analytics-events.md` (nhóm "reminder"). Độ trễ kêu đo bằng `late_ms = fired_at - due_at`.
Dashboard theo OEM, phiên bản OS, quốc gia.

## 8. Nhiều thiết bị
- **Free: 1 thiết bị; Plus: 1 điện thoại + 1 tablet + 1 máy tính cùng lúc** (ADR-013, `max_active_devices`, `max_devices_per_class`). Khi bị đăng xuất vì máy khác đăng nhập
  (push `session.revoked` hoặc lỗi `session_revoked` khi sync), app **hủy toàn bộ thông báo đã lập lịch** và xóa `scheduled_notifications`.
  Máy mới lập lịch ngay sau lần `sync_pull` đầu. Máy cũ đang offline có thể kêu tiếp các nhắc đã lập lịch cho tới khi online lại.
- Các quy tắc dưới đây áp dụng cho Plus nhiều thiết bị và cho dữ liệu sửa offline trước khi bị đá. Máy tính (web/desktop, Phase 4) dùng thông báo trình duyệt/OS,
  mặc định không nhận nhắc (`receives_reminders = false`) để tránh kêu 3 nơi.
- Mỗi điện thoại/tablet tự lập lịch local. Mặc định mọi thiết bị có `devices.receives_reminders = true` đều kêu; người dùng có thể chọn
  "Chỉ thiết bị chính" trong Cài đặt.
- Watch không lập lịch riêng ở Phase 1-2: nhận mirror từ điện thoại ghép đôi, tránh kêu 2 lần.
- Bấm **Xong/Hoãn** trên 1 thiết bị: ghi outbox → `sync_push` → server gửi `sync.tickle` → thiết bị khác pull và hủy/dời thông báo.
  Nếu thiết bị khác offline, nó có thể kêu một lần thừa; khi online lại sẽ tự dọn.
- Client báo `scheduled_until` qua `PUT /v1/devices/{id}` để server biết khi nào gửi push `reschedule` (iOS rolling window, §1).
