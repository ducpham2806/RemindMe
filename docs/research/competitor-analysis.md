# RemindMe – Phân tích đối thủ & thị trường (cuối 2026)

> Persona: Product Trend Researcher. Dữ liệu thu thập 23–24/11/2026. Giá VND lấy trực tiếp từ App Store VN (storefront `vn`) ngày 24/11/2026; giá USD lấy từ trang chính thức khi có, nếu không thì từ nguồn thứ ba. Tỷ giá tham chiếu: ~25.900 VND/USD (Vietcombank bán ra 16/11/2026).
> Ký hiệu: **(chưa xác minh)** = chỉ có nguồn thứ ba, các nguồn mâu thuẫn, hoặc là suy luận của người viết.

---

## 1. Tóm tắt

- **Không đối thủ nào gộp được todo + nhắc việc + lịch trình du lịch + lịch khám bệnh trong một app đa nền tảng.** Nhóm todo (Todoist, TickTick, Any.do) không đọc được vé/booking. Nhóm du lịch (TripIt, Tripsy, Wanderlog) không phải app nhắc việc. Tripsy chỉ có trên Apple.
- **Microsoft To Do sẽ ngừng hoạt động ngày 30/06/2027.** Người dùng tài khoản cá nhân không có app thay thế nào của Microsoft, và Microsoft khuyên họ "chọn app khác". Đây là cơ hội thu hút người dùng trong khoảng 7 tháng tới, với điều kiện RemindMe có công cụ import dữ liệu từ To Do.
- **AI import bằng ảnh/PDF đã có ở nhóm du lịch nhưng hầu như chỉ trên iOS.** TripIt Pro import từ ảnh/PDF và Tripsy 3.10 Smart Import (09/2026) đều cần Apple Intelligence. Android (khoảng 84% lượng máy bán ra ở VN, theo Omdia Q2/2026) gần như chưa có app nào làm tốt việc này.
- **Giá VN đã được bản địa hoá mạnh, nhưng chênh lệch lớn giữa các app.** Theo tháng: TickTick 69.000đ, Structured 50–79k, Tripsy 99–119k, Any.do 139k, Todoist 199k. Theo năm: Structured 149–249k, TickTick 639k, Any.do 839k, TripIt 1.099k, Todoist 1.999k. Mức chịu chi tham chiếu: Spotify 65k/tháng, Google AI Plus 132k/tháng.
- **Free tier của đối thủ ngày càng chặt, nhất là với AI.** Todoist free chỉ có nhắc tự động và 10 phiên Ramble (voice/AI capture) mỗi tháng. Any.do free không có recurring task. TickTick free cho 2 nhắc nhở mỗi task. Motion không có free tier. Giới hạn hạn mức AI/OCR theo tháng đã là chuẩn chung.
- **Thị trường VN có những khoảng trống mà app ngoại chưa lấp:** nhắc theo âm lịch (giỗ, rằm, mùng 1), nhắc qua Zalo, đọc vé Vietjet/Vietnam Airlines/Vexere/Đường sắt và phiếu khám bệnh viện, và nhập liệu giọng nói tiếng Việt có giọng vùng miền. Trong nước mới có app lịch vạn niên (nhắc âm lịch, không có todo) và "Nhắc lịch AI" của Vbee (gọi điện nhắc, rất ngách).
- **Độ tin cậy của thông báo trên Android là rủi ro số 1 ở VN.** Xiaomi, OPPO và vivo chiếm khoảng 47% lượng máy bán ra, và ROM của các hãng này kill app chạy nền rất mạnh. App nhắc việc mà nhắc trễ thì xem như hỏng.
- **Khuyến nghị giá: 59.000đ/tháng, 149.000đ/quý, 449.000đ/năm.** Free: 10 nhắc/ngày, 5 recurring đang hoạt động, 10 cuộc hẹn/booking đang hoạt động, 10 lượt smart import/tháng (chi tiết ở mục 6).

---

## 2. Bảng so sánh tổng quan

