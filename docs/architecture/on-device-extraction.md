# Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình

> TL;DR: **Không gọi AI API trả phí.** Mọi việc đọc file chạy trên máy người dùng bằng code (decoder, OCR của OS/ML Kit,
> luật + mẫu theo nhà cung cấp). LLM có sẵn trong OS (Apple Foundation Models, Gemini Nano) chỉ là lớp **tùy chọn** khi máy hỗ trợ.
> Spam import chỉ tốn pin máy của chính người spam, không tốn tiền server. Kết quả luôn qua màn Xem lại.
> Đa ngôn ngữ: từ khóa phân loại, từ điển cột, extractor ngày giờ dùng **gói ngôn ngữ** chung với NLU (`voice-and-text-input.md` §5);
> mẫu nhà cung cấp theo thị trường. Giọng nói và Quick Add: `voice-and-text-input.md`. Nguồn chuẩn cho giới hạn email (§8), eval (§11), hiệu năng (§12).

## 1. Kiến trúc 5 tầng

```mermaid
flowchart TD
  IN["Đầu vào: ảnh · camera · pdf · xlsx/csv · md · eml · ics · pkpass · giọng nói · text"] --> T0
  T0["T0 Decoder định dạng (Dart thuần)\npkpass, ics, JSON-LD, MIME, xlsx, md, pdf text layer, barcode BCBP"] --> T2
  IN -->|ảnh / pdf scan| T1["T1 OCR của OS\niOS: Vision · Android: ML Kit Text v2\n(+ document scanner, barcode)"]
  T1 --> T2["T2 Bộ máy luật (Dart, packages/parsers)\nphân loại tài liệu → mẫu nhà cung cấp → extractor chung → kiểm tra logic"]
  T2 -->|đủ tin cậy| R["Màn Xem lại → lưu"]
  T2 -->|thiếu trường / chưa biết loại| T3["T3 LLM của OS (nếu máy có)\nApple Foundation Models · Gemini Nano Prompt API"]
  T3 --> V["Validator dùng chung với T2"] --> R
  T2 -.->|thử nghiệm Phase 3| T4["T4 Model mở tải về (tùy chọn)\nGemma qua LiteRT-LM"] -.-> V
```

| Tầng | Chạy ở đâu | Chi phí server | Máy hỗ trợ | Vai trò |
|---|---|---|---|---|
| T0 Decoder | Dart isolate | 0 | 100% | Định dạng có cấu trúc: chính xác gần như tuyệt đối |
| T1 OCR | Native (Vision / ML Kit; model bổ sung theo hệ chữ) | 0 | 100% máy đạt OS tối thiểu (ADR-011) | Ảnh/PDF scan thành chữ + tọa độ |
| T2 Luật + mẫu | Dart isolate | 0 (mẫu tải từ CDN tĩnh) | 100% | **Nguồn độ chính xác chính.** Phải tự đứng vững không cần T3 |
| T3 LLM của OS | Native | 0 | Thiểu số: iPhone có Apple Intelligence; Android flagship có Gemini Nano | Lấp trường thiếu, phân loại tài liệu lạ |
| T4 Model tải về | Native (LiteRT-LM) | 0 (CDN tải model 1 lần) | Máy RAM ≥ 8 GB, người dùng đồng ý tải | Thử nghiệm, chỉ làm nếu eval chứng minh lợi ích |

