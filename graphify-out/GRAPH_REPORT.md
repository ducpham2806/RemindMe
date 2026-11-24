# Graph Report - RemindMe  (2026-11-24)

## Corpus Check
- 57 files · ~62,875 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 5 file(s) not represented in the graph (top: (none) 3, .csv 1, .psql 1)

## Summary
- 387 nodes · 361 edges · 34 communities (27 shown, 7 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `50bd72a5`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UX: kiến trúc thông tin, luồng, màn hình
- Hướng dẫn tích hợp với nền tảng khác
- 4. User stories và tiêu chí chấp nhận (MVP = P0)
- steps
- 3. Phân tích từng đối thủ
- Kiến trúc hệ thống
- Design system
- Architecture Decision Records (ADR)
- Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình
- 2. Worker `/v1`
- Kế hoạch triển khai
- Quốc tế hóa và bản địa hóa (i18n / l10n)
- Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ
- Mô hình dữ liệu
- Gói dịch vụ, giá và giới hạn (entitlements): nguồn chuẩn duy nhất
- Bảo mật & quyền riêng tư
- ai-tools-setup.sh
- graphify-docs.sh
- unslop-docs.sh
- STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)
- Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents
- Nhập bằng giọng nói và câu tự nhiên (đa ngôn ngữ, đa vùng miền)
- RemindMe English style guide (source language)
- Kiểm thử, CI/CD và phát hành
- Analytics & telemetry: danh mục sự kiện và consent
- Hướng dẫn văn phong tiếng Việt cho RemindMe
- validate-fixtures.py
- RemindMe: Nghiên cứu thị trường global (locale, region dữ liệu, nhóm giá), 11/2026
- Bản địa hóa (L0): glossary, style guide, TMS
- Bộ mẫu tài liệu cho eval trích xuất (E0.4)
- db-test.sh
- install-hooks.sh

## God Nodes (most connected - your core abstractions)
1. `Hướng dẫn tích hợp với nền tảng khác` - 15 edges
2. `Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình` - 15 edges
3. `Architecture Decision Records (ADR)` - 14 edges
4. `RemindMe English style guide (source language)` - 14 edges
5. `Hướng dẫn văn phong tiếng Việt cho RemindMe` - 14 edges
6. `3. Phân tích từng đối thủ` - 14 edges
7. `Kế hoạch triển khai` - 12 edges
8. `Quốc tế hóa và bản địa hóa (i18n / l10n)` - 12 edges
9. `Design system` - 11 edges
10. `UX: kiến trúc thông tin, luồng, màn hình` - 10 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (34 total, 7 thin omitted)

### Community 0 - "UX: kiến trúc thông tin, luồng, màn hình"
Cohesion: 0.08
Nodes (23): 1. Kiến trúc thông tin, 2.1 Hôm nay, 2.2 Quick Add (bottom sheet), 2.3 Chi tiết item, 2.4 Import → Xem lại, 2.5 Chi tiết chuyến đi, 2.6 Lịch, 2. Màn hình chính (wireframe) (+15 more)

### Community 1 - "Hướng dẫn tích hợp với nền tảng khác"
Cohesion: 0.10
Nodes (19): 0. Việc phải khởi động sớm (thời gian chờ dài), 10. Dịch vụ du lịch bổ trợ (Phase 3, gói trả phí), 11. Kênh nhắc qua ứng dụng nhắn tin (tùy chọn, Phase 3, Plus), 12. AI có sẵn trong hệ điều hành: việc cần đăng ký/kiểm tra (thiết kế ở `on-device-extraction.md` §3, §5 và `voice-and-text-input.md` §3), 13. Danh sách SDK/plugin dự kiến (Flutter), 1. Thông báo đẩy: FCM + APNs (Phase 1), 2. Thanh toán (Phase 1), 3. Đăng nhập (Phase 1) (+11 more)

