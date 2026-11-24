# Gói dịch vụ, giá và giới hạn (entitlements): nguồn chuẩn duy nhất

> TL;DR: 2 gói: Free và Plus (tháng/quý/năm). Giới hạn Free áp dụng cho mọi loại lịch hẹn (sự kiện, lịch khám, booking vé/khách sạn);
> todo có giờ chỉ tính vào số nhắc/ngày. Giá theo nhóm thị trường (sức mua). Giá trị dưới đây là **seed** cho `plan_entitlements`,
> chỉnh qua DB/remote config, không sửa code. Tài liệu khác chỉ link tới đây, không chép lại con số.

## 1. Giá
### 1.1 Bảng giá theo nhóm thị trường (đề xuất)
| Nhóm | Ví dụ storefront | Tháng | Quý (3 tháng) | Năm | Trial |
|---|---|---|---|---|---|
| **T1** thu nhập cao | US, CA, UK, EU, AU, JP, KR, SG, CH | $4,99 | $12,99 | $39,99 | Tháng 7 ngày; Năm 14 ngày |
| **T2** trung bình | BR, MX, TR, TH, MY, PL, CL, AR, ZA | ~60% T1 | ~60% T1 | ~60% T1 | như trên |
| **T3** sức mua thấp | VN, ID, IN, PH, EG, PK, NG | ~35-45% T1 | | | như trên |
| Việt Nam (T3, đã chốt) | VN | 59.000đ | 149.000đ (-16%) | 449.000đ (-37%) | như trên |
- App Store: đặt giá gốc USD rồi **ghi đè** cho storefront quan trọng; Play: giá theo từng quốc gia. Chọn price point gần nhất mỗi store (chưa xác minh bảng price point từng nước).
- Gói quý là điểm khác biệt: đối thủ chính không có (`research/competitor-analysis.md`).
- Neo giá: Todoist $6,99/tháng, $59,99/năm (App Store US, 11/2026); TickTick ở VN 69k/tháng, 639k/năm.
- Trial: mỗi Apple ID / tài khoản Google chỉ được 1 lần cho mỗi subscription group (store quản lý). Family Sharing: **tắt** ở launch.

### 1.2 Khuyến mãi theo thị trường (thử nghiệm, remote config)
| Thị trường | Dịp |
|---|---|
| Global | Black Friday, năm mới; "chuyển nhà" cho người dùng Microsoft To Do (thử: Plus 1 tháng miễn phí) |
| VN, CN-diaspora, KR | Tết Nguyên đán / Seollal |
| Trung Đông, ID, MY | Ramadan |
| IN | Diwali |
| Sinh viên (thử nghiệm theo thị trường) | Giảm ~30% gói năm; cách xác minh tùy thị trường (chưa chốt) |

## 2. Ma trận giới hạn (seed `plan_entitlements`)
`-1` = không giới hạn. Key `feature_*` là cấp: `0` tắt, `1` cơ bản, `2` đầy đủ.

| Key | Free | Plus | Giải thích |
|---|---|---|---|
| `max_reminders_per_day` | 10 | -1 | Số lần nhắc kêu tối đa trong 1 ngày, tính cả lần lặp |
| `max_recurring_series` | 5 | -1 | Chuỗi lặp đang hoạt động (habit, định kỳ, âm lịch, Hijri) |
| `max_active_appointments` | 10 | -1 | Sự kiện/lịch khám/booking chưa qua. Đã qua thì tự lưu trữ, **không tính** |
| `max_active_trips` | 1 | -1 | Chuyến đi đang/sắp diễn ra |
| `smart_imports_per_month` | 10 | -1 | Ảnh, pdf, xlsx, email forward. `.ics`, `.pkpass`, `.md`, boarding pass **không tính**. Xử lý trên máy (ADR-010) nên đây thuần là đòn bẩy bán hàng, nới được |
| `voice_input` | -1 | -1 | STT của OS + parser luật, không tốn chi phí |
| `max_import_pages` | 20 | 200 | Trang PDF mỗi lần (để máy yếu không treo) |
| `max_originals_mb` | 0 | 1024 | "Giữ bản gốc" trên cloud (Free: bản gốc chỉ nằm trên máy) |
| `max_lists` | 5 | -1 | Inbox không tính |
| `max_active_devices` | 1 | 3 | Tổng số thiết bị đăng nhập cùng lúc; vượt thì máy hoạt động lâu nhất bị đăng xuất (ADR-013). Đồng hồ, widget không tính |
| `max_devices_per_class` | 1 | 1 | Số thiết bị mỗi loại (`phone`, `tablet`, `computer`): Plus = 1 điện thoại + 1 tablet + 1 máy tính (app máy tính: Phase 4, ghi "sắp có"). `-1` cho phép nhiều máy cùng loại |
| `calendar_sync_accounts` | 1 | 5 | Google/Microsoft |
| `feature_watch_app` | 1 | 2 | 1 = xem danh sách + Xong/Hoãn; 2 = thêm nhanh bằng giọng nói, complication/tile, Live Activities. Thông báo mirror luôn có |
| `feature_ics_feed` | 0 | 1 | Feed webcal (Phase 2) |
| `feature_location_reminder` | 0 | 1 | Phase 2 |
| `feature_enhanced_voice` | 1 | 1 | Model giọng nói tải về (PhoWhisper/Whisper), miễn phí vì chạy trên máy (Phase 2) |
| `feature_flight_status` | 0 | 1 | Phase 3 |
| `feature_gmail_scan` | 0 | 1 | Phase 3, chạy trên máy |
| `feature_messaging_channel` | 0 | 1 | Nhắc qua Zalo / LINE / Kakao / WhatsApp, có phí theo tin (Phase 3) |
| `feature_alt_calendars` | 1 | 1 | Âm lịch VN/TQ/HQ, Hijri: miễn phí ở mọi thị trường, vẫn tính vào `max_recurring_series` |
| `feature_themes` | 0 | 1 | |

