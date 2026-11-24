# Hướng dẫn văn phong tiếng Việt cho RemindMe

> TL;DR: Gọi người dùng là "bạn", app không tự xưng. Câu ngắn, động từ đứng trước, dùng tiếng Việt chuẩn toàn quốc:
> từ địa phương ("bữa nay", "ngày mốt", "chừ") không xuất hiện trong UI nhưng NLU vẫn phải hiểu.
> Ngày, giờ, số, tiền luôn qua formatter CLDR (vi: 24 giờ, `dd/MM`, dấu phẩy thập phân). Mỗi chuỗi là một câu ICU hoàn chỉnh.
> Paywall nói rõ giá, kỳ hạn, gia hạn, cách hủy, không gây áp lực. Thuật ngữ lấy từ `glossary.csv`.

Phạm vi: UI, thông báo, đồng hồ, widget, chuỗi xin quyền, email, store listing, help center.
`app_vi.arb` do đội viết trực tiếp (i18n-l10n.md §8.1) nhưng vẫn theo glossary và guide này. Quy tắc chung không nhắc lại ở đây
(ICU, giới hạn độ dài, paywall, accessibility) nằm trong `style-guide-en.md`; file này chỉ ghi phần riêng hoặc khác của tiếng Việt.

## 1. Giọng văn
- Bình tĩnh, rõ ràng, giúp được việc. App là trợ lý đáng tin, không phải người cổ vũ.
- Câu ngắn, động từ trước: "Hoãn 10 phút", "Gộp vào chuyến", "Nhập tay".
- Không đổ lỗi cho người dùng. Nói chuyện gì xảy ra và bạn làm được gì tiếp theo.
- Không dùng dấu chấm than trong UI. Không "Ối", "Úi", "Tuyệt vời!", "Siêu tiện lợi".
- Tiểu từ cuối câu: "nhé" dùng tối đa một lần trên một màn, chỉ ở onboarding hoặc trạng thái trống. Không dùng "nha", "nhen", "hen", "ạ" trong UI.
- "Vui lòng" chỉ dùng trong văn bản pháp lý và email hỗ trợ. Trong UI nói thẳng động từ: "Bật thông báo", không "Vui lòng bật thông báo".

| Ngữ cảnh | Giọng | Ví dụ |
|---|---|---|
| UI thường ngày | Ngắn, trung tính | "3 nhắc hôm nay" |
| Lỗi | Bình tĩnh, cụ thể, một bước tiếp theo | "Không đọc được ảnh này. Thử ảnh rõ hơn hoặc nhập tay." |
| Sức khỏe, thuốc | Trung tính, chỉ nhắc lại thông tin, không khuyên | "Cần nhịn ăn" (chỉ khi giấy hẹn ghi vậy) |
| Ngày giỗ, ngày tưởng niệm | Trang trọng, không emoji, không bán hàng bên cạnh | "Giỗ ông nội" |
| Paywall | Nêu sự thật, không ép | "Plus không giới hạn nhắc lặp lại." |
| Thành công | Xác nhận gọn | "Đã mở khóa Plus" |

## 2. Xưng hô
- Gọi người dùng là **"bạn"** (ux-flows-and-screens.md §6). Không "quý khách" (quá xa cách), không "bạn ơi", không "anh/chị", không "cậu".
- App **không tự xưng** "mình", "tớ", "em", "RemindMe xin...". Dùng câu khuyết chủ ngữ: "Đã lưu 2 mục", không "Mình đã lưu giúp bạn 2 mục".
- "Chúng tôi" chỉ dùng trong Chính sách quyền riêng tư, Điều khoản, giải thích quyền riêng tư và email hỗ trợ.
- Tab "Tôi" là tên màn (theo IA). Ngoài tab đó, nhãn không dùng "của tôi": "Danh sách", không "Danh sách của tôi".
- Câu mẫu người dùng gõ hoặc nói có thể dùng "tôi": "Nhắc tôi gọi mẹ lúc 9 giờ sáng mai".
- Không đoán giới tính, tuổi, vai vế của người dùng.

## 3. Từ ngữ: chuẩn toàn quốc trong UI, NLU hiểu cả từ địa phương
UI dùng từ phổ thông (chuẩn báo chí, sách giáo khoa) để người ở mọi vùng đọc đều tự nhiên. Người dùng gõ hoặc nói bằng giọng vùng
nào thì gói NLU phải hiểu (`architecture/voice-and-text-input.md`). Bảng dưới là đầu vào cho bộ test NLU, không phải chuỗi UI.

