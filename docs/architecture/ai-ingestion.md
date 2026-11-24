# AI ingestion: giọng nói, ảnh, xlsx, pdf, md, email → todo / lịch trình

> TL;DR: Mọi đầu vào đi qua 3 tầng: (1) parse deterministic rẻ, (2) LLM Claude với JSON schema,
> (3) chuẩn hóa + dedupe + màn Xem lại. Không tạo item nào khi chưa qua bước người dùng xác nhận,
> trừ câu nhập nhanh có độ tin cậy cao.
> Persona: *AI Engineer*, *Voice AI Integration Engineer*, *PDF Engine Architect* (Agency).

## 1. Ma trận đầu vào

| Đầu vào | Tầng 1 (deterministic) | Tầng 2 (LLM) khi nào | Ghi chú |
|---|---|---|---|
| Gõ tay câu tự nhiên | `QuickParser` Dart: ngày giờ tiếng Việt/Anh, lặp, ưu tiên `!!`, `#tag`, `@list` | confidence < 0,8 và online | Offline vẫn chạy tầng 1 |
| Giọng nói | STT on-device (`speech_to_text`, vi-VN/en-US), rồi như gõ tay | Như trên; câu dài nhiều việc ("mai làm A, B, chiều C") | Cloud STT là tùy chọn Phase 2 nếu on-device kém |
| Ảnh (vé, booking, giấy hẹn, ảnh chụp bảng) | Đọc QR/barcode trước (ML Kit): boarding pass BCBP (IATA Resolution 792) parse ra PNR, chuyến, ghế, ngày | Luôn, nếu không có barcode hoặc thiếu trường | Gửi ảnh nén (cạnh dài 1600px, JPEG q80) |
| PDF | Trích text layer (pdf.js/pdfium phía worker); tìm JSON-LD/`.ics` đính kèm | Có text: gửi text. Scan không text: gửi PDF dạng `document` block | Giới hạn 20 trang cho Free |
| xlsx/csv | Parse bằng SheetJS; nhận diện cột theo header (Ngày, Giờ, Việc, Người phụ trách, Deadline...) | Header lạ: gửi 30 dòng đầu + header để LLM trả **mapping cột**, sau đó áp mapping deterministic cho toàn bộ file | Không gửi cả file lớn cho LLM |
| Markdown (.md, Obsidian) | `- [ ] việc` → task; `## Heading` → list; `📅 2026-12-01`, `⏰`, `🔁 every week` (cú pháp Obsidian Tasks); front-matter `due:` | Chỉ khi có đoạn văn tự do người dùng chọn "Trích việc" | |
| Email forward / Gmail | JSON-LD schema.org (`FlightReservation`, `LodgingReservation`, `TrainReservation`, `BusReservation`, `EventReservation`) mà nhiều hãng nhúng sẵn; file `.ics`, `.pkpass` đính kèm | Không có markup: gửi text email đã làm sạch (bỏ footer, quảng cáo) | Nhiều email booking VN (Vietjet, Bamboo, VNR, Agoda VN) cần kiểm tra thực tế xem có JSON-LD không |
| `.ics` | Parse VEVENT/VTODO | Không | |
| `.pkpass` (Apple Wallet) | Giải nén, đọc `pass.json` (boardingPass, eventTicket) | Không | |

## 2. Schema trích xuất (rút gọn)
Dùng `output_config.format` JSON schema (structured outputs). Mỗi trường có `confidence` 0..1.

```jsonc
// ExtractionResult
{
  "doc_type": "flight|train|bus|hotel|car_rental|tour|medical|event|todo_list|other",
  "language": "vi|en|...",
  "items": [{
    "kind": "booking|appointment|event|task",
    "title": "Bay Hà Nội - TP.HCM",
    "starts_local": "2026-12-20T10:30", "starts_tz_hint": "SGN",   // giờ địa phương + gợi ý tz (IATA/thành phố)
    "ends_local": "2026-12-20T12:40",   "ends_tz_hint": "HAN",
    "all_day": false,
    "location": {"name": "...", "address": "..."},
    "booking": {
      "booking_type": "flight", "provider": "Vietnam Airlines", "confirmation_code": "ABC123",
      "carrier_code": "VN", "number": "245",
      "origin": {"code": "SGN", "terminal": "T1"}, "destination": {"code": "HAN"},
      "passengers": [{"name": "NGUYEN VAN A"}], "seat": "12A",
      "check_in_at_local": null, "check_out_at_local": null,
      "price": {"amount": 1890000, "currency": "VND"}
    },
    "checklist": ["Mang CCCD", "Nhịn ăn 8 tiếng"],
    "field_confidence": {"starts_local": 0.97, "confirmation_code": 0.9},
    "evidence": {"starts_local": "Khởi hành 10:30 20/12"}       // trích đoạn gốc, để UI giải thích
  }],
  "warnings": ["Năm không ghi rõ, giả định 2026"]
}
```
Quy tắc trong system prompt: không bịa trường thiếu (để `null`), ngày dạng `dd/mm` là kiểu VN,
năm thiếu thì lấy lần xuất hiện gần nhất trong tương lai và thêm warning, giữ nguyên tên riêng, PNR viết hoa.

