# PRD: RemindMe

> TL;DR: Vấn đề, mục tiêu (nguồn chuẩn của KPI), persona, user story có tiêu chí chấp nhận, phạm vi và những gì không làm.
> Thị trường: **global từ launch**, tiếng Việt là một trong hai ngôn ngữ cấp A (`architecture/i18n-l10n.md` §2).
> Ưu tiên: **P0** = Phase 1 (MVP), **P1** = Phase 2, **P2** = Phase 3, **P3** = Phase 4+. Giá/giới hạn: `pricing-entitlements.md`.

## 1. Vấn đề
1. Việc cần nhớ nằm rải rác: email booking, ảnh chụp vé, file Excel công việc, ghi chú, tin nhắn (WhatsApp, Zalo, LINE...), lời dặn miệng.
   Chép tay vào app todo tốn công nên người dùng bỏ dở.
2. App todo phổ biến (Todoist, TickTick) không hiểu vé máy bay/khách sạn. App du lịch (TripIt, Tripsy) không phải app nhắc việc,
   và tính năng đọc ảnh/PDF của chúng chủ yếu chạy trên iOS có Apple Intelligence.
3. Nhập bằng ngôn ngữ mẹ đẻ và giọng vùng miền còn kém: app phổ biến hiểu tốt tiếng Anh chuẩn, hiểu kém tiếng Việt (nhất là giọng miền Trung),
   tiếng Anh Ấn/Úc, tiếng Tây Ban Nha Mỹ Latinh. Nhiều nền văn hóa cần nhắc theo hệ lịch riêng (âm lịch VN/TQ/HQ, Hijri) mà app quốc tế không có.
4. Trên Android phổ thông (Xiaomi, OPPO, vivo... chiếm phần lớn máy bán ra ở châu Á, Mỹ Latinh), nhắc nhở hay bị trễ hoặc mất do hệ điều hành tự đóng app chạy nền.
5. Microsoft To Do ngừng app ngày 30/06/2027, người dùng tài khoản cá nhân phải tìm app khác.

## 2. Mục tiêu và chỉ số
| Mục tiêu | Chỉ số | Mốc 6 tháng sau launch |
|---|---|---|
| Nhập việc thật nhanh | Thời gian trung vị từ mở app tới lưu nhắc | < 8 giây |
| Biến booking thành lịch trình tự động | % import ảnh/pdf được lưu mà không sửa trường nào | ≥ 70% |
| Nhắc đáng tin cậy | % thông báo kêu trong ±60 s (`late_ms`) | ≥ 99,5% (theo OEM) |
| Hiểu đúng ngôn ngữ | Intent accuracy của Quick Add/giọng nói theo locale và vùng | Đạt ngưỡng cấp A/B (`architecture/voice-and-text-input.md` §7) |
| Giữ chân | D30 retention | ≥ 25% |
| Doanh thu | Free→Plus trong 30 ngày | 3-5% |
| North Star | Số "nhắc được hoàn thành"/người dùng hoạt động/tuần | theo dõi, tăng đều |

## 3. Persona
| Persona | Mô tả | Nhu cầu chính |
|---|---|---|
| **Lan, 29, nhân viên văn phòng HCM** | Nhiều deadline, nhận việc qua Excel, đi công tác 1-2 lần/tháng | Import xlsx, nhắc deadline, lịch trình công tác từ email |
| **Minh, 35, trưởng nhóm, hay bay** | Đặt vé Vietnam Airlines/Vietjet, khách sạn Agoda | Forward email/ảnh vé → lịch trình, nhắc ra sân bay, đồng hồ báo cổng |
| **Bà Hoa, 62, nội trợ** (người thân cài giúp) | Uống thuốc, lịch tái khám, giỗ chạp | Nhắc lặp, âm lịch, chữ to, nói để thêm việc |
| **Tuấn, 21, sinh viên** | Lịch học, deadline, thói quen | Gói Free, habit, widget |
| **Chi, 40, người dùng Microsoft To Do** | Dùng To Do 5 năm | Chuyển nhà nhanh, không mất dữ liệu |
| **Sarah, 34, tư vấn viên ở London** | Bay công tác châu Âu, dùng Trainline/Booking.com, nói tiếng Anh Anh | Forward email → chuyến đi, "half seven" hiểu đúng 7:30, giờ địa phương khi qua múi giờ/DST |
| **Diego, 28, kỹ sư ở Mexico City** | Android tầm trung, nói tiếng Tây Ban Nha Mexico | Nhập giọng nói es-MX, nhắc không bị OEM kill, giá phù hợp sức mua |
| **Aisha, 31, giáo viên ở Kuala Lumpur** | Đa ngôn ngữ (Malay/Anh), lịch Hijri cho Ramadan | Câu pha 2 ngôn ngữ, nhắc theo lịch Hijri (Phase 2) |

