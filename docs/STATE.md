# STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)

**Cập nhật:** 2026-11-24 · **Phase:** 0, tài liệu và thiết kế · **Nhánh:** `ccr-7a85f116-dswwig`

## Đã có
- Bộ docs v1: PRD, giá/giới hạn, nghiên cứu đối thủ, kiến trúc + 10 ADR, data model, API, reminder engine,
  trích xuất on-device, tích hợp, design system, UX flows, bảo mật, kế hoạch, quy trình AI (`docs/INDEX.md`).
- **Quyết định mới (ADR-010):** không dùng AI API trả phí để đọc ảnh/file. Mọi trích xuất chạy trên máy (decoder + OCR của OS
  + luật + mẫu nhà cung cấp); LLM của OS chỉ là tùy chọn. Kế hoạch chi tiết E0-E8 trong `plan/implementation-plan.md`.
- Tooling: `tools/ai-tools-setup.sh`, `tools/graphify-docs.sh`, `tools/unslop-docs.sh`; `graphify-out/GRAPH_REPORT.md`.
- Chưa có code.

## Tiếp theo (ưu tiên)
1. Chủ dự án duyệt docs, nhất là giá (59k/149k/449k) và giới hạn Free (`product/pricing-entitlements.md`).
2. Đăng ký Apple Developer (tổ chức, D-U-N-S), Google Play Console, domain `remindme.app` (hoặc tên khác), Firebase, Supabase.
3. Phỏng vấn 10-15 người dùng; thu thập ≥ 300 mẫu vé/booking ẩn danh (≥ 20 nhà cung cấp).
4. Spike E0: OCR tiếng Việt ML Kit vs Vision trên máy thật; thử Foundation Models / Gemini Nano.
5. Prototype 6 luồng P0 (Hôm nay, Quick Add, Import→Xem lại, Chuyến đi, Thông báo, Paywall).
6. Sprint S1 bootstrap (`plan/implementation-plan.md`).

## Câu hỏi mở (cần chủ dự án quyết)
- Tên thương mại/domain chính thức? (docs đang dùng `RemindMe`, `remindme.app`, bundle `app.remindme`, tất cả là giả định)
- Có làm Zalo login/ZNS không? Có bán qua web (VNPay/MoMo) không?
- Chấp nhận phí CASA cho Gmail API ở Phase 3?
- Đội ngũ thực tế (số người, kỹ năng) để chỉnh timeline.

## Blocker
- Không có.

## Ghi chú kỹ thuật
- graphify `section` cần tên heading đầy đủ kể cả số ("1. Rolling window scheduler").
- unslop mặc định chỉ diff; có thể sửa sai tên riêng trong văn bản tiếng Việt.
- Chưa xác minh: Vision iOS có tiếng Việt không; chất lượng tiếng Việt của Foundation Models và Gemini Nano; định dạng vé thật của các hãng VN.