## 2. T0: Decoder định dạng (Dart thuần, `packages/parsers`)
| Định dạng | Thư viện / cách làm | Lấy được gì |
|---|---|---|
| `.pkpass` (Apple Wallet) | `archive` giải zip, đọc `pass.json` | boardingPass/eventTicket: giờ, cổng, ghế, mã vạch, relevantDate |
| `.ics` | Parser iCalendar tự viết (~300 dòng) hoặc package | VEVENT/VTODO, RRULE, VALARM |
| Email `.eml` / MIME | Tự viết (ADR-015): multipart, base64, quoted-printable, RFC 2047/2231; HTML → chữ bằng regex | Text, HTML, file đính kèm (pdf, ics, pkpass, ảnh) |
| JSON-LD / Microdata trong HTML email | Tìm `<script type="application/ld+json">`, map schema.org `FlightReservation`, `LodgingReservation`, `TrainReservation`, `BusReservation`, `EventReservation`, `FoodEstablishmentReservation` | Gần như đủ trường, **không phụ thuộc ngôn ngữ**. Nhiều hãng bay, OTA và nhà ga quốc tế nhúng sẵn; hãng nội địa từng nước cần kiểm tra mẫu thật |
| PDF có text layer | `pdfrx` (PDFium) lấy text + tọa độ từng ký tự | Text có bố cục, dùng chung bộ máy T2 như OCR |
| PDF scan | Render trang → ảnh (`pdfrx`) → T1 | |
| xlsx / csv | Tự viết (ADR-015): `archive` + `xml` cho xlsx, RFC 4180 cho csv | Bảng → mục 6 |
| Markdown | Tự viết theo dòng (ADR-015) + regex Obsidian Tasks | Mục 7 |
| Barcode boarding pass | ML Kit Barcode (Android/iOS, offline) hoặc Vision `DetectBarcodesRequest`; parser **IATA BCBP (Resolution 792)** | Tên, PNR, sân bay đi/đến, hãng, số chuyến, ngày (Julian), hạng, ghế. Chính xác 100% nếu quét được |
| QR khác | Phân loại theo tiền tố: URL (mở/đọc tham số booking id), VietQR (bỏ qua: là mã thanh toán), text | |

**Đã có (S5 kéo sớm):** `packages/parsers/lib/src/decoders/` (`ics.dart`, `bcbp.dart`, `jsonld.dart`, `pkpass.dart`, `mime.dart` + `email.dart`,
`table.dart`, `markdown.dart`; `lib/src/extract/table_tasks.dart`) trả `Candidate`
(`lib/src/extract/candidate.dart`, cùng dạng `fixtures/schema/expected.schema.json`); harness `lib/src/extract/eval.dart` + `test/extract_eval_test.dart`
chấm mọi mẫu trong `fixtures/docs/` (loại chưa có tầng xử lý thì bỏ qua). Giờ giữ như in trên vé + offset nếu nguồn có; `tz` IANA suy sau theo sân bay/ga (T2).
Tên hành khách trong BCBP/JSON-LD không được lấy ra. `EmailDecoder` chuyển HTML sang JSON-LD, `.ics`/`text/calendar`, `.pkpass`, email lồng `message/rfc822`;
đặt chỗ trùng giữa JSON-LD và `.ics` chỉ giữ 1; PDF, ảnh, xlsx đính kèm trả về `pending` cho tầng sau; logo nhúng (`Content-ID`) bị bỏ. Chưa có: PDF.

**Trong app (bản đầu của E5):** Tôi → Nhập từ tệp (`apps/client/lib/features/import/`): `file_picker` → `detectFormat` (đuôi, rồi nội dung)
→ `decodeImport` trong `Isolate.run` → màn Xem lại (chọn/bỏ, sửa tên, chọn thứ tự ngày và trang tính của bảng) → `ImportsRepository.commit`
(1 hàng `imports` + item có `import_id`; list theo tên khớp không dấu hoặc tạo mới; checklist, địa điểm, đã xong, lặp, nhắc đúng giờ hoặc theo VALARM).
Đặt chỗ lưu thành sự kiện (tên mặc định `ZZ 245 · SGN → HAN`, mã đặt chỗ vào ghi chú) tới khi có chuyến đi. Giờ chỉ có offset: dùng múi giờ máy nếu trùng,
không thì `Etc/GMT∓h`. `.csv` tính là `xlsx` trong `imports.kind`/`items.source`. Chưa có: chia sẻ vào app (share intent/extension), đổi cột ở màn xem trước
và nhớ mapping (E5.3), hiển thị hạn mức (chưa có `quota_status` khi offline; `commit` đã nhận `QuotaStatus` để đánh `pending_quota`).