## 4. User stories và tiêu chí chấp nhận (MVP = P0)
### Nhập liệu
- **US-01 (P0)** Gõ câu tự nhiên ("mai 8h họp khách", "dentist next Tue 3pm") thì app hiểu giờ và tạo nhắc. *AC:* gói NLU của locale đạt ngưỡng cấp A/B; chạy offline; hiện xem trước theo định dạng vùng trước khi lưu; câu mơ hồ hiện chip lựa chọn.
- **US-02 (P0)** Nói thay vì gõ, đúng giọng vùng. *AC:* chọn ngôn ngữ giọng nói riêng với ngôn ngữ giao diện; STT của OS với biến thể vùng (en-GB, es-MX...); bias từ vựng người dùng; câu pha 2 ngôn ngữ; nhiều việc trong 1 câu; mic trên widget/watch ở Phase 2.
- **US-02b (P1)** "Nhận dạng nâng cao" tải model trên máy (PhoWhisper cho tiếng Việt nhiều vùng miền, Whisper đa ngữ).
- **US-03 (P0)** Chụp/chia sẻ ảnh vé → lịch trình. *AC:* xử lý hoàn toàn trên máy, chạy offline; hỗ trợ vé máy bay, tàu, xe khách, khách sạn, giấy hẹn khám; chất lượng và tốc độ đạt `architecture/on-device-extraction.md` §11-12; trường nghi ngờ được đánh dấu; có chế độ "nhập tay với ảnh làm tham chiếu".
- **US-04 (P0)** Import PDF booking/e-ticket. *AC:* PDF có text và PDF scan; ≤ 20 trang (Free).
- **US-05 (P0)** Import xlsx/csv danh sách việc. *AC:* nhận diện cột Ngày/Giờ/Việc/Ghi chú bằng header ở ngôn ngữ cấp A/B; xem trước 10 dòng; đổi mapping cột; import ≥ 1.000 dòng.
- **US-06 (P0)** Import `.md` (Obsidian Tasks). *AC:* `- [ ]`, `📅`, `⏰`, `🔁` được hiểu; heading → list.
- **US-07 (P0)** Forward email booking tới địa chỉ riêng. *AC:* server chỉ lưu và chuyển MIME về máy; máy xử lý JSON-LD/ICS/PDF/ảnh đính kèm/text; kết quả vào Hộp đề xuất kèm push.
- **US-08 (P0)** Import từ Microsoft To Do. *AC:* list, task, due, reminder, recurrence, steps; báo cáo số mục đã nhập/lỗi.
- **US-09 (P1)** Import Todoist/TickTick (API/CSV).

### Nhắc nhở
- **US-10 (P0)** Nhắc đúng giờ cả khi offline. *AC:* NFR ±60 s; sống sót reboot, đổi múi giờ, **chuyển DST** (`reminder-engine.md` §5); onboarding chống OEM kill.
- **US-11 (P0)** Lặp: hằng ngày/tuần/tháng/năm, ngày làm việc (theo cuối tuần + ngày lễ của quốc gia), mỗi N giờ trong khung giờ, sau khi hoàn thành N ngày. *AC:* tương thích RRULE.
- **US-12 (P0)** Lặp theo âm lịch VN/TQ/HQ (rằm, mùng 1, giỗ, Tết). *AC:* đúng 2020-2050 so với bảng tra từng nước; xử lý tháng nhuận. Hijri: **P1**.
- **US-12b (P0)** Hiển thị ngày lễ quốc gia trong lịch và gợi ý dời nhắc công việc rơi vào ngày lễ.
- **US-13 (P0)** Hành động từ thông báo: Xong, Hoãn 10', Hoãn 1h, Mở. *AC:* không cần mở app; đồng bộ sang thiết bị khác.
- **US-14 (P0)** Nhắc mặc định thông minh cho booking (bảng trong `reminder-engine.md` mục 5), người dùng sửa được.
- **US-15 (P1)** Nhắc kiểu báo thức (âm to, lặp đến khi bấm) cho nhắc thuốc/chuyến bay.
- **US-16 (P1)** Nhắc theo vị trí (đến/rời khỏi).