| App | Nền tảng | AI / Import | Watch | Parse booking du lịch | Free tier (chính) | Giá US (tháng / năm) | Giá App Store VN (tháng / năm) |
|---|---|---|---|---|---|---|---|
| **Todoist** | iOS, Android, Web, Win, Mac | Ramble (voice→tasks, 38–40+ ngôn ngữ), Email Assist (Pro), NLP | Apple Watch, Wear OS (Ramble trên Wear OS: beta 03/2026) | Không | 5 project, 3 filter, chỉ nhắc tự động, 10 phiên Ramble/tháng | $7 / $60 | 199.000đ / 1.999.000đ |
| **TickTick** | iOS, Android, Web, Win, Mac | NLP, voice, lịch, habit, pomodoro | Apple Watch (Live Activities), Wear OS | Không | 9 list, 99 task/list, 2 nhắc/task (chưa xác minh) | US: chỉ có gói năm, $49,99 (tăng từ $35,99 năm 2026) | 69.000đ / 639.000đ |
| **Microsoft To Do** | iOS, Android, Web, Win, Mac | Không có AI riêng; Copilot Reminders (giới hạn 5) | Không có app Wear OS chính thức | Không | Miễn phí hoàn toàn | Miễn phí | Miễn phí. **Ngừng hoạt động 30/06/2027** |
| **Any.do** | iOS, Android, Web, Mac, Win | AI (chia nhỏ task, ưu tiên), bot WhatsApp | Apple Watch, Wear OS | Không | Task không giới hạn; **không có recurring task**, location reminder, WhatsApp, AI | $7,99 / $59,88 | 139.000đ / 839.000đ (khuyến mãi 67–92k) |
| **Google Tasks / Keep** | Android, iOS, Web | Gemini tạo task/nhắc; Keep Live (voice, gói AI) | Wear OS: tile Tasks; Keep trên Wear OS **không đặt được nhắc** từ 01/2026 | Không (Gmail/Calendar tự tạo event, chưa xác minh trong Tasks) | Miễn phí | Miễn phí (AI cần Google AI Plus) | Miễn phí; AI Plus 132.000đ/tháng |
| **Apple Reminders** | Chỉ iOS, iPadOS, macOS, watchOS | iOS 26: Apple Intelligence gợi ý nhắc từ email/text, tự chia section; có tiếng Việt từ iOS 26.1 | Apple Watch | Không (chỉ gợi ý danh sách việc từ email) | Miễn phí | Miễn phí | Miễn phí; AI chỉ chạy trên iPhone 15 Pro trở lên |
| **Things 3** | Chỉ iOS, iPadOS, macOS, watchOS | iOS 27: Siri AI, Spotlight (09/2026) | Apple Watch (app độc lập) | Không | Không có free (mua đứt) | iPhone $9,99, Mac $49,99, iPad $19,99 (mua một lần) | 209.000đ (iPhone, mua một lần) |
| **Due** | Chỉ iOS, macOS, watchOS | Không có AI; auto-snooze nhắc lại liên tục | Apple Watch (cần iPhone) | Không | Không có free | Khoảng $9,99 mua một lần + Annual Upgrade Pass (chưa xác minh) | 199.000đ + Upgrade Pass 99.000đ/năm |
| **TripIt** | iOS, Android, Web | Forward email, Inbox Sync; import ảnh/PDF (Pro + Apple Intelligence) | Apple Watch (watchOS 10+) | **Có**, mạnh nhất bằng email | Free: parse email, 3 tài liệu/chuyến (chưa xác minh) | Chỉ có gói năm, $49 | 1.099.000đ/năm |
| **Tripsy** | Chỉ iOS, iPadOS, macOS, watchOS | Smart Import (ảnh, PDF, text, link), Smart Insights trên thiết bị; tạo trip qua trợ lý AI | Apple Watch | **Có**, hơn 700 nhà cung cấp, forward email | Có bản free, import nâng cao cần Pro | $7,99 / $39,99–59,99 (tuỳ thời điểm) | 99–119k / 699k–1.199k |
| **Wanderlog** | iOS, Android, Web | Forward email (free), quét Gmail (Pro), tối ưu lộ trình | Không rõ (chưa xác minh) | Có, nhưng có phàn nàn bỏ sót booking | Lập kế hoạch free; offline cần Pro | Pro khoảng $39,99/năm (có vùng có gói tháng) | Chưa lấy được |
| **Motion** | Web, iOS, Android, desktop | AI tự xếp lịch, credit AI | Không | Không | **Không có free**, trial 7 ngày | $49 / $29 mỗi tháng nếu trả năm (Pro AI) | Chưa lấy được |
| **Structured** | iOS, Android, Mac, Web | Structured AI, Replan (Pro) | Apple Watch (chưa xác minh) | Không | Timeline, inbox, widget, thông báo free; recurring cần Pro | $6,99 / $29,99, lifetime $99,99 | 50–79k / 149–249k; lifetime 495k |
| **Amie** | iOS, Mac, Web | Hiện tập trung vào AI meeting notes | Không | Không | 25 credit meeting note (một lần) | Khoảng $20–25/tháng (nguồn mâu thuẫn) | Chưa lấy được |
| **Nhắc lịch AI (Vbee, VN)** | iOS (Android chưa xác minh) | AI **gọi điện** nhắc bằng TTS tiếng Việt, tạo nhắc bằng giọng nói | Không | Không | Có free (chưa rõ hạn mức) | n/a | 39k/tuần, 149k/tháng, 1.499k/năm |
| **Lịch Vạn Niên / Lịch Vạn Sự (VN)** | iOS, Android | Không | Không | Không | Free + quảng cáo | n/a | Free (một số có IAP) |
| **Zalo – Nhắc hẹn** | iOS, Android, PC | Không | Không | Không | Free, nhắc trong chat/nhóm, có lặp lại | n/a | Free |

---

## 3. Phân tích từng đối thủ

### Todoist (Doist)
- **Điểm mạnh:** NLP nhập nhanh tốt nhất nhóm. Ramble (GA 21/01/2026) chạy trên Gemini 2.5 Flash Live và hỗ trợ 38–40+ ngôn ngữ. Có app trên mọi nền tảng, kể cả Wear OS độc lập. Email Assist forward email thành task.
- **AI/Import:** Ramble cùng Task Capture Assist (text, file, ảnh) dùng chung quota 10 phiên/tháng ở bản free. Không parse booking.
- **Free:** 5 project, 3 filter, 1 lịch kết nối, file tối đa 5MB. **Nhắc tuỳ chỉnh, nhắc theo vị trí và nhắc lặp chỉ có ở Pro.**
- **Điểm yếu / phàn nàn:** Nhắc nhở bị khoá sau Pro. Giá VN 199k/tháng đắt nhất nhóm. Giá Pro tăng từ 12/2025. Ramble chưa có trên Apple Watch. Không rõ Ramble có hỗ trợ tiếng Việt không (chưa xác minh).

