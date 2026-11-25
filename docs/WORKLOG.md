# WORKLOG

> Nhật ký công việc. **Entry mới thêm ở ĐẦU** (ngay dưới khối mẫu). Đọc nhanh: `head -60 docs/WORKLOG.md`.
> Khi file > 400 dòng: chuyển các entry cũ sang `docs/worklog/archive/YYYY-MM.md`.

<!-- MẪU (copy, không sửa khối này)
## YYYY-MM-DD · <tiêu đề ngắn> · <người/agent>
- **Làm:** ...
- **Quyết định:** ... (ADR-xxx nếu có)
- **File:** ...
- **Kiểm chứng:** lệnh/test đã chạy + kết quả
- **Dở dang / tiếp theo:** ...
-->

## 2026-11-25 · UI theo Figma đợt 2: Xem lại khi nhập, form sửa, Tôi + chọn ngôn ngữ/giao diện · Claude Code
- **Làm:** màn Xem lại (Figma 15/15b): thẻ tệp nguồn, thẻ từng mục (ô chọn, nút sửa, tuyến lớn SGN ✈ HAN, giờ đi/đến hoặc nhận/trả phòng,
  ô "Cần kiểm tra: <trường>" / "Đã kiểm tra"), banner cần kiểm tra / đã xác nhận đủ, thẻ gộp chuyến chạm mở danh sách chọn (thay dropdown),
  thẻ hạn mức lịch hẹn từ cache `quota_status`. Form sửa (16): ô dạng thẻ, trường vàng nền `warningContainer`, thẻ "Bạn kiểm tra giúp mình"
  + "Đúng, giữ nguyên", nút "Xác nhận & quay lại". Tôi (27): lối tắt, Tài khoản & cài đặt (mục chưa làm ghi "Sắp có"), chọn ngôn ngữ giao diện
  (Theo máy / Tiếng Việt / English) và giao diện (Theo máy / Sáng / Tối), lưu `LocalPrefs`, đọc trước `runApp`. Token `warningContainer`/`onWarningContainer`,
  9 icon SVG mới, 42 key ARB.
- **Quyết định:** trường độ tin cậy thấp phải được xác nhận trước khi lưu (theo Figma): còn mục đang chọn có trường vàng thì nút chính là
  "Kiểm tra để tiếp tục" và mở form mục đó (ux-flows §2.4). Bỏ chọn mục cũng mở khóa nút lưu.
- **Kiểm chứng:** client 74 (+3 màn Tôi; test nhập đổi theo UI mới + luồng xác nhận + thẻ hạn mức); analyze 0; ARB 267 key 0 lỗi; lint chuỗi 0;
  unslop không đổi; ảnh chụp sáng/tối đối chiếu Figma 15/15b/16/27.
- **Tiếp theo:** Ngôn ngữ & vùng (C50) theo Figma, Thêm nhanh (02), chi tiết nhắc (04); evidence khi chạm ⓘ (cần lưu vị trí chữ ở T2).

## 2026-11-25 · UI theo Figma đợt 1 (Hôm nay, Lịch, Chuyến đi, chi tiết chuyến) + 2 lỗi dữ liệu · Claude Code
- **Làm:** đọc file Figma qua MCP (236 frame); token màu/chữ/bo góc theo Figma (design-system.md §2-5), font Be Vietnam Pro bundle (OFL ở màn
  giấy phép), icon SVG + `AppIcon` (tô theo theme, lật khi RTL), thanh dưới 4 tab + nút "+" giữa; làm lại Hôm nay, Lịch, Chuyến đi, chi tiết chuyến.
  `flutter_svg` (parsers nới `xml` về `>=6.5`). `TripsRepository.bookingInfo`, `TripSegment.carrierCode/number`, `cachedQuotaProvider`.
- **Quyết định:** token `danger` → `#BF3035`, `travel` → `#087E89` theo Figma (màu cũ chưa đạt WCAG AA chữ nhỏ). Chế độ Tuần/Ngày, bộ lọc ở Lịch,
  tab Tài liệu/Hành lý chưa đặt lên màn vì chưa có chức năng.
- **Lỗi bắt được:** (1) `offset_minutes` hai quy ước: planner/UI/.ics "dương = trước", data-model/server/nhắc mặc định khi nhập vé "âm = trước"
  → nhắc chuyến bay nhập từ vé kêu **sau** giờ bay; thống nhất "âm = trước". (2) `updateBooking(id, tripId:)` xóa ngày/giờ của item.
  (3) Ô ngày lịch cao cố định tràn khi phóng chữ 1,3×; hàng chip tràn ở 320dp (test pseudo-locale bắt).
- **Kiểm chứng:** core 51, data 51 (+1), parsers 74, client 71; contract Postgres 8, pgTAP 109; analyze 0; ARB 225 key; ảnh chụp sáng/tối đối chiếu Figma.
- **Tiếp theo:** màn Xem lại khi nhập (15/15b/16), Tôi (27), Ngôn ngữ & vùng (C50), Thêm nhanh (02), chi tiết nhắc (04); tab Tài liệu + Hành lý.

## 2026-11-25 · Dời việc khỏi ngày nghỉ lễ, màn Ngôn ngữ & vùng · Claude Code
- **Làm:** `nextWorkday` (core); `ItemsRepository.openTasksOn`/`moveToDate`, `LocalPrefs` (data, khóa `pref.*` trong `sync_state`, không đồng bộ).
  Hôm nay có thẻ ngày nghỉ lễ trong 7 ngày tới còn việc 1 lần: "Dời sang <ngày làm việc kế tiếp>" (giữ giờ, Hoàn tác) / "Để nguyên".
  Tôi → Ngôn ngữ & vùng: quốc gia ngày lễ (theo máy / VN / US / GB / không dùng), hệ lịch phụ (theo ngôn ngữ / âm lịch VN/TQ/HQ / không dùng);
  gói ngày lễ có thêm tên quốc gia (`name`). 17 key ARB.
- **Quyết định:** chỉ gợi ý dời việc (kind `task`, không lặp); sự kiện, lịch hẹn, đặt chỗ không dời. Cài đặt lưu trên máy tới khi có `profiles` đồng bộ.
- **Kiểm chứng:** core 51, data 50, client 71 (+3); analyze 0; ARB 194 key 0 lỗi.
- **Figma:** chủ dự án gửi file thiết kế (236 frame = ~59 màn × VI/EN × sáng/tối, gồm onboarding, đăng nhập, gói, cài đặt); đọc được qua Figma MCP.
  File không có variables (token phải đọc từ giá trị màu/chữ của layer).
