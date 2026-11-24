# Hướng dẫn tích hợp với nền tảng khác

> TL;DR: Thứ tự ưu tiên: (1) Thông báo FCM/APNs + local, (2) Thanh toán RevenueCat/App Store/Play,
> (3) Đăng nhập Google/Apple, (4) Email forward + ICS + share sheet, (5) Google Calendar 2 chiều,
> (6) Watch, (7) Notion/Microsoft, (8) Gmail API (cần CASA). Mỗi mục: mục đích, phase, các bước, bẫy thường gặp.
> Bảng "việc cần làm sớm vì phải chờ duyệt" ở mục 0.

## 0. Việc phải khởi động sớm (thời gian chờ dài)
| Việc | Chờ bao lâu (ước lượng, cần kiểm chứng) | Khi nào bắt đầu |
|---|---|---|
| Apple Developer Program (tổ chức, cần D-U-N-S) | 1-4 tuần | Ngay Phase 0 |
| Google Play Console (tài khoản tổ chức, xác minh danh tính) | Vài ngày - 2 tuần; tài khoản cá nhân mới phải test kín với ≥ 12 tester trong 14 ngày trước khi lên production | Ngay Phase 0 |
| Google OAuth verification (scope sensitive: Calendar) | 2-6 tuần | Khi có Privacy Policy + domain + video demo, Phase 1 |
| Google CASA cho scope restricted (Gmail), nếu Google yêu cầu với cách xử lý trên máy | 1-3 tháng, phí đánh giá hằng năm | Phase 3, chỉ khi số liệu chứng minh cần |
| Apple Critical Alerts entitlement | Không chắc được cấp | Phase 2, với tính năng nhắc thuốc |
| Đăng ký tên miền, email `in.remindme.app` (MX) | 1 ngày | Phase 0 |
| Bán qua web (nếu làm): Merchant of Record (VAT/GST global); riêng VN: thông báo website TMĐT với Bộ Công Thương | Vài tuần | Trước khi bán gói ngoài store |
| Hồ sơ thuế/ngân hàng trên App Store Connect và Play cho mọi storefront phát hành | 1-2 tuần | Phase 0 |
| Pháp lý theo thị trường (`security-privacy.md` §4), đại diện EU nếu cần | 2-6 tuần | Phase 0-1 |

## 1. Thông báo đẩy: FCM + APNs (Phase 1)
1. Tạo project Firebase (staging, prod). Thêm app Android (`app.remindme`) và iOS.
2. iOS: tạo APNs Auth Key (.p8) trong Apple Developer → upload lên Firebase. Bật capability Push Notifications,
   Background Modes (remote notifications, background fetch), Time Sensitive Notifications.
3. Flutter: `firebase_messaging`, `flutter_local_notifications`. Đăng ký token → `PUT /v1/devices/{id}`.
4. Worker gửi bằng FCM HTTP v1 (service account). Silent push iOS: `apns-push-type: background`, `apns-priority: 5`,
   `content-available: 1`. Không lạm dụng (iOS throttle).
5. Bẫy: token đổi khi cài lại app; xử lý `onTokenRefresh`. Android 13+ cần xin `POST_NOTIFICATIONS`.

## 2. Thanh toán (Phase 1)
**Sản phẩm trên store** (cùng 1 subscription group / base plan):
| ID | Kỳ | Ghi chú |
|---|---|---|
| `remindme_plus_monthly` | 1 tháng | |
| `remindme_plus_quarterly` | 3 tháng | App Store và Play đều hỗ trợ kỳ 3 tháng |
| `remindme_plus_yearly` | 1 năm | |
Giá, trial, khuyến mãi theo thị trường: `docs/product/pricing-entitlements.md` §1 (nguồn chuẩn).

Các bước:
1. App Store Connect: tạo Subscription Group "RemindMe Plus", 3 sản phẩm, giá gốc USD + ghi đè theo storefront
   (bảng giá đề xuất: `docs/product/pricing-entitlements.md`). Điền thông tin ngân hàng, thuế.
2. Play Console: 1 subscription `remindme_plus` với 3 base plan (P1M, P3M, P1Y), offer trial.
3. RevenueCat: tạo project, nối App Store (App Store Connect API key + In-App Purchase key) và Play (service account
   có quyền financial). Entitlement `plus`. Offering `default` gồm 3 package.
