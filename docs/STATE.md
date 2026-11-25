# STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)

**Cập nhật:** 2026-11-25 · **Phase:** 0 → S1-S3 (đồng bộ với Supabase dev chạy thật; chờ Firebase, đăng nhập có tài khoản) · **Nhánh:** `claude/stoic-einstein-8g8f7v`

## Đã có
- Bộ docs v2 (`docs/INDEX.md`) + 17 ADR (ADR-017: ngày lễ là gói luật tự viết, tính trên máy; ADR-016: dữ liệu sân bay mwgg/Airports, từ vựng T2 trong gói NLU; ADR-015: decoder MIME/csv/xlsx/md tự viết; ADR-013: Free 1 thiết bị, Plus 1 điện thoại + 1 tablet + 1 máy tính; ADR-014: một codebase Flutter, app máy tính macOS/Windows ở Phase 4, paywall ghi "sắp có"). Nghiên cứu thị trường global (`research/global-market.md`). L0: glossary 258 thuật ngữ, style guide en/vi, so sánh TMS (`docs/l10n/`).
- DB: `supabase/migrations/` (schema, RLS chỉ đọc, `sync_push`/`sync_pull`/`quota_status`/`profile_init`, giới hạn thiết bị `session_claim`/`session_status`/`session_end`
  + lịch sử đăng nhập + cắt thiết bị khi hạ gói, seed gói, chặn/kẹp `field_clock` sai) + 109 test pgTAP.