- **Tiếp theo:** áp token + từng màn theo Figma (Hôm nay, Lịch, Chuyến đi, Xem lại, Tôi, Ngôn ngữ & vùng).

## 2026-11-25 · Hạn mức chuyến đi, đổi tên/Thêm hoạt động, ngày lễ + tab Lịch, lặp ngày làm việc · Claude Code
- **Làm:** `SyncEngine`: lượt push đầu hoãn lỗi khóa ngoại `23503`; chuyến mới bị `quota_exceeded` thì bỏ ở máy, gỡ `trip_id` khỏi item, gửi lại mutation lỗi
  (`SyncReport.rejectedTrips`); cache `quota_status` sau mỗi lần sync (`cachedQuota`, `SyncApi.quotaStatus`). Màn Xem lại đếm chuyến đang hoạt động, hết lượt thì
  khóa "Chuyến mới" + dòng `importTripLimit`, `commit` nhận quota từ cache. Chuyến đi: đổi tên, "Thêm hoạt động" ở khoảng trống > 3h (`freeGapsAfter`).
  `packages/core`: `HolidayCalendar` + gói VN/US/GB, `easterSunday`, `weekendDays` (CLDR), `HolidayCalendars`, `WorkdaysRecurrence`. Tab Lịch dạng tháng
  (`countsByDay`, ngày âm, ngày lễ, chạm ngày). Lựa chọn lặp "Các ngày làm việc" (`workdays_region`).
- **Quyết định:** ADR-017 (ngày lễ là gói luật tự viết theo văn bản luật, tính trên máy; không dùng dữ liệu `date-holidays`). Chuyến bị từ chối thì bỏ chuyến,
  giữ đặt chỗ (như xóa chuyến). `workdays_region` ghi cả khi vùng chưa có gói ngày lễ (chỉ bỏ cuối tuần tới khi có gói).
- **Lỗi bắt được nhờ test:** `RRuleRecurrence.between` assert khi khoảng ngày nằm trước ngày bắt đầu chuỗi. Contract test mới fail đúng chỗ khi bỏ phần sửa SyncEngine.
- **Kiểm chứng:** core 50 (+10), data 48 (+5), contract Postgres 8 (+1), pgTAP 109, parsers 74, client 68 (+7: hạn mức chuyến, đổi tên/xóa chuyến,
  Thêm hoạt động, 3 lịch, 2 ngày làm việc); analyze 0; check-docs/fixtures/lint/ARB (177 key)/platform 0 lỗi.
- **Tiếp theo:** UI báo chuyến bị từ chối + paywall; gợi ý dời nhắc rơi vào ngày lễ; gói ngày lễ AU/CA/IN; tab Tài liệu + checklist hành lý; màn Cài đặt
  (hệ âm lịch, vùng ngày lễ).

## 2026-11-25 · S6 chuyến đi: booking_details, trùng/cập nhật, gom chuyến, nhắc mặc định, tab Chuyến đi · Claude Code
- **Làm:** `packages/data`: `TripsRepository` (tạo, nới ngày, đổi tên, xóa giữ đặt chỗ, `segments`, `bookingsWithCodes`), `ItemsRepository.create` nhận
  `tripId`/`booking`/`absoluteReminders`, `updateBooking`, `addReminderAt`; `ImportsRepository.commit(trips:)`, `ImportedItem.booking/tripIndex/updateItemId`,
  `ImportRecord` kiểm `tier_used`/`kind` theo CHECK của server, ghi `template_id`. `packages/parsers`: `suggestTrips`, `defaultReminders`, `withAirportTimeZones`.
  App: đặt chỗ thành `kind = booking` + `bookingRow`, `matchExistingBookings`, màn Xem lại có dòng "Gộp vào chuyến đi" + "Đã có, sẽ bỏ qua/cập nhật giờ",
  `tier_used = t1t2` khi qua T2, tab Chuyến đi + `/trips/:id` (timeline theo ngày, giờ đi/đến theo múi giờ từng nơi). 11 key ARB.
- **Quyết định:** quy tắc gom chuyến ở on-device-extraction.md §4.4 (khoảng cách ≤ 2 ngày; vé lẻ mặc định không gộp để giữ lượt Free); khách sạn chỉ nhắc
  tuyệt đối (18:00 hôm trước, 1h trước trả phòng), không thêm "đúng giờ".
- **Lỗi bắt được nhờ test:** contract test Postgres từ chối `tier_used = 't2'` (CHECK chỉ có `t1t2`) kéo theo cả item của lần nhập (khóa ngoại) → chặn ngay ở
  client; app ghi `t0` cho kết quả T2 → sửa. Vé JSON-LD chỉ có offset nên `booking_details.origin.tz` rỗng → suy múi giờ theo sân bay.
- **Kiểm chứng:** data 43 (+3 trips), contract Postgres 7 (+1), pgTAP 109; parsers 74 (+4); client 60 (+2 logic, +1 widget chuyến đi end-to-end); analyze 0; lint/ARB/docs 0 lỗi.
  Postgres 16 + pgTAP cài lại trong container (apt), `PGPASSWORD=postgres`.
- **Tiếp theo:** gỡ `trip_id` khi trip bị từ chối quota; sửa/đổi tên chuyến; gợi ý "Thêm hoạt động"; tab Tài liệu; share intent/extension (cần máy thật).

## 2026-11-25 · Màn Xem lại: sửa từng trường, tô `warning` (E5.1) · Claude Code
- **Làm:** `parsers`: `CandidateFields.copyWith` (phân biệt "giữ" với "xóa"), `Candidate.copyWith`. App: `features/import/candidate_editor.dart`
  (`editCandidate` mở form toàn màn hình; `reviewKeys`/`needsCheck`; ô ngày/giờ sửa giờ tường của nguồn, giữ tz/offset; số chuyến "ZZ 245" tách lại mã hãng + số),
  màn Xem lại giữ bản sửa theo vị trí, thẻ có ⓘ `warning` khi còn trường cần kiểm tra. 14 key ARB mới, bỏ `importItemName` (không còn dùng).