### TickTick
- **Điểm mạnh:** Tính năng đầy đủ nhất trong một app: task, lịch, habit, pomodoro, Eisenhower. Có watch cả hai nền tảng (Apple Watch có Live Activities). Giá VN rẻ (69k/tháng).
- **Free:** khoảng 9 list, 99 task/list, 2 nhắc/task. Calendar view và nhiều nhắc hơn cần Premium. Các nguồn ghi khác nhau (chưa xác minh).
- **Điểm yếu:** Tháng 11/2026 giá US tăng từ $35,99 lên $49,99 và chỉ còn gói năm. UI dày đặc. Complication trên Apple Watch không giữ thứ tự sắp xếp thủ công (review App Store). Không có AI import và không parse booking.

### Microsoft To Do
- **Tình trạng:** Ngừng hoạt động trên mọi nền tảng ngày **30/06/2027**. Tài khoản work/school chuyển sang Planner. **Tài khoản cá nhân không có app thay thế.** Microsoft hứa có công cụ export nhưng chưa có hướng dẫn. Shared list không được chuyển đi.
- **Ý nghĩa với RemindMe:** Cần có importer cho file export của To Do (định dạng chưa công bố) và nhập trực tiếp qua Microsoft Graph trước hạn đó, kèm landing page "chuyển từ To Do".

### Any.do
- **Điểm mạnh:** Có bot WhatsApp nhắc việc, mô hình gần với cơ hội "nhắc qua Zalo" ở VN. Có watch cả hai nền tảng. Có gói Family.
- **Free:** Task không giới hạn nhưng **không có recurring task**, location reminder, WhatsApp hay AI. Đây là tiền lệ cho việc khoá recurring sau gói trả phí.
- **Điểm yếu:** Giá VN phân mảnh (8 mức IAP, rất nhiều khuyến mãi), dễ khiến người dùng mất niềm tin. Trang hỗ trợ ghi không chạy trên "Samsung Watch" (có thể là thông tin cũ từ thời Tizen, chưa xác minh với Galaxy Watch chạy Wear OS).

### Google Tasks / Keep
- **Thay đổi gần đây:** Từ 10/2025, nhắc trong Keep được lưu vào Tasks và mất nhắc theo vị trí. Từ 01/2026, Keep trên Wear OS không đặt được nhắc nữa. Google hướng người dùng dùng Gemini để tạo nhắc.
- **Điểm mạnh:** Miễn phí, tích hợp sâu với Gmail và Calendar, Gemini có trên Wear OS từ 07/2025.
- **Điểm yếu:** Tasks quá đơn giản (không có nhắc nhiều mốc, không có ưu tiên). Không có app Tasks độc lập trên Wear OS. Tính năng AI mạnh (Keep Live) cần gói trả phí.
- **Ý nghĩa với RemindMe:** Đồng bộ hai chiều với Google Tasks và Calendar là yêu cầu tối thiểu ("table stakes") ở VN, nơi người dùng dùng Gmail rất phổ biến (chưa xác minh tỷ lệ).

### Apple Reminders
- **Điểm mạnh:** Free, đồng bộ iCloud, watch native. iOS 26 có gợi ý nhắc bằng Apple Intelligence từ email/text được share vào, auto-categorize, và hỗ trợ tiếng Việt từ iOS 26.1.
- **Điểm yếu:** Chỉ có trên Apple. AI chỉ chạy trên iPhone 15 Pro trở lên. Không parse booking thành lịch trình. Không có nhắc âm lịch.

### Things 3
- **Điểm mạnh:** UX được đánh giá cao, mua một lần (VN 209k cho iPhone), app Apple Watch độc lập, bản cập nhật iOS 27 có Siri AI (09/2026).
- **Điểm yếu:** Chỉ có trên Apple. Phải mua riêng cho Mac và iPad. Không có Things 4. Không có AI import. Không phù hợp thị trường VN thiên về Android.

### Due
- **Điểm mạnh:** Là chuẩn mực về **nhắc "dai"**: auto-snooze nhắc lại 5–10 lần với khoảng 1–60 phút cho tới khi người dùng xử lý. Đây là trải nghiệm mà RemindMe nên học.
- **Điểm yếu:** Chỉ có trên iOS. Mô hình mua đứt cộng Upgrade Pass. Rất ít người dùng ở VN (9 đánh giá). Không có AI.

### TripIt (SAP Concur)
- **Điểm mạnh:** Forward email về `plans@tripit.com` và Inbox Sync để tạo master itinerary. Pro ($49/năm) có cảnh báo chuyến bay, giảm giá vé, ghế tốt hơn. Từ 04/2026, Pro import được từ ảnh/PDF qua Apple Intelligence.
- **Điểm yếu:** Chỉ có gói năm (1.099.000đ ở VN). Import ảnh/PDF chỉ chạy trên iOS có Apple Intelligence. Không có todo hay nhắc việc chung. Không rõ mức hỗ trợ booking nội địa VN như Vexere hay Đường sắt (chưa xác minh).