## 3. Quy tắc áp dụng
0. **Hạ gói và thiết bị:** hết Plus thì tự cắt về giới hạn Free, giữ máy hoạt động gần nhất, máy khác bị đăng xuất (`end_reason='plan_limit'`); mua lại không tự đăng nhập lại máy cũ.
1. **Nhắc đã tạo luôn kêu.** Giới hạn chỉ chặn *tạo mới* hoặc *sửa làm tăng* số lượng. Hạ từ Plus xuống Free: giữ nguyên dữ liệu, mọi nhắc vẫn kêu,
   chỉ không tạo thêm khi đang vượt. Không xóa, không khóa dữ liệu.
2. Đếm theo `home_tz`. Ngày mới bắt đầu lúc 00:00 giờ địa phương.
3. Import vượt quota lịch hẹn: màn Xem lại vẫn hiện đủ candidate; người dùng chọn cái nào lưu trong phạm vi còn lại hoặc nâng cấp.
   Import hàng loạt (Microsoft To Do, Todoist): phần vượt quota vào `archived` với `archived_reason='quota'` (xem được, mở lại khi nâng cấp).
4. Offline: dùng entitlement cache; item vượt hạn mức tạo ở `pending_quota`, server quyết định khi sync (ADR-008).
   Đóng paywall giữa chừng: item vẫn được lưu ở `pending_quota`, không mất dữ liệu người dùng đã nhập.
5. Import đọc thất bại (không ra trường nào) thì không tính lượt.
6. Chi phí server còn lại (sync, hộp thư email, bản gốc) có giới hạn kỹ thuật riêng (`on-device-extraction.md` §8), không phụ thuộc gói.

## 4. Paywall theo ngữ cảnh
| Điểm chạm | Thông điệp (chuỗi ICU, giá lấy từ store đã bản địa hóa) |
|---|---|
| Tạo chuỗi lặp thứ 6 | `paywall_recurring_limit`: "Bạn đang dùng {used}/{limit} nhắc lặp lại của gói Free. Plus không giới hạn, chỉ {monthlyEquivalent}/tháng khi trả theo năm." |
| Import lần thứ 11 trong tháng | Vẫn đọc xong trên máy, hiện kết quả mờ của 1 candidate + CTA nâng cấp |
| Chuyến đi thứ 2 | "Gói Free có 1 chuyến đi. Lưu trữ chuyến cũ hoặc nâng cấp" |
| Ngày có đủ số nhắc tối đa | Banner nhẹ trong Hôm nay, không popup |
| Free đăng nhập thiết bị thứ 2 | Trong hộp xác nhận đăng xuất máy cũ (UX §3.7): `paywall_devices`: "Plus dùng cùng lúc trên điện thoại, tablet và máy tính (sắp có)." Bỏ "(sắp có)" khi remote config `desktop_client_available = true` (ADR-014) [Nâng cấp] [Tiếp tục với 1 thiết bị] |
- Không hiện paywall trong 3 ngày đầu sau khi cài, trừ khi người dùng chạm giới hạn.
- Paywall phải ghi rõ giá, kỳ, cách hủy, link Terms/Privacy, nút Khôi phục mua hàng (yêu cầu store).

## 5. Kinh tế đơn vị (giả định, cần đo lại)
- Chi phí biến đổi theo lượt import/giọng nói: **0** (ADR-010). Spam import chỉ tốn pin máy người spam.
- Chi phí server theo người dùng hoạt động (DB, sync, push, hộp thư): ước tính < 0,01 USD/tháng ở quy mô nhỏ (kiểm tra bảng giá Supabase/Cloud Run).
- Phí store 15% (Small Business Program / sau 1 năm duy trì) đến 30%. RevenueCat: kiểm tra bảng phí hiện hành. Thuế VAT/GST do store xử lý với IAP.
- Ví dụ VN: doanh thu ròng gói năm ≈ 449.000 × 0,85 ≈ 381.000đ. T1: $39,99 × 0,85 ≈ $34.
- Mục tiêu: xem `docs/product/PRD.md` §2.
