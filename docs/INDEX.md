# Bản đồ tài liệu

> Đọc file này để chọn đúng tài liệu, đừng đọc cả `docs/`. Mỗi tài liệu chuyên đề mở đầu bằng TL;DR (`head -8`); STATE, WORKLOG, INDEX thì không.
> Tra nhanh hơn: `graphify query "..."` / `graphify section "<heading>"` (`guides/ai-dev-workflow.md`).
> **Nguồn chuẩn**: mỗi chủ đề chỉ có 1 nơi giữ số liệu/quy tắc (cột cuối). Nơi khác chỉ link.

| File | Nội dung | Đọc khi | Nguồn chuẩn của |
|---|---|---|---|
| `STATE.md` | Hiện trạng, việc tiếp theo, blocker | Đầu mỗi phiên (tự động) | Hiện trạng |
| `WORKLOG.md` | Nhật ký, mới nhất ở đầu | Cần biết vì sao/khi nào (`head -60`) | Lịch sử |
| `product/PRD.md` | Vấn đề, persona global, user story + AC, phi mục tiêu | Làm tính năng, viết test chấp nhận | KPI, quy ước P0-P3 |
| `product/pricing-entitlements.md` | Giá theo nhóm thị trường, ma trận Free/Plus, quy tắc quota, paywall | Đụng quota, paywall, thanh toán | Giá, trial, giới hạn |
| `product/analytics-events.md` | Danh mục event, consent theo vùng | Thêm tracking, dashboard | Tên event, consent |
| `research/global-market.md` | Chi tiêu app theo quốc gia, đề xuất đợt locale, region dữ liệu, kiểm tra nhóm giá | Chốt locale/region/giá | Dữ liệu thị trường global |
| `research/competitor-analysis.md` | Đối thủ, giá App Store VN, khoảng trống thị trường | Quyết định sản phẩm, marketing | Dữ liệu nghiên cứu |
| `architecture/system-architecture.md` | Thành phần, luồng chính, sync, NFR, rủi ro | Hiểu tổng thể | Luồng sync, gộp tài khoản |
| `architecture/decisions.md` | ADR-001..017 | Trước khi đổi công nghệ | Quyết định |
| `architecture/data-model.md` | ERD, DDL, cột đồng bộ, phiên đăng nhập, quy tắc đếm quota, bảng client | Viết migration, Drift schema | Tên bảng/cột |
| `architecture/api-spec.md` | RPC sync, endpoint worker, push, CDN pack, webhook | Viết API/client | Endpoint, push type |
| `architecture/reminder-engine.md` | Rolling window, Android/iOS, lặp/hệ lịch, DST, du lịch, watch, nhiều thiết bị | Làm nhắc nhở | Quy tắc thời gian/DST, action thông báo |
| `architecture/on-device-extraction.md` | Đọc ảnh/pdf/xlsx/md/email trên máy: decoder, OCR đa hệ chữ, luật + mẫu theo thị trường, LLM của OS | Làm import | Giới hạn email (§8), eval (§11), hiệu năng (§12) |
| `architecture/voice-and-text-input.md` | STT theo vùng, bias, model tải về, NLU gói ngôn ngữ, eval theo giọng | Làm Quick Add, giọng nói | Ngưỡng NLU/giọng nói |
| `architecture/i18n-l10n.md` | Cấp hỗ trợ locale, định dạng, hệ lịch, ngày lễ, RTL, quy trình dịch, cổng chất lượng | Mọi việc có chữ/ngày/số | Danh sách locale, quy trình dịch |
| `l10n/README.md` + `glossary.csv`, `style-guide-en.md`, `style-guide-vi.md` | Thuật ngữ (258), giọng văn từng locale, so sánh TMS, quy trình dịch giả/LQA, mẫu style guide | Viết/dịch chuỗi UI | Thuật ngữ, giọng văn |
| `architecture/multi-platform.md` | Một codebase cho điện thoại/tablet/máy tính/web, quy tắc code từ S1, ma trận năng lực theo nền tảng | Thêm plugin, làm layout, làm desktop | Năng lực theo nền tảng |
| `integrations/integration-guide.md` | FCM, store, RevenueCat, OAuth, email forward, Google, Notion, MS To Do, watch, kênh nhắn tin | Làm tích hợp, việc cần chờ duyệt | Product ID, bước đăng ký, plugin list |
| `uiux/design-system.md` | Token, font theo hệ chữ, component, a11y, RTL | Làm UI | Token |
| `uiux/ux-flows-and-screens.md` | IA, wireframe, 6 luồng P0, lỗi/trống, hỗ trợ | Làm màn hình/luồng | Danh sách luồng P0 |
| `security-privacy.md` | Phân loại dữ liệu, kiểm soát, bên thứ ba, pháp lý theo thị trường, xóa/xuất | Đụng dữ liệu nhạy cảm, bên thứ ba | Bên thứ ba, định dạng export |
| `engineering/testing-and-release.md` | Ma trận thiết bị, tầng test, CI/CD, phát hành | Viết test, release | Thiết bị QA, quy trình release |
| `plan/implementation-plan.md` | Phase 0-4, sprint, kế hoạch E/V/L (ngày công, AC), rủi ro | Lập kế hoạch sprint | Lịch, sprint |
| `guides/ai-dev-workflow.md` | Token budget, graphify, unslop, agency agents, handoff | Thiết lập quy trình AI | Lệnh tooling |
