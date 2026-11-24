# WORKLOG

> Nhật ký công việc. **Entry mới thêm ở ĐẦU** (ngay dưới khối mẫu). Đọc nhanh: `head -60 docs/WORKLOG.md`.
> Khi file > 400 dòng: chuyển các entry cũ sang `docs/worklog/archive/YYYY-MM.md`.

<!-- MẪU (copy, không sửa khối này)
## YYYY-MM-DD · <tiêu đề ngắn> · <người/agent>
- **Làm:** ...
- **Quyết định:** ... (ADR-xxx nếu có)
- **File:** ...
- **Kiểm chứng:** lệnh/test đã chạy + kết quả
- **Dở dang / tiếp theo:** ...
-->

## 2026-11-24 · Plus đăng nhập nhiều loại thiết bị (ADR-013 sửa đổi 1) · Claude Code
- **Làm:** chủ dự án duyệt: Plus dùng đồng thời điện thoại, tablet, laptop. Migration `20261124000007_plus_multi_device.sql`: entitlement
  `max_devices_per_class` (Free 1, Plus 1) + `max_active_devices` Plus 3; cột `device_class` (web/desktop luôn `computer`, `ipados` luôn `tablet`);
  `app.pick_evictions` (giữ máy mới + máy hoạt động gần nhất); trigger trên `subscriptions` cắt thiết bị khi hạ gói (`end_reason='plan_limit'`);
  `session_status(device_id, platform, device_class)` trả `will_replace` cho màn xác nhận. Test `006_plus_multi_device.sql` (14 test).
- **Quyết định:** Plus = 1 điện thoại + 1 tablet + 1 máy tính; đổi được bằng `plan_entitlements` (`max_devices_per_class = -1` cho nhiều máy cùng loại).
  Free đăng nhập máy thứ 2 thấy paywall `paywall_devices` trong hộp xác nhận.
- **Kiểm chứng:** `tools/db-test.sh` 6 file, 102 test PASS; `check-docs` 0 lỗi.
- **Dở dang / tiếp theo:** "máy tính" cần web app (đang Phase 4): chờ chủ dự án quyết thời điểm; xem `docs/STATE.md`.

## 2026-11-24 · Một tài khoản một thiết bị + lịch sử đăng nhập; sửa CI · Claude Code
- **Làm:**
  - Yêu cầu chủ dự án: đăng nhập máy mới thì máy cũ bị đá, lưu lịch sử đăng nhập. ADR-013 + migration `20261124000006_single_device_sessions.sql`:
    bảng `user_sessions` (theo claim `session_id` của JWT; thiết bị, nền tảng, phiên bản, IP, quốc gia, thời gian, lý do kết thúc), RPC `session_status`,
    `session_claim`, `session_end`; RLS mọi bảng của user + `sync_push`/`sync_pull`/`quota_status` chỉ nhận phiên `active` (bọc hàm cũ, đổi tên `app.*_core`);
    phiên bị đá không claim lại được; xóa `auth.sessions` cũ; entitlement `max_active_devices` = 1/1.
  - Test `005_single_device.sql` (21 test). Tổng 88 test pass.
  - Docs: pricing (key mới), data-model, api-spec (RPC, lỗi 403, push `session.revoked`, job worker), reminder-engine §8 (hủy thông báo khi bị đá),
    UX §3.7 + IA "Tài khoản & thiết bị", PRD US-54, security (phân loại, retention IP 90 ngày/lịch sử 12 tháng), analytics, system-architecture.
  - CI: bước fixtures lỗi vì jsonschema 4.10 của Ubuntu ghép `$id` tương đối hai lần → dùng `$id` tuyệt đối, cố định Python 3.12. Job DB pass trên GitHub.
- **Quyết định:** ADR-013. Vượt giới hạn thì đá phiên `last_seen_at` cũ nhất (không chặn máy mới). Đồng hồ/widget không tính là thiết bị.
- **Kiểm chứng:** `tools/db-test.sh` 5 file, 88 test PASS; validate-fixtures pass với jsonschema 4.10.3 và 4.26.
- **Dở dang / tiếp theo:** worker job `session.notify_revoked`, `cleanup.sessions`; xác nhận quyền xóa `auth.sessions` trên Supabase thật; xem `docs/STATE.md`.