| UI dùng | NLU phải hiểu thêm (không hiện trong UI) | Ghi chú |
|---|---|---|
| hôm nay | bữa nay, hôm ni | |
| ngày mai, mai | bữa mai, mơi | |
| ngày kia | ngày mốt, bữa mốt | "ngày kìa" (Bắc) = 3 ngày nữa: hiện chip hỏi lại |
| tối nay | tối ni, tối nay | |
| bây giờ | chừ, giờ | |
| lát nữa | xíu nữa, chút nữa, tí nữa | Không rõ bao lâu: hiện chip (15 phút / 1 giờ / chọn giờ) |
| tuần sau | tuần tới | Cả hai đều chuẩn; UI chọn "tuần sau" |
| 20:00 | 8h tối, 8 giờ tối, tám giờ tối, 20h | UI hiển thị theo CLDR |
| 1 giờ (khoảng thời gian) | 1 tiếng, một tiếng | |
| không lặp | hông lặp, hổng lặp | |

Từ mượn:
- Dùng từ Việt khi đã phổ biến: "ứng dụng", "tệp", "đồng bộ", "thông báo", "tiện ích" (widget), "đặt chỗ" (booking), "nhập" (import, luôn kèm đối tượng).
- Giữ tiếng Anh khi người dùng quen hơn từ Việt: email, offline, QR, PDF, AI. Tên thương hiệu giữ nguyên (`glossary.csv`, cột `do_not_translate`).
- Không dùng "item", "task", "booking", "deadline", "check" trong UI.

## 4. Chính tả, viết hoa
- Đặt dấu thanh kiểu cũ, thống nhất với tài liệu: "hóa", "thủy", "khỏe", "xóa", "hòa". Không trộn "hoá"/"hóa".
- Giữ "y" trong các từ quen thuộc: "kỹ", "lý", "quý", "mỹ".
- "mùng 1" (không "mồng 1"), "giờ" (không "h" trong chuỗi hiển thị; formatter quyết định).
- Viết hoa chữ đầu câu và tên riêng. Nút, tab, tiêu đề, cài đặt: viết hoa chữ đầu thôi ("Khôi phục mua hàng", "Ngôn ngữ & vùng").
- Địa danh, tên người Việt viết hoa từng âm tiết ("Hà Nội", "Thành phố Hồ Chí Minh"). Tên người giữ đúng thứ tự trong tài liệu, không tách họ tên.
- Tên gói: "gói Free", "gói Plus" ("gói" viết thường). Mã giữ nguyên: VN245, SGN, ABC123.

## 5. Dấu câu
- Không có khoảng trắng trước `:` `?` `!` `;` `,` `.`; có một khoảng trắng sau.
- Không chấm cuối ở nút, nhãn, tiêu đề, chip, tab, tiêu đề thông báo. Câu trong thân bài có dấu chấm, kể cả khi chỉ có một câu.
- Dấu ba chấm là ký tự `…` ("Đang đọc vé…").
- Không dùng dấu phẩy trên `'` cho phút ("Hoãn 10'" trong wireframe): viết "Hoãn 10 phút".
- `·` ngăn các thông tin trong dòng ngắn: "VN245 SGN→HAN · Nhà ga T1".
- `&` chỉ dùng trong nhãn cố định của glossary ("Ngôn ngữ & vùng", "Gói & mức sử dụng"). Trong câu viết "và".
- Ngoặc kép dùng `“ ”`. Không dùng `'` thẳng trong chuỗi ARB (là ký tự escape của ICU khi bật `use-escaping`).

## 6. Ngày, giờ, số, tiền
Không tự format. Kết quả dưới đây là ví dụ đầu ra của formatter CLDR cho `vi`; khi khác thiết kế thì đổi skeleton, không sửa chuỗi.

| Giá trị | Cách làm | Ví dụ `vi_VN` |
|---|---|---|
| Giờ | skeleton `jm`, giờ 24h theo vùng/OS | 20:00 |
| Ngày có thứ | skeleton `MMMEd` / `MEd` | kiểm tra đầu ra thật ("Th 5, 26 thg 11" hoặc "T5, 26/11"); chọn skeleton ở L1 |
| Số | `NumberFormat` | 1.890 · 2,5 |
| Giá gói | chuỗi giá đã bản địa hóa của store | 449.000 ₫ (store quyết định ký hiệu) |
| Giá trong booking | giữ đồng tiền gốc, không quy đổi | 1.890.000 ₫ · €120 |
| Ngày âm | từ bộ chuyển đổi âm lịch, nhãn "ÂL" | 14/10 ÂL |
| Giờ khác múi | ghi cả hai, tên thành phố từ CLDR | 10:30 giờ Hà Nội · 04:30 giờ London |

- Không viết "8h tối", "8g", "20h00" trong chuỗi hiển thị. Câu gợi ý Quick Add là câu người dùng gõ nên được viết "Mai 8h uống thuốc".
- Luôn dùng chữ số: "3 nhắc", không "ba nhắc".
- Khoảng thời gian và thời gian tương đối ("10 phút", "trong 2 giờ"): xem `style-guide-en.md` §6 (formatter chốt ở L1). Không ghép số với chữ "phút" trong code.
- Đơn vị tiền: không tự thêm "đ", "VNĐ", "₫".

