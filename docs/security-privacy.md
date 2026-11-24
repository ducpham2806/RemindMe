# Bảo mật & quyền riêng tư

> TL;DR: Dữ liệu nhạy cảm gồm lịch khám, số giấy tờ trong booking, email. RLS mọi bảng, token OAuth trong Vault,
> file import có TTL, không log nội dung. Tuân thủ Luật Bảo vệ dữ liệu cá nhân VN (hiệu lực 01/01/2026) và Nghị định 13/2023,
> GDPR khi ra global, chính sách App Store/Play và Google API User Data Policy. Cần luật sư xác nhận trước khi launch.
> Persona: *Security Architect*, *Privacy Engineer*, *Data Privacy Officer* (Agency).

## 1. Phân loại dữ liệu
| Mức | Ví dụ | Biện pháp |
|---|---|---|
| Nhạy cảm cao | Lịch khám/ghi chú sức khỏe, số CCCD/hộ chiếu, token OAuth, nội dung email | Mã hóa cột (pgsodium/Vault) cho `passengers`, token; che số giấy tờ; không log; TTL |
| Cá nhân | Tiêu đề việc, địa điểm, lịch trình | RLS, TLS, backup mã hóa |
| Kỹ thuật | Device id, phiên bản app, OEM | Ẩn danh trong analytics |

## 2. Kiểm soát
- **RLS**: mọi bảng có `user_id = auth.uid()`; test RLS tự động trong CI (pgTAP).
- **Worker** dùng service role, chỉ chạy trong mạng riêng; mọi endpoint xác thực JWT và kiểm `user_id` của tài nguyên.
- **Secrets**: Secret Manager; không có secret trong app; quét secret trong CI (gitleaks).
- **File**: bucket private, signed URL 10 phút, quét MIME thật (không tin extension), giới hạn kích thước, xóa theo `expires_at`.
- **Trích xuất trên máy (ADR-010)**: ảnh, file, email được phân tích trên điện thoại; nội dung tài liệu không gửi cho bên thứ ba nào.
  LLM của OS (nếu dùng) chạy cục bộ, đầu ra chỉ là JSON theo schema và qua validator, nên nội dung độc hại trong tài liệu không ra lệnh được cho hệ thống.
- **Mẫu nhà cung cấp** tải từ CDN phải có chữ ký Ed25519 hợp lệ (chống tráo mẫu độc hại); mẫu là dữ liệu khai báo, không chứa code chạy được.
- **"Gửi mẫu để cải thiện"**: chỉ gửi bản đã che (chữ → X, số → 9), người dùng xem trước bản che trước khi gửi.
- **Email inbound**: kiểm SPF/DKIM/DMARC; email từ người gửi lạ chỉ thành đề xuất.
- **Mobile**: lưu token Supabase trong Keychain/Keystore (`flutter_secure_storage`); tùy chọn khóa app bằng sinh trắc học; ẩn nội dung trong app switcher (tùy chọn).
- **Logging**: không log tiêu đề/ghi chú/nội dung import; Sentry scrub PII (`beforeSend`).

## 3. Bên thứ ba xử lý dữ liệu (liệt kê trong Privacy Policy)
Supabase (DB, auth, storage, Singapore), Google Cloud Run (worker),
Firebase (FCM, Crashlytics), RevenueCat (giao dịch), Postmark/Cloudflare (email inbound), Sentry, PostHog.
Mỗi bên cần DPA. Thêm bên mới thì cập nhật bảng này và Privacy Policy.

## 4. Pháp lý cần làm (checklist, xác nhận với luật sư)
- [ ] Privacy Policy + Terms (vi/en), có mục chuyển dữ liệu ra nước ngoài (server Singapore, API Mỹ).
- [ ] Đồng ý xử lý dữ liệu nhạy cảm (sức khỏe) tách riêng, rõ ràng, khi người dùng tạo lịch khám đầu tiên hoặc bật import.
- [ ] Hồ sơ đánh giá tác động xử lý dữ liệu cá nhân và hồ sơ chuyển dữ liệu ra nước ngoài theo luật VN (kiểm tra nghĩa vụ áp dụng cho doanh nghiệp nhỏ/startup).
- [ ] Quyền người dùng: xem, xuất, sửa, xóa dữ liệu; rút lại đồng ý.
- [ ] Google API Services User Data Policy (Limited Use) khi dùng Calendar/Gmail: không dùng dữ liệu Google cho quảng cáo, không cho người đọc trừ khi user đồng ý.
- [ ] App Store Privacy Nutrition Label, Play Data Safety form.
- [ ] Nếu bán qua web tại VN: thông báo website TMĐT, hóa đơn điện tử.

## 5. Ứng phó sự cố
Runbook: phát hiện → khoanh vùng → thu hồi token/khóa → thông báo người dùng và cơ quan có thẩm quyền theo thời hạn luật định
(kiểm tra thời hạn cụ thể trong luật VN và GDPR 72h) → postmortem trong `docs/incidents/`.