## 2026-11-24 · Phase 0: DB sync có quota, khung repo, bộ mẫu, nghiên cứu global, L0 · Claude Code
- **Làm:**
  - `supabase/migrations/` (5 file): schema theo data-model, khóa ngoại kèm `user_id`, RLS chỉ SELECT + trigger chặn ghi từ role client,
    `version` gán sau khóa advisory theo user (sync_pull không sót hàng do commit muộn), entitlement/quota (`app.usage_for`, `app.rrule_fires_on`),
    RPC `sync_push` (LWW theo `field_clock`, conflict notes qua `base_clock`, tombstone dây chuyền, subtransaction từng mutation, pending_quota → archived/quota),
    `sync_pull`, `quota_status`, `profile_init` (Inbox id xác định), seed gói từ pricing §2.
  - 67 test pgTAP (`supabase/tests/database/`) trên Postgres thuần qua shim Supabase; runner `tools/db-test.sh`.
  - Khung repo: CI, `tools/check-docs.py`, `tools/lint-hardcoded-strings.py`, `tools/validate-fixtures.py`, hook commit-msg, `.editorconfig`.
  - E0.4: `packages/parsers/fixtures/` (cấu trúc, schema meta/expected, quy trình ẩn danh, 1 mẫu tổng hợp).
  - Subagent Trend Researcher: `research/global-market.md`. Subagent i18n: `docs/l10n/` (glossary 258 thuật ngữ, style guide en/vi, README TMS).
  - Sửa docs cho khớp code: data-model (HLC, quy tắc quota thực thi), api-spec (`profile_init`, định dạng kết quả), testing, plan, AGENTS, INDEX.
    Sửa số liệu: giá neo Todoist $6,99/$59,99; TickTick US có gói tháng $4,99.
- **Quyết định:** quota import đếm từ bảng `imports` (không dùng `usage_counters`); Inbox không tính `max_lists`; server chỉ đếm nhắc/ngày xấp xỉ (engine máy chính xác);
  billing_retry/paused mất quyền Plus, grace còn quyền. Đề xuất locale/region/giá **chưa áp**, chờ chủ dự án.
