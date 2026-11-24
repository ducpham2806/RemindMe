# Bản đồ tài liệu

> Đọc file này để chọn đúng tài liệu, đừng đọc cả `docs/`. Mỗi file mở đầu bằng TL;DR (`head -8`).
> Tra nhanh hơn: `graphify query "..."` / `graphify section "<heading>"` (xem `guides/ai-dev-workflow.md`).

| File | Nội dung | Đọc khi |
|---|---|---|
| `STATE.md` | Hiện trạng, việc tiếp theo, blocker | Đầu mỗi phiên (tự động) |
| `WORKLOG.md` | Nhật ký công việc, mới nhất ở đầu | Cần biết vì sao/khi nào (`head -60`) |
| `product/PRD.md` | Vấn đề, mục tiêu, persona, user story + AC, phi mục tiêu | Làm tính năng mới, viết test chấp nhận |
| `product/pricing-entitlements.md` | Giá VND/USD, ma trận giới hạn Free/Plus, quy tắc quota, paywall | Đụng tới quota, paywall, thanh toán |
| `research/competitor-analysis.md` | 15+ đối thủ, giá App Store VN, khoảng trống thị trường | Quyết định sản phẩm/giá, marketing |
| `architecture/system-architecture.md` | Thành phần, luồng chính, sync, NFR, rủi ro | Hiểu tổng thể |
| `architecture/decisions.md` | ADR-001..010 (stack, offline-first, email, thanh toán, trích xuất trên máy...) | Trước khi đổi công nghệ |
| `architecture/data-model.md` | ERD, DDL Postgres, quy tắc đếm quota, bảng client | Viết migration, Drift schema |
| `architecture/api-spec.md` | Endpoint worker, push types, webhook, mã lỗi | Viết API/client |
| `architecture/reminder-engine.md` | Rolling window, Android/iOS, lặp/âm lịch, múi giờ, watch | Làm nhắc nhở/thông báo |
| `architecture/on-device-extraction.md` | Đọc ảnh/pdf/xlsx/md/email/giọng nói **trên máy**: decoder, OCR của OS, luật + mẫu nhà cung cấp, LLM của OS (tùy chọn), eval | Làm import, Quick Add, giọng nói |
| `integrations/integration-guide.md` | FCM, store, RevenueCat, OAuth, email forward, Google, Notion, MS To Do, watch | Làm tích hợp, việc cần chờ duyệt |
| `uiux/design-system.md` | Token màu/chữ/khoảng cách, component, a11y, i18n | Làm UI |
| `uiux/ux-flows-and-screens.md` | IA, wireframe, onboarding, import review, paywall | Làm màn hình/luồng |
| `security-privacy.md` | Phân loại dữ liệu, kiểm soát, bên thứ ba, pháp lý VN/GDPR | Đụng dữ liệu nhạy cảm, bên thứ ba mới |
| `plan/implementation-plan.md` | Phase 0-4, sprint MVP, gate, kế hoạch chi tiết trích xuất E0-E8 (ngày công, AC), rủi ro | Lập kế hoạch sprint |
| `guides/ai-dev-workflow.md` | Token budget, graphify, unslop, agency agents, handoff | Thiết lập quy trình |
