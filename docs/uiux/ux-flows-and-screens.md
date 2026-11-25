# UX: kiến trúc thông tin, luồng, màn hình

> TL;DR: 4 tab (Hôm nay · Lịch · Chuyến đi · Tôi) + FAB "+" mở Quick Add đa phương thức.
> **6 luồng P0** (nguồn chuẩn, prototype Phase 0 theo danh sách này): Onboarding + xin quyền, Quick Add (gõ/nói), Import → Xem lại,
> Thông báo → hành động, Paywall, Chuyển nhà từ To Do. Ví dụ màn hình viết bằng tiếng Việt; mọi chuỗi thật lấy từ ARB theo locale.
> Wireframe ASCII bên dưới là chuẩn bố cục, chi tiết hình ảnh theo `design-system.md`.

## 1. Kiến trúc thông tin
```
App
├── Hôm nay (mặc định)
│   ├── Quá hạn · Hôm nay (theo giờ) · Không giờ · Sắp tới (3 ngày)
│   └── Thẻ "Chuyến đi đang diễn ra / sắp tới" ghim trên đầu
├── Lịch
│   ├── Tháng (có ngày âm) · Tuần · Ngày (timeline)
│   └── Lọc theo list / loại
├── Chuyến đi
│   ├── Sắp tới · Đã qua
│   └── Chi tiết chuyến: timeline segment, tài liệu, checklist hành lý
├── 🔍 Tìm kiếm (icon trên thanh tiêu đề Hôm nay/Lịch): item, chuyến đi, ghi chú, mã đặt chỗ; không phân biệt dấu/hoa thường theo locale
├── Tôi
│   ├── Danh sách (lists) & Hộp thư (Inbox)
│   ├── Hộp đề xuất (kết quả từ email/import chưa duyệt)
│   ├── Tích hợp (Google, Microsoft, Notion, email forward, feed ICS, đồng hồ)
│   ├── Gói & mức sử dụng (QuotaMeter)
│   └── Cài đặt (thông báo, giờ yên lặng, thiết bị nhận nhắc, **ngôn ngữ & vùng** [giao diện · định dạng · giọng nói · quốc gia ngày lễ · hệ lịch phụ],
│       giao diện, chữ lớn, độ tin cậy nhắc, dữ liệu & quyền riêng tư [xuất, xóa tài khoản, chỉ nhận dạng trên máy],
│       **tài khoản & thiết bị** [thiết bị đang dùng, lịch sử đăng nhập, đăng xuất])
└── FAB "+" → Quick Add sheet
```
Điều hướng: `go_router`, deep link `remindme://item/<id>`, `remindme://trip/<id>`, `remindme://import/<id>`.

## 2. Màn hình chính (wireframe)

### 2.1 Hôm nay
```
┌─────────────────────────────────┐
│ Hôm nay · T5 26/11   (14/10 ÂL) │
│ [7/10 nhắc hôm nay ▓▓▓▓▓▓▓░░░]  │  ← QuotaMeter chỉ hiện với Free
├─────────────────────────────────┤
│ ✈ Chuyến Hà Nội · mai 10:30     │  ← BookingCard thu gọn
│   VN245 SGN→HAN  [Mở vé]        │
├─────────────────────────────────┤
│ QUÁ HẠN                         │
│ ○ 09:00  Gửi báo giá   🔴 Quá hạn│
│ HÔM NAY                         │
│ ○ 14:30  Họp khách · Công việc  │
│ ○ 20:00  Uống thuốc 🔁           │
│ KHÔNG GIỜ                        │
│ ○ Mua quà sinh nhật             │
├─────────────────────────────────┤
│  Hôm nay  Lịch  (+)  Chuyến  Tôi│
└─────────────────────────────────┘
```
Vuốt phải: Xong. Vuốt trái: Hoãn (mở SnoozePicker). Nhấn giữ: chọn nhiều.

### 2.2 Quick Add (bottom sheet)
```
┌─────────────────────────────────┐
│ Mai 8h sáng họp khách #congviec │
│ [📅 T6 27/11 08:00] [#Công việc]│  ← chip phân tích trực tiếp, chạm để sửa
│ [🔔 trước 15'] [🔁 Không lặp]    │
├─────────────────────────────────┤
│ 🎤 Nói   📷 Chụp   🖼 Ảnh   📎 File│
│                       [  Lưu  ] │
└─────────────────────────────────┘
```
- Mic: nhấn giữ để nói, thả để dừng (hoặc chạm 1 lần, tự dừng khi im 1,5 s). Hiện transcript realtime.
- Chụp/Ảnh/File: chuyển sang luồng Import (2.4).
- "Lưu" bị vô hiệu nếu chưa có tiêu đề; Enter = Lưu; Shift+Enter/nút "+ việc khác" để thêm liên tiếp.