## 7. Độ dài
Giới hạn chung ở `style-guide-en.md` §7 (giới hạn watch ≤ 30 ký tự lấy từ i18n-l10n.md §7, phần còn lại là đề xuất).
Chuỗi tiếng Việt thường dài hơn tiếng Anh vì mỗi âm tiết là một từ có dấu cách (chưa đo trên chuỗi thật; đo ở L1 bằng pseudo-locale và bản `vi`).
Cách rút gọn đúng:
- Bỏ chủ ngữ và từ đệm: "Nhắc nhở có thể không kêu", không "Các lời nhắc của bạn có thể sẽ không kêu được".
- Dùng từ ngắn trong glossary: "Xong" (không "Hoàn thành"), "nhắc" (không "lời nhắc") ở nút và bộ đếm.
- Không viết tắt tự chế ("t.báo", "đ.chỗ", "Th.5" khi formatter không sinh ra).
- Dòng chữ ở cỡ chữ 200% được xuống dòng, không cắt nghĩa.

## 8. Placeholder và ICU
- Tiếng Việt chỉ có dạng số nhiều `other`. Vẫn giữ cấu trúc `plural` từ bản tiếng Anh, điền `other` (và `=0` nếu câu khác hẳn).
- Danh từ đếm đi kèm số, không thêm "cái", "các": "{count} mục", "{count} chuyến đi", "{count} lần".
- Trật tự từ đổi theo tiếng Việt, không giữ theo tiếng Anh: "Hạn: {date}", "Từ email {provider} · {date}".
- Không ghép chuỗi: "Còn " + n + " lần" là sai, phải là một key `Còn {count} lần hôm nay`.
- `select` theo loại booking khi từ đi kèm khác nhau: `{type, select, flight{Giờ lên máy bay} train{Giờ tàu chạy} other{Giờ khởi hành}}`.

```json
"paywallRecurringLimit": "Bạn đang dùng {used}/{limit} nhắc lặp lại của gói Free. Plus không giới hạn, {monthlyEquivalent}/tháng, thanh toán {yearlyPrice} mỗi năm.",
"notifRemainingToday": "{count, plural, =0{Lần cuối hôm nay} other{Còn {count} lần hôm nay}}"
```

## 9. Thông báo lỗi
Mẫu: **chuyện gì xảy ra** + **bạn làm gì tiếp**. Chỉ thêm lý do khi lý do giúp người dùng hành động.
- Mở đầu bằng "Không ..." hoặc "Chưa ...": "Không đọc được ảnh này.", "Chưa kết nối được với Google."
- Một bước tiếp theo, trong câu hoặc trên nút.
- Không mã lỗi, không "thất bại", "lỗi hệ thống" trong câu chính. Mã lỗi để trong phần chi tiết.
- Dữ liệu an toàn thì nói rõ: "Thay đổi đã lưu trên máy."
- Offline là trạng thái, không phải lỗi: không màu đỏ, không chặn thao tác.

## 10. Paywall
Áp dụng đủ 9 quy tắc ở `style-guide-en.md` §10. Riêng tiếng Việt:
- Chữ "chỉ" trước giá ("chỉ {monthlyEquivalent}/tháng" trong pricing-entitlements.md §4) là lời mời mua nhẹ. Đề xuất bỏ "chỉ" và luôn ghi số tiền thực trả mỗi năm ngay bên cạnh.
- Dùng thử: "Miễn phí 7 ngày, sau đó {price}/tháng từ {date}. Hủy trước ngày đó thì không mất phí."
- Cách hủy: "Hủy bất cứ lúc nào trong phần cài đặt của App Store" (hoặc Google Play).
- Không gọi gói Free là "bản giới hạn", "bản dùng thử".
- Nhắc người dùng điều có lợi cho họ khi cần: "Các nhắc đã tạo vẫn kêu bình thường."

## 11. Accessibility
- Nhãn đọc màn hình cho nút chỉ có icon gọi tên hành động: "Hoãn", "Thêm mục", "Tìm kiếm".
- Chuỗi có ký hiệu cần nhãn đọc riêng: `VN245 SGN→HAN` đọc là "Chuyến bay VN245 từ SGN đến HAN"; `🔁` đọc là "Lặp lại hằng ngày"; `ÂL` đọc là "âm lịch".
- Nhãn đọc viết đầy đủ: "10 phút", không "10'"; "thứ Năm", không "T5".
- Không chỉ vị trí hay màu: "Chạm Lưu", không "Chạm nút bên phải"; "Các trường có nhãn Cần kiểm tra", không "các ô màu vàng".