## 3. T1: OCR trên thiết bị
| Nền tảng | Engine | Hệ chữ |
|---|---|---|
| Android | **ML Kit Text Recognition v2** (unbundled qua Google Play services; bundled cho máy không có GMS) | Latin (gồm tiếng Việt), Chinese, Japanese, Korean, Devanagari |
| iOS | **Vision** `VNRecognizeTextRequest` (iOS 17), `RecognizeTextRequest` (iOS 18+), `RecognizeDocumentsRequest` (iOS 26+, nhận bảng/đoạn) | Danh sách đọc lúc chạy (`supportedRecognitionLanguages`); tiếng Việt **chưa xác minh**, nếu thiếu thì dùng ML Kit trên iOS |
| Cả hai (bổ sung) | **PP-OCRv5 mobile** (Apache-2.0, ~8 MB mỗi hệ chữ, chạy qua ONNX Runtime/MNN), tải theo nhu cầu | Ả Rập, Kirin (ru/uk/bg/sr), Thái, Hy Lạp; dùng từ đợt locale 2-3 |
| Chụp giấy | Android **ML Kit Document Scanner**, iOS **VisionKit** `VNDocumentCameraViewController` | |
- Chọn model OCR theo hệ chữ của ngôn ngữ người dùng + ngôn ngữ tài liệu đoán được; tối đa 2 lượt OCR mỗi ảnh.
- Thiết kế interface `OcrEngine` trả `OcrDocument{pages[{blocks[{lines[{text, bbox, conf}]}]}]}` để thay engine không đổi T2.
- Tiền xử lý: thu ảnh về cạnh dài 2000px, xoay theo EXIF; ảnh chụp màn hình giữ nguyên độ phân giải.
- Hậu xử lý: chuẩn hóa Unicode NFC; so khớp từ khóa theo dạng **gấp dấu + chữ thường theo locale** (lưu ý "i" tiếng Thổ Nhĩ Kỳ) và
  Levenshtein ≤ 1 cho hệ chữ có dấu cách ("Gio khoi hanh" khớp "Giờ khởi hành", "Abfahrt" khớp "Abfahrf"); CJK/Thái so khớp chuỗi con.
- Tất cả chạy trong isolate/background thread, UI hiện tiến trình.

## 4. T2: Bộ máy luật (trái tim của hệ thống)
### 4.1 Phân loại tài liệu
Chấm điểm theo từ khóa có trọng số. Từ khóa nằm trong **gói ngôn ngữ** (`packs/<lang>/classifier.json`), trọng số dev huấn luyện offline từ bộ mẫu;
app chạy gói của ngôn ngữ người dùng + ngôn ngữ đoán được của tài liệu. Ví dụ tín hiệu (vi/en; các ngôn ngữ khác tương tự trong gói):
| Loại | Tín hiệu mạnh |
|---|---|
| `flight` | "chuyến bay", "boarding pass", "thẻ lên tàu bay", "PNR", "mã đặt chỗ", cặp mã IATA (SGN, HAN, DAD...), mã hãng + số (VN245, VJ123) |
| `train` | "tàu", "toa", "ga", mã tàu SE/TN/SP/SNT, "giường", "khoang", "Đường sắt" |
| `bus` | "xe khách", "nhà xe", "bến xe", "điểm đón", "ghế/giường số", "limousine" |
| `hotel` | "nhận phòng", "trả phòng", "check-in", "check-out", "đêm", "loại phòng", "khách sạn", "resort" |
| `medical` | "bệnh viện", "phòng khám", "phiếu hẹn", "tái khám", "số thứ tự", "BS.", "khoa", "nhịn ăn" |
| `event` | "vé", "suất chiếu", "sự kiện", "khu vực", "cổng vào" |
| `todo_list` | Nhiều dòng dạng gạch đầu dòng/ô vuông, cột ngày/việc |