- **Quyết định:** trường người dùng sửa hoặc xác nhận có độ tin cậy 1,0; dấu trên thẻ chỉ tính trường form sửa được (số khách 0,6 không lưu vào item nên không tính);
  sửa ngày bắt đầu thì tính lại `past_date`, bỏ `date_order_ambiguous`; sửa ngày kết thúc thì bỏ `arrival_next_day`/`check_out_before_check_in`.
- **Lỗi bắt được nhờ test:** thẻ vé bay T2 không bao giờ hết dấu vì số chuyến/số khách 0,6 không có ô sửa → thêm ô số chuyến, giới hạn dấu theo form.
- **Kiểm chứng:** app 57 test (+1 widget sửa trường → DB, +1 logic `needsCheck`, pseudo-locale 320dp chữ 1,3× mở form khách sạn); parsers 70, core 40, platform 2, data 40;
  analyze 0; docs/ARB/lint 0 lỗi; unslop 0 thay đổi.
- **Tiếp theo:** evidence khi chạm ⓘ (cần giữ vị trí dòng nguồn trong `Slot`), dedupe + gom trip (S6), hiển thị hạn mức ở màn Xem lại khi có `quota_status`.

## 2026-11-24 · T2: tàu/xe, lịch khám, vé sự kiện · Claude Code
- **Làm:** `GenericExtractor` thêm `_ground` (tàu/xe: ga/điểm đón theo nhãn hoặc dòng có mũi tên, giờ + "(+1)" cùng vùng, số hiệu tàu, toa, chỗ, nhà xe),
  `_medical` (nơi khám không nhãn: dòng ngắn hoặc cụm viết hoa quanh từ trong `facility_words`; khoa, số thứ tự, dặn dò), `_event`; `AnchorReader.hitsFor`,
  `excludeField` + `excluded_dates` (ngày sinh, ngày đặt vé). `CandidateFields` thêm `department`, `queueNumber`, `preparation`; `Slots` thêm tên ga, nhà xe.
  Mẫu nhà cung cấp nhận thêm `origin_name`, `destination_name`, `operator`, `department`, `queue_number`, `preparation`, `event_name`.
  Fixtures: `synthetic-train-text-0001`, `synthetic-bus-text-0001`, `synthetic-medical-text-0001` (vi), `synthetic-email-medical-0001`, `synthetic-event-text-0001` (en).
  App: `ImportNoteLabels` (ghi chú: dặn dò, mã đặt chỗ, toa, ghế, khoa, số thứ tự qua ARB, 4 key mới), `fallbackTitle` dùng khoa khi không có tên.
- **Quyết định:** tàu/xe chưa có từ điển ga nên giờ ghi theo múi giờ máy; tàu/xe chỉ 1 chặng. Dặn dò chép nguyên văn (glossary `med_fasting`: không diễn giải).
- **Lỗi bắt được nhờ test:** harness coi T2 rỗng là "chưa có tầng xử lý" (che mất 1 mẫu trượt) → nay chấm là thiếu; anchor mờ nhận "điểm đón" là "điểm đến"
  (bỏ dấu khác 1 ký tự) → bỏ hit gần đúng trùng nhãn trường khác; "chỗ" trong "Mã đặt chỗ" bị đọc là ghế → loại theo nhãn mã đặt chỗ.
- **Kiểm chứng:** parsers 70 (eval 15 mẫu: bắt buộc 100% 88/88, tùy chọn 100% 53/53, điền sai 0); app 55; core 40, platform 2, data 40; analyze 0; lint/ARB/docs 0 lỗi.
- **Tiếp theo:** màn Xem lại sửa từng trường + tô vàng (E5.1); dedupe + gom trip (S6); ga → múi giờ; mẫu thật.

## 2026-11-24 · Tầng luật T2: anchor mờ, extractor chung bay/khách sạn, mẫu nhà cung cấp (E3, E4.1) · Claude Code
- **Làm:** `packages/parsers/lib/src/engine/`: `document.dart` (`TextDocument`/`TextLine`/`TextBox`, `FoldedText` giữ vị trí gốc, anchor mờ Sellers,
  vùng phải/dưới theo bbox), `values.dart` (`ValueReader`: ngày/giờ bằng mẫu `dates`/`times` của gói, khớp dài nhất, thứ tự ngày theo vùng; tiền; số chuyến; mã sân bay),
  `vocabulary.dart` (mục `document:` của gói), `generic.dart` (`DocClassifier`, `AnchorReader`, `GenericExtractor` bay/khách sạn), `slots.dart` (`Slots`,
  `CandidateAssembler`: kiểm tra logic, qua đêm theo UTC, 14:00/12:00 mặc định), `template.dart` (`ProviderTemplate`, `TemplateReader`, `RuleEngine`), `airports.dart`.
  `data/airports.tsv` + `tool/build_airports.py`, `templates/template.schema.json` (kiểm trong `validate-fixtures.py`). `Candidate` thêm `fieldConfidence`, `issues`.
  Harness eval chạy T2 cho `.txt` và email không có T0, chấm thêm trường tùy chọn. Fixtures mới: `synthetic-email-flight-text-0001` (en, khứ hồi, +1),
  `synthetic-hotel-text-0001` (vi, lỗi OCR ở nhãn). App: `decodeImport` gọi T2, `airportsTsvProvider`, 5 key ARB cảnh báo ở màn Xem lại.
- **Quyết định:** ADR-016 (mwgg/Airports thay OurAirports vì có sẵn tz; từ vựng T2 trong gói NLU). Không trả tên hành khách. Tổng tiền chỉ gắn khi 1 chặng.
  Mã sân bay đứng một mình chỉ khi có giờ sát bên. `$`, `¥` một mình không đoán tiền tệ. Tên khách sạn/địa chỉ chỉ lấy khi nhãn đứng như nhãn.
- **Lỗi bắt được nhờ test:** dòng ghế của chặng đi bị gán cho chặng về (ranh giới khối); "ZY 5  Dec 20" đọc thành 5/12; "THE"/"END" là mã sân bay thật;
  `rootBundle.loadString` tệp > 50 KB mở isolate (kẹt fake-async) → `load` + `utf8.decode`.
- **Kiểm chứng:** parsers 65 test (17 engine; eval 10 mẫu: bắt buộc 100% 69/69, tùy chọn 100% 36/36, điền sai 0); app 54 test (+1 logic, +1 widget);
  core 40, platform 2, data 40; analyze 0; check-docs, validate-fixtures (10 mẫu + 1 mẫu nhà cung cấp), lint, ARB, pseudo, platform 0 lỗi; unslop 0 thay đổi.