### 2.3 Chi tiết item
Tiêu đề, ghi chú (markdown nhẹ), thời gian (bắt đầu/kết thúc, cả ngày, múi giờ), lặp (preset + tùy chỉnh + âm lịch),
nhắc (nhiều mốc, kiểu báo thức), list, tag, ưu tiên, checklist, vị trí, nguồn ("Từ email Vietjet 24/11" + mở bản gốc).

### 2.4 Import → Xem lại
```
Bước 1 Chọn/chụp    Bước 2 Đọc trên máy          Bước 3 Xem lại
┌──────────────┐    ┌──────────────────────┐    ┌──────────────────────────┐
│ [ảnh vé]     │ →  │ Đang đọc vé…  ~2 giây│ →  │ Tìm thấy 2 mục            │
│ Cắt/xoay     │    │ ▓▓▓▓▓░░              │    │ ☑ ✈ VN245 SGN→HAN         │
└──────────────┘    │ 🔒 Xử lý trên máy,    │    │   20/12 10:30 ⚠ (giờ đến?)│
                    │ không gửi lên mạng   │    │   Mã: ABC123  Ghế 12A     │
                    └──────────────────────┘    │ ☑ 🏨 Mường Thanh 20-22/12 │
                                                │ Gộp vào: [Chuyến Hà Nội ▾]│
                                                │ Sẽ dùng 2/10 lịch hẹn Free│
                                                │ [Sửa]        [Lưu tất cả] │
                                                └──────────────────────────┘
```
- Lỗi đọc: "Không đọc được ảnh này. Thử ảnh rõ hơn hoặc nhập tay" + nút "Nhập tay với ảnh làm tham chiếu".
- **Nhập tay có ảnh làm tham chiếu**: ảnh ở nửa trên (zoom được), form ở nửa dưới; chạm 1 dòng chữ trên ảnh (từ kết quả OCR)
  để điền vào trường đang chọn. Đây là đường cứu cho tài liệu chưa có mẫu, nên phải nhanh hơn gõ tay.
- Có thêm nút nhỏ "Gửi mẫu để cải thiện (đã che thông tin cá nhân)" sau khi người dùng phải sửa ≥ 2 trường.
- Trường do LLM của máy điền có nhãn nhỏ "✨ AI trên máy" và luôn tô vàng.
- Trường tô vàng phải được xác nhận trước khi lưu (Figma 15/15b/16): còn mục đang chọn có trường vàng thì nút chính là
  "Kiểm tra để tiếp tục" và mở form của mục đó; form có thẻ "Bạn kiểm tra giúp mình" liệt kê các trường vàng, nút "Đúng, giữ nguyên"
  xác nhận cả nhóm, sửa 1 trường thì trường đó hết vàng. Bỏ chọn mục cũng mở khóa nút lưu. Sau khi xác nhận: thẻ xanh "Đã kiểm tra".
- "Gộp vào" là thẻ chạm để mở danh sách chọn (chuyến mới / chuyến đang có / không gộp); dòng hạn mức lịch hẹn lấy từ cache `quota_status`.
- PDF scan nhiều trang: hiện tiến trình theo trang, cho phép hủy.
- Không phải booking (ví dụ ảnh bảng công việc): hiện danh sách task trích được, cho chọn.

### 2.5 Chi tiết chuyến đi
Header ảnh điểm đến + ngày; timeline dọc theo giờ địa phương; mỗi segment là `BookingCard`; khoảng trống > 3h giữa 2 segment
hiện gợi ý "Thêm hoạt động"; tab Tài liệu (file gốc, QR); Checklist hành lý (mẫu: CCCD/hộ chiếu, sạc, thuốc…).

### 2.6 Lịch
Tháng: chấm màu theo loại, ngày âm nhỏ dưới ngày dương (bật/tắt), ngày rằm/mùng 1 có dấu `lunar`. Chạm ngày → danh sách ngày đó.

## 3. Luồng quan trọng

### 3.1 Onboarding (≤ 4 màn, bỏ qua được)
1. Giá trị: "Chụp vé, nói một câu, RemindMe lo phần nhắc." Ngôn ngữ, định dạng, múi giờ lấy từ máy; có link nhỏ "Đổi ngôn ngữ".
2. Chọn mục tiêu (nhiều lựa chọn): Công việc · Du lịch · Sức khỏe/thuốc · Gia đình & dịp lễ · Học tập. Dùng để cá nhân hóa list mẫu, nhắc mặc định,
   và gợi ý bật hệ lịch phụ theo vùng (âm lịch ở VN/TQ/HQ/SG, Hijri ở Trung Đông/ID/MY).
