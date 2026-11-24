# Graph Report - RemindMe  (2026-11-24)

## Corpus Check
- 25 files · ~27,271 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 240 nodes · 220 edges · 21 communities (17 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `30293921`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UX: kiến trúc thông tin, luồng, màn hình
- Hướng dẫn tích hợp với nền tảng khác
- 4. User stories và tiêu chí chấp nhận (MVP = P0)
- RemindMe – Phân tích đối thủ & thị trường (cuối 2026)
- 3. Phân tích từng đối thủ
- Kiến trúc hệ thống
- Design system
- Architecture Decision Records (ADR)
- Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình
- API spec (worker `/v1`)
- Kế hoạch triển khai
- Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ
- Mô hình dữ liệu
- Gói dịch vụ, giá và giới hạn (entitlements)
- Bảo mật & quyền riêng tư
- CLAUDE.md
- ai-tools-setup.sh
- graphify-docs.sh
- unslop-docs.sh
- STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)
- Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents

## God Nodes (most connected - your core abstractions)
1. `Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình` - 15 edges
2. `Hướng dẫn tích hợp với nền tảng khác` - 15 edges
3. `3. Phân tích từng đối thủ` - 14 edges
4. `Architecture Decision Records (ADR)` - 11 edges
5. `Design system` - 11 edges
6. `Kế hoạch triển khai` - 10 edges
7. `Trích xuất on-device: kế hoạch chi tiết` - 10 edges
8. `API spec (worker `/v1`)` - 9 edges
9. `AGENTS.md: RemindMe` - 8 edges
10. `Kiến trúc hệ thống` - 8 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (21 total, 4 thin omitted)

### Community 0 - "UX: kiến trúc thông tin, luồng, màn hình"
Cohesion: 0.10
Nodes (19): 1. Kiến trúc thông tin, 2.1 Hôm nay, 2.2 Quick Add (bottom sheet), 2.3 Chi tiết item, 2.4 Import → Xem lại, 2.5 Chi tiết chuyến đi, 2.6 Lịch, 2. Màn hình chính (wireframe) (+11 more)

### Community 1 - "Hướng dẫn tích hợp với nền tảng khác"
Cohesion: 0.10
Nodes (19): 0. Việc phải khởi động sớm (thời gian chờ dài), 10. Dịch vụ du lịch bổ trợ (Phase 3, gói trả phí), 11. Kênh nhắc bổ sung tại Việt Nam (tùy chọn, Phase 3), 12. AI có sẵn trong hệ điều hành (tùy chọn, không tốn phí), 13. Danh sách SDK/plugin dự kiến (Flutter), 1. Thông báo đẩy: FCM + APNs (Phase 1), 2. Thanh toán (Phase 1), 3. Đăng nhập (Phase 1) (+11 more)

### Community 2 - "4. User stories và tiêu chí chấp nhận (MVP = P0)"
Cohesion: 0.14
Nodes (13): 1. Vấn đề, 2. Mục tiêu và chỉ số, 3. Persona, 4. User stories và tiêu chí chấp nhận (MVP = P0), 5. Phi mục tiêu (không làm ở v1), 6. Giả thuyết cần kiểm chứng sớm, Lịch trình & chuyến đi, Nhập liệu (+5 more)

### Community 3 - "RemindMe – Phân tích đối thủ & thị trường (cuối 2026)"
Cohesion: 0.14
Nodes (13): 1. Tóm tắt, 2. Bảng so sánh tổng quan, 4.1 Giá App Store VN (truy cập 24/11/2026), 4.2 Giới hạn free tier (US/global), 4. Benchmark giá & giới hạn free tier, 5. Khoảng trống thị trường & cơ hội khác biệt, 6.1 Tính năng (ưu tiên theo giá trị / chi phí), 6.2 Giá đề xuất (+5 more)

### Community 4 - "3. Phân tích từng đối thủ"
Cohesion: 0.14
Nodes (14): 3. Phân tích từng đối thủ, Any.do, Apple Reminders, Due, Google Tasks / Keep, Microsoft To Do, Nhóm AI-first (Motion, Structured, Amie), Nhóm Việt Nam (+6 more)

### Community 5 - "Kiến trúc hệ thống"
Cohesion: 0.17
Nodes (11): 1. Sơ đồ thành phần, 2. Thành phần và trách nhiệm, 3.1 Tạo nhắc nhở nhanh (offline được), 3.2 Import booking từ ảnh/pdf/xlsx/email (hoàn toàn trên máy), 3.3 Thông báo kêu và hành động, 3. Luồng chính, 4. Đồng bộ (Sync), 5. Yêu cầu phi chức năng (+3 more)

### Community 6 - "Design system"
Cohesion: 0.17
Nodes (11): 10. Bàn giao cho Flutter, 1. Nguyên tắc, 2. Màu (token), 3. Chữ, 4. Khoảng cách, bo góc, đổ bóng, 5. Icon & hình, 6. Component chính, 7. Chuyển động (+3 more)