- **Tiếp theo:** T2 tàu/xe (VN: mã tàu SE/TN, toa/ghế), khám bệnh; dedupe + gom trip (S6); màn Xem lại sửa từng trường (E5.1); mẫu thật khi có bộ mẫu.

## 2026-11-24 · Nhập từ tệp trong app: màn Xem lại (bản đầu E5) · Claude Code
- **Làm:** `packages/data`: `ImportsRepository` (`commit` ghi hàng `imports` + item có `import_id`, list theo tên khớp không dấu hoặc tạo mới,
  `smartImportsThisMonth` đếm theo tháng của múi giờ máy như server, vượt hạn mức → `pending_quota`); `ItemsRepository.create` thêm `endsAt/endTz/endDate`,
  `location`, `checklist`, `status`, `importId`. App: `features/import/` (`detectFormat`, `decodeImport` chạy trong `Isolate.run`, `toImportedItem` +
  `resolveLocalTime`, màn `ImportScreen` ở `/import`, dòng "Nhập từ tệp" ở Tôi), `file_picker` 13.4.1, `askText` dùng chung cho dialog đặt tên; 24 key ARB.
- **Quyết định:** (chủ dự án đồng ý) csv tính như xlsx; đặt chỗ lưu thành sự kiện tới khi có chuyến đi. Giờ chỉ có offset → múi giờ máy nếu trùng,
  không thì `Etc/GMT∓h`; giờ Z của .ics hiển thị theo máy. Việc đã xong trong tệp mặc định không chọn. Tệp .txt: mỗi dòng 1 việc qua NLU.
- **Kiểm chứng:** data 3 test mới + contract Postgres thật (imports + item có checklist/location/end_tz qua `sync_push`), pgTAP 109; app 52 test
  (8 logic, 4 widget: csv vi, PDF → email vé máy bay en, thứ tự ngày mơ hồ, pseudo-locale 320dp chữ 1,3×); analyze 0.
- **Tiếp theo:** share intent Android + share extension iOS (cần Xcode), đổi cột + nhớ mapping (E5.3), cache `quota_status` khi có server, trips + `booking_details` (S6).

## 2026-11-24 · S5 E1: email MIME, csv/xlsx → việc, Markdown · Claude Code
- **Làm:** `packages/parsers`: `MimePart`/`MimeMessage` (multipart lồng, base64, QP, RFC 2047/2231, windows-1252, ngày RFC 5322), `htmlToText`,
  `EmailDecoder` (JSON-LD trong HTML, `text/calendar`, `.ics`/`.pkpass` đính kèm, `message/rfc822`, `dedupeCandidates`, `pending` cho PDF/ảnh, bỏ logo `Content-ID`);
  `CsvReader` (RFC 4180, đoán `,`/`;`/tab/`|`, BOM UTF-8/UTF-16), `XlsxReader` (shared/inline string, ô ngày theo định dạng, hệ 1904, đúng/sai);
  `TableTaskExtractor` + mục `table:` trong `vi.yaml`/`en.yaml`; `MarkdownDecoder` + `obsidianRecurrenceToRrule`. `Candidate` thêm trường cho việc.
  Fixtures mới: `synthetic-email-hotel-0001`, `synthetic-csv-todo-0001`, `synthetic-xlsx-todo-0001`, `synthetic-md-todo-0001`.
- **Quyết định:** ADR-015 (tự viết thay `enough_mail`/`excel`/`csv`/`markdown`, chỉ thêm `xml`). Thứ tự ngày của bảng: dữ liệu → vùng → hỏi.
  Cột người phụ trách chỉ để nhận diện. Lặp "when done" của Obsidian chưa hỗ trợ (giữ lặp theo lịch).
- **Kiểm chứng:** parsers 48 test; eval 7 mẫu (bỏ qua 1 ảnh): 100% trường bắt buộc, 0 điền sai; `validate-fixtures` 8 mẫu 0 lỗi (boundary MIME số dài
  bị bắt nhầm là số định danh, đổi tên boundary); 5.000 dòng xlsx 0,57 s / csv 0,05 s (container, JIT); analyze 0.
- **Tiếp theo:** nối import vào app (file_picker + share intent → màn Xem lại E5 → tạo item/list/checklist); PDF (E1.3) cần `pdfrx`; T2 chờ OCR thật.

## 2026-11-24 · S5 E1: decoder .ics, BCBP, JSON-LD, .pkpass + harness eval · Claude Code
- **Làm:** `packages/parsers`: `Candidate`/`CandidateFields`/`LocalTime` theo `expected.schema.json`; 4 decoder T0 (`IcsDecoder`, `BcbpDecoder`, `JsonLdDecoder`,
  `PkpassDecoder` qua `archive`); `scoreDocument` (% trường bắt buộc đúng, điền sai, `must_not_fill`) + `test/extract_eval_test.dart` chạy trên `fixtures/docs/`.
  Fixtures tổng hợp mới: `synthetic-ics-0001`, `synthetic-jsonld-flight-0001` (.eml), `synthetic-bcbp-0001`.
- **Quyết định:** không trả tên hành khách (BCBP, JSON-LD `underName`); giờ giữ như in + offset, `tz` để T2 suy theo IATA/ga; TZID kiểu Windows giữ nguyên chờ ánh xạ.
- **Kiểm chứng:** parsers 28 test (10 decoder, eval 3 mẫu: 100% trường bắt buộc, 0 điền sai); `validate-fixtures` 4 mẫu 0 lỗi; analyze 0.
- **Tiếp theo:** MIME `.eml` (`enough_mail`), xlsx/csv (E1.5), md; T2 (E3) cần ảnh OCR thật từ spike E0; nối import vào app (share extension + màn Xem lại E5).

## 2026-11-24 · CI Android, S2 list + tìm kiếm, S4 sửa ngày/giờ + chọn lặp · Claude Code
- **Làm:**
  - CI run #20 `android-build` lỗi (chủ dự án gửi ảnh): `flutter_local_notifications` 23 + `androidx.core` 1.19 cần compileSdk ≥ 37 → `compileSdk = 37`; run #21 pass.
  - `ItemsRepository`: `setSchedule`, `setRecurrence` (chuỗi lặp task/habit chuyển floating), `setList`, `search`, `getItem`, `watchRecurrence`.
    `ListsRepository`: Hộp thư ảo/thật, đếm việc mở, tạo/đổi tên/xóa (việc về Hộp thư), `matchTag`. `core/text.dart`: `foldForSearch` (bỏ dấu, NFD).
  - App: `ScheduleEditor` (chip ngày/giờ, bỏ giờ/bỏ ngày, bottom sheet lặp kèm âm lịch), màn Danh sách + chi tiết list, chọn list ở chi tiết, Quick Add `#tag` → list,
    màn Tìm kiếm (nút trên Hôm nay); route `/item/:id`, `/search` ở gốc; 20 key ARB.
