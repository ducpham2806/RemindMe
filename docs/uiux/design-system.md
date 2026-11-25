# Design system

> TL;DR: Token màu/chữ/khoảng cách/bo góc cho Flutter `ThemeData` (Material 3) + tùy biến nhẹ cho iOS.
> Hỗ trợ sáng/tối/theo hệ thống, cỡ chữ động tới 200%, mọi hệ chữ của các locale phát hành (dấu chồng không bị cắt), sẵn sàng RTL.
> Quy tắc bản địa hóa (định dạng, dịch, RTL chi tiết): `docs/architecture/i18n-l10n.md`.

## 1. Nguyên tắc
1. **Nhập nhanh hơn ghi giấy.** Nút "+" luôn trong tầm ngón cái; mọi phương thức nhập (gõ, nói, ảnh, file) cách 1 chạm.
2. **Giờ là thông tin quan trọng nhất.** Giờ luôn hiển thị đậm, bên trái, theo định dạng 12/24h của vùng.
3. **Máy đề xuất, người dùng quyết định.** Kết quả đọc tự động (luật, mẫu, AI trên máy) luôn qua màn Xem lại, chỗ nghi ngờ được đánh dấu rõ.
4. **Bình tĩnh.** Ít màu, màu chỉ để báo trạng thái (quá hạn, chuyến bay sắp tới, ưu tiên).
5. **Dùng được bằng 1 tay và với người lớn tuổi.** Vùng chạm ≥ 48dp, chữ tối thiểu 14sp, có chế độ "Chữ lớn".

## 2. Màu (token)
Nguồn thiết kế: file Figma "RemindMe" (~59 màn × VI/EN × sáng/tối, không dùng Figma variables: giá trị dưới đây đọc từ layer và là nguồn chuẩn cho code).
| Token | Light | Dark | Dùng cho |
|---|---|---|---|
| `color.primary` | `#2F6BFF` | `#8AA9FF` | Nút chính, FAB, link |
| `color.onPrimary` | `#FFFFFF` | `#0B1B4D` | |
| `color.surface` | `#FFFFFF` | `#121417` | Nền thẻ |
| `color.background` | `#F6F7F9` | `#0B0C0E` | Nền màn |
| `color.textPrimary` | `#14171C` | `#ECEEF2` | |
| `color.textSecondary` | `#5B6472` | `#A2AAB7` | Phụ đề, giờ phụ |
| `color.divider` | `#E4E7EC` | `#2A2E35` | |
| `color.primaryContainer` | `#EAF0FF` | `#172443` | Thẻ tiến độ, nền nút phụ, ngày đang chọn |
| `color.primaryTrack` | `#D4E0FF` | `#26385E` | Rãnh thanh tiến độ trên `primaryContainer` |
| `color.danger` | `#BF3035` | `#FF7A7A` | Quá hạn, xóa (`#D93A3A` cũ chỉ ~4,3:1 trên nền trắng, chưa đạt AA chữ nhỏ) |
| `color.checkOutline` / `checkOverdue` | `#BDC5D1` / `#DA8B8F` | `#596575` / `#A45259` | Vòng "đánh dấu xong" thường / quá hạn |
| `color.warning` | `#C98A00` | `#FFC94D` | Trường đọc tự động có độ tin cậy thấp, sắp tới hạn |
| `color.success` | `#1E9E62` | `#5FD39A` | Hoàn thành |
| `color.travel` | `#087E89` | `#55D6E0` | Booking, chuyến đi, giờ lịch hẹn (`#0E9AA7` cũ ~3,4:1 trên nền trắng, chưa đạt AA) |
| `color.travelContainer` | `#E6F5F4` | `#102D30` | Nền ngày thuộc chuyến đi trên lịch |
| `color.textDisabled` | `#A1A8B3` | `#8993A2` | Ngày ngoài tháng đang xem |
| `color.health` | `#C2410C` | `#FF9F6E` | Lịch khám, thuốc |
| `color.lunar` | `#B4235A` | `#FF8DB8` | Nhãn âm lịch |
| `priority.high/med/low` | `#D93A3A` / `#C98A00` / `#2F6BFF` | sáng hơn 1 bậc | Cờ ưu tiên |

Tương phản tối thiểu WCAG AA: chữ thường 4,5:1, chữ lớn 3:1. Kiểm tra bằng script khi đổi token.
Màu list do người dùng chọn: 12 màu cố định đã kiểm tra tương phản trên cả 2 nền.

