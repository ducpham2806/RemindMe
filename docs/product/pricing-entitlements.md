# Gói dịch vụ, giá và giới hạn (entitlements)

> TL;DR: 2 gói: Free và Plus (tháng/quý/năm). Giới hạn Free áp dụng cho **mọi loại** lịch (todo có giờ, lịch hẹn,
> booking vé/khách sạn, lịch khám...). Giá trị dưới đây là **seed** cho bảng `plan_entitlements`, chỉnh qua DB/remote config,
> không sửa code. Căn cứ: `docs/research/competitor-analysis.md` mục 4 và 6.

## 1. Giá đề xuất
| Kỳ | Việt Nam (VND) | Global (USD) | Quy đổi / tháng | Ghi chú |
|---|---|---|---|---|
| Tháng | 59.000 | 4,99 | 59.000 | Trial 7 ngày |
| Quý (3 tháng) | 149.000 | 12,99 | ~49.700 (-16%) | Đối thủ chính không có gói quý, nên đây là điểm khác biệt |
| Năm | 449.000 | 39,99 | ~37.400 (-37%) | Trial 14 ngày; gói đẩy mạnh nhất |

Tùy chọn thử nghiệm sau launch: gói Sinh viên 299.000đ/năm (xác minh qua email .edu.vn).

Neo giá thị trường VN (App Store VN, 24/11/2026): TickTick 69k/tháng, 639k/năm; Todoist 199k/tháng; Spotify 65k/tháng.
Việc cần làm: ánh xạ sang **price point VND thực tế** của App Store / Play (chưa xác minh bảng price point; có thể là 59.000 hoặc gần đó).
Khuyến mãi gợi ý: giảm 40% gói năm dịp Tết, Black Friday; ưu đãi "chuyển nhà" cho người dùng Microsoft To Do.

## 2. Ma trận giới hạn (seed `plan_entitlements`)
`-1` = không giới hạn.

| Key | Free | Plus | Giải thích |
|---|---|---|---|
| `max_reminders_per_day` | 10 | -1 | Số lần nhắc kêu tối đa trong 1 ngày, tính cả lần lặp |
| `max_recurring_series` | 5 | -1 | Số chuỗi lặp đang hoạt động (habit, nhắc định kỳ, âm lịch) |
| `max_active_appointments` | 10 | -1 | Lịch hẹn/booking/sự kiện chưa qua. Đã qua thì tự lưu trữ, **không tính** |
| `max_active_trips` | 1 | -1 | Chuyến đi đang/sắp diễn ra |
| `smart_imports_per_month` | 10 | -1 | Import ảnh, pdf, xlsx, email forward. `.ics`, `.pkpass`, `.md`, quét boarding pass **không tính**. Xử lý trên máy nên không tốn chi phí: đây thuần là đòn bẩy bán hàng, có thể nới (ví dụ 20) nếu số liệu cho thấy giúp giữ chân |
| `voice_input` | -1 | -1 | Nhập giọng nói dùng STT của OS + parser luật, không tốn chi phí nên không giới hạn ở mọi gói |
| `max_import_pages` | 20 | 200 | Trang PDF mỗi lần import (giới hạn để máy yếu không treo, không phải vì chi phí) |
| `max_originals_mb` | 0 | 1024 | "Giữ bản gốc" tài liệu trên cloud (Free: bản gốc chỉ nằm trên máy) |
| `max_lists` | 5 | -1 | |
| `calendar_sync_accounts` | 1 | 5 | Google/Microsoft |
| `feature_ics_feed` | 0 | 1 | Feed webcal |
| `feature_watch_app` | 1 (xem + Done) | 1 (đủ: thêm nhanh, complication) | Thông báo mirror luôn có ở mọi gói |
| `feature_flight_status` | 0 | 1 | Phase 3 |
| `feature_gmail_scan` | 0 | 1 | Phase 3 |
| `feature_zalo_channel` | 0 | 1 | Phase 3 |
| `feature_lunar_recurrence` | 1 | 1 | Miễn phí để thu hút người dùng VN, nhưng vẫn tính vào `max_recurring_series` |
| `feature_location_reminder` | 0 | 1 | Phase 2 |
| `feature_themes` | 0 | 1 | |

## 3. Quy tắc áp dụng
1. **Nhắc đã tạo luôn kêu.** Giới hạn chỉ chặn việc *tạo mới* hoặc *sửa làm tăng* số lượng. Khi hạ từ Plus xuống Free:
   dữ liệu giữ nguyên, mọi nhắc vẫn kêu; chỉ không tạo thêm khi đang vượt hạn mức. Không xóa, không khóa dữ liệu.
2. Đếm theo `home_tz`. Ngày mới bắt đầu lúc 00:00 giờ địa phương.
3. Import vượt quota lịch hẹn: màn Xem lại vẫn hiện đủ candidate, người dùng chọn cái nào lưu trong phạm vi còn lại hoặc nâng cấp.
4. Offline: dùng entitlement cache; item vượt hạn mức tạo ở `pending_quota`, server quyết định khi sync (ADR-008).
5. Import đọc thất bại (không ra trường nào) thì không tính lượt.
6. Chi phí server còn lại (sync, hộp thư email, lưu bản gốc) có giới hạn kỹ thuật riêng (`on-device-extraction.md` mục 8), không phụ thuộc gói.

## 4. Paywall theo ngữ cảnh (không chặn cứng ngay lần đầu)
| Điểm chạm | Thông điệp gợi ý |
|---|---|
| Tạo chuỗi lặp thứ 6 | "Bạn đang dùng 5/5 nhắc lặp lại của gói Free. Plus không giới hạn, 37.400đ/tháng khi trả theo năm." |
| Import ảnh lần thứ 11 trong tháng | Vẫn đọc xong trên máy, hiện kết quả mờ của 1 candidate + CTA nâng cấp (người dùng thấy giá trị trước) |
| Chuyến đi thứ 2 | "Gói Free có 1 chuyến đi. Lưu trữ chuyến cũ hoặc nâng cấp" |
| Ngày có 10 nhắc | Banner nhẹ trong màn Hôm nay, không popup |
Không hiện paywall trong 3 ngày đầu sau khi cài, trừ khi người dùng chạm giới hạn.

## 5. Kinh tế đơn vị (giả định, cần đo lại)
- Chi phí biến đổi theo lượt import/giọng nói: **0** (xử lý trên máy, ADR-010). Spam import chỉ tốn pin máy người spam.
- Chi phí server theo người dùng hoạt động: DB + sync + push + hộp thư email, ước tính < 0,01 USD/tháng ở quy mô nhỏ (kiểm tra theo bảng giá Supabase/Cloud Run).
- Phí store: 15% (Small Business Program / gói duy trì > 1 năm) đến 30%. RevenueCat: kiểm tra bảng phí hiện hành.
- Doanh thu ròng gói năm VN ≈ 449.000 × 0,85 ≈ 381.000đ/năm.
- Mục tiêu: tỷ lệ chuyển đổi Free→Plus 3-5% sau 30 ngày; giữ chân D30 ≥ 25%.
