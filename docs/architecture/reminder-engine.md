# Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ

> TL;DR: Thông báo được lập lịch local. iOS giới hạn 64 thông báo chờ, nên dùng *rolling window*.
> Android dùng exact alarm và phải chống OEM kill. Lặp lại theo RRULE + âm lịch. Đồng hồ nhận thông báo mirror
> có action, app watch riêng ở Phase 2.

## 1. Rolling window scheduler
Hàm trung tâm: `ReminderScheduler.reschedule()` (Dart), gọi khi: app mở, sau mỗi thay đổi item/reminder,
sau sync pull, khi nhận silent push, BGAppRefresh/WorkManager, `BOOT_COMPLETED`, `TIMEZONE_CHANGED`, `TIME_SET`.

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
| Live Activities | Phase 2: đếm ngược tới giờ bay/check-in trên Lock Screen và Dynamic Island (ActivityKit, cập nhật qua push) |
| Nạp lại | `BGAppRefreshTask` + silent push (`content-available: 1`, không đảm bảo, chỉ là lưới an toàn) |

## 4. Lặp lại (recurrence)
- Thư viện: Dart `rrule` (pub.dev), TS `rrule` (npm). Test fixtures chung `packages/parsers/fixtures/rrule/*.json`.
- Mẫu UI cần hỗ trợ: hằng ngày, các ngày trong tuần, mỗi N ngày/tuần/tháng, ngày X hằng tháng, thứ N cuối tháng,
  hằng năm, ngày làm việc, **sau khi hoàn thành N ngày** (kiểu "tưới cây 3 ngày sau lần tưới trước": không phải RRULE,
  lưu `rrule = null`, `lunar = null`, `settings.after_completion_days`).
- **Âm lịch**: rằm (15), mùng 1, giỗ (ngày/tháng âm), Tết. Thuật toán Hồ Ngọc Đức (tính theo UTC+7). Tháng nhuận:
  `leap: 'skip' | 'both' | 'first'`. Hiển thị ngày âm dưới ngày dương trong lịch (bật/tắt).
- Ngoại lệ: `exdates` cho "bỏ qua lần này"; sửa "chỉ lần này" thì tạo item con với `source_ref = <series_id>:<occurrence>`.
- Hoàn thành 1 lần của chuỗi: lưu vào `occurrence_log(item_id, occurrence_at, status)` (không đóng cả chuỗi).

## 5. Múi giờ và du lịch
- Item thường: lưu `starts_at` UTC + `tz` = `home_tz` lúc tạo. Nhắc "8h sáng mỗi ngày" kiểu *floating*
  (theo giờ nơi đang đứng) bật mặc định cho habit, tắt cho appointment.
- Chuyến bay: `starts_at` tính từ giờ địa phương sân bay đi (`origin.tz`), `ends_at` theo `destination.tz`.
  Hiển thị cả 2 giờ địa phương. Bảng IATA → tz lấy từ dữ liệu mở OurAirports (đóng gói vào app + worker).
- Nhắc mặc định khi tạo booking (người dùng sửa được, mỗi cái tính vào quota nhắc/ngày):
  | Loại | Nhắc mặc định |
  |---|---|
  | Bay nội địa | 24h trước (check-in online), 3h trước, 2h trước "ra sân bay" |
  | Bay quốc tế | 24h, 4h, 3h trước |
  | Tàu/xe | 2h trước, 30' trước |
  | Khách sạn | 18:00 hôm trước check-in, 1h trước giờ check-out |
  | Khám bệnh | 1 ngày trước (nhắc mang giấy tờ/nhịn ăn nếu có trong ghi chú), 1h trước |

## 6. Đồng hồ thông minh
| Giai đoạn | Apple Watch | Wear OS | Đồng hồ khác (Xiaomi, Huawei, Garmin, Samsung Tizen cũ) |
|---|---|---|---|
| Phase 1 | Thông báo iPhone tự mirror; action category hiện trên watch | Thông báo bridge tự động; thêm `WearableExtender` action | Mirror qua app của hãng; chỉ hiện text, nên tiêu đề phải ngắn, rõ, chứa giờ |
| Phase 2 | App SwiftUI: danh sách Hôm nay, chuyến sắp tới, complication (WidgetKit), thêm nhanh bằng giọng nói; WatchConnectivity `transferUserInfo` | App Compose + Tile "Hôm nay" + Complication; Data Layer `DataClient` | (không có) |
| Phase 3 | Thông báo trực tiếp trên watch độc lập (LTE) qua server push | Tương tự | (không có) |

Quy tắc nội dung thông báo (vì watch hiển thị ít): `[⏰ 08:00] Uống thuốc huyết áp`, dòng 2 là ngữ cảnh ("Còn 2 lần hôm nay").
Chuyến bay: `✈ VN245 SGN→HAN 10:30, cổng 12`, action "Mở vé".

## 7. Telemetry bắt buộc
`notification_scheduled`, `notification_fired` (late_ms), `notification_action` (done/snooze/open), `reschedule_run`
(count, horizon_end, truncated), `exact_alarm_permission` (granted/denied), `oem`. Dashboard theo OEM và phiên bản OS.