- **Lỗi bắt được nhờ test:** dialog đặt tên list dispose controller khi dialog còn đang đóng → crash (sửa: dialog StatefulWidget).
  Test: đọc DB bằng `runAsync` kẹt khóa với lập lịch nhắc trong fake-async; `db.close()` lúc teardown chờ câu lệnh của zone giả (ghi chú ở testing-and-release §2).
- **Kiểm chứng:** `flutter analyze` 0; core 40, platform 2, data 37 (+5 contract), parsers 17, client 40 test; lint/ARB/pseudo/platform 0 lỗi.
- **Tiếp theo:** S4 còn: ngày lễ/cuối tuần theo quốc gia (L3), STT (V2, cần máy thật); S5 E1 decoder (`.ics`, `.pkpass`, email JSON-LD, BCBP, xlsx/csv): Dart thuần, làm được không cần tài khoản.

## 2026-11-24 · S3 Reminder engine (offline) · Claude Code
- **Làm:**
  - `core/tz.dart`: giờ tường ↔ UTC qua tzdata (package `timezone`); giờ không tồn tại → giờ hợp lệ kế tiếp, giờ lặp → lần đầu.
  - `data/reminders/`: `ReminderPlanner` (14 ngày, offset/absolute/hoãn, fixed vs floating, cả ngày lúc 09:00, âm lịch, bỏ lần đã Xong, iOS 60 + 1 dự phòng),
    `expandOccurrences` dùng chung với Hôm nay, `ReminderScheduler` (diff với bảng mới `scheduled_notifications`, schema v2 + migration), `NotificationActionHandler`.
  - `ItemsRepository`: reminder (thêm/bỏ/hoãn), lần của chuỗi (xong/bỏ qua/hoàn tác), Hôm nay trải từng lần (theo dõi items + recurrences + occurrence_log).
  - App: `LocalNotificationScheduler` (`flutter_local_notifications` 23), isolate nền cho nút Xong/Hoãn, `ReminderBinding`, mục Nhắc ở màn chi tiết,
    Quick Add mặc định nhắc đúng giờ, thẻ thiếu quyền; Android manifest/desugaring/minSdk 26, AppDelegate, iOS 17; 22 key ARB.
  - CI: job `android-build`, `ios-build` (chạy tay). `tools/check-arb.py` sửa lỗi coi nhánh ICU `=1{Tomorrow}` là placeholder.
- **Quyết định:** Quick Add có thời điểm → mặc định 1 nhắc đúng giờ (reminder-engine §5). Lần lặp đã qua không dồn vào Quá hạn (§4).
  Khóa lần cả ngày = 00:00 theo múi giờ, giờ kêu riêng. Không dùng `USE_EXACT_ALARM` (giữ như §2).
- **Lỗi bắt được nhờ test:** `Mutation.toJson` bỏ payload của lệnh xóa → hoàn tác "Xong" 1 lần lặp bị server từ chối `missing_key` (contract test với Postgres thật);
  tràn layout chip ở 320dp + chữ 1,3x (đã sửa ở lượt trước); `rootBundle` cache Future của zone test cũ.
- **Kiểm chứng:** `flutter analyze` 0; core 39, platform 2, data 31 (+5 contract), parsers 17, client 34 test; pgTAP 109; lint/ARB/pseudo/platform 0 lỗi.
  Chưa chạy trên máy thật (container không có Android SDK/Xcode).
- **Dở dang / tiếp theo:** xem STATE "Việc kỹ thuật còn nợ" mục S3.

## 2026-11-24 · S1/S2 không cần tài khoản: chặn clock, nối DB vào app, NLU en/vi, recurrence + âm lịch · Claude Code
- **Làm:**
  - CI run #9 không tạo job (tên step chứa `: ` làm YAML hỏng) → quote; run #10 xanh cả 3 job.
  - DB migration 08: clock HLC sai định dạng → `invalid/malformed_clock`; clock > now()+1 ngày kẹp về giờ server (`clamped`).
    SyncEngine nhận clock server cho trường bị kẹp, `SyncReport.clockSkewDetected`. pgTAP 007 + contract test máy sai giờ năm 2030.
  - `packages/data`: `ItemsRepository` (tạo/xong/mở lại/đổi tên/ghi chú có `base_clock`/ưu tiên/xóa/lặp), `DayWindow`, `TodaySections`,
    `InstallInfo.deviceId`. SyncEngine báo bảng thay đổi cho stream Drift (trước đó stream không cập nhật sau `customUpdate`).
  - `apps/client`: `drift_flutter`, providers; Hôm nay (Quá hạn/Hôm nay/Chưa đặt giờ/Đã xong, vuốt = Xong + Hoàn tác, 🔁), chi tiết item,
    Quick Add có NLU: chip thời điểm/lặp/tag/ưu tiên, chip "Ý bạn là" khi mơ hồ, nhiều việc → "Lưu tất cả"; múi giờ IANA qua `flutter_timezone` (`lib/platform/`).
  - `packages/parsers`: engine NLU không chứa từ ngữ + gói YAML `en`, `vi` (Bắc/Trung/Nam), bộ câu tổng hợp vi 76 / en 59, eval theo §7.
  - `packages/core`: `CivilDate/Time/DateTime`, âm lịch Hồ Ngọc Đức (+7/+8/+9), `Recurrence` (bọc `rrule`, âm lịch, sau khi hoàn thành).
- **Quyết định:** `device_id` lưu trong DB local thay vì secure storage (Keychain còn sau khi gỡ app, trái "1 lần mỗi lần cài"; multi-platform §2.5).
  Tháng nhuận chỉ `skip | both` (bỏ `first` chưa định nghĩa), ngày 30 tháng thiếu → 29 (reminder-engine §4). Gói NLU là asset của `remindme_parsers`.
