# Design system

> TL;DR: Token màu/chữ/khoảng cách/bo góc cho Flutter `ThemeData` (Material 3) + tùy biến nhẹ cho iOS.
> Hỗ trợ sáng/tối/theo hệ thống, cỡ chữ động tới 200%, tiếng Việt có dấu không bị cắt.
> Persona: *UI Designer*, *UX Architect*, *Accessibility Auditor* (Agency).

## 1. Nguyên tắc
1. **Nhập nhanh hơn ghi giấy.** Nút "+" luôn trong tầm ngón cái; mọi phương thức nhập (gõ, nói, ảnh, file) cách 1 chạm.
2. **Giờ là thông tin quan trọng nhất.** Giờ luôn hiển thị đậm, bên trái, dạng 24h (VN) hoặc theo locale.
3. **AI đề xuất, người dùng quyết định.** Kết quả AI luôn qua màn Xem lại, chỗ nghi ngờ được đánh dấu rõ.
4. **Bình tĩnh.** Ít màu, màu chỉ để báo trạng thái (quá hạn, chuyến bay sắp tới, ưu tiên).
5. **Dùng được bằng 1 tay và với người lớn tuổi.** Vùng chạm ≥ 48dp, chữ tối thiểu 14sp, có chế độ "Chữ lớn".

## 2. Màu (token)
| Token | Light | Dark | Dùng cho |
|---|---|---|---|
| `color.primary` | `#2F6BFF` | `#8AA9FF` | Nút chính, FAB, link |
| `color.onPrimary` | `#FFFFFF` | `#0B1B4D` | |
| `color.surface` | `#FFFFFF` | `#121417` | Nền thẻ |
| `color.background` | `#F6F7F9` | `#0B0C0E` | Nền màn |
| `color.textPrimary` | `#14171C` | `#ECEEF2` | |
| `color.textSecondary` | `#5B6472` | `#A2AAB7` | Phụ đề, giờ phụ |
| `color.divider` | `#E4E7EC` | `#2A2E35` | |
| `color.danger` | `#D93A3A` | `#FF7A7A` | Quá hạn, xóa |
| `color.warning` | `#C98A00` | `#FFC94D` | Trường AI nghi ngờ, sắp tới hạn |
| `color.success` | `#1E9E62` | `#5FD39A` | Hoàn thành |
| `color.travel` | `#0E9AA7` | `#55D6E0` | Booking, chuyến đi |
| `color.health` | `#C2410C` | `#FF9F6E` | Lịch khám, thuốc |
| `color.lunar` | `#B4235A` | `#FF8DB8` | Nhãn âm lịch |
| `priority.high/med/low` | `#D93A3A` / `#C98A00` / `#2F6BFF` | sáng hơn 1 bậc | Cờ ưu tiên |

Tương phản tối thiểu WCAG AA: chữ thường 4,5:1, chữ lớn 3:1. Kiểm tra bằng script khi đổi token.
Màu list do người dùng chọn: 12 màu cố định đã kiểm tra tương phản trên cả 2 nền.

## 3. Chữ
- Font: **Be Vietnam Pro** (thiết kế cho tiếng Việt, dấu đẹp, Google Fonts, OFL), fallback hệ thống (SF Pro, Roboto).
  Số giờ dùng `FontFeature.tabularFigures()` để thẳng cột.
- Thang chữ (sp): `display 32/40 semibold`, `title 22/28 semibold`, `headline 18/24 semibold`, `body 16/24 regular`,
  `bodySmall 14/20`, `label 13/16 medium`, `caption 12/16`.
- Line-height tối thiểu 1,35 để dấu chồng (ệ, ẫ, ỗ) không bị cắt. Không dùng `maxLines: 1` với chiều cao cố định cho tiêu đề tiếng Việt.

## 4. Khoảng cách, bo góc, đổ bóng
- Lưới 4dp: `space.1=4, 2=8, 3=12, 4=16, 5=20, 6=24, 8=32, 10=40`. Lề màn hình 16dp.
- Bo góc: `radius.sm=8` (chip), `md=12` (thẻ), `lg=20` (bottom sheet), `full` (FAB, avatar).
- Elevation: chỉ 0 (phẳng, viền `divider`) và 2 (bottom sheet, FAB). Dark mode dùng tông nền sáng hơn thay cho bóng.