### 4.2 Mẫu theo nhà cung cấp (provider templates)
Mẫu dạng JSON khai báo, không phải code, nên **cập nhật qua CDN mà không cần phát hành app**:
```jsonc
{
  "id": "vietjet.eticket.v2", "doc_type": "flight", "version": 3,
  "match": { "any_text": ["VIETJET", "VJ\\d{2,4}"], "sender_domains": ["vietjetair.com"], "min_score": 2 },
  "fields": {
    "confirmation_code": { "anchors": ["Mã đặt chỗ", "Reservation code", "Booking code"], "dir": "right|below", "pattern": "[A-Z0-9]{6}" },
    "flight_number":     { "pattern": "\\bVJ\\s?\\d{2,4}\\b" },
    "departure_date":    { "anchors": ["Ngày bay", "Date"], "dir": "right|below", "type": "date_vi" },
    "departure_time":    { "anchors": ["Giờ khởi hành", "Departure"], "dir": "right|below", "type": "time" },
    "origin":            { "type": "iata", "nth": 1 },
    "destination":       { "type": "iata", "nth": 2 },
    "passengers":        { "anchors": ["Hành khách", "Passenger"], "dir": "below", "repeat": true, "type": "person_name" }
  },
  "repeat_block": { "start": ["Chuyến đi", "Chuyến về", "Flight"], "as": "segments" }
}
```
- Engine đọc mẫu: tìm anchor (so khớp mờ), lấy vùng bên phải/bên dưới theo bbox, áp `pattern`/`type`, chấm confidence.
- Kho mẫu: `packages/parsers/templates/*.json` + test fixtures. Ký số (Ed25519) khi phát hành lên CDN; app chỉ nhận mẫu có chữ ký hợp lệ.
- **Danh sách ứng viên** theo thị trường (đợt 1 chọn 12 mẫu, xem `plan/implementation-plan.md` E4.3; cần mẫu thật để xác nhận định dạng):
  | Thị trường | Bay | Tàu/xe | Lưu trú / OTA | Khám bệnh / sự kiện |
  |---|---|---|---|---|
  | Global | (boarding pass BCBP mọi hãng; email JSON-LD) | FlixBus, Trainline | Booking.com, Expedia/Hotels.com, Airbnb, Agoda, Trip.com | Ticketmaster, Eventbrite |
  | VN | Vietnam Airlines, Vietjet, Bamboo, Vietravel, Sun PhuQuoc | Đường sắt VN, FUTA, Vexere | Traveloka | Medpro, YouMed, phiếu hẹn giấy; Ticketbox |
  | EU | (BCBP, JSON-LD) | Deutsche Bahn, SNCF Connect, Eurostar, Trenitalia | | Doctolib (thường kèm .ics) |
  | US | (BCBP, JSON-LD) | Amtrak, Greyhound | | Zocdoc (thường kèm .ics) |
  | JP / KR | ANA, JAL / Korean Air | JR (smartEX), Korail | Rakuten Travel, Jalan / Yanolja | |
  | IN / ID / TH / BR / MX | IndiGo / Garuda, Lion / AirAsia / LATAM, Azul / Aeroméxico, Volaris | IRCTC, redBus / KAI / ADO | MakeMyTrip / Traveloka / Despegar | |

### 4.3 Extractor chung (khi không khớp mẫu nào)
| Trường | Cách làm |
|---|---|
| Ngày/giờ | Dùng gói ngôn ngữ chung với NLU: `20/12/2026`, `12/20/2026` (theo ngôn ngữ/nhà cung cấp tài liệu), `Thứ Hai, 20 tháng 12`, `Dec 20, 2026`, `20. Dezember 2026`, `2026年12月20日`, `10:30`, `10h30`, `10:30 PM`, khoảng `14:00 - 15:30` |
| Sân bay | Từ điển IATA đầy đủ (OurAirports) + tên thành phố theo nhiều ngôn ngữ → tz |
| Số chuyến bay | `\b(VN|VJ|QH|VU|9G|BL|...)\s?\d{2,4}\b` (danh sách mã hãng IATA) |
| PNR | 6 ký tự `[A-Z0-9]` gần anchor "mã đặt chỗ/PNR/booking"; loại từ tiếng Anh thường gặp |
| Ghế/toa | `\b\d{1,2}[A-K]\b`, "Toa \d+", "Ghế|Giường \d+" |
| Mã tàu | `\b(SE|TN|SP|SNT|SPT|SQN)\d{1,2}\b` |
| Địa chỉ, SĐT | SĐT: `phone_numbers_parser` (dữ liệu libphonenumber) với vùng mặc định theo tài liệu/người dùng; địa chỉ: giữ nguyên khối văn bản sau anchor; iOS thêm `NSDataDetector` (address, phoneNumber, transitInformation) làm tín hiệu phụ |
| Số tiền | Ký hiệu/mã ISO 4217 + dấu phân cách theo locale tài liệu (`1.890.000 ₫`, `€1.234,50`, `$1,234.50`, `¥12,000`) |
| Tiêu đề | Ghép theo loại: "Bay SGN → HAN (VJ123)", "Nhận phòng Mường Thanh", "Tái khám BV Chợ Rẫy" |