- **Kiểm chứng:** `flutter analyze` 0; core 35, platform 2, data 17 (+4 contract với Postgres), parsers 17, client 28 test pass; pgTAP 109 pass.
  Âm lịch khớp Tết 2023-2027, Tết VN/TQ 1985/2007, nhuận 2023/2025, Trung thu, Giỗ Tổ. NLU (bộ tổng hợp, do nhóm viết): vi 100%, en 98,3%, 0 sai nguy hiểm.
- **Dở dang / tiếp theo:** bộ câu thật ≥ 300/gói (cần người dùng 3 miền); Hôm nay chưa trải lần lặp (chỉ hiện ngày bắt đầu: làm ở S3 cùng occurrence/rolling window);
  ngôn ngữ giọng nói riêng (V2); auth/`SupabaseSyncApi` chờ project.

## 2026-11-24 · S1 phần 1: workspace Flutter, core/platform/data, sync engine, app khung · Claude Code
- **Làm:**
  - Cài Flutter 3.50.1 (Dart 3.14) trong container; pub workspace ở gốc (`pubspec.yaml`, `analysis_options.yaml`).
  - `packages/core`: `Hlc`/`HlcClock` (định dạng khớp server, so sánh = thứ tự byte), `uuidV7`, `inboxListId` (khớp `md5(uid||':inbox')::uuid`),
    `resolveDeviceClass` (khớp `app.device_class_of`), `QuotaStatus` (cache 24h, không hard-code giá trị), giao thức `Mutation`/`MutationResult`/`PullPage`/`SyncErrorCode`/`SyncApi`.
  - `packages/platform`: interface `NotificationScheduler`, `OcrEngine`, `SttEngine`, `PurchaseService`... + `PlatformCapabilities.defaultsFor` theo ma trận multi-platform §3.
  - `packages/data`: Drift mirror 8 bảng đồng bộ + outbox/sync_state/sync_issues; `RowCodec` (ISO ↔ epoch ms, JSON ↔ text); `SyncEngine`
    (sửa local + outbox trong 1 transaction, push theo lô 200, pull nhiều trang, merge theo trường bằng HLC, tombstone dây chuyền, ghi quota/notes conflict vào `sync_issues`, `session_revoked` giữ outbox).
    Test: 9 test với server giả + 3 contract test với RPC Postgres thật (hội tụ 2 máy, quota, bị đá phiên).
  - `apps/client`: theme từ token (`RemindColors`), `WindowSize` (600/840), shell thích ứng (NavigationBar / rail / rail mở rộng), 4 tab khung,
    Quick Add (nút + Ctrl/Cmd+N), ARB en/vi theo glossary, pseudo-locale `en_XA` (debug), chuỗi fallback locale, dò nền tảng trong `lib/platform/`.
    14 test widget (3 cỡ màn hình, pseudo-locale + chữ 1,3x không tràn, tiếng Việt, fallback locale, phím tắt).
  - Tools: `check-arb.py`, `pseudo-arb.py` (hiểu ICU plural), `lint-platform-checks.py`. CI: job `flutter`, contract test trong job `db`.
- **Quyết định:** Flutter 3.50 tách Material/Cupertino thành `material_ui`/`cupertino_ui`: dùng delegate của 2 package này (danh sách sinh sẵn của gen-l10n còn trỏ bản cũ, thiếu tiếng Việt).
  File l10n sinh ra không commit (CI chạy `flutter gen-l10n`); `database.g.dart` của Drift có commit. Test package chạy trong từng thư mục (sqlite3 dùng native assets).
- **Kiểm chứng:** `flutter analyze` 0 lỗi; core 19, platform 2, data 9 (+3 contract khi có Postgres), client 14 test pass; `tools/db-test.sh` 102 pass.
- **Dở dang / tiếp theo:** auth, flavors, `SupabaseSyncApi`, nối DB vào UI cần project Supabase/Firebase; xem `docs/STATE.md`.

## 2026-11-24 · Lộ trình app máy tính, chuẩn bị nền tảng để nâng cấp (ADR-014) · Claude Code
- **Làm:** chủ dự án chốt: paywall ghi "máy tính: sắp có"; máy tính có thể là app PC/MacBook. Thêm ADR-014 (một codebase Flutter, macOS + Windows ở Phase 4)
  và `architecture/multi-platform.md` (lộ trình, 6 quy tắc code từ S1, ma trận năng lực theo nền tảng, phát hành desktop).
  Plan: Phase 4 = app máy tính + Family; kế hoạch D (D0-D4, ~26 ngày công); S1 thêm cấu trúc package + `PlatformCapabilities` + layout thích ứng;
  Phase 2 tùy chọn cho app iPad chạy trên Mac. Đổi `apps/mobile` → `apps/client`; AGENTS thêm package `core`/`data`/`platform`.
  Pricing: chuỗi `paywall_devices` có "(sắp có)", bật/tắt bằng remote config `desktop_client_available`. Design system §11 màn hình lớn.
- **Kiểm chứng (tra web 24/11/2026):** `flutter_local_notifications` hỗ trợ Windows từ 19.5 (chưa thấy xác nhận độ chính xác giờ kêu);
  `purchases_flutter` hỗ trợ macOS, không hỗ trợ Windows, có Web Billing; `Windows.Media.Ocr` cần package identity, ngôn ngữ theo language pack.
- **Dở dang / tiếp theo:** chính sách thanh toán Microsoft Store chưa xác minh; xem `docs/STATE.md`.

## 2026-11-24 · Plus đăng nhập nhiều loại thiết bị (ADR-013 sửa đổi 1) · Claude Code
- **Làm:** chủ dự án duyệt: Plus dùng đồng thời điện thoại, tablet, laptop. Migration `20261124000007_plus_multi_device.sql`: entitlement
  `max_devices_per_class` (Free 1, Plus 1) + `max_active_devices` Plus 3; cột `device_class` (web/desktop luôn `computer`, `ipados` luôn `tablet`);
  `app.pick_evictions` (giữ máy mới + máy hoạt động gần nhất); trigger trên `subscriptions` cắt thiết bị khi hạ gói (`end_reason='plan_limit'`);
  `session_status(device_id, platform, device_class)` trả `will_replace` cho màn xác nhận. Test `006_plus_multi_device.sql` (14 test).
- **Quyết định:** Plus = 1 điện thoại + 1 tablet + 1 máy tính; đổi được bằng `plan_entitlements` (`max_devices_per_class = -1` cho nhiều máy cùng loại).
  Free đăng nhập máy thứ 2 thấy paywall `paywall_devices` trong hộp xác nhận.