3. Thử ngay: ô Quick Add với câu gợi ý theo ngôn ngữ ("Mai 8h uống thuốc" / "Take pills tomorrow at 8am"). Tạo nhắc đầu tiên.
4. **Xin quyền đúng lúc** (priming screen trước dialog hệ thống): thông báo (sau khi tạo nhắc đầu tiên), exact alarm (Android, khi tạo nhắc có giờ),
   micro (khi bấm mic lần đầu), camera (khi bấm chụp), lịch (khi bật đồng bộ).
5. Android OEM có nguy cơ kill: màn "Đảm bảo nhắc nhở luôn kêu" với hướng dẫn từng bước theo hãng + nút mở đúng trang cài đặt + nút "Gửi thông báo thử sau 1 phút".
Đăng nhập: đề xuất sau khi có ≥ 3 item ("Lưu lại để không mất khi đổi máy"), không bắt buộc lúc đầu.

### 3.2 Thông báo → hành động
```
[RemindMe] ⏰ 20:00 Uống thuốc huyết áp
Còn 1 lần hôm nay
[ Xong ] [ Hoãn 10' ] [ Hoãn 1h ]
```
- Nhắc kiểu báo thức không bấm gì: nhắc lại sau 5', tối đa 3 lần (kiểu Due), cấu hình được.
- Chuyến bay: `✈ Còn 3 giờ: VN245 SGN→HAN 10:30 · Nhà ga T1` → [Mở vé] [Chỉ đường].

### 3.3 Chạm giới hạn → Paywall
Thông điệp theo ngữ cảnh (`pricing-entitlements.md` mục 4) → `PaywallSheet` → mua → xác nhận "Đã mở khóa Plus" → quay lại đúng hành động dở (tạo item tiếp).
Đóng paywall: item lưu ở `pending_quota`, không mất dữ liệu người dùng đã nhập (`pricing-entitlements.md` §3).

### 3.4 Chuyển nhà từ Microsoft To Do
Tôi → Tích hợp → "Chuyển từ Microsoft To Do" → đăng nhập Microsoft → chọn list → xem trước số lượng → Import → báo cáo.
Vượt giới hạn Free: import đủ nhưng các mục vượt ở `archived` (`archived_reason='quota'`), kèm ưu đãi "Plus 1 tháng miễn phí cho người chuyển từ To Do" (thử nghiệm).

### 3.5 Kết nối email forward
Tôi → Tích hợp → Email → hiện địa chỉ riêng (nút Copy) → hướng dẫn 3 bước tạo filter Gmail/Outlook (ảnh minh họa theo ngôn ngữ) → "Gửi email thử" → xác nhận nhận được.

### 3.6 Xung đột ghi chú
Khi 2 thiết bị sửa cùng ghi chú lúc offline (`system-architecture.md` §4): item hiện nhãn "Có 2 phiên bản"; mở ra thấy 2 bản cạnh nhau
(thiết bị + thời gian sửa), nút "Giữ bản này", "Giữ bản kia", "Gộp cả hai" (nối 2 đoạn).

### 3.7 Đăng nhập trên thiết bị khác (ADR-013)
- **Máy mới, trước khi vào:** sau đăng nhập, app gọi `session_status(device_id, platform, device_class)`. Nếu `will_replace` có máy: hộp thoại
  "Tài khoản đang dùng trên {device_model} (hoạt động {relative_time}). Tiếp tục sẽ đăng xuất thiết bị đó." [Tiếp tục] [Hủy].
  Gói Free thêm dòng `paywall_devices` + nút [Nâng cấp Plus] (Plus: điện thoại + tablet + máy tính cùng lúc; máy tính ghi "sắp có" tới Phase 4). Plus chỉ thấy hộp thoại khi đăng nhập máy thứ 2 cùng loại.
  Hủy thì đăng xuất ngay trên máy mới (phiên chưa claim không đọc được dữ liệu).
- **Máy cũ, khi nhận `session.revoked` hoặc lỗi `session_revoked`:** hủy mọi thông báo đã lập lịch, rồi màn toàn trang
  "Bạn đã được đăng xuất vì tài khoản vừa đăng nhập trên {device_model} lúc {time}." Nếu không phải bạn: nút "Đổi mật khẩu / bảo mật tài khoản".
  Có thay đổi chưa đồng bộ: "Còn {count} thay đổi chưa đồng bộ, sẽ được đồng bộ khi bạn đăng nhập lại tài khoản này." [Đăng nhập lại].
