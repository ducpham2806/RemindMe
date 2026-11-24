# Bảo mật & quyền riêng tư

> TL;DR: Dữ liệu nhạy cảm: lịch khám, số giấy tờ trong booking, email, giọng nói. Tài liệu và audio được xử lý trên máy (ADR-010).
> RLS mọi bảng, đường ghi duy nhất là RPC `sync_push`, token OAuth trong Vault, MIME email có TTL, không log nội dung.
> Pháp lý theo từng thị trường launch (mục 4), luật sư địa phương xác nhận trước khi bật một storefront.

## 1. Phân loại dữ liệu
| Mức | Ví dụ | Biện pháp |
|---|---|---|
| Nhạy cảm cao | Lịch khám/ghi chú sức khỏe (GDPR Art. 9), số CCCD/hộ chiếu, token OAuth, nội dung email | Mã hóa cột (pgsodium/Vault) cho `passengers`, token; che số giấy tờ; không log; TTL |
| Cá nhân | Tiêu đề việc, địa điểm, lịch trình | RLS, TLS, backup mã hóa |
| Kỹ thuật | Device id, phiên bản app, OEM, locale | Ẩn danh trong analytics |
| Phiên đăng nhập | `user_sessions`: IP, quốc gia, mẫu máy, thời gian (ADR-013) | Chỉ user (phiên đang hoạt động) đọc; UI chỉ hiện quốc gia; IP xóa sau 90 ngày; mục đích an ninh tài khoản (lợi ích chính đáng, ghi trong Privacy Policy) |

## 2. Kiểm soát
- **RLS**: mọi bảng `user_id = auth.uid()`. Bảng đồng bộ chỉ cho `SELECT` qua PostgREST; ghi chỉ qua RPC `sync_push` (ADR-012). Test RLS bằng pgTAP trong CI.
- **Worker** dùng service role, mạng riêng; mọi endpoint xác thực JWT và kiểm `user_id` của tài nguyên.
- **Secrets**: Secret Manager; không có secret trong app; quét secret trong CI (gitleaks).
- **File trên server** (chỉ MIME email và "Giữ bản gốc" của Plus): bucket private, signed URL 10 phút, quét MIME thật, giới hạn kích thước, xóa theo `expires_at`.
- **Trích xuất trên máy**: ảnh, file, email được phân tích trên điện thoại, nội dung không gửi cho bên thứ ba. LLM của OS (nếu dùng) chạy cục bộ;
  đầu ra là JSON theo schema qua validator, nên nội dung độc hại trong tài liệu không ra lệnh được cho hệ thống.
- **Giọng nói**: audio không lưu, không gửi lên server RemindMe. Nếu locale chỉ có STT online của Apple/Google, app báo rõ và xin đồng ý 1 lần;
  có thiết lập "Chỉ nhận dạng trên máy" (`architecture/voice-and-text-input.md` §8).
- **Mẫu nhà cung cấp và gói dữ liệu** (NLU, ngày lễ) từ CDN: ký Ed25519, là dữ liệu khai báo, không chứa code chạy được.
  Khóa ký nằm trong Cloud KMS, chỉ CI phát hành ký được. App nhúng 2 public key (hiện tại + kế tiếp) để xoay khóa; `manifest.json` có danh sách `revoked`.
- **"Gửi mẫu để cải thiện"**: chỉ gửi bản đã che (chữ → X, số → 9), người dùng xem trước bản che.
- **Email inbound**: kiểm SPF/DKIM/DMARC; người gửi lạ chỉ tạo đề xuất.
- **Phiên**: 1 thiết bị hoạt động mỗi tài khoản (ADR-013); RLS + RPC kiểm `session_id` của JWT còn `active`, phiên bị đá mất quyền ngay; phiên GoTrue cũ bị xóa để refresh token chết.
- **Mobile**: token trong Keychain/Keystore (`flutter_secure_storage`); token Gmail (Phase 3) chỉ nằm trên máy; tùy chọn khóa app bằng sinh trắc học.
- **Logging/analytics**: không log tiêu đề/ghi chú/nội dung import; Sentry scrub PII (`beforeSend`); analytics theo consent (`docs/product/analytics-events.md`).
- **Threat model** (STRIDE rút gọn) viết trước S5 cho: sync RPC, hộp thư email, CDN mẫu, OAuth. Pen-test bên ngoài trước production.

