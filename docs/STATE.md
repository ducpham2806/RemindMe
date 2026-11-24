# STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)

**Cập nhật:** 2026-11-24 · **Phase:** 0, tài liệu và thiết kế · **Nhánh:** `ccr-7a85f116-dswwig`

## Đã có
- Bộ docs v2 (`docs/INDEX.md`): sản phẩm, kiến trúc + 12 ADR, trích xuất trên máy, giọng nói/NLU đa vùng, i18n/l10n, analytics, kiểm thử/phát hành, kế hoạch E/V/L.
- Quyết định chính: trích xuất trên máy, không AI API trả phí (ADR-010); global từ launch với cấp locale A/B/C (ADR-011); ghi chỉ qua `sync_push` (ADR-012).
- Tooling: `tools/ai-tools-setup.sh`, `tools/graphify-docs.sh`, `tools/unslop-docs.sh`; `graphify-out/GRAPH_REPORT.md`. Chưa có code.

## Tiếp theo (ưu tiên)
1. Chủ dự án duyệt: giá theo nhóm thị trường và giới hạn Free (`product/pricing-entitlements.md`), đợt locale 1 (`architecture/i18n-l10n.md` §2).
2. Nghiên cứu thị trường global (doanh thu productivity app theo quốc gia) để chốt đợt locale 1 và region dữ liệu (ADR-011).
3. Đăng ký Apple Developer (tổ chức, D-U-N-S), Google Play Console, domain, Firebase, Supabase; hồ sơ thuế cho các storefront.
4. Phỏng vấn 15-20 người dùng (VN + ≥ 2 thị trường đợt 1); thu ≥ 300 mẫu tài liệu (≥ 3 thị trường) và bộ câu nói theo vùng (V4).
5. Spike E0 (OCR theo hệ chữ), V0 (STT/NLU), L0 (TMS, glossary, style guide).
6. Prototype 6 luồng P0 (`uiux/ux-flows-and-screens.md`, có bản tiếng Anh), rồi Sprint S1.

## Câu hỏi mở (cần chủ dự án quyết)
- Tên thương mại/domain (docs dùng giả định `RemindMe`, `remindme.app`, bundle `app.remindme`).
- Đợt locale 1 cuối cùng; region Supabase chính.
- Đăng nhập theo thị trường (Zalo/LINE/Kakao) có làm ở Phase 1 không; có bán qua web không.
- Ngân sách dịch giả bản ngữ cho cấp A/B; chấp nhận CASA cho Gmail nếu Google yêu cầu.
- Đội ngũ thực tế để chỉnh timeline.

## Blocker
- Không có.

## Chưa xác minh (kiểm tra ở spike)
Vision iOS với tiếng Việt và các hệ chữ khác; locale STT on-device thực tế trên máy; chất lượng Foundation Models/Gemini Nano theo ngôn ngữ;
định dạng vé thật của các nhà cung cấp; price point từng storefront; giấy phép từng checkpoint PhoWhisper và dữ liệu ngày lễ.