4. App: `purchases_flutter`. `Purchases.logIn(supabaseUserId)` sau đăng nhập để gắn giao dịch vào user.
5. Webhook RevenueCat → `/hooks/revenuecat` → cập nhật `subscriptions` → entitlements. Không tin client.
6. Test: StoreKit Configuration file + Sandbox tester; Play license testers. Kiểm tra: mua, gia hạn, hủy, hoàn tiền,
   grace period, billing retry, đổi kỳ (monthly → yearly), khôi phục giao dịch (nút "Khôi phục mua hàng" bắt buộc).
7. Bẫy: Apple yêu cầu hiển thị rõ giá, kỳ, cách hủy trên paywall; link Terms + Privacy. Không dẫn người dùng iOS
   sang thanh toán ngoài (ví dụ ví điện tử địa phương như MoMo/VNPay ở VN, Pix ở BR, UPI ở IN) trong app nếu quy định của Apple tại VN không cho phép (kiểm tra App Review Guidelines 3.1 tại thời điểm làm).
   Web checkout (Merchant of Record + phương thức địa phương) dùng cho người mua trên web; entitlement vẫn đồng bộ qua RevenueCat (Web Billing / API).
   Quy định thanh toán ngoài khác nhau theo khu vực (EU DMA, US, KR, JP...): kiểm tra theo từng storefront tại thời điểm làm.

## 3. Đăng nhập (Phase 1)
- Supabase Auth: Google (native `google_sign_in` → `signInWithIdToken`), Sign in with Apple (bắt buộc trên iOS nếu có đăng nhập
  mạng xã hội), Email OTP (email dịch theo ngôn ngữ người dùng). Tùy thị trường có thể thêm: Zalo (VN), LINE (JP/TH/TW), Kakao (KR).
- Cho phép dùng thử không cần tài khoản (anonymous sign-in của Supabase), liên kết tài khoản sau; quy tắc gộp dữ liệu: `system-architecture.md` §4.
- Xóa tài khoản trong app (yêu cầu của Apple và Google Play).

## 4. Đầu vào và đầu ra không cần OAuth (share sheet, email, lịch máy: Phase 1; feed ICS: Phase 2)
### 4.1 Share sheet / share intent
- iOS Share Extension (Swift) nhận ảnh, PDF, text, URL, `.pkpass`, `.ics` → lưu vào App Group container → app chính xử lý trên máy (`on-device-extraction.md`).
- Android: `intent-filter` `ACTION_SEND`/`ACTION_SEND_MULTIPLE` cho `image/*`, `application/pdf`, `text/*`,
  `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`. Plugin `receive_sharing_intent`.
- Đây là đường nhập chính cho ảnh chụp màn hình booking, email trong app Mail, file từ ứng dụng nhắn tin (WhatsApp, Zalo, LINE...).

### 4.2 Email forward
1. Domain `in.remindme.app`: MX trỏ về Postmark Inbound hoặc Cloudflare Email Routing + Email Worker.
2. Địa chỉ mỗi user: `u-<token>@in.remindme.app` (token 10 ký tự ngẫu nhiên, đổi được). Cho phép thêm alias email gốc của user
   để email từ địa chỉ đó gửi tới `trips@in.remindme.app` cũng khớp được (kiểm tra SPF/DKIM để chống giả mạo).
3. Luồng xử lý và giới hạn: `on-device-extraction.md` §8 (nguồn chuẩn).
4. Hướng dẫn trong app: tạo filter Gmail/Outlook tự động forward, với từ khóa lấy từ gói ngôn ngữ của người dùng
   (vi "đặt chỗ", "xác nhận đặt phòng"; en "booking confirmation", "e-ticket"; de "Buchungsbestätigung"...).
   Gmail cần xác minh địa chỉ forward: worker tự bấm link xác minh của Google gửi tới.
5. Bẫy: chống spam/loop; người lạ gửi vào địa chỉ token thì vẫn nhận nhưng chỉ tạo đề xuất.

### 4.3 Feed ICS (xuất ra mọi lịch, Phase 2, Plus)
`webcal://api.remindme.app/ics/<token>.ics`: Apple Calendar, Google Calendar, Outlook đều subscribe được.
Google Calendar refresh feed chậm (có thể vài giờ đến 1 ngày), ghi rõ trong UI. Đây là cách rẻ để có "đồng bộ 1 chiều" trước khi làm 2 chiều.

### 4.4 Lịch trên thiết bị (Phase 1, S6)
- iOS EventKit (`device_calendar` plugin): đọc/ghi Calendar và Reminders của Apple (cần quyền full access iOS 17+).
- Android `CalendarContract` qua cùng plugin. Cho phép "Thêm vào lịch máy" từng item hoặc tự động cho booking.