- **Kiểm chứng:** `tools/db-test.sh`: 4 file, 67 test PASS (Postgres 16.15 + pgTAP). Test bắt được lỗi thật: CHECK múi giờ cần quyền execute `app.is_valid_tz`.
  `check-docs`: 0 tham chiếu hỏng. `validate-fixtures`: bắt được email/SĐT chưa che. CI chưa xác nhận chạy trên GitHub (MCP GitHub lỗi kết nối).
  unslop trên `style-guide-en.md`: 1 đề xuất sai (đổi ’ thành ' trong ví dụ về dấu nháy cong), không áp.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`.

## 2026-11-24 · Global từ launch, giọng nói đa vùng, rà soát chồng chéo toàn bộ docs · Claude Code
- **Làm:**
  - Tài liệu mới: `architecture/i18n-l10n.md` (cấp locale A/B/C, CLDR, hệ lịch, RTL, quy trình dịch, cổng chất lượng),
    `architecture/voice-and-text-input.md` (STT theo biến thể vùng, bias, PhoWhisper/Whisper tùy chọn, gói ngữ pháp có từ địa phương Bắc/Trung/Nam),
    `product/analytics-events.md` (danh mục event + consent theo vùng), `engineering/testing-and-release.md` (ma trận thiết bị, tầng test, CI/CD, rollout).
  - Một subagent rà độc lập toàn bộ docs (mâu thuẫn, trùng lặp, tham chiếu hỏng, thiếu sót, giả định chỉ-VN). Đã sửa các phát hiện mức Cao và phần lớn mức TB.
  - Viết lại: data-model (SYNC_COLS + `field_clock`, cascade xóa, bỏ default vi-VN, `recurrences.kind` rrule/calendar/after_completion, `plan_products`,
    trạng thái subscription đầy đủ, `occurrence_log`, `local_files`), pricing (nhóm giá T1/T2/T3, `feature_watch_app` theo cấp, khuyến mãi theo thị trường),
    plan (global ở Phase 1, gantt 43 tuần, auth/entitlement lên S1-S2, nhánh việc E/V/L), PRD (persona global, quy ước P0-P3), api-spec (sync là RPC Postgres, bỏ Gmail server),
    security (pháp lý theo thị trường, bên thứ ba đầy đủ, khóa ký mẫu, xóa/xuất dữ liệu).
  - Sửa: ADR-001/002/004/005/007/008, thêm ADR-011 (global, region, OS tối thiểu, điều kiện xem lại ADR-010) và ADR-012 (đường ghi duy nhất);
    reminder-engine (DST là nguồn chuẩn, nhiều thiết bị, lập lịch lại khi đổi ngôn ngữ); extraction (OCR đa hệ chữ + PP-OCRv5, mẫu theo thị trường);
    integration, UX (tìm kiếm, cài đặt ngôn ngữ & vùng, xung đột ghi chú, bảng lỗi/trống, hỗ trợ), design system (font theo hệ chữ, RTL), competitor (TL;DR, bỏ bảng giá cũ).
  - INDEX thêm cột "Nguồn chuẩn"; AGENTS thêm quy tắc không giả định locale, không chuỗi hard-code, một nguồn chuẩn; CLAUDE.md rút còn import.
- **Quyết định:** ADR-011, ADR-012. Gmail Phase 3 chạy trên máy. Live Activities Phase 3. Feed ICS Phase 2.
- **Kiểm chứng (tra web 24/11/2026):** PhoWhisper (VinAI) huấn luyện trên dữ liệu nhiều giọng vùng, repo Apache-2.0 (model card ghi không thống nhất);
  Android có `EXTRA_BIASING_STRINGS` (API 33), `EXTRA_ENABLE_LANGUAGE_SWITCH` (API 34); iOS có `contextualStrings`, `SFCustomLanguageModelData`;
  ML Kit Text v2 không có Ả Rập/Kirin/Thái nên dùng PP-OCRv5 mobile (~8 MB/hệ chữ); có package Flutter cho whisper.cpp.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`. Chưa sửa các phát hiện mức Thấp như cắt bớt phần nguồn của competitor doc.

## 2026-11-24 · Bỏ AI API trả phí, chuyển trích xuất sang chạy trên máy · Claude Code
- **Làm:**
  - Viết `docs/architecture/on-device-extraction.md`, thay cho `ai-ingestion.md` (đã xóa). Thiết kế 5 tầng: decoder, OCR của OS,
    luật + mẫu nhà cung cấp, LLM của OS tùy chọn, model tải về để thử nghiệm.
  - Thêm ADR-010 (supersedes ADR-004). Cập nhật cho thống nhất: AGENTS, system-architecture, data-model (bỏ cột chi phí AI,
    thêm `mailbox_messages`), api-spec (bỏ endpoint import/parse, thêm mailbox + CDN mẫu), pricing (`smart_imports_per_month`,
    giọng nói không giới hạn, kinh tế đơn vị = 0 chi phí theo lượt), integration-guide, PRD, UX, security (bỏ Anthropic khỏi bên thứ ba), plan.
  - Kế hoạch chi tiết E0-E8 kèm ngày công và AC; tổng MVP ~54 ngày công.
- **Quyết định:** ADR-010. Email forward: server chỉ lưu MIME (TTL 7 ngày), máy tự phân tích. Mẫu nhà cung cấp là JSON có chữ ký, cập nhật qua CDN.
- **Kiểm chứng (tra web 24/11/2026):** Foundation Models có tiếng Việt từ iOS 26.1, iOS 27 nhận ảnh; ML Kit Text v2 có tiếng Việt;
  Gemini Nano Prompt API chỉ chạy trên một số flagship, đang alpha/beta; Vision iOS tiếng Việt và STT on-device tiếng Việt chưa xác nhận được, phải test trên máy thật (E0).
- **Dở dang / tiếp theo:** Spike E0, thu mẫu thật. Kiểm tra lại yêu cầu CASA khi Gmail chỉ xử lý trên máy.

## 2026-11-24 · Khởi tạo bộ tài liệu Phase 0 · Claude Code
- **Làm:**
  - Viết bộ tài liệu hệ thống, UI/UX, sản phẩm, tích hợp, kế hoạch (17 file trong `docs/`).
  - Nghiên cứu đối thủ bằng 1 subagent (persona Trend Researcher): `docs/research/competitor-analysis.md`.
  - Dựng context phân tầng cho AI: `AGENTS.md` (Codex) + `CLAUDE.md` (import AGENTS + STATE).
  - Cài và thử graphify 0.9.118 + unslop 0.7.0; viết script wrapper trong `tools/`.
- **Quyết định:**
  - Stack: Flutter + watch native, Supabase + worker TS, offline-first, Claude API phía server (**đã thay bởi ADR-010**), RevenueCat (ADR-001..009).
  - (Ghi chú sau: thị trường "VN trước" đã thay bởi global từ launch, ADR-011; giới hạn/giá dưới đây đã chỉnh, xem pricing.)
  - Giá đề xuất 59.000đ/tháng, 149.000đ/quý, 449.000đ/năm.
  - Free: 10 nhắc/ngày, 5 chuỗi lặp, 10 lịch hẹn đang hoạt động (gồm booking), 1 chuyến đi, 10 import AI/tháng.
  - Email forward trước, Gmail API sau (tránh CASA sớm). Import Microsoft To Do vào MVP, vì app To Do ngừng 30/06/2027 (đã kiểm chứng qua nhiều nguồn tin 11/2026).
- **Kiểm chứng:**
  - `graphify update .`: 193 node, 174 cạnh, 20 cộng đồng. `graphify benchmark`: ~877 token/query so với ~12,9k token đọc thô (giảm 14,7 lần).
  - `query` và `section` chạy được sau khi thêm `anyio` vào requirements.
  - unslop `--diff` trên toàn bộ docs: 0 AI-ism. Hai sửa đổi nó đề xuất là sai ("iOS" thành "IOS", "watchOS" thành "WatchOS"), nên script để mặc định chỉ hiện diff.
- **Dở dang / tiếp theo:** xem `docs/STATE.md`. Các con số giá/giới hạn và thời gian chờ duyệt store/OAuth là ước lượng, cần xác minh.