## 3. Chữ
- Font: **Be Vietnam Pro** (Latin + tiếng Việt, Google Fonts, OFL) cho các locale chữ Latin. Hệ chữ khác dùng font hệ thống:
  CJK (PingFang / Noto Sans CJK), Thái (Thonburi / Noto Sans Thai), Ả Rập (SF Arabic / Noto Sans Arabic), Devanagari (Kohinoor / Noto Sans Devanagari).
  Khai báo `fontFamilyFallback` theo thứ tự này; không nhúng font CJK.
  Số giờ dùng `FontFeature.tabularFigures()` để thẳng cột.
- Font bundle trong app (`apps/client/assets/fonts`, 400/500/600/700, giấy phép OFL hiện ở màn giấy phép).
- Thang chữ (sp, theo Figma): tiêu đề màn `headlineLarge 30/44 semibold`, `titleLarge 22/28 semibold`, tiêu đề thẻ `titleMedium 16/23 semibold`,
  tên việc `titleSmall 14/20 medium`, `bodyLarge 16/24`, `bodyMedium 14/20`, `bodySmall 12/17` (màu phụ), giờ `labelMedium 13/19 semibold`,
  tiêu đề nhóm `labelLarge 12/17 semibold`, phụ đề/đếm `labelSmall 11/16 medium`, nhãn tab 10/15.
- Line-height tối thiểu 1,35 để dấu chồng (tiếng Việt ệ/ẫ, tiếng Thái) không bị cắt. Không dùng `maxLines: 1` với chiều cao cố định cho tiêu đề.
  CJK không dùng chữ nghiêng; tiếng Đức/Phần Lan có thể dài hơn tiếng Anh ~35%.

## 4. Khoảng cách, bo góc, đổ bóng
- Lưới 4dp: `space.1=4, 2=8, 3=12, 4=16, 5=20, 6=24, 8=32, 10=40`. Lề màn hình 20dp (Figma).
- Bo góc: `radius.sm=8` (chip), `md=14` (thẻ việc), `xl=18` (thẻ nổi, nút "+" ở thanh dưới), `lg=20` (bottom sheet), `full` (avatar).
- Elevation: phẳng; thẻ là khối `surface` trên nền `background`, không viền, không bóng. Dark mode dùng tông nền sáng hơn thay cho bóng.

## 5. Icon & hình
- Icon nét 1,8 lấy từ Figma (`apps/client/assets/icons/*.svg`, widget `AppIcon` tô theo màu theme, 1 tệp cho sáng/tối): thanh điều hướng
  (today, calendar, trip, user), `search`, `plus`, vòng `check`, `back`/`chevron`/`chevronSmall` (lật khi RTL), `plane`, `hotel`, `globe`. Icon khác tạm dùng Material Symbols tới khi lấy đủ từ Figma.
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

## 9. Bản địa hóa (phần hình ảnh)
- Mọi padding/alignment dùng bản directional (`EdgeInsetsDirectional`, `AlignmentDirectional`). Icon có hướng dùng `matchTextDirection`;
  swipe Xong/Hoãn, timeline chuyến đi, thanh tiến trình đảo chiều ở RTL.
- Chừa chỗ cho chuỗi dài: nút cho phép 2 dòng; `TaskTile` xuống dòng giờ khi chữ lớn hoặc chuỗi dài.
- Số giờ và mã (PNR, số hiệu chuyến) luôn hiển thị LTR, kể cả trong giao diện RTL.
- Các mục khác (định dạng, dịch, cổng chất lượng): `docs/architecture/i18n-l10n.md`.

## 10. Bàn giao cho Flutter
`lib/core/theme/tokens.dart` (hằng số), `app_theme.dart` (ThemeData light/dark từ token), `ThemeExtension<RemindColors>`
cho màu ngoài Material (`travel`, `health`, `lunar`, `warning`). Mọi widget dùng token, không dùng mã màu trực tiếp.

## 11. Màn hình lớn (tablet, máy tính)
Breakpoint, master-detail, chuột/bàn phím: `architecture/multi-platform.md` §2 (nguồn chuẩn). Component phải có trạng thái hover, focus nhìn thấy được,
tooltip cho nút chỉ có icon, và không phụ thuộc cử chỉ vuốt (luôn có nút hoặc menu thay thế). Golden test chạy ở compact, medium, expanded.
