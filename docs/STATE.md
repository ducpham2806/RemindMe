# STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)

**Cập nhật:** 2026-11-24 · **Phase:** 0, tài liệu và thiết kế · **Nhánh:** `ccr-7a85f116-dswwig`

## Đã có
- Bộ docs v1: PRD, giá/giới hạn, nghiên cứu đối thủ, kiến trúc + 9 ADR, data model, API, reminder engine,
  AI ingestion, tích hợp, design system, UX flows, bảo mật, kế hoạch, quy trình AI (`docs/INDEX.md`).
- Tooling: `tools/ai-tools-setup.sh`, `tools/graphify-docs.sh`, `tools/unslop-docs.sh`; `graphify-out/GRAPH_REPORT.md`.
- Chưa có code.

## Tiếp theo (ưu tiên)
1. Chủ dự án duyệt docs, nhất là giá (59k/149k/449k) và giới hạn Free (`product/pricing-entitlements.md`).
2. Đăng ký Apple Developer (tổ chức, D-U-N-S), Google Play Console, domain `remindme.app` (hoặc tên khác), Firebase, Supabase.
3. Phỏng vấn 10-15 người dùng; thu thập ≥ 150 mẫu vé/booking ẩn danh cho eval.
4. Prototype 6 luồng P0 (Hôm nay, Quick Add, Import→Xem lại, Chuyến đi, Thông báo, Paywall).
5. Sprint S1 bootstrap (`plan/implementation-plan.md`).

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
