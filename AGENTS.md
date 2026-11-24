# AGENTS.md: RemindMe

> File này được nạp tự động mỗi phiên (Claude Code qua `CLAUDE.md`, Codex đọc trực tiếp).
> Giữ dưới ~120 dòng. Chi tiết nằm trong `docs/`, chỉ đọc khi cần.

## Dự án
App todo + nhắc việc + lịch trình du lịch đa nền tảng (Android/iOS), freemium.
Điểm khác biệt: nhập bằng giọng nói, ảnh, xlsx, pdf, md, email chuyển tiếp; AI tự tạo lịch trình
từ vé máy bay/tàu/xe/khách sạn/lịch khám; nhắc lặp lại (kể cả âm lịch); thông báo tới điện thoại và đồng hồ.
Thị trường đầu tiên: Việt Nam (tiếng Việt là ngôn ngữ chính), sau đó global.

## Trạng thái
Giai đoạn: **Phase 0, tài liệu và thiết kế** (chưa có code). Xem `docs/STATE.md`.

## Stack đã chốt (lý do: `docs/architecture/decisions.md`)
- Mobile: Flutter 3 (Dart), Riverpod, go_router, Drift (SQLite), offline-first
- Watch: watchOS (SwiftUI) + Wear OS (Compose, Tiles), Phase 2
- Backend: Supabase (Postgres, Auth, Storage, RLS) + `worker` TypeScript (Node 22, Fastify, pg-boss)
- AI: Claude API qua backend (mặc định `claude-opus-5-5`, model cấu hình theo route), structured outputs
- Push: FCM (Android) + APNs (iOS, qua FCM); nhắc giờ chính xác chạy **local trên máy**
- Thanh toán: RevenueCat (StoreKit 2 + Google Play Billing)

## Cấu trúc repo (dự kiến)
```
apps/mobile/        Flutter app
apps/watch-ios/     watchOS app        apps/wear-android/  Wear OS app
services/worker/    TS worker: AI ingestion, email inbound, Gmail, push, webhooks
supabase/           migrations SQL, seed, edge functions
packages/parsers/   parser dùng chung (rrule, âm lịch, ngày giờ tiếng Việt) + test fixtures
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
5. Thời gian: lưu `timestamptz` UTC + `tz` IANA của sự kiện. Vé máy bay dùng giờ địa phương của sân bay.
6. Dữ liệu y tế/booking là dữ liệu nhạy cảm: không log nội dung, không gửi cho bên thứ ba ngoài danh sách
   trong `docs/security-privacy.md`.
7. Không bao giờ để API key (Claude, Google, RevenueCat secret) trong app mobile; mọi lời gọi AI đi qua worker.
8. Văn bản viết cho người dùng hoặc tài liệu: chạy `tools/unslop-docs.sh <file>` trước khi commit.
9. Sau khi sửa docs/code nhiều: `tools/graphify-docs.sh` để cập nhật `graphify-out/GRAPH_REPORT.md`.
10. Commit nhỏ, message dạng `type(scope): mô tả` (feat, fix, docs, chore, refactor, test).

## Lệnh hay dùng
```bash
tools/ai-tools-setup.sh            # cài graphify + unslop vào .venv-tools (1 lần mỗi máy/phiên cloud)
tools/graphify-docs.sh             # dựng lại knowledge graph của docs/
.venv-tools/bin/graphify query "luồng import vé máy bay" --budget 1500
.venv-tools/bin/graphify section "1. Rolling window scheduler"   # tên heading đầy đủ
tools/unslop-docs.sh docs/product/PRD.md   # làm sạch văn phong AI (deterministic, không gọi API)
```
<!-- Khi có code: thêm lệnh build/test/lint ở đây, mỗi lệnh 1 dòng. -->

## Agency agents (persona chuyên môn)
Gọi qua skill `agency-agents`. Bảng persona nào dùng cho phase nào: `docs/guides/ai-dev-workflow.md`.