### Tripsy
- **Điểm mạnh:** Bản 3.10 (09/2026) có Smart Import (screenshot, PDF, text, link Maps) và Smart Insights trên thiết bị (hành lý, bữa sáng, chính sách huỷ). Tự import từ hơn 700 nhà cung cấp. Theo dõi chuyến bay, có app Apple Watch, kết nối trợ lý AI để tạo trip.
- **Điểm yếu:** **Chỉ có trên Apple.** Giá VN phân mảnh (10 mức IAP, 79k–1.199k). Reviewer gặp trường hợp parse hỏng xác nhận khách sạn.

### Wanderlog
- **Điểm mạnh:** Lập kế hoạch cộng tác, bản đồ, tối ưu lộ trình. Forward email miễn phí.
- **Điểm yếu:** Quét Gmail chỉ có ở Pro. Người dùng phàn nàn bị bỏ sót booking (03/2026) và lỗi kết nối. Thiên về lên kế hoạch hơn là nhắc việc.

### Nhóm AI-first (Motion, Structured, Amie)
- **Motion:** AI tự xếp lịch, Pro AI $29/tháng (trả theo năm) hoặc $49/tháng, không có free. Giá quá cao với thị trường VN, chỉ dùng tham khảo cho tính năng tự xếp lịch.
- **Structured:** Planner dạng timeline. Free khá rộng nhưng recurring, import lịch và AI cần Pro. **Giá VN rất thấp (50k/tháng, 149k/năm, lifetime 495k)**, là mức sàn cạnh tranh. Có "Scholarship" tặng Pro miễn phí cho người không đủ khả năng chi trả.
- **Amie:** Đã chuyển hướng sang AI meeting notes với giá khoảng $20–40/tháng. Không còn là đối thủ trực tiếp.

### Nhóm Việt Nam
- **Nhắc lịch AI (Vbee):** Gọi điện thoại nhắc bằng giọng AI tiếng Việt, chọn được giọng vùng miền. Giá 149k/tháng, 1.499k/năm. Mới có 8 đánh giá. Cho thấy có nhu cầu với kiểu nhắc "không thể bỏ lỡ" (người lớn tuổi, uống thuốc), nhưng quy mô còn nhỏ.
- **Lịch Vạn Niên / Lịch Vạn Sự / Lịch Việt:** Nhắc sinh nhật, ngày giỗ, Vu Lan, Trung Thu theo âm lịch. Không có todo, không có sync, nhiều quảng cáo.
- **Zalo Nhắc hẹn:** Nhắc trong chat/nhóm, có lặp lại. Đây là thói quen nhắc lịch phổ biến nhất ở VN (chưa xác minh bằng số liệu). Không có âm lịch, không có todo.
- **App y tế (Medpro, BookingCare, VNeCare, app riêng của bệnh viện):** Có nhắc lịch khám trong từng app riêng lẻ. Không app nào tổng hợp lịch hẹn từ nhiều nơi.

---

## 4. Benchmark giá & giới hạn free tier

### 4.1 Giá App Store VN (truy cập 24/11/2026)

| App | Tháng | Năm | Năm ÷ tháng | Ghi chú |
|---|---|---|---|---|
| Structured | 50.000–79.000đ | 149.000–249.000đ | khoảng 3× | Lifetime 495k, giá rất "PPP" |
| TickTick | 69.000đ | 639.000đ | 9,3× | Giá US $49,99/năm ≈ 1,29tr, nên VN rẻ hơn khoảng 50% |
| Tripsy | 99.000–119.000đ | 699.000–1.199.000đ | 7–10× | Nhiều SKU khuyến mãi |
| Any.do | 139.000đ (KM 67–92k) | 839.000đ (có SKU 1.399k) | 6× | Giảm giá liên tục |
| Nhắc lịch AI (Vbee) | 149.000đ (39k/tuần) | 1.499.000đ | 10× | App nội địa |
| Todoist | 199.000đ | 1.999.000đ | 10× | Gần như không giảm giá theo vùng |
| TripIt | n/a | 1.099.000đ | n/a | Chỉ có gói năm |
| Things 3 / Due | 209.000đ / 199.000đ mua một lần | Due: Upgrade Pass 99k/năm | n/a | Mua đứt |

**Mốc chịu chi ở VN:** Spotify Premium 65.000đ/tháng (tăng 10,2%), Google AI Plus 132.000đ/tháng, Google AI Pro 489.000đ/tháng, iCloud+ tăng tới 32% vào 07/2026. AppsOps gợi ý app productivity ở VN nên đặt **49.000–79.000đ/tháng**, và gói năm khoảng **8–10× giá tháng**, ví dụ 399k/năm cho mức ~49k/tháng (nguồn vendor, mang tính định hướng). Bậc giá Apple là các mệnh giá cố định, nên cần chọn đúng tier trong App Store Connect (danh sách tier VND chưa xác minh).

**Thanh toán:** Google Play ở VN nhận MoMo (khuyến mãi 2026) và carrier billing Viettel, Mobifone, Vinaphone, Vietnamobile (ra mắt 2016–2017, chưa xác minh còn hoạt động năm 2026). Tỷ lệ dùng thẻ tín dụng thấp, nên nên bán qua IAP hoặc Play Billing thay vì thanh toán thẻ trên web.

### 4.2 Giới hạn free tier (US/global)