- **Đăng nhập tài khoản khác trên máy có dữ liệu chưa đồng bộ:** cảnh báo "{count} thay đổi của tài khoản trước sẽ bị xóa khỏi máy này" [Xuất trước] [Tiếp tục].
- **Cài đặt → Tài khoản & thiết bị:** thiết bị đang dùng; lịch sử đăng nhập (mẫu máy, nền tảng, quốc gia, thời điểm đăng nhập/kết thúc, lý do:
  "Đăng nhập ở máy khác", "Đã đăng xuất", "Hết gói Plus"); Plus thấy danh sách máy đang hoạt động theo loại, nút Đăng xuất từng máy. Không hiện IP đầy đủ, chỉ quốc gia.

## 4. Đồng hồ (Phase 2)
- watchOS: màn chính danh sách "Tiếp theo" (5 item), chạm → chi tiết + Xong/Hoãn; nút mic thêm nhanh; complication: item tiếp theo + giờ.
- Wear OS: Tile "Hôm nay" (3 item + nút +), complication "Tiếp theo", app Compose cùng chức năng.
- Chuyến bay ngày bay: thẻ lớn giờ đi, cổng, ghế, mã QR boarding (nếu có).

## 5. Widget (Phase 2)
Nhỏ: item tiếp theo. Vừa: 3-4 item hôm nay + checkbox (interactive). Lớn: hôm nay + chuyến đi sắp tới. Nút nhanh: "🎤 Nói để thêm".

## 6. Microcopy (giọng văn)
- Nguyên tắc chung mọi ngôn ngữ: câu ngắn, động từ trước ("Hoãn 10 phút" / "Snooze 10 min"), không đổ lỗi người dùng, nói điều làm được tiếp theo.
- Xưng hô, độ trang trọng từng ngôn ngữ: style guide theo locale (`architecture/i18n-l10n.md` §8). Tiếng Việt xưng "bạn".
- Chuỗi tiếng Anh (ngôn ngữ nguồn) và store listing tiếng Anh chạy `tools/unslop-docs.sh` rồi người duyệt.

## 6b. Trạng thái lỗi và trống (mỗi màn phải có)
| Tình huống | Hiển thị | Hành động |
|---|---|---|
| Offline | Banner nhỏ "Đang offline. Nhắc vẫn kêu đúng giờ, dữ liệu sẽ đồng bộ khi có mạng." | Không chặn thao tác |
| Sync lỗi lặp lại | Icon cảnh báo ở Tôi → Đồng bộ, chi tiết lỗi | "Thử lại", "Gửi báo lỗi" |
| Thiếu quyền thông báo / exact alarm | Thẻ đỏ trên Hôm nay "Nhắc nhở có thể không kêu" | Mở đúng trang cài đặt |
| Hết quota | `QuotaMeter` + paywall theo ngữ cảnh | Nâng cấp / lưu trữ bớt |
| OCR không đọc được | "Không đọc được ảnh này" | Thử ảnh khác / nhập tay với ảnh tham chiếu |
| Locale giọng nói không khả dụng | "Ngôn ngữ này chưa nhận dạng được trên máy bạn" | Đổi ngôn ngữ giọng nói / tải nhận dạng nâng cao |
| Danh sách trống (Hôm nay, Chuyến đi, Hộp đề xuất) | `EmptyState` + 1 câu + 1 CTA (ví dụ "Chia sẻ ảnh vé vào RemindMe") | |
| Tích hợp hết hạn token | Thẻ ở Tích hợp | "Kết nối lại" |

## 6c. Hỗ trợ người dùng
Tôi → Trợ giúp: FAQ theo ngôn ngữ (help center), "Gửi phản hồi / báo lỗi" (kèm log kỹ thuật nếu người dùng đồng ý, không kèm nội dung item),
hướng dẫn hoàn tiền (chuyển sang trang của App Store/Play), trang trạng thái dịch vụ.

## 7. Kiểm thử UX
- 5 người/persona, mỗi thị trường đợt 1 ít nhất 1 vòng; bài test: tạo nhắc lặp (âm lịch với persona châu Á), import ảnh vé, hoãn từ thông báo,
  tìm mã đặt chỗ khi ở sân bay (≤ 2 chạm từ thông báo), nhập bằng giọng vùng của mình.
- Persona *Persona Walkthrough Specialist* và *UX Researcher* chạy walkthrough trên prototype trước khi code từng luồng P0.