- **Kiểm chứng:** `tools/db-test.sh` 6 file, 102 test PASS; `check-docs` 0 lỗi.
- **Dở dang / tiếp theo:** "máy tính" cần web app (đang Phase 4): chờ chủ dự án quyết thời điểm; xem `docs/STATE.md`.

## 2026-11-24 · Một tài khoản một thiết bị + lịch sử đăng nhập; sửa CI · Claude Code
- **Làm:**
  - Yêu cầu chủ dự án: đăng nhập máy mới thì máy cũ bị đá, lưu lịch sử đăng nhập. ADR-013 + migration `20261124000006_single_device_sessions.sql`:
    bảng `user_sessions` (theo claim `session_id` của JWT; thiết bị, nền tảng, phiên bản, IP, quốc gia, thời gian, lý do kết thúc), RPC `session_status`,
    `session_claim`, `session_end`; RLS mọi bảng của user + `sync_push`/`sync_pull`/`quota_status` chỉ nhận phiên `active` (bọc hàm cũ, đổi tên `app.*_core`);
    phiên bị đá không claim lại được; xóa `auth.sessions` cũ; entitlement `max_active_devices` = 1/1.
  - Test `005_single_device.sql` (21 test). Tổng 88 test pass.
  - Docs: pricing (key mới), data-model, api-spec (RPC, lỗi 403, push `session.revoked`, job worker), reminder-engine §8 (hủy thông báo khi bị đá),
    UX §3.7 + IA "Tài khoản & thiết bị", PRD US-54, security (phân loại, retention IP 90 ngày/lịch sử 12 tháng), analytics, system-architecture.
  - CI: bước fixtures lỗi vì jsonschema 4.10 của Ubuntu ghép `$id` tương đối hai lần → dùng `$id` tuyệt đối, cố định Python 3.12. Job DB pass trên GitHub.
- **Quyết định:** ADR-013. Vượt giới hạn thì đá phiên `last_seen_at` cũ nhất (không chặn máy mới). Đồng hồ/widget không tính là thiết bị.
- **Kiểm chứng:** `tools/db-test.sh` 5 file, 88 test PASS; validate-fixtures pass với jsonschema 4.10.3 và 4.26.
- **Dở dang / tiếp theo:** worker job `session.notify_revoked`, `cleanup.sessions`; xác nhận quyền xóa `auth.sessions` trên Supabase thật; xem `docs/STATE.md`.

## 2026-11-24 · Phase 0: DB sync có quota, khung repo, bộ mẫu, nghiên cứu global, L0 · Claude Code
- **Làm:**
  - `supabase/migrations/` (5 file): schema theo data-model, khóa ngoại kèm `user_id`, RLS chỉ SELECT + trigger chặn ghi từ role client,
    `version` gán sau khóa advisory theo user (sync_pull không sót hàng do commit muộn), entitlement/quota (`app.usage_for`, `app.rrule_fires_on`),
    RPC `sync_push` (LWW theo `field_clock`, conflict notes qua `base_clock`, tombstone dây chuyền, subtransaction từng mutation, pending_quota → archived/quota),
    `sync_pull`, `quota_status`, `profile_init` (Inbox id xác định), seed gói từ pricing §2.
  - 67 test pgTAP (`supabase/tests/database/`) trên Postgres thuần qua shim Supabase; runner `tools/db-test.sh`.
  - Khung repo: CI, `tools/check-docs.py`, `tools/lint-hardcoded-strings.py`, `tools/validate-fixtures.py`, hook commit-msg, `.editorconfig`.
  - E0.4: `packages/parsers/fixtures/` (cấu trúc, schema meta/expected, quy trình ẩn danh, 1 mẫu tổng hợp).
  - Subagent Trend Researcher: `research/global-market.md`. Subagent i18n: `docs/l10n/` (glossary 258 thuật ngữ, style guide en/vi, README TMS).
  - Sửa docs cho khớp code: data-model (HLC, quy tắc quota thực thi), api-spec (`profile_init`, định dạng kết quả), testing, plan, AGENTS, INDEX.
    Sửa số liệu: giá neo Todoist $6,99/$59,99; TickTick US có gói tháng $4,99.
- **Quyết định:** quota import đếm từ bảng `imports` (không dùng `usage_counters`); Inbox không tính `max_lists`; server chỉ đếm nhắc/ngày xấp xỉ (engine máy chính xác);
  billing_retry/paused mất quyền Plus, grace còn quyền. Đề xuất locale/region/giá **chưa áp**, chờ chủ dự án.
