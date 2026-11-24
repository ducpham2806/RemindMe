# UX: kiến trúc thông tin, luồng, màn hình

> TL;DR: 4 tab (Hôm nay · Lịch · Chuyến đi · Tôi) + FAB "+" mở Quick Add đa phương thức.
> Luồng quan trọng: Onboarding + xin quyền, Quick Add, Import → Xem lại, Thông báo → hành động, Paywall, Chuyển nhà từ To Do.
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
├── Tôi
│   ├── Danh sách (lists) & Hộp thư (Inbox)
│   ├── Hộp đề xuất (kết quả từ email/import chưa duyệt)
│   ├── Tích hợp (Google, Microsoft, Notion, email forward, feed ICS, đồng hồ)
│   ├── Gói & mức sử dụng (QuotaMeter)
│   └── Cài đặt (thông báo, giờ yên lặng, âm lịch, giao diện, chữ lớn, độ tin cậy nhắc, dữ liệu & quyền riêng tư)
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
- PDF scan nhiều trang: hiện tiến trình theo trang, cho phép hủy.
- Không phải booking (ví dụ ảnh bảng công việc): hiện danh sách task trích được, cho chọn.

### 2.5 Chi tiết chuyến đi
Header ảnh điểm đến + ngày; timeline dọc theo giờ địa phương; mỗi segment là `BookingCard`; khoảng trống > 3h giữa 2 segment
hiện gợi ý "Thêm hoạt động"; tab Tài liệu (file gốc, QR); Checklist hành lý (mẫu: CCCD/hộ chiếu, sạc, thuốc…).

### 2.6 Lịch
Tháng: chấm màu theo loại, ngày âm nhỏ dưới ngày dương (bật/tắt), ngày rằm/mùng 1 có dấu `lunar`. Chạm ngày → danh sách ngày đó.

## 3. Luồng quan trọng

### 3.1 Onboarding (≤ 4 màn, bỏ qua được)
1. Giá trị: "Chụp vé, nói một câu, RemindMe lo phần nhắc."
2. Chọn mục tiêu (nhiều lựa chọn): Công việc · Du lịch · Sức khỏe/thuốc · Gia đình & giỗ chạp · Học tập. Dùng để cá nhân hóa list mẫu và nhắc mặc định.
3. Thử ngay: ô Quick Add với câu gợi ý "Mai 8h uống thuốc". Tạo nhắc đầu tiên.
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
Đóng paywall: item ở trạng thái nháp, không mất dữ liệu người dùng đã nhập.

### 3.4 Chuyển nhà từ Microsoft To Do
Tôi → Tích hợp → "Chuyển từ Microsoft To Do" → đăng nhập Microsoft → chọn list → xem trước số lượng → Import → báo cáo.
Vượt giới hạn Free: import đủ nhưng các mục vượt ở trạng thái `archived`, kèm ưu đãi "Plus 1 tháng miễn phí cho người chuyển từ To Do" (thử nghiệm).

### 3.5 Kết nối email forward
Tôi → Tích hợp → Email → hiện địa chỉ riêng (nút Copy) → hướng dẫn 3 bước tạo filter Gmail (ảnh minh họa) → "Gửi email thử" → xác nhận nhận được.

## 4. Đồng hồ (Phase 2)
- watchOS: màn chính danh sách "Tiếp theo" (5 item), chạm → chi tiết + Xong/Hoãn; nút mic thêm nhanh; complication: item tiếp theo + giờ.
- Wear OS: Tile "Hôm nay" (3 item + nút +), complication "Tiếp theo", app Compose cùng chức năng.
- Chuyến bay ngày bay: thẻ lớn giờ đi, cổng, ghế, mã QR boarding (nếu có).

## 5. Widget (Phase 2)
Nhỏ: item tiếp theo. Vừa: 3-4 item hôm nay + checkbox (interactive). Lớn: hôm nay + chuyến đi sắp tới. Nút nhanh: "🎤 Nói để thêm".

## 6. Microcopy (giọng văn)
- Xưng "bạn", câu ngắn, động từ trước: "Hoãn 10 phút", "Lưu tất cả", "Thử ảnh rõ hơn".
- Không đổ lỗi người dùng; nói điều làm được tiếp theo.
- Lỗi mạng: "Đang offline. Nhắc vẫn kêu đúng giờ, dữ liệu sẽ đồng bộ khi có mạng."
- Mọi chuỗi qua `tools/unslop-docs.sh` cho docs; chuỗi UI rà bằng mắt (persona *Brand Guardian*).

## 7. Kiểm thử UX
- 5 người/persona, bài test: tạo nhắc lặp âm lịch, import ảnh vé, hoãn từ thông báo, tìm mã đặt chỗ khi ở sân bay (≤ 2 chạm từ thông báo).
- Persona *Persona Walkthrough Specialist* và *UX Researcher* chạy walkthrough trên prototype trước khi code từng luồng P0.
