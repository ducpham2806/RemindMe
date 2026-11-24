# Bộ mẫu tài liệu cho eval trích xuất (E0.4)

> TL;DR: Mỗi mẫu là 1 thư mục `docs/<id>/` gồm `input.<ext>` (đã ẩn danh), `meta.json`, `expected.json`, sau đó thêm `ocr.android.json` / `ocr.ios.json`
> chạy 1 lần trên máy thật. CI chạy bộ máy luật trên OCR đã lưu và so với `expected.json` (`docs/architecture/on-device-extraction.md` §11).
> Mục tiêu Phase 0: ≥ 300 mẫu, ≥ 20 nhà cung cấp, ≥ 3 thị trường, đủ 6 loại (bay, tàu/xe, khách sạn, khám bệnh, sự kiện, danh sách việc).
> Kiểm tra: `python3 tools/validate-fixtures.py` (schema + quét dấu hiệu chưa ẩn danh).

## 1. Cấu trúc
```
fixtures/
  schema/meta.schema.json        # thông tin mẫu
  schema/expected.schema.json    # kết quả mong đợi
  docs/<id>/
    input.<ext>                  # .jpg .png .pdf .eml .txt .xlsx .csv .md .pkpass .ics
    meta.json
    expected.json
    ocr.android.json             # thêm sau, do app spike E0.1 xuất ra
    ocr.ios.json
```
Đặt `id` theo `<market>-<doc_type>-<provider ngắn>-<số>`, chữ thường, ví dụ `vn-flight-vietjet-0007`, `de-train-db-0003`, `us-medical-generic-0012`.
Mẫu tự dựng để minh họa dùng tiền tố `synthetic-` và `consent: "synthetic"`.

## 2. Thu mẫu
- Nguồn hợp lệ: tài liệu của chính đội; tài liệu người khác tặng **có đồng ý bằng văn bản** (ghi `consent: "donor_written_consent"`, lưu bản đồng ý ngoài repo).
  Không lấy ảnh vé từ mạng xã hội, diễn đàn.
- Mỗi nhà cung cấp lấy ≥ 5 mẫu, trộn nhiều dạng: ảnh chụp màn hình app, ảnh chụp giấy (nghiêng, thiếu sáng), PDF, email.
- Phân bổ gợi ý cho 300 mẫu: VN 120, thị trường đợt 1 lớn nhất thứ 2 và thứ 3 mỗi nơi 60, mẫu global (Booking.com, Agoda, Airbnb, boarding pass BCBP) 60.
  Thị trường cụ thể chốt theo `docs/research/global-market.md` khi có.

## 3. Ẩn danh (bắt buộc trước khi commit)
| Dữ liệu | Cách che | Lý do giữ hình dạng |
|---|---|---|
| Họ tên, email, SĐT, địa chỉ nhà | Thay bằng tên giả cùng độ dài (`NGUYEN VAN A`), email `@example.com`, số thay bằng `9` | Bộ luật dựa vào vị trí và độ dài |
| Mã đặt chỗ, số vé, số thẻ thành viên | Thay ký tự giữ nguyên định dạng (6 ký tự chữ số → 6 ký tự khác) | Pattern PNR phải còn đúng |
| Barcode/QR | Xóa, hoặc thay bằng barcode BCBP tự sinh từ dữ liệu giả | Barcode thật chứa đủ tên + PNR |
| Ngày | Có thể dịch, nhưng **theo bội số 7 ngày** (ghi `date_shift_days`) | Giữ đúng "Thứ Hai", "Mon" trên vé |
| Y tế: chẩn đoán, số hồ sơ, BHYT/bảo hiểm | Xóa nội dung, giữ nhãn ("Chẩn đoán:") | Dữ liệu nhạy cảm (`docs/security-privacy.md`) |
| Ảnh | Xóa EXIF (vị trí, thiết bị): `exiftool -all= input.jpg` | |
Giữ nguyên: tên hãng, logo, bố cục, nhãn trường, mã sân bay/ga, giờ, số chuyến. Người thứ hai kiểm lại trước khi merge.

## 4. Viết `expected.json`
- Ghi đúng những gì **màn Xem lại phải đề xuất**, giờ là giờ địa phương in trên vé + múi giờ IANA nơi đó (`{"local": "2026-12-21T10:30", "tz": "Asia/Ho_Chi_Minh"}`).
- `required`: trường bắt buộc, tính vào chỉ số "% trường bắt buộc đúng". Tối thiểu theo loại:
  | Loại | Trường bắt buộc |
  |---|---|
  | flight | `confirmation_code`, `carrier_code`, `number`, `origin.code`, `destination.code`, `starts_at` |
  | train, bus, ferry | `number` (nếu có), `origin.name`, `destination.name`, `starts_at` |
  | hotel | `provider` hoặc `title`, `check_in`, `check_out`, `confirmation_code` (nếu có) |
  | medical | `title` (cơ sở + khoa), `starts_at` |
  | event_ticket | `title`, `starts_at`, `location_text` |
  | todo_list | mỗi dòng là 1 candidate `kind: task` với `title` (+ `due` nếu có) |
- `optional`: trường có trên vé nhưng thiếu cũng không sao (ghế, hạng, giá...).
- `must_not_fill`: trường vé **không có**; app điền gì vào đó đều tính là "điền sai" (chỉ số ≤ 2%).
- Vé khứ hồi/nhiều chặng: mỗi chặng 1 candidate, `trip_expected: true`.

## 5. OCR trên máy thật
App spike E0.1 chụp/chọn `input`, chạy ML Kit (Android) và Vision (iOS), xuất `ocr.<platform>.json` (định dạng `OcrDocument`: block → line → text + bbox chuẩn hóa 0-1 + ngôn ngữ).
Ghi engine + phiên bản vào `meta.json` → `ocr`. Khi đổi engine OCR thì chạy lại cả bộ.