## 3. Bên thứ ba xử lý dữ liệu (liệt kê trong Privacy Policy)
| Bên | Mục đích | Dữ liệu | Khu vực |
|---|---|---|---|
| Supabase | DB, auth, storage | Toàn bộ dữ liệu đồng bộ | 1 region chính (ADR-011) |
| Google Cloud Run | Worker | Metadata, MIME email (tạm) | Cùng region |
| Firebase | FCM, Crashlytics | Device token, crash (đã scrub) | US |
| RevenueCat | Giao dịch | User id, lịch sử mua | US |
| Postmark / Cloudflare | Email inbound; Postmark/Amazon SES gửi email (Phase 3) | Email forward | US/EU |
| Sentry, PostHog (EU cloud hoặc tự host) | Lỗi, analytics | Sự kiện ẩn danh | EU |
| Apple / Google speech service | STT online khi không có on-device | Audio (chỉ khi người dùng đồng ý) | Theo nhà cung cấp |
| Google APIs, Microsoft Graph, Notion | Tích hợp người dùng bật | Dữ liệu lịch/task của tích hợp đó | Theo nhà cung cấp |
| CDN (Cloudflare) | Mẫu, gói dữ liệu, model tải về | Không có dữ liệu cá nhân | Global |
| (Phase 3) API trạng thái chuyến bay, Zalo/LINE/Kakao/WhatsApp | Tính năng Plus | Số hiệu chuyến / nội dung tin nhắc | Theo nhà cung cấp |
Mỗi bên cần DPA và cơ chế chuyển dữ liệu xuyên biên giới (SCC với EU/UK). Thêm bên mới thì cập nhật bảng này và Privacy Policy.

## 4. Pháp lý theo thị trường (checklist, luật sư địa phương xác nhận)
| Thị trường | Luật chính | Việc cần làm |
|---|---|---|
| EU/EEA, UK | GDPR, UK GDPR, ePrivacy | Cơ sở pháp lý cho từng mục đích; đồng ý rõ ràng cho dữ liệu sức khỏe; đại diện EU (Art. 27) nếu không có pháp nhân EU; consent analytics; DPIA |
| US | CCPA/CPRA (California) và luật bang khác; FTC Health Breach Notification Rule (app có dữ liệu sức khỏe) | "Do not sell/share", thông báo vi phạm dữ liệu sức khỏe |
| Brazil | LGPD | Cơ sở pháp lý, DPO liên hệ |
| Japan / Korea | APPI / PIPA | Đồng ý chuyển dữ liệu ra nước ngoài |
| Thái Lan, Singapore, Malaysia | PDPA (từng nước) | Thông báo mục đích, đồng ý |
| Ấn Độ | DPDP Act 2023 | Đồng ý, thông báo theo quy định hiện hành |
| Việt Nam | Luật Bảo vệ dữ liệu cá nhân (hiệu lực 01/01/2026), Nghị định 13/2023 | Hồ sơ đánh giá tác động và hồ sơ chuyển dữ liệu ra nước ngoài (kiểm tra nghĩa vụ với startup) |
| Mọi nơi | Store policy, Google API User Data Policy (Limited Use) | Privacy Nutrition Label, Play Data Safety; không dùng dữ liệu Google cho quảng cáo |
- Privacy Policy và Terms bằng mọi ngôn ngữ đã phát hành (bản dịch pháp lý do luật sư/dịch giả pháp lý duyệt).
- Độ tuổi tối thiểu 13 (16 ở một số nước EU); không nhắm tới trẻ em (COPPA).
- Đồng ý xử lý dữ liệu sức khỏe tách riêng, khi người dùng tạo lịch khám đầu tiên.
- Bán qua web (nếu có): dùng Merchant of Record để xử lý VAT/GST; ở VN cần thông báo website TMĐT, hóa đơn điện tử.

## 5. Ứng phó sự cố
Runbook: phát hiện → khoanh vùng → thu hồi token/khóa → thông báo người dùng và cơ quan có thẩm quyền theo thời hạn luật định
(GDPR 72h; kiểm tra thời hạn của từng thị trường) → postmortem trong `docs/incidents/`.

## 6. Xóa tài khoản, xuất dữ liệu, lưu trữ
- **Xóa tài khoản** (trong app, yêu cầu của Apple và Google): xóa `auth.users` sẽ cascade toàn bộ bảng; thu hồi token tích hợp phía provider;
  xóa file Storage; hoàn tất trong ≤ 30 ngày, backup tự hết hạn sau ≤ 35 ngày. Subscription do store quản lý: nhắc người dùng hủy trong store.
- **Xuất dữ liệu**: file ZIP gồm `remindme-export.json` (schema có `export_version`, một mảng cho mỗi bảng đồng bộ, thời gian ISO 8601 + IANA tz)
  và `calendar.ics` (VEVENT/VTODO, RRULE; hệ lịch phụ được trải phẳng 2 năm). Tạo trên máy, không cần server.
- **Thời hạn lưu**: MIME email 7 ngày (hoặc tới khi máy `ack`); tombstone `deleted_at` 90 ngày rồi xóa hẳn; log server 30 ngày; telemetry ẩn danh 13 tháng;
  `user_sessions`: IP và quốc gia xóa sau 90 ngày, hàng đã kết thúc xóa sau 12 tháng (job `cleanup.sessions`).
