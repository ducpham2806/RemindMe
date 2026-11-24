# AGENTS.md: RemindMe

> File này được nạp tự động mỗi phiên (Claude Code qua `CLAUDE.md`, Codex đọc trực tiếp).
> Giữ dưới ~120 dòng. Chi tiết nằm trong `docs/`, chỉ đọc khi cần.

## Dự án
App todo + nhắc việc + lịch trình du lịch đa nền tảng (Android/iOS), freemium.
Điểm khác biệt: nhập bằng giọng nói (đúng giọng vùng), ảnh, xlsx, pdf, md, email chuyển tiếp; tự tạo lịch trình
từ vé máy bay/tàu/xe/khách sạn/lịch khám; nhắc lặp lại (kể cả âm lịch, Hijri); thông báo tới điện thoại và đồng hồ.
Thị trường: **global từ launch**, ngôn ngữ cấp A là `en` + `vi`, các locale khác theo cấp B/C (`docs/architecture/i18n-l10n.md`).

## Trạng thái
Giai đoạn: **Phase 0 → S1-S3** (Supabase migrations + pgTAP; core/platform/data/parsers; app offline: Hôm nay, chi tiết, Quick Add NLU en/vi, nhắc local). Xem `docs/STATE.md`.

## Stack đã chốt (lý do: `docs/architecture/decisions.md`)
- Mobile: Flutter 3 (Dart), Riverpod, go_router, Drift (SQLite), offline-first
- Watch: watchOS (SwiftUI) + Wear OS (Compose, Tiles), Phase 2
- Máy tính: Flutter macOS + Windows cùng codebase, Phase 4 (ADR-014). Từ S1 giữ quy tắc `docs/architecture/multi-platform.md` §2
- Backend: Supabase (Postgres, Auth, Storage, RLS; ghi chỉ qua RPC `sync_push`) + `worker` TypeScript (Node 22, Fastify, pg-boss)
- i18n: ARB + ICU (`gen-l10n`), CLDR qua `intl`; NLU, mẫu tài liệu, ngày lễ là **gói dữ liệu theo locale** tải qua CDN có chữ ký
- OS tối thiểu: iOS 17+, Android 8.0+ (ADR-011)
- Đọc file/ảnh/giọng nói: **chạy trên máy, không gọi AI API trả phí** (OCR của OS/ML Kit + luật + mẫu nhà cung cấp;
  LLM của OS như Apple Foundation Models/Gemini Nano chỉ là tùy chọn). Xem `docs/architecture/on-device-extraction.md`
- Push: FCM (Android) + APNs (iOS, qua FCM); nhắc giờ chính xác chạy **local trên máy**
- Thanh toán: RevenueCat (StoreKit 2 + Google Play Billing)

## Cấu trúc repo (`*` = chưa tạo)
```
apps/client/        Flutter app (khung S1): Android, iOS, iPadOS; macOS, Windows ở Phase 4
apps/watch-ios/*    watchOS app        apps/wear-android/*  Wear OS app
services/worker/*   TS worker: entitlement, hộp thư email, push, OAuth, webhooks (không phân tích nội dung, không nằm trên đường ghi)
supabase/           migrations/ (schema, RLS, sync_push/pull, quota, seed gói), tests/database/ (pgTAP), tests/shim/
packages/core/      Dart thuần: HLC, id, thiết bị, entitlement, giao thức sync, CivilDate, recurrence (RRULE + âm lịch)
packages/data/      Drift (mirror bảng server), outbox, SyncEngine, reminders/ (rolling window); test server giả + contract Postgres
packages/platform/  interface + PlatformCapabilities; adapter theo nền tảng nằm trong apps/*/lib/platform/
packages/parsers/   Dart thuần: NLU luật + gói en/vi (nlu/packs/), bộ câu eval; decoder, mẫu tài liệu* ; fixtures/
docs/               tài liệu (bản đồ: docs/INDEX.md)
tools/              script cho AI tooling (graphify, unslop)
```