## 5. Google Calendar 2 chiều (Phase 2)
1. Google Cloud project, bật Calendar API, OAuth consent screen (External), scope `https://www.googleapis.com/auth/calendar.events`
   (hoặc `calendar.app.created` nếu chỉ ghi vào lịch riêng do app tạo, ít nhạy cảm hơn: kiểm tra scope có sẵn tại thời điểm làm).
2. Nộp verification (domain, privacy policy, video demo luồng OAuth).
3. Đồng bộ: tạo lịch riêng "RemindMe" trên Google; dùng `syncToken` cho incremental sync; push channel `events.watch`
   (hết hạn tối đa ~7 ngày, job gia hạn); mapping `items.source_ref = gcal:<calendarId>:<eventId>`.
4. Xung đột: Google thắng với trường thời gian nếu `updated` mới hơn; RemindMe giữ reminder riêng (Google reminder chỉ là popup/email).
5. Hệ lịch khác (âm lịch, Hijri): trải phẳng 24 tháng tới (ADR-007).

## 6. Gmail API (Phase 3, tùy số liệu, chạy trên máy)
- OAuth trên thiết bị (scope `gmail.readonly`, restricted), token chỉ nằm trong Keychain/Keystore. Không có Pub/Sub về server:
  máy tự gọi `users.messages.list` với query theo gói ngôn ngữ (ví dụ `newer_than:30d (booking OR reservation OR itinerary OR "đặt chỗ")`)
  khi mở app và khi background fetch, xử lý trên máy, kết quả vào "Hộp đề xuất".
- Hỏi Google xem cách xử lý chỉ trên máy có cần CASA không (ADR-005).
- Chỉ bật cho gói trả phí; ghi rõ dữ liệu nào được đọc. Nếu chi phí CASA không xứng đáng: giữ email forward.

## 7. Hệ thống ghi chú
| Nền tảng | Có API công khai? | Cách tích hợp | Phase |
|---|---|---|---|
| Notion | Có (OAuth public integration) | Chọn database → map cột (Title, Date, Status) ↔ item; sync 2 chiều theo `last_edited_time`, polling 10'; webhook Notion nếu đã GA | 2 |
| Microsoft To Do | Có (Microsoft Graph `Tasks.Read`) | **Import 1 lần, ưu tiên cao**: app To Do ngừng 30/06/2027 (thông báo 11/2026), API ngừng muộn hơn (chưa có ngày). Nhập list, task, hạn, nhắc, lặp, bước con. Cũng nhận file export chính thức khi Microsoft công bố định dạng | **1** (phải có trước 03/2027) |
| Outlook Calendar / OneNote | Có (Graph `Calendars.ReadWrite`, `Notes.Read`) | Sync lịch; OneNote chỉ import | 3 |
| Google Keep | Keep API chỉ dành cho Google Workspace (doanh nghiệp), không dùng được cho tài khoản cá nhân | Share sheet từ Keep sang app | 1 |
| Google Tasks | Có (scope `tasks`) | Import/sync 2 chiều task (không có giờ, chỉ ngày) | 2 |
| Apple Notes | Không có API | Share sheet; Apple Reminders qua EventKit | 1 |
| Obsidian / Logseq | File markdown | Import `.md` (cú pháp Obsidian Tasks), xuất `.md` | 1 |
| Evernote | API có nhưng hạn chế cấp key mới | Import file `.enex` | 3 |
| Todoist / TickTick | Todoist có REST API; TickTick có Open API | Công cụ "Chuyển nhà" import 1 lần để kéo người dùng đối thủ | 2 |

## 8. Đồng hồ (Phase 1 mirror, Phase 2 app riêng)
- **watchOS**: target WatchKit App (SwiftUI) trong project iOS của Flutter (`ios/`), cùng App Group.
  WatchConnectivity: điện thoại gửi snapshot "Hôm nay + 7 ngày" qua `updateApplicationContext` (JSON ≤ 64 KB),
  watch gửi action qua `sendMessage`/`transferUserInfo`. Complication bằng WidgetKit. Siri/App Intents: "Thêm nhắc nhở RemindMe".
- **Wear OS**: module `wear/` Kotlin + Compose for Wear OS, Tiles API (Hôm nay), Complications API.
  Data Layer `DataClient.putDataItem("/today")` từ app Android (method channel từ Flutter).
  Cùng `applicationId` và chữ ký với app điện thoại để Data Layer hoạt động.
- **Đồng hồ khác** (Mi Band, Huawei, Garmin, Amazfit, phổ biến ở VN): chỉ nhận thông báo mirror. Tối ưu tiêu đề ngắn.
- Bẫy: thông báo đã có app watch riêng thì tránh hiện 2 lần (dùng `setLocalOnly`/bridging tag trên Android).