### 4.4 Kiểm tra logic và confidence
- Confidence theo nguồn: khớp mẫu + pattern 0,95 · anchor + pattern 0,8 · chỉ pattern 0,6 · suy luận mặc định 0,4.
- Kiểm tra: giờ đến < giờ đi khi không qua đêm; ngày quá khứ (cảnh báo, không chặn); năm thiếu thì lấy lần gần nhất trong tương lai;
  check-in/check-out khách sạn thiếu giờ thì dùng 14:00/12:00; mã IATA đi = đến thì loại.
- Dedupe với dữ liệu sẵn có: `(confirmation_code, starts_at)` hoặc hash file. Trùng thì đề xuất **cập nhật** (đổi giờ bay).
- Gom trip, nhắc mặc định: như `reminder-engine.md` mục 5.

### 4.5 Học từ người dùng mà không cần AI
- **Nhớ mapping**: người dùng sửa cột xlsx hoặc chọn đúng loại tài liệu thì lưu theo "chữ ký" (hash header / tập anchor), lần sau tự áp dụng.
- **Telemetry ẩn danh** (opt-in): `{doc_type, template_id, template_version, fields_found[], fields_edited[], tier_used}`, không có giá trị trường.
  Dashboard chỉ ra mẫu nào hay sai, loại tài liệu nào chưa có mẫu.
- **"Gửi mẫu để cải thiện"** (opt-in từng lần): app tự che dữ liệu cá nhân (thay chữ/số bằng `X`/`9`, giữ bố cục và từ khóa) rồi gửi bản đã che.
  Dev viết mẫu mới. Ở bước này dev có thể dùng AI coding assistant để viết mẫu: chi phí AI chỉ nằm ở khâu phát triển, không theo đầu người dùng.

## 5. T3: LLM có sẵn trong hệ điều hành (tùy chọn)
| | Apple Foundation Models | Gemini Nano (ML Kit GenAI Prompt API) |
|---|---|---|
| Yêu cầu | iOS 26+, máy có Apple Intelligence (iPhone 15 Pro trở lên), Apple Intelligence đang bật, ngôn ngữ hệ thống được hỗ trợ (tiếng Việt từ iOS 26.1) | Android có AICore + Gemini Nano: Pixel 9/10, Galaxy S25/S26 và một số flagship Xiaomi/vivo/OPPO/Honor (danh sách thay đổi, kiểm tra runtime) |
| Đầu vào | Text (iOS 26); ảnh + text (iOS 27 multimodal) | Text (+ ảnh trên một số máy/phiên bản: kiểm tra) |
| Xuất có cấu trúc | `@Generable` guided generation, trả về struct Swift | JSON theo prompt, phải validate |
| Hạn chế | Context nhỏ (vài nghìn token) nên cắt theo trang/khối | Alpha/beta; chỉ chạy khi app ở foreground; có thể trả lỗi busy |
| Chất lượng tiếng Việt | Cần đo bằng eval | Chưa xác minh, cần đo |

Quy tắc dùng:
1. Chỉ gọi khi T2 không khớp mẫu và còn trường bắt buộc thiếu, hoặc chưa phân loại được tài liệu.
2. Input là text OCR đã cắt gọn (hoặc ảnh trên iOS 27), prompt cố định nằm trong app, đầu ra theo schema `ExtractionResult`.
3. Kết quả qua **cùng validator** với T2, confidence tối đa 0,75, **không bao giờ ghi đè** trường đã khớp mẫu.
4. Kiểm tra khả dụng lúc chạy (`SystemLanguageModel.default.availability` / `checkFeatureStatus`), không có thì bỏ qua và không báo lỗi.
5. Hiển thị "Đọc bằng AI trên máy" để người dùng biết dữ liệu không rời khỏi điện thoại.

