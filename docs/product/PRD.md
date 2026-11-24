# PRD: RemindMe

> TL;DR: Vấn đề, mục tiêu, persona, user story có tiêu chí chấp nhận, phạm vi MVP và những gì không làm.
> Persona soạn: *Product Manager* (Agency): bắt đầu từ vấn đề, mọi tính năng là giả thuyết cần đo.
> Giá/giới hạn: `pricing-entitlements.md`. Kế hoạch: `docs/plan/implementation-plan.md`.

## 1. Vấn đề
1. Việc cần nhớ nằm rải rác: email booking, ảnh chụp vé, file Excel công việc, ghi chú, tin nhắn Zalo, lời dặn miệng.
   Chép tay vào app todo tốn công nên người dùng bỏ dở.
2. App todo phổ biến (Todoist, TickTick) không hiểu vé máy bay/khách sạn. App du lịch (TripIt, Tripsy) không phải app nhắc việc,
   và tính năng đọc ảnh/PDF của chúng chủ yếu chạy trên iOS có Apple Intelligence.
3. Người Việt cần nhắc theo âm lịch (giỗ, rằm, mùng 1) và nhập liệu tiếng Việt. Chưa app quốc tế nào làm tốt.
4. Trên điện thoại Android phổ thông ở VN (Xiaomi, OPPO, vivo chiếm ~47% máy bán ra), nhắc nhở hay bị trễ hoặc mất do hệ điều hành tự đóng app chạy nền.
5. Microsoft To Do ngừng app ngày 30/06/2027, người dùng tài khoản cá nhân phải tìm app khác.

## 2. Mục tiêu và chỉ số
| Mục tiêu | Chỉ số | Mốc 6 tháng sau launch |
|---|---|---|
| Nhập việc thật nhanh | Thời gian trung vị từ mở app tới lưu nhắc | < 8 giây |
| Biến booking thành lịch trình tự động | % import ảnh/pdf được lưu mà không sửa trường nào | ≥ 70% |
| Nhắc đáng tin cậy | % thông báo kêu trong ±60 s | ≥ 99,5% (theo OEM) |
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

## 4. User stories và tiêu chí chấp nhận (MVP = P0)
### Nhập liệu
- **US-01 (P0)** Gõ "mai 8h họp khách" thì app hiểu giờ và tạo nhắc. *AC:* fixtures `vi_datetime.json` pass ≥ 95%; chạy được offline; hiện xem trước "Thứ Năm 26/11, 08:00" trước khi lưu.
- **US-02 (P0)** Nói thay vì gõ. *AC:* nút mic trên quick-add, widget, và watch (Phase 2); STT vi-VN on-device; câu có nhiều việc tách thành nhiều item.
- **US-03 (P0)** Chụp/chia sẻ ảnh vé → lịch trình. *AC:* hỗ trợ vé máy bay, tàu, xe khách, khách sạn, giấy hẹn khám; màn Xem lại; p95 < 20 s; trường nghi ngờ được đánh dấu.
- **US-04 (P0)** Import PDF booking/e-ticket. *AC:* PDF có text và PDF scan; ≤ 20 trang (Free).
- **US-05 (P0)** Import xlsx/csv danh sách việc. *AC:* nhận diện cột Ngày/Giờ/Việc/Ghi chú; xem trước 10 dòng; cho phép đổi mapping cột; import ≥ 1.000 dòng.
- **US-06 (P0)** Import `.md` (Obsidian Tasks). *AC:* `- [ ]`, `📅`, `⏰`, `🔁` được hiểu; heading → list.
- **US-07 (P0)** Forward email booking tới địa chỉ riêng. *AC:* JSON-LD/ICS/PDF đính kèm/text đều được xử lý; kết quả vào Hộp đề xuất kèm push.
- **US-08 (P0)** Import từ Microsoft To Do. *AC:* list, task, due, reminder, recurrence, steps; báo cáo số mục đã nhập/lỗi.
- **US-09 (P1)** Import Todoist/TickTick (API/CSV).

### Nhắc nhở
- **US-10 (P0)** Nhắc đúng giờ cả khi offline. *AC:* NFR ±60 s; sống sót reboot, đổi múi giờ; onboarding chống OEM kill.
- **US-11 (P0)** Lặp: hằng ngày/tuần/tháng/năm, ngày làm việc, mỗi N giờ trong khung giờ, sau khi hoàn thành N ngày. *AC:* tương thích RRULE.
- **US-12 (P0)** Lặp âm lịch (rằm, mùng 1, giỗ). *AC:* đúng lịch VN 2020-2050 so với bảng tham chiếu; xử lý tháng nhuận.
- **US-13 (P0)** Hành động từ thông báo: Xong, Hoãn 10', Hoãn 1h, Mở. *AC:* không cần mở app; đồng bộ sang thiết bị khác.
- **US-14 (P0)** Nhắc mặc định thông minh cho booking (bảng trong `reminder-engine.md` mục 5), người dùng sửa được.
- **US-15 (P1)** Nhắc kiểu báo thức (âm to, lặp đến khi bấm) cho nhắc thuốc/chuyến bay.
- **US-16 (P2)** Nhắc theo vị trí (đến/rời khỏi).

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
- **US-34 (P2)** Notion database sync, Google Tasks.
- **US-35 (P3)** Quét Gmail tự động (Plus, sau CASA).

### Thiết bị đeo
- **US-40 (P0)** Thông báo hiện trên Apple Watch / Wear OS / đồng hồ khác với action.
- **US-41 (P1)** App watch: Hôm nay, chuyến sắp tới, Done, thêm bằng giọng nói, complication/tile.

### Tài khoản & thanh toán
- **US-50 (P0)** Gói Free có giới hạn theo `pricing-entitlements.md`; hiển thị mức đã dùng trong Cài đặt.
- **US-51 (P0)** Mua Plus tháng/quý/năm, khôi phục mua hàng, quản lý/hủy.
- **US-52 (P0)** Xóa tài khoản và dữ liệu, xuất dữ liệu (JSON + ICS).

## 5. Phi mục tiêu (không làm ở v1)
- Cộng tác nhóm / chia sẻ list nhiều người (cân nhắc v2: chia sẻ chuyến đi cho gia đình).
- Bản web và desktop (v2; người dùng dùng feed ICS trong lúc chờ).
- Đặt vé trong app / affiliate (v3, cân nhắc nguồn doanh thu phụ).
- Quản lý dự án kiểu Kanban/Gantt.
- Nhắc qua SMS.

## 6. Giả thuyết cần kiểm chứng sớm
| Giả thuyết | Cách kiểm chứng | Ngưỡng |
|---|---|---|
| Người dùng VN sẽ forward email booking | Đo % người dùng kích hoạt địa chỉ forward trong beta | ≥ 20% người có ít nhất 1 booking |
| Import ảnh là lý do chính để trả tiền | Paywall test: mở khóa import vs mở khóa lặp | So sánh conversion |
| Gói quý được chọn đủ nhiều | Phân bổ gói đã mua | ≥ 15% giao dịch |
| Âm lịch tăng retention | Cohort có dùng nhắc âm lịch vs không | D30 cao hơn ≥ 5 điểm % |