### Community 2 - "4. User stories và tiêu chí chấp nhận (MVP = P0)"
Cohesion: 0.14
Nodes (13): 1. Vấn đề, 2. Mục tiêu và chỉ số, 3. Persona, 4. User stories và tiêu chí chấp nhận (MVP = P0), 5. Phi mục tiêu (không làm ở v1), 6. Giả thuyết cần kiểm chứng sớm, Lịch trình & chuyến đi, Nhập liệu (+5 more)

### Community 3 - "steps"
Cohesion: 0.11
Nodes (20): runs-on, steps, runs-on, steps, PGHOST, PGPASSWORD, PGUSER, jobs (+12 more)

### Community 4 - "3. Phân tích từng đối thủ"
Cohesion: 0.08
Nodes (25): 1. Tóm tắt, 2. Bảng so sánh tổng quan, 3. Phân tích từng đối thủ, 4.1 Giá App Store VN (truy cập 24/11/2026), 4.2 Giới hạn free tier (US/global), 4. Benchmark giá & giới hạn free tier, 5. Khoảng trống thị trường & cơ hội khác biệt, 6.1 Tính năng (ưu tiên theo giá trị / chi phí) (+17 more)

### Community 5 - "Kiến trúc hệ thống"
Cohesion: 0.17
Nodes (11): 1. Sơ đồ thành phần, 2. Thành phần và trách nhiệm, 3.1 Tạo nhắc nhở nhanh (offline được), 3.2 Import booking từ ảnh/pdf/xlsx/email (hoàn toàn trên máy), 3.3 Thông báo kêu và hành động, 3. Luồng chính, 4. Đồng bộ (Sync), 5. Yêu cầu phi chức năng (+3 more)

### Community 6 - "Design system"
Cohesion: 0.17
Nodes (11): 10. Bàn giao cho Flutter, 1. Nguyên tắc, 2. Màu (token), 3. Chữ, 4. Khoảng cách, bo góc, đổ bóng, 5. Icon & hình, 6. Component chính, 7. Chuyển động (+3 more)

### Community 7 - "Architecture Decision Records (ADR)"
Cohesion: 0.13
Nodes (14): ADR-001: Flutter cho app mobile, native cho watch, ADR-002: Supabase + worker TypeScript, ADR-003: Offline-first, nhắc nhở local, ADR-004: AI extraction phía server (Superseded by ADR-010), ADR-005: Email chuyển tiếp trước, Gmail API sau, ADR-006: RevenueCat cho subscription, ADR-007: Lặp lại RRULE + hệ lịch khác, ADR-008: Entitlement phía server (+6 more)

### Community 8 - "Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình"
Cohesion: 0.10
Nodes (20): 10. Quick Add bằng chữ, 11. Đánh giá chất lượng (eval) không cần thiết bị trong CI, 12. Hiệu năng và kích thước app, 13. Thư viện dự kiến, 14. Rủi ro, 1. Kiến trúc 5 tầng, 2. T0: Decoder định dạng (Dart thuần, `packages/parsers`), 3. T1: OCR trên thiết bị (+12 more)

### Community 9 - "2. Worker `/v1`"
Cohesion: 0.20
Nodes (9): 1. Sync (RPC Postgres, `SECURITY DEFINER`, kiểm `auth.uid()`), 2. Worker `/v1`, 3. Webhook (không dùng JWT, xác thực bằng chữ ký/secret), 4. Mã lỗi & rate limit, API spec, Dữ liệu tĩnh trên CDN (không qua worker), Hộp thư email & bản gốc, Thiết bị & push (+1 more)

### Community 10 - "Kế hoạch triển khai"
Cohesion: 0.10
Nodes (20): Checklist tích hợp theo phase, E0. Spike & dữ liệu (Phase 0, ~8d), E1. Decoder T0 (S5, ~7d), `packages/parsers/decoders/`, E2. Plugin OCR native (S5, ~7d), E3. Bộ máy luật T2 (S4-S5, ~10d), `packages/parsers/engine/`, E4. Mẫu nhà cung cấp (S4-S6 rồi liên tục), E5. Màn Xem lại & vòng cải thiện (S6, ~7d), E6. Hộp thư email (S6, ~4d) (+12 more)