- Khung repo: CI `.github/workflows/ci.yml` (3 job docs-and-lint, db + contract test, flutter đều pass trên GitHub, run #10), kiểm tham chiếu docs, lint chuỗi hard-code, hook commit-msg, bộ mẫu `packages/parsers/fixtures/` (schema + quy trình ẩn danh, 1 mẫu tổng hợp).
- Workspace Dart/Flutter 3.50.1 (`pubspec.yaml` gốc): `packages/core` (HLC khớp server, UUIDv7, id Inbox, loại thiết bị, entitlement, giao thức sync),
  `packages/platform` (interface + `PlatformCapabilities`), `packages/data` (Drift mirror bảng server, outbox, `SyncEngine` merge HLC; contract test với RPC Postgres thật),
  `apps/client` (theme token, go_router + shell thích ứng 3 cỡ, ARB en/vi + pseudo `en_XA`, Ctrl/Cmd+N Quick Add). CI thêm job `flutter` + contract test.
- App chạy offline với DB thật (`drift_flutter`): Hôm nay (Quá hạn/Hôm nay/Chưa đặt giờ/Đã xong, vuốt = Xong + Hoàn tác), chi tiết item
  (tên, ghi chú có `base_clock`, ưu tiên, xóa), Quick Add lưu việc. `ItemsRepository` + `InstallInfo.deviceId` trong `packages/data`. `OfflineSyncApi` giữ outbox tới khi có server.
- Quick Add hiểu câu tự nhiên en/vi (`packages/parsers`: engine NLU + gói YAML, chip thời điểm/lặp/tag/ưu tiên, "Ý bạn là" khi mơ hồ, nhiều việc 1 câu).
  `packages/core`: âm lịch VN/TQ/HQ + `Recurrence` (RRULE qua `rrule`, âm lịch, sau khi hoàn thành). Bộ câu tổng hợp: vi 100%, en 98,3%.
- S3 nhắc nhở (offline, `reminder-engine.md` §1 "Code"): rolling window 14 ngày (iOS 60 + thông báo dự phòng, Android 500), đổi múi giờ theo quy tắc DST,
  fixed/floating, âm lịch; diff với `scheduled_notifications`; adapter `flutter_local_notifications` (exact alarm nếu được cấp, `alarmClock` cho nhắc kiểu báo thức,
  nút Xong/Hoãn 10'/1h cả khi app tắt); Hôm nay trải từng lần của chuỗi lặp; màn chi tiết thêm/bỏ nhắc; Quick Add mặc định nhắc đúng giờ; thẻ "Nhắc nhở có thể không kêu".
  Manifest Android (quyền + receiver), desugaring, AppDelegate iOS; min iOS 17 / Android API 26 theo ADR-011. CI thêm `android-build` (+ `ios-build` chạy tay).
- S2 còn lại đã xong: Tôi → Danh sách (Hộp thư + list người dùng, tạo/đổi tên/xóa, việc về Hộp thư), chọn list ở chi tiết, Quick Add `#tag` khớp tên list,
  tìm kiếm không dấu (`foldForSearch`). S4 phần UI: sửa ngày/giờ ở chi tiết, chọn lặp (hằng ngày, ngày thường, hằng tuần, hằng tháng, hằng năm, âm lịch theo ngôn ngữ).
  Chi tiết item và tìm kiếm là route gốc `/item/:id`, `/search`. CI `android-build` pass (compileSdk 37).
- S5 E1 phần đầu: decoder `.ics` (TZID, cả ngày, RRULE, VALARM, VTODO), IATA BCBP (nhiều chặng, suy năm từ ngày Julian), JSON-LD schema.org
  trong email (Flight/Lodging/Train/Bus/Event/Restaurant/RentalCar), `.pkpass` (ưu tiên BCBP); harness eval E3.5 trên `fixtures/docs/`.
- S5 E1 tiếp: email MIME (`EmailDecoder`: HTML → JSON-LD, `.ics`, `.pkpass`, email lồng, gộp trùng, PDF/ảnh trả `pending`), csv/xlsx → việc
  (`TableTaskExtractor`: dò header theo từ điển cột trong gói, suy cột khi không header, thứ tự ngày, NLU cho ô chữ), Markdown/Obsidian Tasks (`MarkdownDecoder`).
  `Candidate` thêm `priority`, `done`, `tags`, `listName`, `checklist`. Eval 7 mẫu tổng hợp: 100% trường bắt buộc, 0 điền sai.
- Nhập từ tệp trong app (bản đầu E5): Tôi → Nhập từ tệp (`file_picker`) → giải mã trong isolate → màn Xem lại → `ImportsRepository.commit`
  (hàng `imports` + item có `import_id`, list theo tên, checklist, địa điểm, lặp, nhắc). Đặt chỗ tạm lưu thành sự kiện; csv tính như xlsx (chủ dự án đồng ý).
- Tầng luật T2 (E3 phần đầu + E4.1, `packages/parsers/lib/src/engine/`, on-device-extraction.md §4.4 "Đã có"): `TextDocument` (dòng + bbox), anchor mờ,
  `ValueReader` (ngày/giờ qua mẫu gói NLU, tiền ISO 4217, số chuyến, mã sân bay), phân loại theo mục `document:` của gói, extractor chung bay (nhiều chặng, "+1",
  qua đêm theo UTC), khách sạn, tàu/xe, lịch khám (bỏ ngày sinh, không trả tên bệnh nhân), vé sự kiện; validator (`fieldConfidence`, `issues`), mẫu nhà cung cấp JSON + schema (CI kiểm), `RuleEngine`. Dữ liệu IATA → tz
  `data/airports.tsv` (ADR-016). App: email không JSON-LD và `.txt` dạng vé đi qua T2, màn Xem lại có cảnh báo + "hãy kiểm tra lại"; ghi chú item có mã đặt chỗ, toa, ghế, khoa, số thứ tự, dặn dò. Eval 15 mẫu: 100%, 0 điền sai.
- Màn Xem lại E5.1: chạm 1 mục mở form sửa từng trường (ngày/giờ đi-đến giữ múi giờ nguồn, địa điểm, mã, số chuyến, ghế, toa, khoa, số thứ tự, dặn dò);
  trường độ tin cậy thấp viền `warning` + ⓘ, xác nhận/sửa thì hết dấu trên thẻ.
- S6 chuyến đi (offline): đặt chỗ lưu `kind = booking` + `booking_details` (không có tên hành khách), nhắc mặc định theo loại (reminder-engine §5,
  khách sạn bằng nhắc tuyệt đối), trùng/đổi giờ với đặt chỗ đã có (bỏ qua hoặc cập nhật), gợi ý gom chuyến ở màn Xem lại (mới / có sẵn / không gộp),
  tab Chuyến đi (danh sách + timeline giờ địa phương từng điểm, đổi tên, xóa chuyến giữ đặt chỗ, "Thêm hoạt động" ở khoảng trống > 3h giữa 2 chặng có giờ
  (khách sạn/thuê xe không tính là bận) tạo việc trong chuyến), múi giờ sân bay cho vé chỉ có offset. `TripsRepository` trong `packages/data`.
  Contract test Postgres: trips + booking_details + nhắc tuyệt đối + cập nhật qua `sync_push` thật.
- Hạn mức chuyến đi: `SyncEngine` cache `quota_status` sau mỗi lần sync; màn Xem lại đếm chuyến đang hoạt động trên máy, hết lượt thì khóa "Chuyến mới"
  + dòng giải thích (số lấy từ gói). Chuyến mới vẫn bị server từ chối thì máy bỏ chuyến, gỡ `trip_id` khỏi đặt chỗ và gửi lại (không mất item, data-model §4).
- US-12b phần đầu: ngày lễ VN/US/GB từ gói luật tự viết (ADR-017, `HolidayCalendar` trong `packages/core`); tab Lịch dạng tháng (UX §2.6): chấm ở ngày
  có item (gồm từng lần của chuỗi lặp), ngày âm dưới ngày dương khi ngôn ngữ có âm lịch, ngày nghỉ lễ tô màu, chạm ngày → ngày lễ (nghỉ lễ/nghỉ bù) + item.
  Thẻ trên Hôm nay khi ngày nghỉ lễ trong 7 ngày tới có việc 1 lần đang hẹn: "Dời sang <ngày làm việc kế tiếp>" (giữ giờ, có Hoàn tác) hoặc "Để nguyên" (`LocalPrefs`).
  Lặp "Các ngày làm việc" (US-11): thứ không phải cuối tuần theo CLDR + bỏ ngày nghỉ lễ của vùng (`workdays_region`), áp cho Hôm nay, lịch và nhắc.
- UI theo Figma (đợt 1): token màu/chữ/bo góc theo file Figma (design-system.md §2-5), font Be Vietnam Pro bundle trong app, icon SVG
  (`AppIcon`), thanh dưới có nút "+" giữa, màn Hôm nay (tiêu đề lớn + ngày âm, thẻ tiến độ, nhóm có số việc, thẻ việc với giờ bên phải),
  màn Lịch (thẻ tháng, dải ngày chuyến đi + chú thích, thẻ lịch hẹn giờ theo từng nơi + icon loại, ô ngày cao thêm khi phóng chữ),
  tab Chuyến đi (lọc Sắp tới/Đã qua, thẻ chuyến: ngày, số ngày, nơi đến, tuyến, 3 chặng đầu, Xem lịch trình; thẻ Thêm vé; dòng hạn mức từ cache),
  chi tiết chuyến (theo ngày "Ngày N", banner giờ địa phương UTC±, thẻ bay giờ đi/đến + thời lượng + mã đặt chỗ sao chép được + nhắc,
  thẻ nhận/trả phòng, ngày trống, nút Thêm vào lịch trình → hoạt động hoặc nhập vé).
  Đợt 2: màn Xem lại khi nhập (thẻ mục, tuyến lớn, ô "Cần kiểm tra"/"Đã kiểm tra", trường vàng phải xác nhận trước khi lưu, thẻ gộp chuyến
  chạm để chọn, thẻ hạn mức lịch hẹn từ cache), form sửa dạng thẻ + "Đúng, giữ nguyên", màn Tôi (lối tắt, cài đặt, chọn ngôn ngữ giao diện và
  sáng/tối trong app, lưu trên máy).
  Thêm nhanh (02): tiêu đề + đóng, ô nhập lớn, chip thời điểm/list/nhắc/lặp (chạm chip thời điểm → chọn ngày giờ, chip nhắc → chọn độ lệch
  hoặc Không nhắc), dòng "Đã hiểu thời gian", nút Nói/Chụp/Ảnh (mờ, sắp có) và Tệp (mở Nhập từ tệp).
  Chi tiết (04): chip list + trạng thái (chạm để xong/mở lại), tên lớn, thẻ ghi chú, thẻ Ngày & giờ / Nhắc / Lặp / Danh sách / Ưu tiên
  (`SettingRow` dùng chung, ưu tiên chọn ở bottom sheet); tự lưu, không có nút Lưu; checklist chưa có.
  Ngôn ngữ & vùng (C50): ngôn ngữ giao diện, định dạng + múi giờ (theo máy, chỉ xem), quốc gia ngày lễ kèm ngày nghỉ cuối tuần, hệ lịch phụ, xem trước.
  Chưa làm theo Figma: chế độ Tuần/Ngày và bộ lọc ở Lịch (chưa có chức năng), tab Tài liệu/Hành lý của chuyến,
  bước chọn ngày giờ/lặp/hoãn (05-08), onboarding/đăng nhập/gói (chờ auth, paywall).
- Server dev (Supabase `msgamxrlohgszgpvvyfd`, ap-southeast-1, `guides/backend-setup.md`): đã áp migrations 01-08, chạy thử
  `profile_init` → `session_claim` → `sync_push` → `sync_pull` → `quota_status` trên DB thật (rollback, không để dữ liệu).
  App: `SupabaseSyncApi` (RPC + đổi lỗi server sang `SyncErrorCode`), `RemoteSync` (đăng nhập ẩn danh → profile_init → session_claim →
  sync, thử lại 1 lần khi thiếu profile/phiên), `RemoteSyncBinding` (đồng bộ lúc mở app, khi trở lại, 3 giây sau sửa, 15 phút/lần);
  build có server bằng `--dart-define-from-file=env/dev.json`, không có thì offline như cũ. Test live `test/live_supabase_test.dart` (REMINDME_LIVE=1).
  Đăng nhập ẩn danh đã bật; test live pass (đăng nhập → profile → phiên → push → máy thứ 2 pull về đúng). Banner offline trên Hôm nay,
  thẻ Đồng bộ ở Tôi (trạng thái, giờ đồng bộ gần nhất, số thay đổi chờ, Đồng bộ ngay).
  Tài khoản (Figma C35-C37, UX §3.7): đăng nhập email + mã OTP (gắn vào user ẩn danh, giữ dữ liệu; email đã có tài khoản thì hỏi rồi thay dữ liệu
  trên máy, nêu máy bị đăng xuất), Tài khoản & thiết bị (email, gói, lịch sử đăng nhập, Đăng xuất), màn "Bạn đã được đăng xuất" khi phiên bị
  máy khác thay (hủy mọi thông báo, số thay đổi chưa đồng bộ, Đăng nhập lại). `SyncEngine.resetLocalData`. Chờ chủ dự án thêm `{{ .Token }}`
  vào email template để mã gửi tới email (guides/backend-setup.md §3).
- Chưa có: worker, PDF decoder, chia sẻ vào app (share intent Android / share extension iOS), đổi cột + nhớ mapping ở màn xem trước,
  mẫu nhà cung cấp thật (cần mẫu thật), evidence khi chạm ⓘ + dòng hạn mức nhập thông minh ở màn Xem lại, ảnh điểm đến ở đầu chuyến,
  tab Tài liệu + checklist hành lý của chuyến, đăng nhập Google/Apple, flavors staging/prod.

## Tiếp theo (ưu tiên)
1. **Chủ dự án duyệt** đề xuất ở `research/global-market.md` §9 (chưa áp vào docs): thêm `it` vào đợt 1 cấp B; đợt 2 `tr, th, zh-Hans, ar, nl, pl, ms`;
   region `eu-central-1` (sửa ADR-011); BR/TR ~50% giá T1, EU/UK ghi đè €4,99/£4,99, thêm SA/AE/HK/TW vào bảng giá. Cùng lúc duyệt giới hạn Free.
2. Trả lời câu hỏi l10n (dưới) rồi chạy trial TMS 14 ngày với 50 key (Crowdin Pro, dự phòng Weblate hosted).
3. Đăng ký Apple Developer (tổ chức, D-U-N-S), Google Play Console, domain, Firebase, Supabase (region theo mục 1); hồ sơ thuế storefront.
4. Thu mẫu tài liệu theo `packages/parsers/fixtures/README.md` (≥ 300, ≥ 3 thị trường); phỏng vấn 15-20 người; bộ câu nói theo vùng (V4).
5. Spike cần máy thật: E0 (OCR theo hệ chữ), V0 (STT/NLU). Prototype 6 luồng P0.
   Bộ câu NLU thật ≥ 300 câu/gói (vi chia đều Bắc/Trung/Nam) thay bộ tổng hợp trong `packages/parsers/fixtures/nlu/`.
6. Sprint S1 phần còn lại: chủ dự án sửa email template (thêm `{{ .Token }}`) rồi thử đăng nhập email trên máy thật; Google/Apple
   (`linkIdentity`, cần OAuth client); SMTP riêng trước khi ra mắt; Firebase (FCM); flavors staging/prod; golden test.

## Câu hỏi mở (cần chủ dự án quyết)
- Tên thương mại/domain (docs dùng giả định `RemindMe`, `remindme.app`, bundle `app.remindme`).
- Đợt locale 1, region, nhóm giá: xem Tiếp theo mục 1. Project dev đã tạo ở `ap-southeast-1` (khác đề xuất `eu-central-1`): giữ cho dev, prod chọn sau?
- l10n: giữ tên gói "Free" không dịch ở mọi locale? Đổi tên list mặc định "Inbox/Hộp thư" (trùng nghĩa hộp thư email, đề xuất "Chưa phân loại")?
  Một file `en` hay thêm `en_GB`; tách `es-ES`/`es-419` ở đợt 1? Ngân sách dịch giả cấp B.
- Đăng nhập theo thị trường (Zalo/LINE/Kakao) ở Phase 1? Bán qua web? Chấp nhận CASA cho Gmail nếu Google yêu cầu? Đội ngũ thực tế.

## Việc kỹ thuật còn nợ
- S3 còn thiếu (cần máy thật hoặc hạ tầng): chạy thử trên Android/iOS thật (chưa có SDK trong container; CI build APK sẽ kiểm biên dịch),
  method channel `setAlarmClock`/nghe `TIMEZONE_CHANGED`·`TIME_SET` native (hiện lập lại khi mở app), BGAppRefreshTask + silent push `reschedule` (iOS),
  onboarding OEM (Xiaomi/Oppo/Vivo/Samsung/Huawei), màn priming trước khi hỏi quyền (hiện gọi thẳng hộp thoại OS), telemetry `reminder.*` (chưa có SDK analytics),
  , cài đặt "giờ nhắc của item cả ngày" (đang 09:00).
- T2: chưa có tên thành phố → sân bay, ga → múi giờ, tàu/xe nhiều chặng, SĐT; tệp `.txt` dạng vé (đi qua T2) đang ghi `imports.kind = text`
  nên không tính `smart_imports_per_month` (cần chủ dự án chốt: văn bản dán vào có tính là nhập thông minh không).
- Chuyến đi: chưa có UI báo/paywall từ `SyncReport.rejectedTrips` (chờ luồng sync thật); dòng hạn mức ở màn Xem lại chưa có nút nâng cấp (chưa có paywall).
- Nhập từ tệp: chưa thử `file_picker` trên máy thật; `quota_status` được cache sau mỗi lần sync (`SyncEngine.cachedQuota`) (build có server thì cache có sau lần đồng bộ đầu); lặp âm lịch từ dòng chữ trong tệp .txt chưa giữ (chỉ RRULE).
- ADR-013 phía worker/app chưa làm: job `session.notify_revoked`, `cleanup.sessions`, kiểm phiên ở endpoint worker, màn UX §3.7.
  Kiểm trước Phase 4 (desktop): chính sách thanh toán Microsoft Store, giờ kêu thông báo Windows.
- Rate limit `sync_push` (30/phút/thiết bị) chưa có trong DB/PostgREST; mã hóa cột `booking_details.passengers` chưa làm.
- Tôi → Ngôn ngữ & vùng (quốc gia ngày lễ, hệ lịch phụ; mặc định theo máy/ngôn ngữ) lưu ở `LocalPrefs` trên máy: chuyển sang
  `profiles.region`/`calendar_systems` (đã có `SupabaseSyncApi`, chưa làm). Ngôn ngữ giao diện + sáng/tối chọn ở Tôi cũng chỉ trên máy
  (chưa gọi per-app language của OS); chưa có chọn định dạng, giọng nói.
- Ngày lễ còn thiếu: server `app.rrule_fires_on` chưa trừ ngày lễ khi đếm quota (đếm dư, an toàn), gói ngày lễ
  cho các nước khác (AU, CA, IN, đợt locale cấp B), màu loại item trên chấm lịch.
- UX copy: wireframe "KHÔNG GIỜ" dễ đọc thành 0:00 (đề xuất "Chưa đặt giờ"); "Hoãn 10'" dùng dấu phẩy trên. `intl` không có formatter khoảng thời gian/tương đối: chọn ở L1.

## Blocker
- Không có.

## Chưa xác minh (kiểm tra ở spike)
Vision iOS với tiếng Việt và các hệ chữ khác; locale STT on-device thực tế trên máy; chất lượng Foundation Models/Gemini Nano theo ngôn ngữ;
định dạng vé thật; price point từng storefront; giấy phép checkpoint PhoWhisper và dữ liệu ngày lễ; UK coi EEA là adequate; hạn mức từ của Crowdin Pro.