## 12. Thuật ngữ hay sai
| Dùng | Không dùng | Lý do |
|---|---|---|
| việc | nhiệm vụ, công việc | "Công việc" là tên list |
| Hoãn | Báo lại, Snooze | Theo UX/PRD; iOS Đồng hồ dùng "Báo lại", sẽ test với người dùng |
| Chưa đặt giờ | Không giờ | "Không giờ" đọc thành 0 giờ |
| Nhập từ ảnh | Import | "Nhập" luôn kèm đối tượng |
| Xem lại | Duyệt | "Duyệt" giống quy trình phê duyệt |
| Hộp đề xuất | Hộp thư | "Hộp thư" trùng với hộp thư email (glossary `core_inbox`, chờ PO chốt) |
| thẻ lên máy bay | boarding pass, vé lên máy bay | Extractor vẫn nhận "thẻ lên tàu bay" |
| làm thủ tục / nhận phòng | check-in | Hai nghĩa khác nhau, hai key khác nhau |
| căn cước | CMND, CCCD | Tên thẻ từ 1/7/2024 |
| Hiển thị (mục cài đặt) | Giao diện | "Giao diện" đã dùng trong "Ngôn ngữ giao diện" |

## 13. Nên và không nên (lấy từ các luồng P0)
| # | Luồng | Nên | Không nên |
|---|---|---|---|
| 1 | Onboarding | Chụp vé, nói một câu, RemindMe lo phần nhắc. | Trải nghiệm quản lý công việc thông minh vượt trội cùng AI! |
| 2 | Xin quyền thông báo | Bật thông báo để nhắc kêu đúng giờ. | Ứng dụng cần quyền truy cập thông báo. |
| 3 | Nút phụ màn xin quyền | Để sau | Không, tôi không cần nhắc nhở |
| 4 | Gợi ý Quick Add | Mai 8h uống thuốc | Nhập nội dung công việc tại đây... |
| 5 | Thông báo | Tiêu đề `⏰ 20:00 Uống thuốc huyết áp`, dòng 2 `Còn 1 lần hôm nay` | Nhắc nhở!!! Đã đến giờ uống thuốc huyết áp rồi bạn ơi |
| 6 | Nút trên thông báo | Hoãn 10 phút | Hoãn 10' · Nhắc lại sau mười phút nữa |
| 7 | Mục quá hạn | Quá hạn | Bạn đã bỏ lỡ việc này! |
| 8 | OCR không đọc được | Không đọc được ảnh này. Thử ảnh rõ hơn hoặc nhập tay. | Lỗi 422: OCR thất bại. |
| 9 | Màn Xem lại, trường nghi ngờ | Cần kiểm tra: giờ đến | Giờ đến không hợp lệ |
| 10 | Offline | Đang offline. Nhắc vẫn kêu đúng giờ, dữ liệu sẽ đồng bộ khi có mạng. | Mất kết nối mạng. Vui lòng thử lại sau. |
| 11 | Thiếu quyền | Nhắc nhở có thể không kêu. [Mở cài đặt thông báo] | Thông báo đã bị tắt. Hãy sửa ngay! |
| 12 | Paywall nhắc lặp | Bạn đang dùng 5/5 nhắc lặp lại của gói Free. Plus không giới hạn, 37.417 ₫/tháng, thanh toán 449.000 ₫ mỗi năm. | Ưu đãi chỉ hôm nay! Giảm 80%, đừng bỏ lỡ! |
| 13 | Chuyến đi thứ 2 | Gói Free có 1 chuyến đi. Lưu trữ chuyến cũ hoặc nâng cấp. | Bạn đã hết lượt. Nâng cấp ngay. |
| 14 | Giọng nói chưa hỗ trợ | Ngôn ngữ này chưa nhận dạng được trên máy bạn. [Đổi ngôn ngữ giọng nói] | Không hỗ trợ nhận dạng giọng nói. |
| 15 | Hộp đề xuất trống | Chuyển tiếp email đặt vé, kết quả sẽ hiện ở đây. [Thiết lập chuyển tiếp email] | Chưa có gì ở đây cả! |
| 16 | Xóa tài khoản | Xóa tài khoản và dữ liệu đã đồng bộ? Không hoàn tác được. Gói đăng ký trên App Store vẫn tiếp tục đến khi bạn hủy ở đó. | Bạn có chắc không? |
| 17 | Xung đột ghi chú | Có 2 phiên bản. [Giữ bản này] [Giữ bản kia] [Gộp cả hai] | Xung đột dữ liệu! Chọn phiên bản. |
| 18 | Hủy trong hộp thoại về vé | Đóng | Hủy (dễ hiểu là hủy vé) |

Giá và ngày trong bảng là ví dụ đầu ra của formatter và store, không phải chuỗi cố định.
