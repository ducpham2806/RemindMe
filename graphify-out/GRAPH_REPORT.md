# Graph Report - RemindMe  (2026-11-24)

## Corpus Check
- 25 files · ~22,405 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 1 file(s) not represented in the graph (top: (none) 1)

## Summary
- 216 nodes · 196 edges · 22 communities (18 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- UX: kiến trúc thông tin, luồng, màn hình
- Hướng dẫn tích hợp với nền tảng khác
- 4. User stories và tiêu chí chấp nhận (MVP = P0)
- RemindMe – Phân tích đối thủ & thị trường (cuối 2026)
- 3. Phân tích từng đối thủ
- Kiến trúc hệ thống
- Design system
- Architecture Decision Records (ADR)
- AI ingestion: giọng nói, ảnh, xlsx, pdf, md, email → todo / lịch trình
- API spec (worker `/v1`)
- Kế hoạch triển khai
- AGENTS.md: RemindMe
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
1. `3. Phân tích từng đối thủ` - 14 edges
2. `Hướng dẫn tích hợp với nền tảng khác` - 14 edges
3. `Design system` - 11 edges
4. `Architecture Decision Records (ADR)` - 10 edges
5. `Kế hoạch triển khai` - 9 edges
6. `AI ingestion: giọng nói, ảnh, xlsx, pdf, md, email → todo / lịch trình` - 9 edges
7. `API spec (worker `/v1`)` - 9 edges
8. `AGENTS.md: RemindMe` - 8 edges
9. `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` - 8 edges
10. `UX: kiến trúc thông tin, luồng, màn hình` - 8 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (22 total, 4 thin omitted)

### Community 0 - "UX: kiến trúc thông tin, luồng, màn hình"
Cohesion: 0.10
Nodes (19): 1. Kiến trúc thông tin, 2.1 Hôm nay, 2.2 Quick Add (bottom sheet), 2.3 Chi tiết item, 2.4 Import → Xem lại, 2.5 Chi tiết chuyến đi, 2.6 Lịch, 2. Màn hình chính (wireframe) (+11 more)

### Community 1 - "Hướng dẫn tích hợp với nền tảng khác"
Cohesion: 0.11
Nodes (18): 0. Việc phải khởi động sớm (thời gian chờ dài), 10. Dịch vụ du lịch bổ trợ (Phase 3, gói trả phí), 11. Kênh nhắc bổ sung tại Việt Nam (tùy chọn, Phase 3), 12. Danh sách SDK/plugin dự kiến (Flutter), 1. Thông báo đẩy: FCM + APNs (Phase 1), 2. Thanh toán (Phase 1), 3. Đăng nhập (Phase 1), 4.1 Share sheet / share intent (+10 more)

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
Nodes (11): 1. Sơ đồ thành phần, 2. Thành phần và trách nhiệm, 3.1 Tạo nhắc nhở nhanh (offline được), 3.2 Import booking từ ảnh/pdf/xlsx/email, 3.3 Thông báo kêu và hành động, 3. Luồng chính, 4. Đồng bộ (Sync), 5. Yêu cầu phi chức năng (+3 more)

### Community 6 - "Design system"
Cohesion: 0.17
Nodes (11): 10. Bàn giao cho Flutter, 1. Nguyên tắc, 2. Màu (token), 3. Chữ, 4. Khoảng cách, bo góc, đổ bóng, 5. Icon & hình, 6. Component chính, 7. Chuyển động (+3 more)

### Community 7 - "Architecture Decision Records (ADR)"
Cohesion: 0.18
Nodes (10): ADR-001: Flutter cho app mobile, native cho watch, ADR-002: Supabase + worker TypeScript, ADR-003: Offline-first, nhắc nhở local, ADR-004: AI extraction phía server, ADR-005: Email chuyển tiếp trước, Gmail API sau, ADR-006: RevenueCat cho subscription, ADR-007: Lặp lại RRULE + âm lịch, ADR-008: Entitlement phía server (+2 more)

### Community 8 - "AI ingestion: giọng nói, ảnh, xlsx, pdf, md, email → todo / lịch trình"
Cohesion: 0.20
Nodes (9): 1. Ma trận đầu vào, 2. Schema trích xuất (rút gọn), 3. Gọi Claude (worker, TypeScript, `@anthropic-ai/sdk`), 4. Chuẩn hóa sau LLM, 5. Màn Xem lại (contract với UI), 6. Eval & chất lượng, 7. Giọng nói tiếng Việt: parser nhanh, 8. Quyền riêng tư (+1 more)

### Community 9 - "API spec (worker `/v1`)"
Cohesion: 0.20
Nodes (9): API spec (worker `/v1`), Entitlement & quota, Mã lỗi chuẩn, Parse & import, Rate limit, Sync, Thiết bị & push, Tích hợp (+1 more)

### Community 10 - "Kế hoạch triển khai"
Cohesion: 0.20
Nodes (9): Checklist tích hợp theo phase, Kế hoạch triển khai, Phase 0: Khám phá & nền móng (3 tuần, đang làm), Phase 1: MVP (16 tuần = 8 sprint x 2 tuần), Phase 2: Hệ sinh thái (8 tuần), Phase 3: Thông minh hơn (8 tuần), Phase 4: Mở rộng, Rủi ro kế hoạch (+1 more)

### Community 11 - "AGENTS.md: RemindMe"
Cohesion: 0.25
Nodes (8): Agency agents (persona chuyên môn), AGENTS.md: RemindMe, Cấu trúc repo (dự kiến), Dự án, Lệnh hay dùng, Quy tắc làm việc (bắt buộc), Stack đã chốt (lý do: `docs/architecture/decisions.md`), Trạng thái

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
Cohesion: 0.12
Nodes (11): Bản đồ tài liệu, Blocker, Câu hỏi mở (cần chủ dự án quyết), Ghi chú kỹ thuật, STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG), Tiếp theo (ưu tiên), Đã có, 2026-11-24 · Khởi tạo bộ tài liệu Phase 0 · Claude Code (+3 more)

### Community 21 - "Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents"
Cohesion: 0.25
Nodes (7): 1. Ngân sách ngữ cảnh (token budget), 2. graphify (knowledge graph của repo), 3. unslop (rà văn phong AI), 4. Agency agents (persona chuyên môn), 5. Mẫu handoff (dùng khi chuyển việc giữa persona, giữa phiên, hoặc giữa người), 6. Checklist cuối phiên (bắt buộc), Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents

## Knowledge Gaps
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `3. Phân tích từng đối thủ` connect `3. Phân tích từng đối thủ` to `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Should `UX: kiến trúc thông tin, luồng, màn hình` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Why does `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` connect `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` to `3. Phân tích từng đối thủ`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Should `Hướng dẫn tích hợp với nền tảng khác` be split into smaller, more focused modules?**
  _Cohesion score 0.10526315789473684 - nodes in this community are weakly interconnected._
- **Should `4. User stories và tiêu chí chấp nhận (MVP = P0)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `RemindMe – Phân tích đối thủ & thị trường (cuối 2026)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `3. Phân tích từng đối thủ` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._