## Quy tắc làm việc (bắt buộc)
1. **Đầu phiên:** chỉ đọc `AGENTS.md` + `docs/STATE.md`. Cần thêm thì tra `docs/INDEX.md`,
   rồi đọc đúng section: `graphify section "Tên heading"` hoặc `grep -n "^#" file` rồi `Read` theo offset.
   Không đọc nguyên cả thư mục `docs/`.
2. **Cuối phiên / sau mỗi mốc:** thêm 1 entry lên **đầu** `docs/WORKLOG.md` (mẫu có sẵn trong file)
   và cập nhật `docs/STATE.md` (việc đang dở, bước tiếp theo, blocker). Không bỏ qua bước này.
3. Quyết định kiến trúc mới thì thêm ADR vào `docs/architecture/decisions.md` (ngắn: bối cảnh, quyết định, hệ quả).
4. Giới hạn gói Free **không hard-code**: lấy từ bảng `plan_entitlements` (xem `docs/product/pricing-entitlements.md`).
5. Thời gian: lưu `timestamptz` UTC + `tz` IANA; item cả ngày dùng `date`. Quy tắc DST/floating: `reminder-engine.md` §5.
   Không giả định locale, múi giờ, định dạng ngày, đồng tiền hay ngôn ngữ mặc định ở bất kỳ đâu.
5b. Không chuỗi hiển thị hard-code: mọi chuỗi qua ARB, mọi ngày/số/tiền qua formatter CLDR; UI dùng widget directional (sẵn sàng RTL).
6. Dữ liệu y tế/booking là dữ liệu nhạy cảm: không log nội dung, không gửi cho bên thứ ba ngoài danh sách
   trong `docs/security-privacy.md`.
7. Không bao giờ để secret (Google, RevenueCat) trong app mobile. Không thêm lời gọi AI API trả phí theo đầu người dùng
   (ADR-010); AI chỉ dùng ở khâu phát triển (viết mẫu, code).
8. Văn bản tiếng Anh cho người dùng/store/docs: chạy `tools/unslop-docs.sh <file>` (xem diff) trước khi commit.
8b. Mỗi nội dung có **một nguồn chuẩn** (bảng ở `docs/INDEX.md`); tài liệu khác chỉ link, không chép số liệu.
9. Sau khi sửa docs/code nhiều: `tools/graphify-docs.sh` để cập nhật `graphify-out/GRAPH_REPORT.md`.
10. Commit nhỏ, message dạng `type(scope): mô tả` (feat, fix, docs, chore, refactor, test).

## Lệnh hay dùng
```bash
tools/ai-tools-setup.sh            # cài graphify + unslop vào .venv-tools (1 lần mỗi máy/phiên cloud)
tools/graphify-docs.sh             # dựng lại knowledge graph của docs/
.venv-tools/bin/graphify query "luồng import vé máy bay" --budget 1500
.venv-tools/bin/graphify section "1. Rolling window scheduler"   # tên heading đầy đủ
tools/unslop-docs.sh docs/product/PRD.md   # làm sạch văn phong AI (deterministic, không gọi API)
tools/install-hooks.sh             # hook commit-msg (1 lần sau khi clone)
PGHOST=localhost PGUSER=postgres tools/db-test.sh   # migrations + pgTAP trên Postgres thuần (cần pgtap, pg_prove)
python3 tools/check-docs.py && python3 tools/validate-fixtures.py && python3 tools/lint-hardcoded-strings.py
python3 tools/check-arb.py && python3 tools/pseudo-arb.py && python3 tools/lint-platform-checks.py   # ARB, pseudo-locale en_XA, quy tắc nền tảng
flutter pub get && (cd apps/client && flutter gen-l10n) && flutter analyze      # Flutter 3.50.1, pub workspace ở gốc
for p in core platform data parsers; do (cd packages/$p && dart test); done; (cd apps/client && flutter test)
(cd packages/data && dart run build_runner build)   # sau khi sửa bảng Drift
REMINDME_PG=1 PGHOST=localhost PGUSER=postgres (cd packages/data && dart test test/pg_contract_test.dart)  # sau db-test.sh
```

## Agency agents (persona chuyên môn)
Gọi qua skill `agency-agents`. Bảng persona nào dùng cho phase nào: `docs/guides/ai-dev-workflow.md`.