## 9. Widget, Siri, Google Assistant (Phase 2)
- iOS WidgetKit (Hôm nay, Chuyến đi tới), interactive widget (iOS 17+) để tick Done. App Intents cho Siri & Shortcuts.
- Android Glance widget; App Actions/shortcuts cho Google Assistant (`CREATE_THING`/`GET_THING` built-in intents nếu còn được hỗ trợ; kiểm tra lại).

## 10. Dịch vụ du lịch bổ trợ (Phase 3, gói trả phí)
- Trạng thái chuyến bay (trễ, đổi cổng): AeroAPI (FlightAware), Aviationstack, OAG, Cirium: so sánh giá và độ phủ ở các thị trường đợt 1 trước khi chọn.
  Job theo dõi từ T-24h đến khi hạ cánh, push `trip.update`, cập nhật Live Activity.
- Bản đồ: deep link Google Maps / Apple Maps; nút gọi xe bằng deep link theo thị trường (Uber, Lyft, Bolt, Grab, Gojek, DiDi, 99; VN thêm Be, Xanh SM).
- Thời tiết điểm đến: Open-Meteo (miễn phí, không key).

## 11. Kênh nhắc qua ứng dụng nhắn tin (tùy chọn, Phase 3, Plus)
| Kênh | Thị trường | Cách làm |
|---|---|---|
| WhatsApp Business Platform | Global (LatAm, IN, EU, ID...) | Template message đã duyệt, tính phí theo hội thoại |
| Zalo ZNS | VN | Template đã duyệt, cần Zalo OA doanh nghiệp, tính phí theo tin |
| LINE Messaging API | JP, TH, TW | Official Account, giới hạn tin miễn phí theo gói |
| KakaoTalk (Alimtalk) | KR | Qua đối tác phân phối, tính phí theo tin |
Hợp với nhắc lịch khám, nhắc người thân. Có chi phí theo tin nên chỉ ở gói Plus (`feature_messaging_channel`) và có giới hạn/ngày.
- Email digest hằng ngày qua Postmark/Amazon SES.

## 12. AI có sẵn trong hệ điều hành: việc cần đăng ký/kiểm tra (thiết kế ở `on-device-extraction.md` §3, §5 và `voice-and-text-input.md` §3)
| API | Nền tảng | Việc cần làm |
|---|---|---|
| Vision (OCR, barcode, `RecognizeDocumentsRequest`) | iOS | Kiểm tra `supportedRecognitionLanguages` cho các hệ chữ đợt 1 (E0.2) |
| VisionKit document camera | iOS | Không cần đăng ký |
| Foundation Models (`SystemLanguageModel`) | iOS 26+ có Apple Intelligence | Capability không cần xin; kiểm `availability` lúc chạy; iOS 27 có đầu vào ảnh |
| ML Kit Text Recognition v2, Barcode, Document Scanner | Android (+ iOS) | Thêm dependency; Document Scanner cần Google Play services |
| ML Kit GenAI Prompt API (Gemini Nano) | Android flagship có AICore | Đang alpha/beta: theo dõi thay đổi API, kiểm `checkFeatureStatus`, chỉ chạy khi app ở foreground |
| SpeechRecognizer / SpeechAnalyzer | Android / iOS | Xin quyền micro + speech recognition (iOS) |

## 13. Danh sách SDK/plugin dự kiến (Flutter)
`supabase_flutter`, `drift`, `riverpod`, `go_router`, `firebase_messaging`, `flutter_local_notifications`, `timezone`,
`flutter_timezone`, `rrule`, plugin STT native riêng (cần bias/language switch, `speech_to_text` không đủ), `google_mlkit_barcode_scanning`, `image_picker`, `file_picker`,
`receive_sharing_intent`, `google_mlkit_text_recognition`, `google_mlkit_document_scanner`, `pdfrx`, `archive`, `xml` (MIME, csv/xlsx, Markdown tự viết: ADR-015),
`phone_numbers_parser`, `onnxruntime` (PP-OCR), `whisper_cpp_flutter_plus` hoặc tương đương (Phase 2), `purchases_flutter`, `device_calendar`, `home_widget`, `sentry_flutter`, `posthog_flutter`,
`google_sign_in`, `sign_in_with_apple`, `intl`, `flutter_localizations`. Kiểm tra bảo trì (pub.dev score, ngày phát hành) trước khi khóa phiên bản.
Plugin nào chạy trên macOS/Windows/web: `architecture/multi-platform.md` §3 (cập nhật bảng đó khi thêm plugin).