### Community 11 - "Quốc tế hóa và bản địa hóa (i18n / l10n)"
Cohesion: 0.15
Nodes (12): 10. Nội dung theo thị trường (ảnh hưởng tới các tài liệu khác), 11. Kỹ thuật (Flutter), 1. Nguyên tắc, 2. Cấp hỗ trợ và đợt phát hành (đề xuất, chốt sau nghiên cứu thị trường), 3. Mô hình locale trong app, 4. Định dạng (CLDR qua `intl`), 5. Hệ lịch, ngày lễ, cuối tuần, 6. Múi giờ và giờ mùa hè (DST) (+4 more)

### Community 12 - "Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ"
Cohesion: 0.20
Nodes (9): 1. Rolling window scheduler, 2. Android, 3. iOS, 4. Lặp lại (recurrence), 5. Múi giờ, DST và du lịch (nguồn chuẩn cho quy tắc thời gian), 6. Đồng hồ thông minh, 7. Telemetry, 8. Nhiều thiết bị (+1 more)

### Community 13 - "Mô hình dữ liệu"
Cohesion: 0.29
Nodes (6): 1. Sơ đồ quan hệ, 2. Phân loại item, 3. DDL rút gọn (Postgres), 4. Quy tắc đếm quota (thực thi trong RPC `sync_push`, hàm `app.usage_for`), 5. Bảng chỉ có ở client (Drift), Mô hình dữ liệu

### Community 14 - "Gói dịch vụ, giá và giới hạn (entitlements): nguồn chuẩn duy nhất"
Cohesion: 0.22
Nodes (8): 1.1 Bảng giá theo nhóm thị trường (đề xuất), 1.2 Khuyến mãi theo thị trường (thử nghiệm, remote config), 1. Giá, 2. Ma trận giới hạn (seed `plan_entitlements`), 3. Quy tắc áp dụng, 4. Paywall theo ngữ cảnh, 5. Kinh tế đơn vị (giả định, cần đo lại), Gói dịch vụ, giá và giới hạn (entitlements): nguồn chuẩn duy nhất

### Community 15 - "Bảo mật & quyền riêng tư"
Cohesion: 0.25
Nodes (7): 1. Phân loại dữ liệu, 2. Kiểm soát, 3. Bên thứ ba xử lý dữ liệu (liệt kê trong Privacy Policy), 4. Pháp lý theo thị trường (checklist, luật sư địa phương xác nhận), 5. Ứng phó sự cố, 6. Xóa tài khoản, xuất dữ liệu, lưu trữ, Bảo mật & quyền riêng tư

### Community 20 - "STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)"
Cohesion: 0.07
Nodes (24): Agency agents (persona chuyên môn), AGENTS.md: RemindMe, Cấu trúc repo (`*` = chưa tạo), Dự án, Lệnh hay dùng, Quy tắc làm việc (bắt buộc), Stack đã chốt (lý do: `docs/architecture/decisions.md`), Trạng thái (+16 more)

### Community 21 - "Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents"
Cohesion: 0.25
Nodes (7): 1. Ngân sách ngữ cảnh (token budget), 2. graphify (knowledge graph của repo), 3. unslop (rà văn phong AI), 4. Agency agents (persona chuyên môn), 5. Mẫu handoff (dùng khi chuyển việc giữa persona, giữa phiên, hoặc giữa người), 6. Checklist cuối phiên (bắt buộc), Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents

### Community 22 - "Nhập bằng giọng nói và câu tự nhiên (đa ngôn ngữ, đa vùng miền)"
Cohesion: 0.20
Nodes (9): 1. Luồng, 2. Chọn ngôn ngữ và giọng vùng, 3. Engine STT theo nền tảng, 4. Model mở chạy trên máy (tùy chọn, Phase 2), 5. NLU luật: gói ngữ pháp theo ngôn ngữ, 6. Hậu xử lý văn bản STT, 7. Đánh giá theo ngôn ngữ và vùng, 8. Quyền riêng tư (+1 more)

