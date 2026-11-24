# Đa nền tảng: điện thoại, tablet, máy tính (macOS, Windows), web

> TL;DR: Một codebase Flutter `apps/client` cho mọi nền tảng (ADR-014). Launch: Android, iOS, iPadOS. Máy tính (macOS + Windows) làm ở Phase 4,
> paywall Plus ghi "máy tính: sắp có" tới lúc đó. Để nâng cấp rẻ, **từ S1** phải tuân 6 quy tắc ở §2: logic trong package Dart thuần,
> tính năng nền tảng sau interface + `PlatformCapabilities`, layout thích ứng, plugin chọn theo bảng §3.

## 1. Lộ trình
| Giai đoạn | Nền tảng | Ghi chú |
|---|---|---|
| Phase 1 (launch) | Android phone/tablet, iOS, iPadOS | Layout tablet có từ đầu (Plus tính tablet là 1 loại thiết bị) |
| Phase 2 (tùy chọn, ~1 ngày) | App iPad chạy trên Mac Apple Silicon | Apple cho chạy app iPad trên Mac nếu không tắt trong App Store Connect. App phải báo `platform='macos'` (kiểm `isiOSAppOnMac`) để tính là `computer`. Chỉ bật sau khi test |
| Phase 4 | macOS, Windows (Flutter desktop) | Kế hoạch D trong `plan/implementation-plan.md` |
| Phase 4+ | Web (Flutter web, đọc/sửa) | Không lập lịch thông báo trên trình duyệt |
Paywall và store listing đọc remote config `desktop_client_available` (mặc định `false`) để đổi chữ "sắp có" thành link tải, không cần phát hành app.

## 2. Quy tắc code từ S1 (để thêm desktop không phải viết lại)
1. **Logic không phụ thuộc Flutter/nền tảng** nằm trong package Dart thuần: `packages/core` (model, thời gian/DST, recurrence, hệ lịch),
   `packages/parsers` (decoder, luật, NLU), `packages/data` (Drift schema, outbox, sync engine, entitlement cache). Các package này không import `dart:ui`, plugin hay `dart:io Platform`.
2. **Tính năng nền tảng sau interface**: `NotificationScheduler`, `OcrEngine`, `SttEngine`, `BarcodeScanner`, `PurchaseService`, `ShareInbox`, `CalendarWriter`,
   `PushChannel`. Mỗi interface có bản cho từng nền tảng (federated plugin hoặc lớp adapter), inject qua Riverpod.
3. **`PlatformCapabilities`** (provider): `canPurchaseInApp`, `hasExactAlarms`, `hasPush`, `hasOcr`, `hasOnDeviceStt`, `hasShareExtension`, `hasWidgets`, `hasWatch`.
   UI ẩn/hiện tính năng theo capability, **không** rải `Platform.isIOS` trong UI. Chỉ `packages/platform/**` và `apps/*/lib/platform/**` được dò nền tảng;
   package Dart thuần không import Flutter (`tools/lint-platform-checks.py`, chạy trong CI).
4. **Layout thích ứng** theo window size class của Material 3: compact < 600 dp, medium 600-839, expanded ≥ 840. Medium/expanded dùng master-detail
   (danh sách + chi tiết), lịch tuần rộng. Mọi màn chạy được với chuột, bàn phím (Tab, Enter, Esc, phím tắt), hover, menu chuột phải, cửa sổ đổi kích thước.
   Golden test chạy ở 3 kích thước.
5. **Định danh thiết bị**: `device_id` sinh 1 lần mỗi lần cài, lưu secure storage; app báo `platform` + `device_class` cho `session_claim` (ADR-013).
6. **Thêm plugin**: kiểm cột nền tảng trên pub.dev và ghi vào bảng §3 trong cùng PR. Plugin chỉ có mobile thì phải nằm sau interface ở mục 2.

## 3. Ma trận năng lực theo nền tảng
| Năng lực | Android / iOS / iPadOS | macOS | Windows | Web |
|---|---|---|---|---|
| DB local, sync, auth | Drift (sqlite3), `supabase_flutter` | Như mobile | Như mobile | Drift wasm (thử nghiệm) |
| Đăng nhập | Google, Apple, email OTP | Như mobile; OAuth qua trình duyệt + URL scheme | Email OTP ưu tiên; OAuth qua trình duyệt + protocol MSIX | Như web |
| Nhắc local | `flutter_local_notifications` (AlarmManager / UNNotification) | Có (UNUserNotification) | Có từ 19.5 ([changelog](https://pub.dev/packages/flutter_local_notifications/changelog)); không có lặp sẵn, nhưng rolling window đã lập lịch từng lần; **cần test giờ kêu trên máy thật** | Không lập lịch được |
| Push | FCM / APNs | APNs qua FCM | Không có FCM: sync khi mở app + Realtime; WNS để sau | FCM web |
| OCR | ML Kit / Vision | Vision (dùng chung code Swift với iOS) | `Windows.Media.Ocr` (cần package identity → phát hành MSIX, ngôn ngữ theo language pack cài trên máy, [docs](https://learn.microsoft.com/uwp/api/windows.media.ocr.ocrengine)); thiếu ngôn ngữ thì PP-OCRv5 qua `onnxruntime` | Không (chỉ PDF có text) |
| PDF, xlsx, md, ics, pkpass, email | Dart thuần | Như mobile | Như mobile | Như mobile |
| Giọng nói | STT của OS | SFSpeechRecognizer / SpeechAnalyzer | STT của Windows ít ngôn ngữ: dùng whisper.cpp (máy tính đủ mạnh) | Web Speech API (online) |
| Mua Plus | `purchases_flutter` | `purchases_flutter` hỗ trợ macOS, paywall tự vẽ (`purchases_ui_flutter` chưa có macOS) ([RevenueCat](https://www.revenuecat.com/docs/flutter)) | **Không** có SDK RevenueCat ([forum](https://community.revenuecat.com/sdks-51/revenuecat-flutter-sdk-support-for-windows-and-linux-5081)): chỉ hiện trạng thái gói, mua trên điện thoại hoặc web (RevenueCat Web Billing) | RevenueCat Web Billing / Stripe |
| Nhập file | Share extension, chọn file | Kéo thả vào cửa sổ, "Mở bằng", chọn file | Như macOS | Kéo thả, chọn file |
| Widget, đồng hồ | Có (Phase 2) | Widget macOS (WidgetKit) để sau | Không | Không |
| Ghi vào lịch máy | EventKit / CalendarContract | EventKit | Xuất `.ics` | Xuất `.ics` |
Máy tính mặc định `receives_reminders = false` (tránh kêu 3 nơi), người dùng bật được (`reminder-engine.md` §8).

## 4. Phát hành máy tính
- macOS: Mac App Store (sandbox, StoreKit qua RevenueCat, cùng subscription group với iOS nếu dùng universal purchase), hoặc DMG notarized nếu không bán trong app.
- Windows: Microsoft Store (MSIX, có package identity cho OCR và thông báo) + winget. Không bán trong app ở bản đầu (xem §3).
  Chính sách thanh toán của Microsoft Store với app không phải game: chưa xác minh, kiểm trước Phase 4.
- Version, changelog, CI: như mobile (`engineering/testing-and-release.md`); thêm job build macOS/Windows chạy hằng tuần từ khi bắt đầu Phase 4, chạy theo PR trong Phase 4.
