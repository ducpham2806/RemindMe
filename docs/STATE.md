# STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)

**Cập nhật:** 2026-11-24 · **Phase:** 0 → S1 (nền móng code) · **Nhánh:** `ccr-7a85f116-dswwig`

## Đã có
- Bộ docs v2 (`docs/INDEX.md`) + 14 ADR (ADR-013: Free 1 thiết bị, Plus 1 điện thoại + 1 tablet + 1 máy tính; ADR-014: một codebase Flutter, app máy tính macOS/Windows ở Phase 4, paywall ghi "sắp có"). Nghiên cứu thị trường global (`research/global-market.md`). L0: glossary 258 thuật ngữ, style guide en/vi, so sánh TMS (`docs/l10n/`).
- DB: `supabase/migrations/` (schema, RLS chỉ đọc, `sync_push`/`sync_pull`/`quota_status`/`profile_init`, giới hạn thiết bị `session_claim`/`session_status`/`session_end`
  + lịch sử đăng nhập + cắt thiết bị khi hạ gói, seed gói) + 102 test pgTAP.
- Khung repo: CI `.github/workflows/ci.yml` (3 job docs-and-lint, db + contract test, flutter đều pass trên GitHub, run #10), kiểm tham chiếu docs, lint chuỗi hard-code, hook commit-msg, bộ mẫu `packages/parsers/fixtures/` (schema + quy trình ẩn danh, 1 mẫu tổng hợp).
- Workspace Dart/Flutter 3.50.1 (`pubspec.yaml` gốc): `packages/core` (HLC khớp server, UUIDv7, id Inbox, loại thiết bị, entitlement, giao thức sync),
  `packages/platform` (interface + `PlatformCapabilities`), `packages/data` (Drift mirror bảng server, outbox, `SyncEngine` merge HLC; contract test với RPC Postgres thật),
  `apps/client` (theme token, go_router + shell thích ứng 3 cỡ, ARB en/vi + pseudo `en_XA`, Ctrl/Cmd+N Quick Add). CI thêm job `flutter` + contract test.
- Chưa có: worker, `packages/parsers` (code), auth/flavors, nối DB + sync vào UI.

## Tiếp theo (ưu tiên)
1. **Chủ dự án duyệt** đề xuất ở `research/global-market.md` §9 (chưa áp vào docs): thêm `it` vào đợt 1 cấp B; đợt 2 `tr, th, zh-Hans, ar, nl, pl, ms`;
   region `eu-central-1` (sửa ADR-011); BR/TR ~50% giá T1, EU/UK ghi đè €4,99/£4,99, thêm SA/AE/HK/TW vào bảng giá. Cùng lúc duyệt giới hạn Free.
2. Trả lời câu hỏi l10n (dưới) rồi chạy trial TMS 14 ngày với 50 key (Crowdin Pro, dự phòng Weblate hosted).
3. Đăng ký Apple Developer (tổ chức, D-U-N-S), Google Play Console, domain, Firebase, Supabase (region theo mục 1); hồ sơ thuế storefront.
4. Thu mẫu tài liệu theo `packages/parsers/fixtures/README.md` (≥ 300, ≥ 3 thị trường); phỏng vấn 15-20 người; bộ câu nói theo vùng (V4).
5. Spike cần máy thật: E0 (OCR theo hệ chữ), V0 (STT/NLU). Prototype 6 luồng P0.
6. Sprint S1 phần còn lại: tạo project Supabase/Firebase (cần tài khoản chủ dự án) → flavors dev/staging/prod, auth (ẩn danh + Google + Apple + email OTP),
   `SupabaseSyncApi` (bản thật của `SyncApi`) + luồng `profile_init` → `session_claim` → sync; nối Drift (`drift_flutter`) vào app; bundle font Be Vietnam Pro; golden test.

## Câu hỏi mở (cần chủ dự án quyết)
- Tên thương mại/domain (docs dùng giả định `RemindMe`, `remindme.app`, bundle `app.remindme`).
- Đợt locale 1, region, nhóm giá: xem Tiếp theo mục 1.
- l10n: giữ tên gói "Free" không dịch ở mọi locale? Đổi tên list mặc định "Inbox/Hộp thư" (trùng nghĩa hộp thư email, đề xuất "Chưa phân loại")?
  Một file `en` hay thêm `en_GB`; tách `es-ES`/`es-419` ở đợt 1? Ngân sách dịch giả cấp B.
- Đăng nhập theo thị trường (Zalo/LINE/Kakao) ở Phase 1? Bán qua web? Chấp nhận CASA cho Gmail nếu Google yêu cầu? Đội ngũ thực tế.

## Việc kỹ thuật còn nợ
- Server chưa chặn `field_clock` ở tương lai xa (máy sai giờ năm 2030 sẽ luôn thắng LWW): kẹp clock > now()+1 ngày trong `sync_push`. Client đã báo lệch qua `HlcClock.receive`.
- ADR-013 phía worker/app chưa làm: job `session.notify_revoked`, `cleanup.sessions`, kiểm phiên ở endpoint worker, màn UX §3.7.
  Kiểm trước Phase 4 (desktop): chính sách thanh toán Microsoft Store, giờ kêu thông báo Windows.
  Cần xác nhận trên Supabase thật: role `postgres` có quyền `delete from auth.sessions` (nếu không, refresh token cũ sống tới khi hết hạn nhưng vẫn bị RLS chặn).
- Rate limit `sync_push` (30/phút/thiết bị) chưa có trong DB/PostgREST; mã hóa cột `booking_details.passengers` chưa làm.
- UX copy: wireframe "KHÔNG GIỜ" dễ đọc thành 0:00 (đề xuất "Chưa đặt giờ"); "Hoãn 10'" dùng dấu phẩy trên. `intl` không có formatter khoảng thời gian/tương đối: chọn ở L1.

## Blocker
- Không có.

## Chưa xác minh (kiểm tra ở spike)
Vision iOS với tiếng Việt và các hệ chữ khác; locale STT on-device thực tế trên máy; chất lượng Foundation Models/Gemini Nano theo ngôn ngữ;
định dạng vé thật; price point từng storefront; giấy phép checkpoint PhoWhisper và dữ liệu ngày lễ; UK coi EEA là adequate; hạn mức từ của Crowdin Pro.