## 6. xlsx / csv → danh sách việc
1. Tìm dòng header trong 10 dòng đầu (dòng có nhiều ô text khớp từ điển đồng nghĩa nhất).
2. Từ điển cột nằm trong gói ngôn ngữ (mục `table:` của `nlu/packs/<lang>.yaml`, định dạng ở `packages/parsers/nlu/packs/README.md`), ví dụ vi/en: **Việc** (Công việc, Nội dung, Tiêu đề, Task) · **Ngày** (Ngày, Hạn, Deadline, Due) ·
   **Giờ** (Giờ, Time) · **Ghi chú** (Note, Mô tả) · **Ưu tiên** (Priority) · **Trạng thái** (Status) · **Địa điểm** · **Người phụ trách**. Thử mọi gói cấp A/B, chọn gói khớp nhiều cột nhất.
3. Không có header thì suy theo kiểu dữ liệu 20 dòng mẫu: cột phần lớn là ngày → Ngày; cột chuỗi dài nhất → Việc.
4. Ô ngày kiểu số serial Excel, chuỗi `dd/mm/yyyy`, ô datetime đều được hỗ trợ. Nhiều sheet thì người dùng chọn sheet.
5. Màn xem trước 10 dòng + dropdown đổi mapping; lưu mapping theo hash header (mục 4.5).
6. Hiệu năng: 5.000 dòng < 3 giây trên máy tầm trung (parse trong isolate).
7. Thứ tự ngày `03/04`: ô có phần > 12 quyết định cho cả cột; không có thì theo vùng người dùng (gói), vẫn không biết thì màn xem trước hỏi (`dateOrderAmbiguous`).
   Ô ngày dạng chữ ("thứ 6 tuần sau") và tên việc có thời điểm khi bảng không có cột ngày chạy qua NLU của gói.

**Đã có:** `CsvReader`, `XlsxReader` (`decoders/table.dart`), `TableTaskExtractor.detect` → `TableMapping` (sửa được ở màn xem trước) → `extract`.
Đo trong container (JIT): xlsx 5.000 dòng 0,57 s, csv 5.000 dòng 0,05 s; máy thật đo ở spike. Cột `assignee` chỉ để không nhầm làm tên việc, chưa nhập giá trị.

## 7. Markdown
- `- [ ] việc` / `- [x] việc` → task (open/done); `#`/`##` heading → list; thụt lề → checklist con.
- Cú pháp Obsidian Tasks: `📅 2026-12-01` (hạn), `⏳` (scheduled), `🛫` (start), `⏰ 08:00`, `🔁 every week`, `⏫/🔼/🔽` (ưu tiên).
- Front-matter YAML `due:`, `tags:`. Câu tự nhiên trong dòng ("họp lúc 3h chiều mai") chạy qua parser ngày giờ tiếng Việt.
- **Đã có:** `MarkdownDecoder` (`decoders/markdown.dart`): thêm dạng Dataview `[due:: ...]`, `[-]` = đã hủy (bỏ), `✅` = đã xong, không có ô checkbox nào
  thì mọi gạch đầu dòng là việc, bỏ khối code. `🔁` → RRULE qua `obsidianRecurrenceToRrule`; không hiểu thì giữ nguyên văn trong ghi chú. "when done" chưa hỗ trợ.

## 8. Email chuyển tiếp: server chỉ là hộp thư
1. Email tới `u-<token>@in.remindme.app` → webhook → server **chỉ lưu MIME đã mã hóa** (TTL 7 ngày) và gửi push `inbox.new`.
2. Điện thoại tải MIME về, chạy đúng pipeline T0 → T1 (ảnh/pdf đính kèm) → T2 → (T3), tạo đề xuất trong Hộp đề xuất.
3. Server không phân tích nội dung, nên không tốn CPU/AI và ít dữ liệu nhạy cảm nằm trên server hơn.
4. Chống lạm dụng: tối đa 30 email/ngày/user, 10 MB/email, 50 MB tổng mỗi hộp thư (cũ nhất bị xóa trước), bỏ đính kèm > 5 MB
   (trừ PDF), kiểm SPF/DKIM; email từ người gửi lạ chỉ thành đề xuất.