## 3. Gọi Claude (worker, TypeScript, `@anthropic-ai/sdk`)
- Model mặc định: `claude-opus-5-5`, `thinking: {type: "adaptive"}`, `output_config: {effort: "low"|"medium", format: {...}}`.
  Effort `low` cho ảnh/pdf rõ ràng, `medium` khi lần đầu lỗi validate.
- Bật `fallbacks: "default"` (beta `server-side-fallback-2026-07-01`) và luôn kiểm tra `stop_reason` (`refusal`, `max_tokens`).
- **Prompt caching**: system prompt + schema + ví dụ few-shot đặt trước, đánh `cache_control`; phần ảnh/text người dùng đặt sau.
- Model cấu hình theo route trong bảng `ai_routes(route, model, effort, max_tokens)`. Đổi model chỉ sau khi chạy eval (mục 6).
  Bảng giá tham khảo (USD / 1 triệu token, kiểm tra lại trước khi tính giá bán):

  | Model | Input | Output |
  |---|---|---|
  | `claude-opus-5-5` | 4,00 | 20,00 |
  | `claude-sonnet-5-5` | 2,00 | 10,00 |
  | `claude-haiku-5-5` | 0,10 | 0,50 |

  Ước tính 1 import ảnh vé: ~2.500 token input (ảnh + prompt, phần prompt cache được) + ~600 token output.
  Với Opus 5.5 khoảng 0,01 + 0,012 = **~0,022 USD (~550 VND)/import**. Cần đo thực tế bằng `usage` và ghi vào `imports.cost_usd`.
- Message Batches (giảm 50% chi phí) cho việc không gấp: quét Gmail hằng đêm, import xlsx lớn.

## 4. Chuẩn hóa sau LLM
1. Validate schema (zod). Lỗi thì retry 1 lần với effort cao hơn, kèm lỗi validate.
2. `starts_tz_hint` → IANA tz (IATA từ OurAirports; tên ga/bến/thành phố VN từ bảng tĩnh; mặc định `home_tz`).
3. Kiểm tra logic: chuyến bay `ends` < `starts` mà không qua ngày thì gắn cờ; giờ check-in khách sạn mặc định 14:00, check-out 12:00 nếu thiếu.
4. Dedupe: `(confirmation_code, starts_at)` hoặc `source_ref` (Message-ID email, sha256 file). Trùng thì đề xuất **cập nhật** thay vì tạo mới (đổi giờ bay).
5. Gom trip: các booking có ngày giao nhau hoặc liền nhau ≤ 1 ngày, cùng điểm đến, thì gợi ý gộp vào 1 trip.
6. Sinh nhắc mặc định theo `reminder-engine.md` mục 5.

## 5. Màn Xem lại (contract với UI)
- Hiển thị từng candidate dạng thẻ; trường `field_confidence < 0,85` tô vàng, có tooltip `evidence`.
- Nút: **Lưu tất cả**, sửa từng trường, bỏ chọn candidate, "Gộp vào chuyến…".
- Hiện số quota sẽ dùng: "Sẽ tạo 3 lịch hẹn (còn 5/30 trong gói Free)".

## 6. Eval & chất lượng
- `services/worker/evals/booking/`: ≥ 150 mẫu ẩn danh (vé VN Airlines, Vietjet, Bamboo, Vietravel Airlines, VNR, FUTA, Agoda, Booking.com,
  Traveloka, phiếu hẹn khám BV), mỗi mẫu có `expected.json`.
- Chỉ số: độ chính xác từng trường bắt buộc, tỷ lệ "bịa" (trường có giá trị mà expected là null), chi phí và latency trung bình.
- Chạy eval trên CI khi đổi prompt/model; ngưỡng chặn merge: không giảm > 1 điểm % ở trường bắt buộc.

## 7. Giọng nói tiếng Việt: parser nhanh
Ví dụ phải pass (fixtures `packages/parsers/fixtures/vi_datetime.json`):
| Câu | Kết quả |
|---|---|
| "8 giờ sáng mai uống thuốc" | mai 08:00, "Uống thuốc" |
| "chiều thứ 6 họp team lúc 3 rưỡi" | thứ Sáu tới 15:30 |
| "nhắc tôi đóng tiền điện ngày 5 hàng tháng" | RRULE `FREQ=MONTHLY;BYMONTHDAY=5`, 09:00 mặc định |
| "rằm tháng giêng đi chùa" | âm lịch 15/1 |
| "mỗi 2 tiếng uống nước từ 8h đến 18h" | RRULE `FREQ=HOURLY;INTERVAL=2;BYHOUR=8..18` |
| "tối nay 9h gọi mẹ" | hôm nay 21:00 |
| "next Monday 10am dentist" | thứ Hai tới 10:00 |
Từ khóa buổi: sáng (giờ < 12 giữ nguyên), trưa (11-13), chiều (+12 nếu giờ 1-6), tối (+12 nếu 6-11), đêm.
"Mai", "mốt/ngày kia", "tuần sau", "cuối tuần", "đầu tháng", "cuối tháng".

## 8. Quyền riêng tư
- File import xóa khỏi Storage sau TTL (`expires_at`); Free 7 ngày, trả phí 30 ngày, hoặc giữ nếu bật "Lưu bản gốc".
- Gửi Claude qua API thương mại (không dùng dữ liệu để huấn luyện theo điều khoản API; kiểm tra lại điều khoản và nêu trong Privacy Policy).
- Che bớt số giấy tờ (CCCD, hộ chiếu) trong `raw_extraction` trước khi lưu.