## 5. Icon & hình
- Material Symbols Rounded (Android), SF Symbols tương đương trên iOS cho thanh điều hướng.
- Icon loại booking: ✈ máy bay, 🚆 tàu, 🚌 xe, 🏨 khách sạn, 🚗 thuê xe, ⛴ phà, 🩺 khám bệnh, 🎫 sự kiện (dùng icon vector, emoji chỉ trong thông báo).
- Minh họa empty state: nét đơn, 2 màu (`primary` + `textSecondary`).

## 6. Component chính
| Component | Mô tả | Trạng thái |
|---|---|---|
| `TaskTile` | Checkbox tròn 24dp, tiêu đề, dòng phụ (giờ · list · icon lặp/âm lịch/nhắc), cờ ưu tiên bên phải | default, overdue (giờ đỏ), done (gạch, mờ 60%), pending_quota (icon khóa) |
| `TimeBadge` | Giờ đậm `14:30`, phụ "còn 25'" | sắp tới < 1h thì `warning` |
| `BookingCard` | Header icon + hãng + mã đặt chỗ (nút copy), thân: `SGN 10:30 → HAN 12:40`, giờ địa phương mỗi đầu, nút "Mở vé/QR" | upcoming, in-progress, completed |
| `QuickAddBar` | Ô nhập + chip phân tích trực tiếp (📅 Mai 08:00, 🔁 Hằng ngày, #list) + nút mic + nút 📎 | idle, typing, listening (sóng âm), parsing |
| `ImportReviewCard` | Trường dạng form; trường confidence thấp viền `warning` + icon ⓘ hiện `evidence` | |
| `QuotaMeter` | Thanh tiến trình nhỏ "7/10 nhắc hôm nay" | ≥ 80% thì `warning` |
| `PaywallSheet` | Bottom sheet, 3 gói, gói năm chọn sẵn, ghi rõ giá/kỳ/cách hủy, nút Khôi phục | |
| `SnoozePicker` | 10', 30', 1h, Tối nay 20:00, Mai 08:00, Tùy chọn | |
| `LunarDateLabel` | "15/7 Âm lịch" chữ nhỏ màu `lunar` | |
| `EmptyState` | Minh họa + 1 câu + 1 CTA | |

## 7. Chuyển động
- Thời lượng: 150ms (nhỏ), 250ms (chuyển màn), easing `emphasized` của Material 3.
- Hoàn thành task: checkbox nảy + gạch ngang chạy trái sang phải 200ms, rung nhẹ (haptic light). Tôn trọng "Giảm chuyển động".
- Persona *Whimsy Injector*: chuỗi hoàn thành habit 7 ngày có hiệu ứng confetti nhỏ (tắt được).

## 8. Khả năng truy cập
- Semantics label cho mọi icon-button ("Hoãn 10 phút", "Đánh dấu hoàn thành Uống thuốc").
- Hỗ trợ TalkBack/VoiceOver: thứ tự đọc TaskTile: tiêu đề → giờ → trạng thái.
- Dynamic Type tới 200%: layout chuyển sang 1 cột, giờ xuống dòng dưới tiêu đề.
- Không truyền tải thông tin chỉ bằng màu (quá hạn có thêm chữ "Quá hạn").
- Chế độ "Chữ lớn & đơn giản" (persona Bà Hoa): ẩn tag/ưu tiên, nút to, chỉ 3 tab.

## 9. Bản địa hóa
- `intl` + ARB: `vi` (mặc định), `en`. Không ghép chuỗi; dùng ICU plural/select.
- Định dạng: `vi-VN` ngày `T5, 26/11`, giờ 24h, tiền `1.890.000 ₫`. `en` theo locale máy.
- Độ dài chuỗi tiếng Việt dài hơn tiếng Anh ~20-30%, nên chừa chỗ trong nút.

## 10. Bàn giao cho Flutter
`lib/core/theme/tokens.dart` (hằng số), `app_theme.dart` (ThemeData light/dark từ token), `ThemeExtension<RemindColors>`
cho màu ngoài Material (`travel`, `health`, `lunar`, `warning`). Mọi widget dùng token, không dùng mã màu trực tiếp.