| App | Giới hạn chính ở bản free | Bài học cho RemindMe |
|---|---|---|
| Todoist | Chỉ nhắc tự động, không có nhắc tuỳ chỉnh/lặp/vị trí; 10 phiên AI capture/tháng; 5 project | Quota AI theo tháng là chuẩn chung, 10/tháng được thị trường chấp nhận |
| TickTick | 2 nhắc/task, 9 list, 99 task/list (chưa xác minh) | Giới hạn theo số lượng dễ hiểu |
| Any.do | Không có recurring, không có nhắc vị trí, không có AI | Khoá recurring hoàn toàn gây khó chịu; nên chỉ giới hạn số lượng |
| Structured | Recurring, import lịch, AI cần Pro | Tương tự |
| TripIt | Free parse email; tài liệu 3/chuyến (chưa xác minh); alert cần Pro | Cho parse free để tạo thói quen, bán thêm giá trị "real-time" |
| Wanderlog | Quét Gmail và offline cần Pro | Tự động quét inbox là tính năng trả phí hợp lý |
| Motion | Không có free | Không áp dụng cho VN |
| Apple Reminders, Google Tasks, MS To Do | Miễn phí hoàn toàn | Đây là "đối thủ mặc định", nên free tier phải tốt hơn bản todo cơ bản của hệ điều hành |

---

## 5. Khoảng trống thị trường & cơ hội khác biệt

1. **Một timeline cho mọi thứ có giờ giấc:** task, nhắc việc, chuyến bay, xe khách, tàu, khách sạn, lịch khám. Hiện người dùng phải dùng Todoist + TripIt + app bệnh viện + Zalo cùng lúc. Chưa đối thủ nào kết hợp được, và đây là định vị cốt lõi.
2. **AI import trên Android, dùng được trên mọi máy.** Import ảnh/PDF của TripIt và Tripsy phụ thuộc Apple Intelligence. RemindMe nên làm OCR trên thiết bị (ML Kit hoặc Vision) kết hợp LLM trên server hoặc on-device, chạy được cả trên máy Android tầm trung (Xiaomi, OPPO).
3. **Parser chuyên cho định dạng VN:** e-ticket Vietjet, Vietnam Airlines, Bamboo; vé Vexere (hơn 500 nhà xe) và Đường sắt VN; xác nhận Traveloka, Agoda, Booking bằng tiếng Việt; phiếu khám Medpro, BookingCare và app bệnh viện; đơn thuốc (lịch uống thuốc). App ngoại gần như chắc chắn không tối ưu cho các định dạng này (suy luận, chưa xác minh).
4. **Nhắc theo âm lịch (recurring lunar):** giỗ, rằm, mùng 1, sinh nhật âm. Hiện chỉ app lịch vạn niên có tính năng này, không app todo nào có (chưa xác minh với TickTick, vốn có hiển thị âm lịch). Tính năng làm ít mà hiệu quả cao ở VN.
5. **Kênh nhắc qua Zalo**, tương tự bot WhatsApp của Any.do: gửi nhắc quan trọng hoặc gửi cho người thân (cha mẹ uống thuốc) qua Zalo OA/ZNS. ZNS tính phí theo tin, nên chỉ phù hợp với gói trả phí (giá ZNS chưa xác minh).
6. **Nhắc "dai" kiểu Due, nhưng đa nền tảng:** auto-snooze leo thang (thông báo → âm báo kiểu báo thức → rung watch), kèm onboarding tắt tối ưu pin cho Xiaomi HyperOS, ColorOS, Funtouch. Độ tin cậy của thông báo là lợi thế có thể đem ra so sánh trực tiếp ("nhắc đúng giờ trên Xiaomi").
7. **Watch trên cả hai nền tảng với tính năng đầy đủ:** Keep trên Wear OS mất khả năng đặt nhắc, Google Tasks không có app Wear OS độc lập, Tripsy và TripIt không có trên Wear OS. RemindMe có thể làm complication hoặc tile "việc tiếp theo / chuyến tiếp theo" kèm voice capture tiếng Việt trên watch.
8. **Đón người dùng rời Microsoft To Do (hạn 30/06/2027):** importer bằng một chạm qua Microsoft Graph, giữ nguyên list, nhắc và recurring.
9. **Giá VND và gói quý:** đối thủ hầu như chỉ có gói tháng và năm, TickTick US và TripIt chỉ có gói năm. Gói quý hợp với thói quen chi tiêu ngắn hạn ở VN (chưa xác minh bằng dữ liệu). Nên dùng ít SKU, giá ổn định, tránh kiểu 8–10 mức IAP của Any.do và Tripsy.
10. **Quyền riêng tư cho dữ liệu y tế và giấy tờ đi lại:** ưu tiên OCR trên thiết bị, cho xoá ảnh gốc sau khi parse. Luật Bảo vệ dữ liệu cá nhân có hiệu lực từ 01/01/2026 coi dữ liệu sức khoẻ là dữ liệu nhạy cảm (chưa xác minh chi tiết điều khoản). Đây cũng là điểm marketing.

---

## 6. Khuyến nghị cụ thể cho RemindMe

### 6.1 Tính năng (ưu tiên theo giá trị / chi phí)

> Cập nhật 24/11/2026: chủ dự án quyết định không dùng AI đám mây để đọc tài liệu. Xem ADR-010 và `docs/architecture/on-device-extraction.md`.