## 9. Giọng nói
Chuyển sang `voice-and-text-input.md` (STT theo vùng, bias, model tải về, đánh giá theo giọng).

## 10. Quick Add bằng chữ
Chuyển sang `voice-and-text-input.md` §5 (gói ngữ pháp theo ngôn ngữ, từ địa phương, câu pha 2 ngôn ngữ).

## 11. Đánh giá chất lượng (eval) không cần thiết bị trong CI
1. Phase 0 thu ≥ 300 mẫu ẩn danh (≥ 20 nhà cung cấp, ≥ 3 thị trường, cả ảnh chụp màn hình, ảnh chụp giấy, PDF, email). Mỗi thị trường đợt sau
   thêm ≥ 100 mẫu trước khi bật cấp A. Báo cáo eval tách theo thị trường và ngôn ngữ tài liệu.
2. Chạy OCR **một lần** trên máy thật (ML Kit Android, Vision iOS), lưu kết quả `ocr.json` vào `packages/parsers/fixtures/docs/<id>/`
   cùng `expected.json`. CI chỉ chạy T2 trên `ocr.json` (`dart test`), nhanh và lặp lại được.
3. Chỉ số: độ chính xác từng trường bắt buộc, tỷ lệ "điền sai" (có giá trị nhưng sai, tệ hơn bỏ trống), % tài liệu khớp mẫu,
   thời gian xử lý trên máy chuẩn.
4. Mục tiêu MVP: nhà cung cấp có mẫu ≥ 95% trường bắt buộc đúng; tài liệu lạ ≥ 60% (còn lại người dùng tự điền ở màn Xem lại);
   tỷ lệ điền sai ≤ 2%.
5. Chặn merge nếu bất kỳ mẫu nào giảm chất lượng.
6. T3 có eval riêng chạy tay trên máy hỗ trợ trước mỗi lần đổi prompt.

## 12. Hiệu năng và kích thước app
| Việc | Mục tiêu (máy Android tầm trung 2022) |
|---|---|
| OCR 1 ảnh chụp màn hình | < 1,5 s |
| Toàn pipeline 1 ảnh (T0-T2) | p95 < 4 s |
| PDF 20 trang có text | < 3 s; PDF scan 20 trang < 30 s (hiện tiến trình từng trang) |
| xlsx 5.000 dòng | < 3 s |
| Tăng kích thước app | Android ≈ +1 MB (ML Kit unbundled); iOS: 0 nếu dùng Vision, ≈ +10 MB nếu nhúng ML Kit |

## 13. Thư viện dự kiến
Danh sách chung: `integration-guide.md` §13. Riêng phần này: ML Kit (text, barcode, document scanner), `pdfrx`,
`archive`, `xml` (MIME, csv/xlsx, Markdown tự viết: ADR-015), `phone_numbers_parser`, ONNX Runtime (PP-OCRv5); native plugin `RemindExtractKit` (Swift) và Kotlin plugin.

## 14. Rủi ro
| Rủi ro | Giảm thiểu |
|---|---|
| Mẫu lạ đọc kém hơn hẳn so với LLM đám mây | Màn Xem lại tốt (sửa nhanh); ưu tiên mẫu cho top nhà cung cấp; T3 trên máy hỗ trợ; vòng "Gửi mẫu" |
| Nhà cung cấp đổi bố cục vé, mẫu hỏng | Telemetry phát hiện trường bị sửa tăng đột biến; cập nhật mẫu qua CDN trong ngày |
| Vision iOS đọc kém một hệ chữ (ví dụ tiếng Việt) | Kiểm tra Phase 0 (E0.2); fallback ML Kit trên iOS |
| Thị trường mới chưa có mẫu | JSON-LD/BCBP/ics/pkpass không phụ thuộc ngôn ngữ; extractor chung; điều kiện xem lại ở ADR-011 |
| Công sức viết mẫu lớn | 1 dev phụ trách mẫu liên tục sau launch; công cụ thử mẫu (`packages/parsers/tool/template_lab.dart`) |
| T3 không ổn định (alpha, thay đổi API) | Tầng tùy chọn, tắt bằng remote config, không ảnh hưởng luồng chính |