### Community 23 - "RemindMe English style guide (source language)"
Cohesion: 0.13
Nodes (14): 10. Paywall wording, 11. Accessibility wording, 12. Terminology, 13. Do and don't (from the P0 flows), 1. Source English, 2. Voice and tone, 3. Addressing the user, 4. Capitalization (+6 more)

### Community 24 - "Kiểm thử, CI/CD và phát hành"
Cohesion: 0.33
Nodes (5): 1. Ma trận thiết bị, 2. Các tầng test, 3. CI/CD, 4. Phát hành, Kiểm thử, CI/CD và phát hành

### Community 25 - "Analytics & telemetry: danh mục sự kiện và consent"
Cohesion: 0.33
Nodes (5): 1. Consent, 2. Thuộc tính chung (mọi event), 3. Danh mục sự kiện, 4. Quy tắc, Analytics & telemetry: danh mục sự kiện và consent

### Community 26 - "Hướng dẫn văn phong tiếng Việt cho RemindMe"
Cohesion: 0.13
Nodes (14): 10. Paywall, 11. Accessibility, 12. Thuật ngữ hay sai, 13. Nên và không nên (lấy từ các luồng P0), 1. Giọng văn, 2. Xưng hô, 3. Từ ngữ: chuẩn toàn quốc trong UI, NLU hiểu cả từ địa phương, 4. Chính tả, viết hoa (+6 more)

### Community 28 - "RemindMe: Nghiên cứu thị trường global (locale, region dữ liệu, nhóm giá), 11/2026"
Cohesion: 0.18
Nodes (10): 1. Chi tiêu và lượt tải theo quốc gia, 2. Hồ sơ từng thị trường, 3. Dữ liệu có cấu trúc trong tài liệu du lịch, 4. Đề xuất locale (cấp B đợt 1 và thứ tự các đợt sau), 5. Region Supabase chính, 6. Kiểm tra nhóm giá T1/T2/T3, 7. Rủi ro và việc cần xác minh, 8. Nguồn (truy cập 24/11/2026) (+2 more)

### Community 29 - "Bản địa hóa (L0): glossary, style guide, TMS"
Cohesion: 0.22
Nodes (8): 1. Thư mục có gì, 2. So sánh TMS (giá tra ngày 2026-11-24), 3. Đề xuất, 4. Thuê dịch giả bản ngữ và LQA, 5. Glossary và style guide trong quy trình, 6. Mẫu `style-guide-<locale>.md` cho dịch giả cấp B, 7. Câu hỏi mở cho chủ dự án, Bản địa hóa (L0): glossary, style guide, TMS

### Community 30 - "Bộ mẫu tài liệu cho eval trích xuất (E0.4)"
Cohesion: 0.29
Nodes (6): 1. Cấu trúc, 2. Thu mẫu, 3. Ẩn danh (bắt buộc trước khi commit), 4. Viết `expected.json`, 5. OCR trên máy thật, Bộ mẫu tài liệu cho eval trích xuất (E0.4)

### Community 31 - "db-test.sh"
Cohesion: 0.67
Nodes (3): PGUSER, run(), db-test.sh script

## Knowledge Gaps
- **1 isolated node(s):** `PGUSER`
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 321 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `PGUSER` to the rest of the system?**
  _1 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UX: kiến trúc thông tin, luồng, màn hình` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Should `Hướng dẫn tích hợp với nền tảng khác` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `4. User stories và tiêu chí chấp nhận (MVP = P0)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `steps` be split into smaller, more focused modules?**
  _Cohesion score 0.10952380952380952 - nodes in this community are weakly interconnected._
- **Should `3. Phân tích từng đối thủ` be split into smaller, more focused modules?**
  _Cohesion score 0.07692307692307693 - nodes in this community are weakly interconnected._
- **Should `Architecture Decision Records (ADR)` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._