### Community 7 - "Architecture Decision Records (ADR)"
Cohesion: 0.17
Nodes (11): ADR-001: Flutter cho app mobile, native cho watch, ADR-002: Supabase + worker TypeScript, ADR-003: Offline-first, nhắc nhở local, ADR-004: AI extraction phía server (Superseded by ADR-010), ADR-005: Email chuyển tiếp trước, Gmail API sau, ADR-006: RevenueCat cho subscription, ADR-007: Lặp lại RRULE + âm lịch, ADR-008: Entitlement phía server (+3 more)

### Community 8 - "Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình"
Cohesion: 0.10
Nodes (20): 10. Quick Add bằng chữ, 11. Đánh giá chất lượng (eval) không cần thiết bị trong CI, 12. Hiệu năng và kích thước app, 13. Thư viện dự kiến, 14. Rủi ro, 1. Kiến trúc 5 tầng, 2. T0: Decoder định dạng (Dart thuần, `packages/parsers`), 3. T1: OCR trên thiết bị (+12 more)

### Community 9 - "API spec (worker `/v1`)"
Cohesion: 0.20
Nodes (9): API spec (worker `/v1`), Entitlement & quota, Import (metadata) & hộp thư email, Mã lỗi chuẩn, Rate limit, Sync, Thiết bị & push, Tích hợp (+1 more)

### Community 10 - "Kế hoạch triển khai"
Cohesion: 0.10
Nodes (19): Checklist tích hợp theo phase, E0. Spike & dữ liệu (Phase 0, ~8d), E1. Decoder T0 (S5, ~7d), `packages/parsers/decoders/`, E2. Plugin OCR native (S5, ~6d), E3. Bộ máy luật T2 (S5, ~10d), `packages/parsers/engine/`, E4. Mẫu nhà cung cấp (S6 rồi liên tục, ~12d cho 10 mẫu đầu), E5. Màn Xem lại & vòng cải thiện (S6, ~7d), E6. Hộp thư email (S6, ~4d) (+11 more)

### Community 12 - "Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ"
Cohesion: 0.22
Nodes (8): 1. Rolling window scheduler, 2. Android, 3. iOS, 4. Lặp lại (recurrence), 5. Múi giờ và du lịch, 6. Đồng hồ thông minh, 7. Telemetry bắt buộc, Reminder engine: lập lịch, lặp lại, thông báo, đồng hồ

### Community 13 - "Mô hình dữ liệu"
Cohesion: 0.29
Nodes (6): 1. Sơ đồ quan hệ, 2. Phân loại item, 3. DDL rút gọn (Postgres), 4. Quy tắc đếm quota (thực thi trong RPC `sync_push` và trigger), 5. Bảng chỉ có ở client (Drift), Mô hình dữ liệu

### Community 14 - "Gói dịch vụ, giá và giới hạn (entitlements)"
Cohesion: 0.29
Nodes (6): 1. Giá đề xuất, 2. Ma trận giới hạn (seed `plan_entitlements`), 3. Quy tắc áp dụng, 4. Paywall theo ngữ cảnh (không chặn cứng ngay lần đầu), 5. Kinh tế đơn vị (giả định, cần đo lại), Gói dịch vụ, giá và giới hạn (entitlements)

### Community 15 - "Bảo mật & quyền riêng tư"
Cohesion: 0.29
Nodes (6): 1. Phân loại dữ liệu, 2. Kiểm soát, 3. Bên thứ ba xử lý dữ liệu (liệt kê trong Privacy Policy), 4. Pháp lý cần làm (checklist, xác nhận với luật sư), 5. Ứng phó sự cố, Bảo mật & quyền riêng tư

### Community 20 - "STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)"
Cohesion: 0.08
Nodes (20): Agency agents (persona chuyên môn), AGENTS.md: RemindMe, Cấu trúc repo (dự kiến), Dự án, Lệnh hay dùng, Quy tắc làm việc (bắt buộc), Stack đã chốt (lý do: `docs/architecture/decisions.md`), Trạng thái (+12 more)

### Community 21 - "Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents"
Cohesion: 0.25
Nodes (7): 1. Ngân sách ngữ cảnh (token budget), 2. graphify (knowledge graph của repo), 3. unslop (rà văn phong AI), 4. Agency agents (persona chuyên môn), 5. Mẫu handoff (dùng khi chuyển việc giữa persona, giữa phiên, hoặc giữa người), 6. Checklist cuối phiên (bắt buộc), Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents

## Knowledge Gaps
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `3. Phân tích từng đối thủ` connect `3. Phân tích từng đối thủ` to `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `UX: kiến trúc thông tin, luồng, màn hình` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Why does `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` connect `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` to `3. Phân tích từng đối thủ`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `Hướng dẫn tích hợp với nền tảng khác` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `4. User stories và tiêu chí chấp nhận (MVP = P0)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `3. Phân tích từng đối thủ` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._