### Lịch trình & chuyến đi
- **US-20 (P0)** Màn chuyến đi dạng timeline: bay → khách sạn → tàu..., hiện giờ địa phương mỗi điểm.
- **US-21 (P0)** Tự gom booking vào chuyến đi (gợi ý, người dùng xác nhận).
- **US-22 (P1)** Mở mã đặt chỗ/QR/boarding pass nhanh từ thông báo và watch.
- **US-23 (P2)** Trạng thái chuyến bay realtime (Plus).
- **US-24 (P1)** Lịch khám bệnh: loại `appointment` với checklist chuẩn bị (giấy tờ, nhịn ăn), nhắc tái khám lặp.

### Đồng bộ & tích hợp
- **US-30 (P0)** Đăng nhập Google/Apple/email; dùng thử không tài khoản.
- **US-31 (P0)** Đồng bộ nhiều thiết bị.
- **US-32 (P1)** Feed ICS xuất ra lịch khác (Plus).
- **US-33 (P1)** Google Calendar 2 chiều.
- **US-34 (P1)** Notion database sync, Google Tasks.
- **US-35 (P2)** Quét Gmail tự động, chạy trên máy (Plus).
- **US-36 (P0)** "Thêm vào lịch máy" (EventKit / CalendarContract) cho từng item hoặc tự động cho booking.

### Thiết bị đeo
- **US-40 (P0)** Thông báo hiện trên Apple Watch / Wear OS / đồng hồ khác với action.
- **US-41 (P1)** App watch: Hôm nay, chuyến sắp tới, Done, thêm bằng giọng nói, complication/tile.

### Tài khoản & thanh toán
- **US-50 (P0)** Gói Free có giới hạn theo `pricing-entitlements.md`; hiển thị mức đã dùng trong Cài đặt.
- **US-51 (P0)** Mua Plus tháng/quý/năm, khôi phục mua hàng, quản lý/hủy.
- **US-52 (P0)** Xóa tài khoản và dữ liệu, xuất dữ liệu (JSON theo schema có version + ICS), định dạng ở `security-privacy.md` §6.
- **US-54 (P0)** Free: tài khoản chỉ hoạt động trên 1 thiết bị; Plus: 1 điện thoại + 1 tablet + 1 máy tính cùng lúc. Vượt giới hạn thì máy cũ (cùng loại, hoặc ít dùng nhất) bị đăng xuất; xem lịch sử đăng nhập. *AC:* máy cũ mất quyền đọc/ghi ngay (không đợi token hết hạn), hủy thông báo đã lập lịch, hiện máy nào đã đăng nhập; máy mới được hỏi xác nhận trước khi đá; lịch sử có thiết bị, nền tảng, quốc gia, thời gian, lý do; giới hạn lấy từ `max_active_devices`, `max_devices_per_class`; hạ gói tự cắt về giới hạn Free (ADR-013).
- **US-53 (P0)** Chọn ngôn ngữ giao diện riêng cho app, định dạng vùng, quốc gia ngày lễ (`architecture/i18n-l10n.md` §3).

## 5. Phi mục tiêu (không làm ở v1)
- Gọi AI API đám mây trả phí để đọc tài liệu (ADR-010).
- Cộng tác nhóm / chia sẻ list nhiều người (cân nhắc v2: chia sẻ chuyến đi cho gia đình).
- Bản web và desktop (Phase 4; người dùng dùng feed ICS trong lúc chờ).
- Phát hành ở Trung Quốc đại lục (không có FCM/Google services, cần đăng ký ICP).
- Ngôn ngữ RTL ở launch (kiến trúc sẵn sàng, phát hành ở đợt locale 3).
- Đặt vé trong app / affiliate (v3, cân nhắc nguồn doanh thu phụ).
- Quản lý dự án kiểu Kanban/Gantt.
- Nhắc qua SMS.

## 6. Giả thuyết cần kiểm chứng sớm
| Giả thuyết | Cách kiểm chứng | Ngưỡng |
|---|---|---|
| Người dùng sẽ forward email booking | % người dùng kích hoạt địa chỉ forward trong beta, theo thị trường | ≥ 20% người có ít nhất 1 booking |
| Hỗ trợ giọng vùng tốt là lý do chọn app | Khảo sát + retention cohort theo `voice_locale` | Cohort dùng giọng nói có D30 cao hơn ≥ 5 điểm % |
| Import ảnh là lý do chính để trả tiền | Paywall test: mở khóa import vs mở khóa lặp | So sánh conversion |
| Gói quý được chọn đủ nhiều | Phân bổ gói đã mua | ≥ 15% giao dịch |
| Hệ lịch riêng (âm lịch, Hijri) tăng retention | Cohort có dùng vs không, theo thị trường | D30 cao hơn ≥ 5 điểm % |