**P0 – MVP để vào thị trường VN**
- Todo + nhắc việc với NLP tiếng Việt ("mai 8h họp", "thứ 6 hàng tuần", "rằm tháng này"). Recurring hỗ trợ cả **âm lịch**.
- Smart Import: ảnh/screenshot/PDF thành cuộc hẹn hoặc booking. Ưu tiên parse vé máy bay nội địa, Vexere, tàu, khách sạn và phiếu khám. Luôn có bước **review trước khi lưu** (như TripIt).
- Import xlsx, md, pdf hàng loạt (danh sách việc, lịch trực, lịch học).
- Thông báo tin cậy: dùng exact alarm và foreground service khi cần, có wizard tắt tối ưu pin cho từng hãng, auto-snooze leo thang.
- Đồng bộ hai chiều Google Calendar và Google Tasks. Đọc Gmail chỉ khi người dùng bật (OAuth scope tối thiểu).
- Watch: Wear OS (tile + complication + voice) và Apple Watch (complication + Live Activities cho chuyến bay/cuộc hẹn).

**P1 – Trong 3–6 tháng**
- Importer cho Microsoft To Do (trước 06/2027), TickTick/Todoist (CSV) và Apple Reminders.
- Voice input tiếng Việt có giọng vùng miền, trên cả điện thoại và watch.
- Theo dõi trạng thái chuyến bay (delay, cổng) cho booking đã parse. Đây là tính năng trả phí theo kiểu TripIt Pro.
- Nhắc qua Zalo (ZNS) và chia sẻ nhắc cho người thân (gói Pro/Family).

**P2 – Mở rộng toàn cầu**
- Forward email (địa chỉ riêng `@remindme`) và quét Gmail tự động.
- Gói Family, chia sẻ trip.
- Tối ưu parser cho các OTA toàn cầu (Booking, Agoda, Expedia, Trip.com).

### 6.2 Giá đề xuất

| Gói | VN (VND) | Tương đương USD | Global (USD) | Ghi chú |
|---|---|---|---|---|
| Tháng | **59.000đ** | khoảng $2,3 | $4,99 | Thấp hơn TickTick (69k), cao hơn mức sàn của Structured; nằm trong dải 49–79k được gợi ý |
| Quý | **149.000đ** (khoảng 49,7k/tháng, -16%) | khoảng $5,8 | $12,99 | Điểm khác biệt, phù hợp chi tiêu ngắn hạn |
| Năm | **449.000đ** (khoảng 37,4k/tháng, -37%; bằng 7,6× giá tháng) | khoảng $17,3 | $39,99 | Rẻ hơn TickTick 639k, Any.do 839k, TripIt 1.099k |
| (Tuỳ chọn) Học sinh/sinh viên | 299.000đ/năm | n/a | n/a | Học theo mô hình Scholarship của Structured |

- Trial 7 ngày cho gói năm. Không bán lifetime ở giai đoạn đầu, vì chi phí AI/OCR là chi phí biến đổi.
- Chọn tier App Store và Play gần nhất với các mức trên (mức thực tế phụ thuộc bảng tier VND, chưa xác minh). Giữ tối đa 3–4 SKU.
- Global: $4,99 / $12,99 / $39,99, thấp hơn Todoist ($7/$60) và Any.do ($7,99/$59,88), ngang Wanderlog và Tripsy.

### 6.3 Giới hạn free tier đề xuất (áp dụng cho **mọi loại**, kể cả booking)

> Bản chốt (nguồn sự thật) nằm ở `docs/product/pricing-entitlements.md`. Ở đó gói trả phí tên là **Plus**.

| Hạn mức | Free | Pro | Lý do |
|---|---|---|---|
| Nhắc nhở mỗi ngày (số nhắc được lên lịch để kêu trong một ngày) | **10/ngày** | Không giới hạn | Đủ cho nhu cầu cá nhân cơ bản. Người dùng nặng sẽ chạm giới hạn trong khoảng 1–2 tuần |
| Recurring đang hoạt động | **5** | Không giới hạn | Không khoá hẳn như Any.do. 5 slot đủ cho uống thuốc, giỗ, hoá đơn |
| Cuộc hẹn/booking **đang hoạt động** (chuyến bay, xe, tàu, khách sạn, trip, lịch khám; chỉ tính mục chưa diễn ra) | **10** | Không giới hạn | Mục đã qua tự lưu trữ và không tính vào hạn mức, nên người dùng không bị "phạt" vì dùng lâu |
| Smart Import (OCR/AI parse ảnh, PDF, xlsx, md) | **10 lượt/tháng** | 300/tháng (fair use) | Theo chuẩn 10/tháng của Todoist; kiểm soát chi phí LLM |
| Voice input | **20 phiên/tháng** | Không giới hạn (fair use) | STT tiếng Việt có chi phí |
| Đồng bộ Google | 1 tài khoản Calendar + Tasks | 3 tài khoản, có tự quét Gmail | Theo kiểu Todoist (1 vs 3) và Wanderlog (quét Gmail ở Pro) |
| Watch | Nhận thông báo, xem danh sách, đánh dấu xong | Complication/tile đầy đủ, voice trên watch, Live Activities chuyến bay | Watch là điểm khác biệt, nên bản free vẫn phải dùng được |
| Theo dõi trạng thái chuyến bay | Không | Có | Giá trị kiểu TripIt Pro |
| Nhắc qua Zalo / cho người thân | Không | Có | Có chi phí ZNS |