- **Kiểm chứng:** `tools/db-test.sh`: 4 file, 67 test PASS (Postgres 16.15 + pgTAP). Test bắt được lỗi thật: CHECK múi giờ cần quyền execute `app.is_valid_tz`.
  `check-docs`: 0 tham chiếu hỏng. `validate-fixtures`: bắt được email/SĐT chưa che. CI chưa xác nhận chạy trên GitHub (MCP GitHub lỗi kết nối).
  unslop trên `style-guide-en.md`: 1 đề xuất sai (đổi ’ thành ' trong ví dụ về dấu nháy cong), không áp.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`.

## 2026-11-24 · Global từ launch, giọng nói đa vùng, rà soát chồng chéo toàn bộ docs · Claude Code
- **Làm:**
  - Tài liệu mới: `architecture/i18n-l10n.md` (cấp locale A/B/C, CLDR, hệ lịch, RTL, quy trình dịch, cổng chất lượng),
    `architecture/voice-and-text-input.md` (STT theo biến thể vùng, bias, PhoWhisper/Whisper tùy chọn, gói ngữ pháp có từ địa phương Bắc/Trung/Nam),
    `product/analytics-events.md` (danh mục event + consent theo vùng), `engineering/testing-and-release.md` (ma trận thiết bị, tầng test, CI/CD, rollout).
  - Một subagent rà độc lập toàn bộ docs (mâu thuẫn, trùng lặp, tham chiếu hỏng, thiếu sót, giả định chỉ-VN). Đã sửa các phát hiện mức Cao và phần lớn mức TB.
  - Viết lại: data-model (SYNC_COLS + `field_clock`, cascade xóa, bỏ default vi-VN, `recurrences.kind` rrule/calendar/after_completion, `plan_products`,
    trạng thái subscription đầy đủ, `occurrence_log`, `local_files`), pricing (nhóm giá T1/T2/T3, `feature_watch_app` theo cấp, khuyến mãi theo thị trường),
    plan (global ở Phase 1, gantt 43 tuần, auth/entitlement lên S1-S2, nhánh việc E/V/L), PRD (persona global, quy ước P0-P3), api-spec (sync là RPC Postgres, bỏ Gmail server),
    security (pháp lý theo thị trường, bên thứ ba đầy đủ, khóa ký mẫu, xóa/xuất dữ liệu).
  - Sửa: ADR-001/002/004/005/007/008, thêm ADR-011 (global, region, OS tối thiểu, điều kiện xem lại ADR-010) và ADR-012 (đường ghi duy nhất);
    reminder-engine (DST là nguồn chuẩn, nhiều thiết bị, lập lịch lại khi đổi ngôn ngữ); extraction (OCR đa hệ chữ + PP-OCRv5, mẫu theo thị trường);
    integration, UX (tìm kiếm, cài đặt ngôn ngữ & vùng, xung đột ghi chú, bảng lỗi/trống, hỗ trợ), design system (font theo hệ chữ, RTL), competitor (TL;DR, bỏ bảng giá cũ).
  - INDEX thêm cột "Nguồn chuẩn"; AGENTS thêm quy tắc không giả định locale, không chuỗi hard-code, một nguồn chuẩn; CLAUDE.md rút còn import.
- **Quyết định:** ADR-011, ADR-012. Gmail Phase 3 chạy trên máy. Live Activities Phase 3. Feed ICS Phase 2.
- **Kiểm chứng (tra web 24/11/2026):** PhoWhisper (VinAI) huấn luyện trên dữ liệu nhiều giọng vùng, repo Apache-2.0 (model card ghi không thống nhất);
  Android có `EXTRA_BIASING_STRINGS` (API 33), `EXTRA_ENABLE_LANGUAGE_SWITCH` (API 34); iOS có `contextualStrings`, `SFCustomLanguageModelData`;
  ML Kit Text v2 không có Ả Rập/Kirin/Thái nên dùng PP-OCRv5 mobile (~8 MB/hệ chữ); có package Flutter cho whisper.cpp.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`. Chưa sửa các phát hiện mức Thấp như cắt bớt phần nguồn của competitor doc.

## 2026-11-24 · Bỏ AI API trả phí, chuyển trích xuất sang chạy trên máy · Claude Code
- **Làm:**
  - Viết `docs/architecture/on-device-extraction.md`, thay cho `ai-ingestion.md` (đã xóa). Thiết kế 5 tầng: decoder, OCR của OS,
    luật + mẫu nhà cung cấp, LLM của OS tùy chọn, model tải về để thử nghiệm.
  - Thêm ADR-010 (supersedes ADR-004). Cập nhật cho thống nhất: AGENTS, system-architecture, data-model (bỏ cột chi phí AI,
    thêm `mailbox_messages`), api-spec (bỏ endpoint import/parse, thêm mailbox + CDN mẫu), pricing (`smart_imports_per_month`,
    giọng nói không giới hạn, kinh tế đơn vị = 0 chi phí theo lượt), integration-guide, PRD, UX, security (bỏ Anthropic khỏi bên thứ ba), plan.
  - Kế hoạch chi tiết E0-E8 kèm ngày công và AC; tổng MVP ~54 ngày công.
- **Quyết định:** ADR-010. Email forward: server chỉ lưu MIME (TTL 7 ngày), máy tự phân tích. Mẫu nhà cung cấp là JSON có chữ ký, cập nhật qua CDN.
- **Kiểm chứng (tra web 24/11/2026):** Foundation Models có tiếng Việt từ iOS 26.1, iOS 27 nhận ảnh; ML Kit Text v2 có tiếng Việt;
  Gemini Nano Prompt API chỉ chạy trên một số flagship, đang alpha/beta; Vision iOS tiếng Việt và STT on-device tiếng Việt chưa xác nhận được, phải test trên máy thật (E0).
- **Dở dang / tiếp theo:** Spike E0, thu mẫu thật. Kiểm tra lại yêu cầu CASA khi Gmail chỉ xử lý trên máy.

## 2026-11-24 · Khởi tạo bộ tài liệu Phase 0 · Claude Code
- **Làm:**
  - Viết bộ tài liệu hệ thống, UI/UX, sản phẩm, tích hợp, kế hoạch (17 file trong `docs/`).
  - Nghiên cứu đối thủ bằng 1 subagent (persona Trend Researcher): `docs/research/competitor-analysis.md`.
  - Dựng context phân tầng cho AI: `AGENTS.md` (Codex) + `CLAUDE.md` (import AGENTS + STATE).
  - Cài và thử graphify 0.9.118 + unslop 0.7.0; viết script wrapper trong `tools/`.
- **Quyết định:**
  - Stack: Flutter + watch native, Supabase + worker TS, offline-first, Claude API phía server (**đã thay bởi ADR-010**), RevenueCat (ADR-001..009).
  - (Ghi chú sau: thị trường "VN trước" đã thay bởi global từ launch, ADR-011; giới hạn/giá dưới đây đã chỉnh, xem pricing.)
  - Giá đề xuất 59.000đ/tháng, 149.000đ/quý, 449.000đ/năm.
  - Free: 10 nhắc/ngày, 5 chuỗi lặp, 10 lịch hẹn đang hoạt động (gồm booking), 1 chuyến đi, 10 import AI/tháng.
  - Email forward trước, Gmail API sau (tránh CASA sớm). Import Microsoft To Do vào MVP, vì app To Do ngừng 30/06/2027 (đã kiểm chứng qua nhiều nguồn tin 11/2026).
- **Kiểm chứng:**
  - `graphify update .`: 193 node, 174 cạnh, 20 cộng đồng. `graphify benchmark`: ~877 token/query so với ~12,9k token đọc thô (giảm 14,7 lần).
  - `query` và `section` chạy được sau khi thêm `anyio` vào requirements.
  - unslop `--diff` trên toàn bộ docs: 0 AI-ism. Hai sửa đổi nó đề xuất là sai ("iOS" thành "IOS", "watchOS" thành "WatchOS"), nên script để mặc định chỉ hiện diff.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`. Các con số giá/giới hạn và thời gian chờ duyệt store/OAuth là ước lượng, cần xác minh.
