# Graph Report - RemindMe  (2026-11-25)

## Corpus Check
- 272 files · ~219,813 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 47 file(s) not represented in the graph (top: (none) 7, .xml 7, .ttf 4)

## Summary
- 4228 nodes · 5482 edges · 212 communities (184 shown, 28 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `60645e82`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- UX: kiến trúc thông tin, luồng, màn hình
- Hướng dẫn tích hợp với nền tảng khác
- 4. User stories và tiêu chí chấp nhận (MVP = P0)
- database.dart
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
- WORKLOG
- Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents
- Nhập bằng giọng nói và câu tự nhiên (đa ngôn ngữ, đa vùng miền)
- RemindMe English style guide (source language)
- Kiểm thử, CI/CD và phát hành
- Analytics & telemetry: danh mục sự kiện và consent
- Hướng dẫn văn phong tiếng Việt cho RemindMe
- sys
- RemindMe: Nghiên cứu thị trường global (locale, region dữ liệu, nhóm giá), 11/2026
- Bản địa hóa (L0): glossary, style guide, TMS
- Bộ mẫu tài liệu cho eval trích xuất (E0.4)
- db-test.sh
- install-hooks.sh
- Đa nền tảng: điện thoại, tablet, máy tính (macOS, Windows), web
- tables.dart
- sync_protocol.dart
- services.dart
- entitlements.dart
- sync_engine.dart
- capabilities.dart
- dependencies
- DataClass
- tokens.dart
- hlc.dart
- AppDelegate.swift
- package:remindme_data/remindme_data.dart
- pg_contract_test.dart
- mime.dart
- app.dart
- fake_server.dart
- data/pubspec.yaml
- Table
- app_theme.dart
- formatters.dart
- package:remindme_core/remindme_core.dart
- quick_add_sheet.dart
- reminders.dart
- core/pubspec.yaml
- platform/pubspec.yaml
- values.dart
- analysis_options.yaml
- main.dart
- client/analysis_options.yaml
- ids.dart
- markdown.dart
- pubspec.yaml
- items_repository.dart
- MainActivity.kt
- remindme_client
- LaunchImage.imageset/README.md
- pack.dart
- engine.dart
- result.dart
- providers.dart
- lunar.dart
- today_screen.dart
- with
- recurrence.dart
- _
- months
- weekdays
- table.dart
- day_parts
- numbers
- numbers
- day_parts
- units
- extract/eval.dart
- weekdays
- regions
- helpers.dart
- en.yaml
- package:remindme_parsers/remindme_parsers.dart
- parsers/pubspec.yaml
- vi.yaml
- recurrence
- relative_days
- units
- relative_days
- weekday_list_tokens
- table_tasks.dart
- CivilDate
- row_codec.dart
- Gói ngữ pháp NLU (`<lang>.yaml`)
- imports_repository.dart
- recurrence
- planner.dart
- import_decode.dart
- import_mapper.dart
- text_prompt.dart
- trips_repository.dart
- local_notifications.dart
- candidate_editor.dart
- template.dart
- reminder_binding.dart
- scheduler.dart
- candidate.dart
- package:drift/drift.dart
- actions.dart
- testing.dart
- email.dart
- slots.dart
- itemsRepositoryProvider
- SyncException
- schedule_editor.dart
- lists_repository.dart
- jsonld.dart
- ics.dart
- listsProvider
- package:remindme_data/remindme_data.dart
- import_logic_test.dart
- priority
- import_screen.dart
- me_screen.dart
- columns
- trips.dart
- tz.dart
- priority
- extract_eval_test.dart
- package:remindme_data/remindme_data.dart
- remote_sync.dart
- html_text.dart
- Việc nhà tháng 12
- nlu/eval.dart
- import_test.dart
- document.dart
- dart:convert
- holidays.dart
- calendar_screen.dart
- generic.dart
- flight
- sync_engine_test.dart
- vocabulary.dart
- trips_screen.dart
- quick_add_test.dart
- item_detail_screen.dart
- flight
- airports.dart
- anchors
- anchors
- hotel
- medical
- event
- hotel
- train
- bus
- classify
- train
- event
- medical
- app_icons.dart
- SyncApi
- bus
- adaptive_shell.dart
- Dữ liệu tham chiếu của bộ máy luật T2
- static const
- templates/README.md
- deviceTimeZoneProvider
- package:material_ui/material_ui.dart
- NotificationScheduler
- _ReminderBindingState
- remote_sync_binding.dart
- language_region_screen.dart
- meridiem
- ConsumerWidget
- nowProvider
- calendarSystemSettingProvider
- package:go_router/go_router.dart
- database.dart
- adaptive_shell.dart
- build
- supabase_sync_api_test.dart
- ../../core/theme/tokens.dart
- static const
- Backend Supabase: cấu hình và chạy app với server
- dates
- String?
- BookingType

## God Nodes (most connected - your core abstractions)
1. `_` - 31 edges
2. `anchors` - 30 edges
3. `anchors` - 30 edges
4. `nowProvider` - 28 edges
5. `WORKLOG` - 25 edges
6. `months` - 25 edges
7. `weekdays` - 23 edges
8. `dependencies` - 21 edges
9. `itemsRepositoryProvider` - 20 edges
10. `numbers` - 20 edges

## Surprising Connections (you probably didn't know these)
- `OfflineSyncApi` --implements--> `SyncApi`  [EXTRACTED]
  apps/client/lib/data/providers.dart → packages/core/lib/src/sync_protocol.dart
- `SupabaseSyncApi` --implements--> `SyncApi`  [EXTRACTED]
  apps/client/lib/data/remote/supabase_sync_api.dart → packages/core/lib/src/sync_protocol.dart
- `LocalNotificationScheduler` --implements--> `NotificationScheduler`  [EXTRACTED]
  apps/client/lib/platform/local_notifications.dart → packages/platform/lib/src/services.dart
- `NoopNotificationScheduler` --implements--> `NotificationScheduler`  [EXTRACTED]
  apps/client/lib/platform/local_notifications.dart → packages/platform/lib/src/services.dart
- `AppNotificationTexts` --implements--> `NotificationTexts`  [EXTRACTED]
  apps/client/lib/data/reminders.dart → packages/data/lib/src/reminders/planner.dart

## Import Cycles
- None detected.

## Communities (212 total, 28 thin omitted)

### Community 0 - "UX: kiến trúc thông tin, luồng, màn hình"
Cohesion: 0.08
Nodes (23): 1. Kiến trúc thông tin, 2.1 Hôm nay, 2.2 Quick Add (bottom sheet), 2.3 Chi tiết item, 2.4 Import → Xem lại, 2.5 Chi tiết chuyến đi, 2.6 Lịch, 2. Màn hình chính (wireframe) (+15 more)

### Community 1 - "Hướng dẫn tích hợp với nền tảng khác"
Cohesion: 0.10
Nodes (19): 0. Việc phải khởi động sớm (thời gian chờ dài), 10. Dịch vụ du lịch bổ trợ (Phase 3, gói trả phí), 11. Kênh nhắc qua ứng dụng nhắn tin (tùy chọn, Phase 3, Plus), 12. AI có sẵn trong hệ điều hành: việc cần đăng ký/kiểm tra (thiết kế ở `on-device-extraction.md` §3, §5 và `voice-and-text-input.md` §3), 13. Danh sách SDK/plugin dự kiến (Flutter), 1. Thông báo đẩy: FCM + APNs (Phase 1), 2. Thanh toán (Phase 1), 3. Đăng nhập (Phase 1) (+11 more)

### Community 2 - "4. User stories và tiêu chí chấp nhận (MVP = P0)"
Cohesion: 0.14
Nodes (13): 1. Vấn đề, 2. Mục tiêu và chỉ số, 3. Persona, 4. User stories và tiêu chí chấp nhận (MVP = P0), 5. Phi mục tiêu (không làm ở v1), 6. Giả thuyết cần kiểm chứng sớm, Lịch trình & chuyến đi, Nhập liệu (+5 more)

### Community 3 - "database.dart"
Cohesion: 0.02
Nodes (203): _, actualTableName, _alias, aliasedName, allDay, _allDayMeta, allSchemaEntities, allTables (+195 more)

### Community 4 - "3. Phân tích từng đối thủ"
Cohesion: 0.08
Nodes (25): 1. Tóm tắt, 2. Bảng so sánh tổng quan, 3. Phân tích từng đối thủ, 4.1 Giá App Store VN (truy cập 24/11/2026), 4.2 Giới hạn free tier (US/global), 4. Benchmark giá & giới hạn free tier, 5. Khoảng trống thị trường & cơ hội khác biệt, 6.1 Tính năng (ưu tiên theo giá trị / chi phí) (+17 more)

### Community 5 - "Kiến trúc hệ thống"
Cohesion: 0.17
Nodes (11): 1. Sơ đồ thành phần, 2. Thành phần và trách nhiệm, 3.1 Tạo nhắc nhở nhanh (offline được), 3.2 Import booking từ ảnh/pdf/xlsx/email (hoàn toàn trên máy), 3.3 Thông báo kêu và hành động, 3. Luồng chính, 4. Đồng bộ (Sync), 5. Yêu cầu phi chức năng (+3 more)

### Community 6 - "Design system"
Cohesion: 0.15
Nodes (12): 10. Bàn giao cho Flutter, 11. Màn hình lớn (tablet, máy tính), 1. Nguyên tắc, 2. Màu (token), 3. Chữ, 4. Khoảng cách, bo góc, đổ bóng, 5. Icon & hình, 6. Component chính (+4 more)

### Community 7 - "Architecture Decision Records (ADR)"
Cohesion: 0.11
Nodes (18): ADR-001: Flutter cho app mobile, native cho watch, ADR-002: Supabase + worker TypeScript, ADR-003: Offline-first, nhắc nhở local, ADR-004: AI extraction phía server (Superseded by ADR-010), ADR-005: Email chuyển tiếp trước, Gmail API sau, ADR-006: RevenueCat cho subscription, ADR-007: Lặp lại RRULE + hệ lịch khác, ADR-008: Entitlement phía server (+10 more)

### Community 8 - "Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình"
Cohesion: 0.10
Nodes (20): 10. Quick Add bằng chữ, 11. Đánh giá chất lượng (eval) không cần thiết bị trong CI, 12. Hiệu năng và kích thước app, 13. Thư viện dự kiến, 14. Rủi ro, 1. Kiến trúc 5 tầng, 2. T0: Decoder định dạng (Dart thuần, `packages/parsers`), 3. T1: OCR trên thiết bị (+12 more)

### Community 9 - "2. Worker `/v1`"
Cohesion: 0.20
Nodes (9): 1. Sync (RPC Postgres, `SECURITY DEFINER`, kiểm `auth.uid()`), 2. Worker `/v1`, 3. Webhook (không dùng JWT, xác thực bằng chữ ký/secret), 4. Mã lỗi & rate limit, API spec, Dữ liệu tĩnh trên CDN (không qua worker), Hộp thư email & bản gốc, Thiết bị & push (+1 more)

### Community 10 - "Kế hoạch triển khai"
Cohesion: 0.09
Nodes (21): Checklist tích hợp theo phase, D. App máy tính (chi tiết, Phase 4), E0. Spike & dữ liệu (Phase 0, ~8d), E1. Decoder T0 (S5, ~7d), `packages/parsers/decoders/`, E2. Plugin OCR native (S5, ~7d), E3. Bộ máy luật T2 (S4-S5, ~10d), `packages/parsers/lib/src/engine/`, E4. Mẫu nhà cung cấp (S4-S6 rồi liên tục), E5. Màn Xem lại & vòng cải thiện (S6, ~7d) (+13 more)

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

### Community 20 - "WORKLOG"
Cohesion: 0.04
Nodes (42): Agency agents (persona chuyên môn), AGENTS.md: RemindMe, Cấu trúc repo (`*` = chưa tạo), Dự án, Lệnh hay dùng, Quy tắc làm việc (bắt buộc), Stack đã chốt (lý do: `docs/architecture/decisions.md`), Trạng thái (+34 more)

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

### Community 27 - "sys"
Cohesion: 0.10
Nodes (6): resolves(), allowed(), argument(), icu(), main(), text()

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

### Community 34 - "Đa nền tảng: điện thoại, tablet, máy tính (macOS, Windows), web"
Cohesion: 0.33
Nodes (5): 1. Lộ trình, 2. Quy tắc code từ S1 (để thêm desktop không phải viết lại), 3. Ma trận năng lực theo nền tảng, 4. Phát hành máy tính, Đa nền tảng: điện thoại, tablet, máy tính (macOS, Windows), web

### Community 35 - "tables.dart"
Cohesion: 0.02
Nodes (92): allDay, archivedReason, at, attempts, bookingType, bytes, calendar, carrierCode (+84 more)

### Community 36 - "sync_protocol.dart"
Cohesion: 0.05
Nodes (40): baseClock, bookingDetails, clampedFields, code, details, edit, endsSession, error (+32 more)

### Community 37 - "services.dart"
Cohesion: 0.04
Nodes (45): actionId, addEvent, alternatives, availableLocales, BarcodeScanner, body, CalendarWriter, cancel (+37 more)

### Community 38 - "entitlements.dart"
Cohesion: 0.06
Nodes (32): cacheTtl, EntitlementKey, featureAltCalendars, featureEnhancedVoice, featureLevel, features, featureWatchApp, fetchedAt (+24 more)

### Community 39 - "sync_engine.dart"
Cohesion: 0.05
Nodes (39): api, _applyResult, _applyServerRow, _bumpAttempts, cachedQuota, clock, clockSkewDetected, _codecs (+31 more)

### Community 40 - "capabilities.dart"
Cohesion: 0.07
Nodes (23): detectPlatform, devicePlatformProvider, platformCapabilitiesProvider, DeviceClass, DevicePlatform, mobileClassFromShortestSide, resolveDeviceClass, tabletShortestSideDp (+15 more)

### Community 41 - "dependencies"
Cohesion: 0.04
Nodes (44): dependencies, archive, cupertino_ui, drift, drift_flutter, file_picker, flutter, flutter_local_notifications (+36 more)

### Community 42 - "DataClass"
Cohesion: 0.14
Nodes (25): BookingDetail, BookingDetailsCompanion, DataClass, Import, ImportsCompanion, Item, ItemsCompanion, ListsCompanion (+17 more)

### Community 43 - "tokens.dart"
Cohesion: 0.07
Nodes (28): background, checkOutline, checkOverdue, danger, divider, fontFallback, fontFamily, health (+20 more)

### Community 44 - "hlc.dart"
Cohesion: 0.11
Nodes (16): compareTo, counter, hashCode, HlcClock, _last, maxCounter, maxDriftMs, millis (+8 more)

### Community 45 - "AppDelegate.swift"
Cohesion: 0.10
Nodes (8): AppDelegate, SceneDelegate, RunnerTests, Flutter, flutter_local_notifications, Testing, UIKit, UserNotifications

### Community 46 - "package:remindme_data/remindme_data.dart"
Cohesion: 0.17
Nodes (8): main, openLists, phone, vi, en, main, phone, NotificationTap

### Community 47 - "pg_contract_test.dart"
Cohesion: 0.13
Nodes (12): call, conn, enabled, env, main, pull, push, quotaStatus (+4 more)

### Community 48 - "mime.dart"
Cohesion: 0.03
Nodes (57): _attached, attachments, b, _base64, body, children, clean, continued (+49 more)

### Community 49 - "app.dart"
Cohesion: 0.13
Nodes (5): appSupportedLocales, createState, locale, pseudoLocale, _router

### Community 50 - "fake_server.dart"
Cohesion: 0.12
Nodes (16): SyncErrorCode, apiFor, apply, checkForeignKeys, device, failWith, _foreignKey, _k (+8 more)

### Community 51 - "data/pubspec.yaml"
Cohesion: 0.12
Nodes (15): dependencies, drift, remindme_core, remindme_platform, description, dev_dependencies, build_runner, drift_dev (+7 more)

### Community 52 - "Table"
Cohesion: 0.26
Nodes (13): BookingDetails, Imports, Items, Lists, OccurrenceLog, Outbox, Recurrences, Reminders (+5 more)

### Community 53 - "app_theme.dart"
Cohesion: 0.14
Nodes (10): buildTheme, copyWith, dark, lerp, of, pick, RemindColors, scheme (+2 more)

### Community 54 - "formatters.dart"
Cohesion: 0.10
Nodes (18): asUtc, civil, _context, date, dayHeader, Fmt, h, _locale (+10 more)

### Community 55 - "package:remindme_core/remindme_core.dart"
Cohesion: 0.12
Nodes (11): main, main, main, days, main, pack, main, main (+3 more)

### Community 56 - "quick_add_sheet.dart"
Cohesion: 0.08
Nodes (23): _canSave, createState, dispose, _Draft, _drafts, fallbackTitle, icon, label (+15 more)

### Community 57 - "reminders.dart"
Cohesion: 0.10
Nodes (18): describeReminderOffset, fallback, forOccurrence, forSnooze, fromSubtags, into, l, labels (+10 more)

### Community 58 - "core/pubspec.yaml"
Cohesion: 0.13
Nodes (14): dependencies, crypto, rrule, timezone, description, dev_dependencies, test, environment (+6 more)

### Community 59 - "platform/pubspec.yaml"
Cohesion: 0.18
Nodes (10): dependencies, remindme_core, description, dev_dependencies, test, environment, sdk, name (+2 more)

### Community 60 - "values.dart"
Cohesion: 0.04
Nodes (53): AirportMention, airports, airportsIn, _amount, _bareCode, carrier, code, confirmationCodeIn (+45 more)

### Community 61 - "analysis_options.yaml"
Cohesion: 0.22
Nodes (8): analyzer, exclude, language, include, strict-casts, strict-raw-types, linter, rules

### Community 62 - "main.dart"
Cohesion: 0.10
Nodes (13): appearance, client, db, deviceId, initialize, launchTap, loadBundledHolidays, local (+5 more)

### Community 63 - "client/analysis_options.yaml"
Cohesion: 0.22
Nodes (8): analyzer, exclude, language, include, strict-casts, strict-raw-types, linter, rules

### Community 64 - "ids.dart"
Cohesion: 0.18
Nodes (8): bytes, digest, _format, hex, inboxListId, ms, _random, uuidV7

### Community 65 - "markdown.dart"
Cohesion: 0.05
Nodes (36): checklist, _date, _dayList, _days, decode, done, doneOn, _Draft (+28 more)

### Community 66 - "pubspec.yaml"
Cohesion: 0.25
Nodes (7): dev_dependencies, lints, environment, sdk, name, publish_to, workspace

### Community 67 - "items_repository.dart"
Cohesion: 0.03
Nodes (71): addReminder, addReminderAt, allDay, completedAt, completeOccurrence, countsByDay, create, _db (+63 more)

### Community 79 - "pack.dart"
Cohesion: 0.04
Nodes (42): conjunctions, contains, dateOrderByRegion, dateOrderDefault, dateOrderFor, DayPart, dayParts, defaultTime (+34 more)

### Community 80 - "engine.dart"
Cohesion: 0.05
Nodes (33): _apply, byDay, byMonthDay, characters0, datePack, explicit24, _Facts, _firstOccurrence (+25 more)

### Community 81 - "result.dart"
Cohesion: 0.06
Nodes (30): ambiguities, Ambiguity, AmbiguityKind, calendar, chosen, end, hashCode, kind (+22 more)

### Community 82 - "providers.dart"
Cohesion: 0.04
Nodes (44): Appearance, AppearanceSettings, appLanguagePref, build, bundledHolidayRegions, bundledNluPacks, byDate, c (+36 more)

### Community 83 - "lunar.dart"
Cohesion: 0.07
Nodes (29): _dateFromJd, day, fromSolar, fromWire, hashCode, _jdFromDate, leap, _leapMonthOffset (+21 more)

### Community 84 - "today_screen.dart"
Cohesion: 0.12
Nodes (13): _byday, describeRecurrence, l, locale, n, parts, done, _ProgressCard (+5 more)

### Community 85 - "with"
Cohesion: 0.07
Nodes (37): runs-on, steps, runs-on, steps, runs-on, steps, PGHOST, PGPASSWORD (+29 more)

### Community 86 - "recurrence.dart"
Cohesion: 0.07
Nodes (26): LunarSystem, AfterCompletion, between, both, day, fromRow, _fromRow, fromWire (+18 more)

### Community 87 - "_"
Cohesion: 0.08
Nodes (25): _, addDays, addMonths, compareTo, date, day, daysSince, hashCode (+17 more)

### Community 88 - "months"
Cohesion: 0.08
Nodes (25): months, apr, april, aug, august, dec, december, feb (+17 more)

### Community 89 - "weekdays"
Cohesion: 0.09
Nodes (23): weekdays, chúa nhật, chủ nhật, cn, cuối tuần, t2, t3, t4 (+15 more)

### Community 90 - "table.dart"
Cohesion: 0.06
Nodes (33): base, boolean, _builtinDateFormats, cell, _cell, columnCount, _columnIndex, CsvReader (+25 more)

### Community 91 - "day_parts"
Cohesion: 0.10
Nodes (20): default, range, default, range, day_parts, afternoon, arvo, evening (+12 more)

### Community 92 - "numbers"
Cohesion: 0.10
Nodes (20): numbers, ba, ba mươi, bảy, bẩy, bốn, bốn lăm, bốn mươi lăm (+12 more)

### Community 93 - "numbers"
Cohesion: 0.11
Nodes (19): numbers, eight, eleven, fifteen, five, forty-five, four, nine (+11 more)

### Community 94 - "day_parts"
Cohesion: 0.11
Nodes (19): default, range, day_parts, chiều, khuya, sáng, trưa, tối (+11 more)

### Community 95 - "units"
Cohesion: 0.11
Nodes (18): units, day, days, fortnight, hour, hours, hr, hrs (+10 more)

### Community 96 - "extract/eval.dart"
Cohesion: 0.11
Nodes (16): docs, exp, ExtractEvalReport, failures, _flatten, optionalAccuracy, optionalCorrect, optionalTotal (+8 more)

### Community 97 - "weekdays"
Cohesion: 0.12
Nodes (17): weekdays, fri, friday, mon, monday, saturday, sunday, thu (+9 more)

### Community 98 - "regions"
Cohesion: 0.12
Nodes (16): date_order, default, regions, AU, CA, FM, GB, IE (+8 more)

### Community 99 - "helpers.dart"
Cohesion: 0.14
Nodes (10): container, db, pump, pumpAndSettle, pumpApp, pumpWidget, settleReminders, testNow (+2 more)

### Community 100 - "en.yaml"
Cohesion: 0.10
Nodes (19): conjunctions, filler_tails, fillers, lang, list_separators, meridiem, a.m., am (+11 more)

### Community 101 - "package:remindme_parsers/remindme_parsers.dart"
Cohesion: 0.07
Nodes (24): sessionPlatform, airports, en, main, ref, run, vi, en (+16 more)

### Community 102 - "parsers/pubspec.yaml"
Cohesion: 0.12
Nodes (15): dependencies, archive, remindme_core, xml, yaml, description, dev_dependencies, test (+7 more)

### Community 103 - "vi.yaml"
Cohesion: 0.07
Nodes (26): conjunctions, date_order, default, dates, re, type, filler_tails, fillers (+18 more)

### Community 104 - "recurrence"
Cohesion: 0.22
Nodes (10): recurrence, re, type, value, times, re, type, value (+2 more)

### Community 105 - "relative_days"
Cohesion: 0.22
Nodes (9): relative_days, bữa nay, hôm nay, mai, mai ni, mốt, ngày kia, ngày mai (+1 more)

### Community 106 - "units"
Cohesion: 0.25
Nodes (8): units, giờ, ngày, năm, phút, tháng, tiếng, tuần

### Community 107 - "relative_days"
Cohesion: 0.29
Nodes (7): relative_days, day after tomorrow, the day after tomorrow, tmr, tmrw, today, tomorrow

### Community 108 - "weekday_list_tokens"
Cohesion: 0.29
Nodes (7): weekday_list_tokens, 2, 3, 4, 5, 6, 7

### Community 109 - "table_tasks.dart"
Cohesion: 0.05
Nodes (32): columns, copyWith, dateOrder, dateOrderAmbiguous, detect, _done, extract, _foldHeader (+24 more)

### Community 110 - "CivilDate"
Cohesion: 0.33
Nodes (5): CivilDate, CivilDateTime, CivilTime, Hlc, When

### Community 111 - "row_codec.dart"
Cohesion: 0.15
Nodes (9): ColumnKind, columns, dataColumns, keyColumns, metaColumns, name, RowCodec, table (+1 more)

### Community 112 - "Gói ngữ pháp NLU (`<lang>.yaml`)"
Cohesion: 0.40
Nodes (4): Gói ngữ pháp NLU (`<lang>.yaml`), Mơ hồ thì hỏi, Mẫu, Từ vựng

### Community 114 - "imports_repository.dart"
Cohesion: 0.04
Nodes (54): absoluteReminders, booking, bytes, commit, createdListIds, _db, destination, docLanguage (+46 more)

### Community 115 - "recurrence"
Cohesion: 0.50
Nodes (4): recurrence, re, type, value

### Community 116 - "planner.dart"
Cohesion: 0.03
Nodes (56): allDay, allDayTime, at, base, body, contentHash, date, deviceTz (+48 more)

### Community 117 - "import_decode.dart"
Cohesion: 0.05
Nodes (41): airports, airportsTsv, bytes, candidates, copyWith, ctx, dateOrder, dateOrderAmbiguous (+33 more)

### Community 118 - "import_mapper.dart"
Cohesion: 0.05
Nodes (42): absolute, asUtc, BookingMatch, bookingRow, code, date, duplicate, end (+34 more)

### Community 119 - "text_prompt.dart"
Cohesion: 0.11
Nodes (15): askText, build, _controller, createState, dispose, fieldKey, hint, initial (+7 more)

### Community 120 - "trips_repository.dart"
Cohesion: 0.05
Nodes (36): activeCount, activeOn, bookingsWithCodes, bookingType, carrierCode, confirmationCode, create, _db (+28 more)

### Community 121 - "local_notifications.dart"
Cohesion: 0.07
Nodes (23): _android, _apple, cancel, cancelAll, _category, _channelAlarm, channelAlarms, _channelDefault (+15 more)

### Community 122 - "candidate_editor.dart"
Cohesion: 0.04
Nodes (43): _box, build, c, candidate, checkedKeys, _checkIcon, createState, _decoration (+35 more)

### Community 123 - "template.dart"
Cohesion: 0.04
Nodes (40): airports, anchors, anyText, below, candidates, dateOrder, docType, extract (+32 more)

### Community 124 - "reminder_binding.dart"
Cohesion: 0.11
Nodes (14): _askedKey, build, child, createState, _dbSub, didChangeAppLifecycleState, dispose, _formatKey (+6 more)

### Community 125 - "scheduler.dart"
Cohesion: 0.09
Nodes (20): ReminderPlanner, cancelAll, cancelled, db, _exdates, horizonEnd, locale, os (+12 more)

### Community 126 - "candidate.dart"
Cohesion: 0.04
Nodes (55): amount, CandidateFields, CandidateKind, carriage, carrierCode, checkIn, checklist, ChecklistEntry (+47 more)

### Community 127 - "package:drift/drift.dart"
Cohesion: 0.06
Nodes (32): live, main, AppDatabase, ImportsRepository, ItemsRepository, ListsRepository, TripsRepository, allItems (+24 more)

### Community 128 - "actions.dart"
Cohesion: 0.13
Nodes (12): done, handle, itemId, NotificationActionHandler, NotificationActionIds, NotificationPayload, occurrenceAt, reminderId (+4 more)

### Community 129 - "testing.dart"
Cohesion: 0.15
Nodes (11): NotificationHealth, cancel, cancelAll, health, healthValue, maxPending, openExactAlarmSettings, pending (+3 more)

### Community 130 - "email.dart"
Cohesion: 0.06
Nodes (26): bytes, candidates, decode, _decode, dedupeCandidates, EmailDecoder, EmailExtraction, fa (+18 more)

### Community 131 - "slots.dart"
Cohesion: 0.04
Nodes (52): _addDay, address, airports, anchored, _appointment, arrivalDate, arrivalNextDay, arrivalTime (+44 more)

### Community 132 - "itemsRepositoryProvider"
Cohesion: 0.16
Nodes (13): holidayRegionProvider, itemsRepositoryProvider, nluEngineProvider, recurrenceProvider, _onTap, initState, _toggle, build (+5 more)

### Community 134 - "schedule_editor.dart"
Cohesion: 0.11
Nodes (13): _check, inset, item, overdue, between, _byday, days, item (+5 more)

### Community 135 - "lists_repository.dart"
Cohesion: 0.11
Nodes (15): create, _db, delete, engine, id, isInbox, _items, _lists (+7 more)

### Community 136 - "jsonld.dart"
Cohesion: 0.13
Nodes (13): _address, _countPeople, decodeHtml, decodeJson, JsonLdDecoder, _map, _nodes, _price (+5 more)

### Community 137 - "ics.dart"
Cohesion: 0.09
Nodes (19): BcbpDecoder, _dateFromJulian, decode, _flightNumber, looksLikeBcbp, _seat, _alarmMinutes, decode (+11 more)

### Community 138 - "listsProvider"
Cohesion: 0.21
Nodes (12): listItemsProvider, listsProvider, listsRepositoryProvider, recurringIdsProvider, todayWindowProvider, _badges, build, ItemTile (+4 more)

### Community 139 - "package:remindme_data/remindme_data.dart"
Cohesion: 0.11
Nodes (14): AppNotificationTexts, create, en, main, phone, seedDay, today, NotificationTexts (+6 more)

### Community 140 - "import_logic_test.dart"
Cohesion: 0.17
Nodes (7): airportsTsv, code, docs, labels, main, packs, req

### Community 141 - "priority"
Cohesion: 0.17
Nodes (12): assignee, date, list, location, notes, priority, status, time (+4 more)

### Community 142 - "import_screen.dart"
Cohesion: 0.06
Nodes (30): ImportRequest, _activeTrips, _banner, build, _busy, _canCreateTrip, _candidate, _checkTile (+22 more)

### Community 143 - "me_screen.dart"
Cohesion: 0.12
Nodes (13): boxed, _Choice, dividers, _Group, hint, icon, onChanged, radius (+5 more)

### Community 144 - "columns"
Cohesion: 0.09
Nodes (22): assignee, date, list, location, notes, priority, status, time (+14 more)

### Community 145 - "trips.dart"
Cohesion: 0.08
Nodes (22): beforeEndMinutes, confident, copyWith, dayBeforeAt, _daysBetween, DefaultReminders, destination, endsOn (+14 more)

### Community 146 - "tz.dart"
Cohesion: 0.12
Nodes (12): dayBounds, dstAdjusted, ensureInitialized, isValid, _loc, _offsetMs, _ready, ResolvedInstant (+4 more)

### Community 147 - "priority"
Cohesion: 0.18
Nodes (11): bình thường, cao, gấp, khẩn, khẩn cấp, quan trọng, rất cao, thấp (+3 more)

### Community 148 - "extract_eval_test.dart"
Cohesion: 0.14
Nodes (12): airports, engine, ext, extract, lang, main, packs, reference (+4 more)

### Community 149 - "package:remindme_data/remindme_data.dart"
Cohesion: 0.10
Nodes (18): find, resolveLocale, sup, inDay, main, cal, main, _pack (+10 more)

### Community 150 - "remote_sync.dart"
Cohesion: 0.06
Nodes (25): _claimedSession, claims, client, _current, deviceId, DeviceProfile, dispose, engine (+17 more)

### Community 151 - "html_text.dart"
Cohesion: 0.29
Nodes (6): decodeHtmlEntities, htmlToText, lines, _named, s, where

### Community 152 - "Việc nhà tháng 12"
Cohesion: 0.50
Nodes (3): Sửa chữa, Việc nhà tháng 12, Định kỳ

### Community 153 - "nlu/eval.dart"
Cohesion: 0.12
Nodes (13): accuracy, byDialect, _canon, correct, dangerous, dangerousRate, data, evaluateNlu (+5 more)

### Community 154 - "import_test.dart"
Cohesion: 0.11
Nodes (11): appIcon, docs, fixture, i, main, openImport, phone, pumpAndSettle (+3 more)

### Community 155 - "document.dart"
Cohesion: 0.05
Nodes (39): AnchorHit, approximateMatches, ApproxMatch, below, bottom, box, end, errors (+31 more)

### Community 156 - "dart:convert"
Cohesion: 0.07
Nodes (24): _barcodeMessage, decodePassJson, decodeZip, _Field, group, key, label, PkpassDecoder (+16 more)

### Community 157 - "holidays.dart"
Cohesion: 0.04
Nodes (46): a, between, _cache, cal, clear, _compute, d, date (+38 more)

### Community 158 - "calendar_screen.dart"
Cohesion: 0.06
Nodes (27): count, createState, date, _go, holidays, inMonth, inTrip, isSelected (+19 more)

### Community 159 - "generic.dart"
Cohesion: 0.04
Nodes (43): airports, _anchoredDate, AnchorReader, anchorsFor, assembler, _capitalizedAround, _carriage, Classification (+35 more)

### Community 160 - "flight"
Cohesion: 0.12
Nodes (17): flight, airline, airport, arrival, baggage, boarding pass, boarding time, departure (+9 more)

### Community 161 - "sync_engine_test.dart"
Cohesion: 0.17
Nodes (11): SyncEngine, FakeServer, db, Device, engine, main, name, now (+3 more)

### Community 162 - "vocabulary.dart"
Cohesion: 0.12
Nodes (14): anchors, classify, codeStopwords, DocType, DocVocabulary, facilityWords, fromMap, isEmpty (+6 more)

### Community 163 - "trips_screen.dart"
Cohesion: 0.06
Nodes (34): _Chip, _DayCell, _DraftChips, _InputMethod, _Pill, active, _AddBookingCard, checkOut (+26 more)

### Community 164 - "quick_add_test.dart"
Cohesion: 0.12
Nodes (9): main, enterText, main, openQuickAdd, phone, pumpAndSettle, rows, runAsync (+1 more)

### Community 165 - "item_detail_screen.dart"
Cohesion: 0.07
Nodes (20): createState, _delete, didUpdateWidget, dispose, id, item, _notes, _notesBaseClock (+12 more)

### Community 166 - "flight"
Cohesion: 0.13
Nodes (15): flight, chuyến bay, cất cánh, cửa ra máy bay, giờ lên máy bay, hành khách, hành lý, hãng hàng không (+7 more)

### Community 167 - "airports.dart"
Cohesion: 0.11
Nodes (15): b, _fold, foldForSearch, groups, toString, Airport, AirportIndex, _byCode (+7 more)

### Community 168 - "anchors"
Cohesion: 0.05
Nodes (43): address, appointment_date, appointment_time, arrival_time, carriage, check_in, check_out, class (+35 more)

### Community 169 - "anchors"
Cohesion: 0.07
Nodes (30): address, appointment_date, appointment_time, arrival_time, carriage, check_in, check_out, class (+22 more)

### Community 170 - "hotel"
Cohesion: 0.18
Nodes (11): hotel, accommodation, check-in, check-out, guests, hotel, nights, property (+3 more)

### Community 171 - "medical"
Cohesion: 0.18
Nodes (11): medical, bác sĩ, bệnh nhân, bệnh viện, chuyên khoa, lịch khám, nhịn ăn, phiếu hẹn (+3 more)

### Community 172 - "event"
Cohesion: 0.15
Nodes (13): event, admission, cinema, concert, doors open, event, movie, row (+5 more)

### Community 173 - "hotel"
Cohesion: 0.20
Nodes (10): hotel, homestay, khách sạn, loại phòng, nhận phòng, resort, số phòng, số đêm (+2 more)

### Community 174 - "train"
Cohesion: 0.20
Nodes (10): train, ga đi, ga đến, ghế ngồi mềm, giường nằm, khoang, toa, tàu hỏa (+2 more)

### Community 175 - "bus"
Cohesion: 0.22
Nodes (9): biển số xe, bến xe, limousine, nhà xe, xe giường nằm, xe khách, điểm trả, điểm đón (+1 more)

### Community 176 - "classify"
Cohesion: 0.18
Nodes (11): document, classify, facility_words, passenger_units, preparation_words, segments, travel_classes, hạng nhất (+3 more)

### Community 177 - "train"
Cohesion: 0.20
Nodes (10): train, arrival station, carriage, coach, departure station, platform, rail, railway (+2 more)

### Community 178 - "event"
Cohesion: 0.25
Nodes (8): event, buổi biểu diễn, cổng vào, khu vực, rạp, suất chiếu, sự kiện, vé xem

### Community 179 - "medical"
Cohesion: 0.22
Nodes (9): medical, appointment, clinic, date of birth, dental, doctor, hospital, patient (+1 more)

### Community 180 - "app_icons.dart"
Cohesion: 0.14
Nodes (9): AppIcon, asset, build, color, directional, flag, icon, semanticLabel (+1 more)

### Community 181 - "SyncApi"
Cohesion: 0.40
Nodes (5): OfflineSyncApi, SupabaseSyncApi, SyncApi, FakeApi, PgSyncApi

### Community 182 - "bus"
Cohesion: 0.29
Nodes (7): boarding point, bus, bus station, drop-off point, pickup point, bus, classify

### Community 183 - "adaptive_shell.dart"
Cohesion: 0.09
Nodes (17): AppIcons, build, ChoiceButtons, keyPrefix, onChanged, _option, unselectedColor, value (+9 more)

### Community 185 - "static const"
Cohesion: 0.25
Nodes (6): expanded, expandedMin, fromWidth, mediumMin, of, WindowSize

### Community 187 - "deviceTimeZoneProvider"
Cohesion: 0.10
Nodes (20): build, RemindMeApp, _RemindMeAppState, appearanceProvider, deviceTimeZoneProvider, holidayHintProvider, importsRepositoryProvider, localPrefsProvider (+12 more)

### Community 188 - "package:material_ui/material_ui.dart"
Cohesion: 0.33
Nodes (4): deviceRegion, deviceTimeZone, etcZoneFor, h

### Community 189 - "NotificationScheduler"
Cohesion: 0.50
Nodes (4): LocalNotificationScheduler, NoopNotificationScheduler, NotificationScheduler, InMemoryNotificationScheduler

### Community 190 - "_ReminderBindingState"
Cohesion: 0.15
Nodes (17): appDatabaseProvider, launchNotificationTapProvider, notificationTapsProvider, remoteSyncProvider, initState, ReminderBinding, _ReminderBindingState, initState (+9 more)

### Community 191 - "remote_sync_binding.dart"
Cohesion: 0.11
Nodes (13): build, child, createState, debounce, didChangeAppLifecycleState, dispose, _now, _outboxSub (+5 more)

### Community 192 - "language_region_screen.dart"
Cohesion: 0.11
Nodes (9): PickedFile, calendar, calendarLabel, effectiveRegion, icon, onTap, regionLabel, _SettingRow (+1 more)

### Community 193 - "meridiem"
Cohesion: 0.67
Nodes (3): meridiem, am, pm

### Community 195 - "ConsumerWidget"
Cohesion: 0.17
Nodes (15): cachedQuotaProvider, itemProvider, remindersProvider, tripSegmentsProvider, tripsProvider, tripsRepositoryProvider, build, ItemDetailScreen (+7 more)

### Community 196 - "nowProvider"
Cohesion: 0.20
Nodes (15): airportsTsvProvider, deviceRegionProvider, nluPackSourcesProvider, nowProvider, syncEngineProvider, filePickerProvider, importDecoderProvider, _decode (+7 more)

### Community 197 - "calendarSystemSettingProvider"
Cohesion: 0.20
Nodes (14): bookingInfoProvider, bundledHolidayCalendarsProvider, calendarCountsProvider, calendarSystemSettingProvider, daySectionsProvider, holidayCalendarProvider, holidayRegionSettingProvider, build (+6 more)

### Community 199 - "database.dart"
Cohesion: 0.33
Nodes (4): addToSet, _db, getSet, LocalPrefs

### Community 203 - "adaptive_shell.dart"
Cohesion: 0.17
Nodes (8): AdaptiveShell, addTooltip, _BottomBar, build, navigation, onAdd, onSelect, selected

### Community 204 - "build"
Cohesion: 0.24
Nodes (9): hasRemindersProvider, notificationHealthProvider, notificationSchedulerProvider, todaySectionsProvider, didChangeDependencies, _run, build, _ReminderHealthCard (+1 more)

### Community 205 - "supabase_sync_api_test.dart"
Cohesion: 0.22
Nodes (3): client, json, main

### Community 206 - "../../core/theme/tokens.dart"
Cohesion: 0.25
Nodes (5): body, build, EmptyState, icon, title

### Community 207 - "static const"
Cohesion: 0.29
Nodes (4): isConfigured, publishableKey, SupabaseConfig, url

### Community 208 - "Backend Supabase: cấu hình và chạy app với server"
Cohesion: 0.29
Nodes (6): 1. Project, 2. Migrations, 3. Auth, 4. Build app có server, 5. Test với server thật, Backend Supabase: cấu hình và chạy app với server

### Community 209 - "dates"
Cohesion: 0.50
Nodes (4): dates, re, type, value

## Knowledge Gaps
- **2143 isolated node(s):** `pseudoLocale`, `locale`, `_router`, `appSupportedLocales`, `createState` (+2138 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 3303 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **28 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CivilDate` connect `CivilDate` to `markdown.dart`, `providers.dart`, `lunar.dart`, `planner.dart`, `_`, `quick_add_sheet.dart`, `candidate_editor.dart`, `holidays.dart`, `calendar_screen.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `pseudoLocale`, `locale`, `_router` to the rest of the system?**
  _2143 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UX: kiến trúc thông tin, luồng, màn hình` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Why does `AppDatabase` connect `package:drift/drift.dart` to `sync_engine_test.dart`, `database.dart`, `sync_engine.dart`, `database.dart`, `providers.dart`, `scheduler.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Should `Hướng dẫn tích hợp với nền tảng khác` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `4. User stories và tiêu chí chấp nhận (MVP = P0)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017915590008613265 - nodes in this community are weakly interconnected._