**Nguyên tắc:** nhắc đã tạo thì **luôn kêu**, không bao giờ chặn lúc đến giờ. Giới hạn chỉ áp dụng khi tạo mới. Hiện bộ đếm hạn mức rõ ràng (ví dụ "7/10 nhắc hôm nay"). Khi chạm giới hạn, gợi ý gói quý.

### 6.4 KPI theo dõi giai đoạn đầu (đề xuất)
- Tỷ lệ thông báo đến đúng giờ (±1 phút) theo hãng máy: mục tiêu ≥ 99% trên Xiaomi/OPPO.
- Độ chính xác parse booking (tỷ lệ trường dữ liệu đúng, không phải sửa ở bước review): mục tiêu ≥ 90% với 10 mẫu vé VN phổ biến.
- Tỷ lệ chuyển free sang trả phí: tham chiếu SEA thấp hơn US; đặt mục tiêu 2–4% trong 90 ngày (chưa xác minh benchmark).

---

## 7. Nguồn (truy cập 23–24/11/2026)

**Todo / nhắc việc**
- Todoist plans: https://www.todoist.com/help/articles/todoist-plans-pricing
- Todoist Ramble GA (TechCrunch, 21/01/2026): https://techcrunch.com/2026/01/21/todoists-app-now-lets-you-add-tasks-to-your-to-do-list-by-speaking-to-its-ai/
- Todoist Ramble help: https://www.todoist.com/help/articles/dictate-to-add-tasks-with-ramble-P1Raq7vVF
- Todoist Ramble trên Wear OS (03/2026): https://www.todoist.com/help/todoist/product-updates/just-talk-to-your-wrist-ramble-on-wear-os-beta-mar-23-2026-Kskv3T9JF
- Todoist Wear OS: https://todoist.com/help/articles/use-todoist-on-wear-os-t8tzJ0mO
- Todoist pricing (Morgen): https://morgen.so/blog-posts/todoist-pricing
- TickTick pricing 2026 (Activepieces): https://www.activepieces.com/blog/ticktick-pricing-in-2026-for-free-and-premium-plans
- TickTick pricing (Toolradar): https://toolradar.com/tools/ticktick/pricing.md
- TickTick pricing (Capterra): https://www.capterra.com/p/170641/TickTick/pricing/
- TickTick What's New (watchOS 11): https://help.ticktick.com/articles/7082552170989486080
- Microsoft To Do ngừng hoạt động (Windows Latest, 19/11/2026): https://windowslatest.com/2026/11/19/microsoft-is-killing-to-do-and-telling-you-to-choose-another-app-after-it-reportedly-paid-up-to-200-million-for-wunderlist-and-killed-it-for-to-do
- The Register (19/11/2026): https://theregister.com/personal-tech/2026/11/19/microsoft-to-do-will-soon-become-microsoft-done/5310973
- Copilot Reminders (Windows Central): https://www.windowscentral.com/artificial-intelligence/microsoft-copilot/microsoft-copilot-can-now-send-you-reminders-straight-to-your-phone
- Any.do pricing: https://www.any.do/pricing
- Any.do smart watch: https://support.any.do/en/articles/8634356-any-do-smart-watch
- Google Keep reminders lưu vào Tasks (10/2025): https://workspaceupdates.googleblog.com/2025/10/google-keep-reminders-now-saved-to-tasks.html
- Keep Wear OS mất nhắc (9to5Google, 01/2026): https://9to5google.com/2026/01/23/google-keep-wear-reminders/
- Gemini trên Wear OS: https://blog.google/products/wear-os/gemini-wear-os-watches
- Keep Live / Gmail Live (9to5Google, 09/2026): https://9to5google.com/2026/09/03/gmail-docs-keep-live/
- Apple Reminders + Apple Intelligence (iOS 26): https://support.apple.com/124025
- Apple Intelligence tiếng Việt (iOS 26.1): https://9to5mac.com/2025/11/11/ios-26-1-brings-apple-intelligence-to-these-eight-new-languages/
- Siri AI ngôn ngữ mới (Apple Newsroom, 10/2026): https://www.apple.com/newsroom/2026/10/siri-ai-is-available-in-more-languages-starting-today/
- Things 3 cho iOS 27 (MacRumors, 09/2026): https://macrumors.com/2026/09/14/things-3-updated-for-ios-27
- Things 3 review/giá: https://www.asianefficiency.com/task-management/things-3-review/
- Due (App Store): https://apps.apple.com/app/id390017969
- Motion pricing (Dupple, 10/2026): https://dupple.com/pricing/motion
- Motion pricing (Morgen): https://morgen.so/blog-posts/motion-pricing
- Structured (App Store US): https://apps.apple.com/US/app/id1499198946
- Amie pricing (ClickUp review 2026): https://clickup.com/blog/amie-calendar-review/
- Amie billing: https://amie.so/documentation/account/billing

**Du lịch**
- TripIt Pro + Apple Intelligence (04/2026): https://www.tripit.com/web/blog/news-culture/automate-travel-plans-tripit-pro-apple-intelligence
- TripIt help (import ảnh/PDF): https://help.tripit.com/en/support/solutions/articles/103000361047
- TripIt pricing: https://www.tripit.com/uhp/pricing
- TripIt review (Pilot Plans): https://www.pilotplans.com/blog/review-of-tripit
- Tripsy 3.10 Smart Import (AlternativeTo, 09/2026): https://alternativeto.net/news/2026/9/tripsy-3-10-brings-ai-powered-travel-planning-features-smart-import-and-smart-insights/
- Tripsy (App Store US): https://apps.apple.com/us/app/-/id1429967544
- Tripsy forward email (MacStories): https://www.macstories.net/reviews/tripsy-2-1-adds-web-based-itineraries-and-expanded-travel-email-forwarding/
- Wanderlog review 2026: https://www.endlesstravelplans.com/guides/planning-tools/wanderlog-review
- Wanderlog pricing tracker: https://recurdash.com/subscription-pricing/wanderlog
- Vexere guide 2026: https://www.vietnamtourism.com/en/vexere-vietnam-bus-the-complete-guide-to-booking-and-riding-in-2026

**App Store VN (giá VND, truy cập 24/11/2026)**
- Todoist: https://apps.apple.com/vn/app/todoist-to-do-list-planner/id572688855
- TickTick: https://apps.apple.com/vn/app/ticktick-to-do-list-calendar/id626144601
- Any.do: https://apps.apple.com/vn/app/any-do-to-do-list-planner/id497328576
- Structured: https://apps.apple.com/vn/app/structured-daily-planner/id1499198946
- TripIt: https://apps.apple.com/vn/app/tripit-travel-planner/id311035142
- Tripsy: https://apps.apple.com/vn/app/tripsy-travel-planner/id1429967544
- Things 3: https://apps.apple.com/vn/app/things-3/id904237743
- Due: https://apps.apple.com/vn/app/due-reminders-timers/id390017969
- Nhắc lịch AI (Vbee): https://apps.apple.com/vn/app/id6499468129
- Lịch Vạn Niên 2026, Lịch Việt: https://apps.apple.com/vn/app/l%E1%BB%8Bch-v%E1%BA%A1n-ni%C3%AAn-2026-l%E1%BB%8Bch-vi%E1%BB%87t/id585253443?l=vi

**Thị trường VN**
- Pricing iOS SEA 2026 (AppsOps): https://appsops.store/blog/ios-pricing-emerging-markets-southeast-asia-2026
- Spotify tăng giá VN: https://vietnamnet.vn/en/spotify-raises-premium-price-by-10-2-in-vietnam-2443684.html
- Google AI Plus VN: https://e.vnexpress.net/news/tech/tech-news/google-launches-ai-service-package-in-vietnam-for-5-4943555.html
- Gemini subscriptions VN: https://gemini.google/vn/subscriptions?hl=vi
- iCloud tăng giá VN (07/2026): https://news.tuoitre.vn/apple-raises-icloud-prices-in-vietnam-by-up-to-32-highest-plan-nears-69-per-month-103260719123209661.htm
- Thị phần smartphone VN Q2/2026 (Omdia qua TelecomLead): https://telecomlead.com/smart-phone/vietnam-smartphone-market-q2-2026-samsung-leads-with-28-as-xiaomi-and-oppo-gain-on-apple-127483
- StatCounter VN vendor share: https://gs.statcounter.com/vendor-market-share/mobile/viet-nam
- Vietnam app trends 2026 (Adjust): https://www.adjust.com/blog/vietnam-app-trends-2026/
- Chi tiêu app AI ở VN (VnExpress): https://e.vnexpress.net/news/tech/vietnam-innovation/vietnamese-spend-1-7m-on-claude-7-1m-on-chatgpt-5115931.html
- Smartwatch VN (VnExpress, dữ liệu 2022): https://e.vnexpress.net/news/industries/huawei-xiaomi-lead-vietnams-smartwatch-market-4528623.html
- MoMo thanh toán Google Play (2026): https://www.momo.vn/tin-tuc/khuyen-mai/google-play-tet-nay-giai-tri-cuc-tiet-kiem-voi-8483
- Carrier billing Viettel (Fortumo): https://finextra.com/pressarticle/63509/fortumo-and-viettel-launch-google-play-carrier-billing-in-vietnam
- Tỷ giá USD 16–17/11/2026: https://vietbao.vn/ty-gia-usd-hom-nay-1611-ty-gia-trung-tam-25637-dongusd-615928.html
- Zalo nhắc hẹn (Sforum, 07/2026): https://cellphones.com.vn/sforum/cach-tao-nhac-hen-tren-zalo
- Medpro: https://medpro.vn/tin-tuc/ung-dung-medpro-dat-kham-online-voi-bac-si
- Đặt khám qua app (VnExpress): https://vnexpress.net/thoi-dang-ky-kham-benh-qua-app-4949022.html

**Kỹ thuật thông báo Android**
- Notification issues theo OEM (Batch): https://doc.batch.com/developer/technical-guides/how-to-guides/how-to-fix-notification-delivery-issues-on-specific-android-devices
- Chinese OEM push deliverability (Braze): https://www.braze.com/docs/user_guide/channels/push/best_practices/chinese_push_deliverability
- OEM interfere with notifications (OneSignal): https://onesignal.com/blog/manufacturers-interfere-with-reliable-notifications/
