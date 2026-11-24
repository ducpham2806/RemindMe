# Graph Report - RemindMe  (2026-11-24)

## Corpus Check
- 175 files · ~145,811 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 36 file(s) not represented in the graph (top: (none) 7, .xml 7, .plist 4)

## Summary
- 2466 nodes · 3173 edges · 150 communities (128 shown, 22 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f0377949`
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
- STATE (hiện trạng, cập nhật cuối mỗi phiên; chỉ giữ hiện tại, lịch sử ở WORKLOG)
- Quy trình phát triển với AI (Claude Code, Codex) + graphify, unslop, agency agents
- Nhập bằng giọng nói và câu tự nhiên (đa ngôn ngữ, đa vùng miền)
- RemindMe English style guide (source language)
- Kiểm thử, CI/CD và phát hành
- Analytics & telemetry: danh mục sự kiện và consent
- Hướng dẫn văn phong tiếng Việt cho RemindMe
- pseudo-arb.py
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
- AppDelegate
- app.dart
- pg_contract_test.dart
- sync_engine_test.dart
- package:material_ui/material_ui.dart
- fake_server.dart
- data/pubspec.yaml
- Table
- app_theme.dart
- row_codec.dart
- package:remindme_core/remindme_core.dart
- quick_add_sheet.dart
- ids.dart
- core/pubspec.yaml
- platform/pubspec.yaml
- quick_add_test.dart
- analysis_options.yaml
- main.dart
- client/analysis_options.yaml
- window_size.dart
- adaptive_shell.dart
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
- item_detail_screen.dart
- with
- recurrence.dart
- _
- months
- weekdays
- formatters.dart
- day_parts
- numbers
- numbers
- day_parts
- units
- eval.dart
- weekdays
- regions
- helpers.dart
- en.yaml
- nlu_test.dart
- parsers/pubspec.yaml
- vi.yaml
- recurrence
- relative_days
- units
- relative_days
- weekday_list_tokens
- device_time.dart
- Comparable
- meridiem
- Gói ngữ pháp NLU (`<lang>.yaml`)
- dates
- recurrence
- planner.dart
- meridiem
- months
- next_modifiers
- parts
- local_notifications.dart
- String?
- reminders.dart
- reminder_binding.dart
- scheduler.dart
- tz.dart
- scheduler_test.dart
- actions.dart
- testing.dart
- package:remindme_data/remindme_data.dart
- SyncApi
- NotificationScheduler
- SyncException
- schedule_editor.dart
- lists_repository.dart
- itemsRepositoryProvider
- package:remindme_data/remindme_data.dart
- search_screen.dart
- lists_screen.dart
- nowProvider
- ConsumerState
- reminders_test.dart
- today_test.dart
- build
- schedule_editor_test.dart
- app_test.dart
- Map
- _ReminderBindingState
- NotificationTexts

## God Nodes (most connected - your core abstractions)
1. `_` - 31 edges
2. `months` - 25 edges
3. `weekdays` - 23 edges
4. `numbers` - 20 edges
5. `numbers` - 19 edges
6. `units` - 18 edges
7. `dependencies` - 17 edges
8. `weekdays` - 17 edges
9. `itemsRepositoryProvider` - 16 edges
10. `Hướng dẫn tích hợp với nền tảng khác` - 15 edges

## Surprising Connections (you probably didn't know these)
- `OfflineSyncApi` --implements--> `SyncApi`  [EXTRACTED]
  apps/client/lib/data/providers.dart → packages/core/lib/src/sync_protocol.dart
- `LocalNotificationScheduler` --implements--> `NotificationScheduler`  [EXTRACTED]
  apps/client/lib/platform/local_notifications.dart → packages/platform/lib/src/services.dart
- `NoopNotificationScheduler` --implements--> `NotificationScheduler`  [EXTRACTED]
  apps/client/lib/platform/local_notifications.dart → packages/platform/lib/src/services.dart
- `AppNotificationTexts` --implements--> `NotificationTexts`  [EXTRACTED]
  apps/client/lib/data/reminders.dart → packages/data/lib/src/reminders/planner.dart
- `_run` --references--> `appDatabaseProvider`  [EXTRACTED]
  apps/client/lib/data/reminder_binding.dart → apps/client/lib/data/providers.dart

## Import Cycles
- None detected.

## Communities (150 total, 22 thin omitted)

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
Cohesion: 0.12
Nodes (15): ADR-001: Flutter cho app mobile, native cho watch, ADR-002: Supabase + worker TypeScript, ADR-003: Offline-first, nhắc nhở local, ADR-004: AI extraction phía server (Superseded by ADR-010), ADR-005: Email chuyển tiếp trước, Gmail API sau, ADR-006: RevenueCat cho subscription, ADR-007: Lặp lại RRULE + hệ lịch khác, ADR-008: Entitlement phía server (+7 more)

### Community 8 - "Trích xuất trên thiết bị: ảnh, pdf, xlsx, md, email, giọng nói → todo / lịch trình"
Cohesion: 0.10
Nodes (20): 10. Quick Add bằng chữ, 11. Đánh giá chất lượng (eval) không cần thiết bị trong CI, 12. Hiệu năng và kích thước app, 13. Thư viện dự kiến, 14. Rủi ro, 1. Kiến trúc 5 tầng, 2. T0: Decoder định dạng (Dart thuần, `packages/parsers`), 3. T1: OCR trên thiết bị (+12 more)

### Community 9 - "2. Worker `/v1`"
Cohesion: 0.20
Nodes (9): 1. Sync (RPC Postgres, `SECURITY DEFINER`, kiểm `auth.uid()`), 2. Worker `/v1`, 3. Webhook (không dùng JWT, xác thực bằng chữ ký/secret), 4. Mã lỗi & rate limit, API spec, Dữ liệu tĩnh trên CDN (không qua worker), Hộp thư email & bản gốc, Thiết bị & push (+1 more)

### Community 10 - "Kế hoạch triển khai"
Cohesion: 0.09
Nodes (21): Checklist tích hợp theo phase, D. App máy tính (chi tiết, Phase 4), E0. Spike & dữ liệu (Phase 0, ~8d), E1. Decoder T0 (S5, ~7d), `packages/parsers/decoders/`, E2. Plugin OCR native (S5, ~7d), E3. Bộ máy luật T2 (S4-S5, ~10d), `packages/parsers/engine/`, E4. Mẫu nhà cung cấp (S4-S6 rồi liên tục), E5. Màn Xem lại & vòng cải thiện (S6, ~7d) (+13 more)

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
Cohesion: 0.06
Nodes (30): Agency agents (persona chuyên môn), AGENTS.md: RemindMe, Cấu trúc repo (`*` = chưa tạo), Dự án, Lệnh hay dùng, Quy tắc làm việc (bắt buộc), Stack đã chốt (lý do: `docs/architecture/decisions.md`), Trạng thái (+22 more)

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

### Community 27 - "pseudo-arb.py"
Cohesion: 0.12
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
Nodes (39): baseClock, bookingDetails, clampedFields, code, details, edit, endsSession, error (+31 more)

### Community 37 - "services.dart"
Cohesion: 0.04
Nodes (45): actionId, addEvent, alternatives, availableLocales, BarcodeScanner, body, CalendarWriter, cancel (+37 more)

### Community 38 - "entitlements.dart"
Cohesion: 0.06
Nodes (32): cacheTtl, EntitlementKey, featureAltCalendars, featureEnhancedVoice, featureLevel, features, featureWatchApp, fetchedAt (+24 more)

### Community 39 - "sync_engine.dart"
Cohesion: 0.06
Nodes (30): api, _applyResult, _applyServerRow, _bumpAttempts, clock, clockSkewDetected, _codecs, db (+22 more)

### Community 40 - "capabilities.dart"
Cohesion: 0.09
Nodes (19): DeviceClass, DevicePlatform, mobileClassFromShortestSide, resolveDeviceClass, tabletShortestSideDp, canPurchaseInApp, canScheduleLocalNotifications, canWriteDeviceCalendar (+11 more)

### Community 41 - "dependencies"
Cohesion: 0.06
Nodes (33): dependencies, cupertino_ui, drift, drift_flutter, flutter, flutter_local_notifications, flutter_localizations, flutter_riverpod (+25 more)

### Community 42 - "DataClass"
Cohesion: 0.14
Nodes (25): BookingDetail, BookingDetailsCompanion, DataClass, Import, ImportsCompanion, Item, ItemsCompanion, ListsCompanion (+17 more)

### Community 43 - "tokens.dart"
Cohesion: 0.10
Nodes (20): background, danger, divider, fontFallback, fontFamily, health, lunar, minLineHeight (+12 more)

### Community 44 - "hlc.dart"
Cohesion: 0.11
Nodes (16): compareTo, counter, hashCode, HlcClock, _last, maxCounter, maxDriftMs, millis (+8 more)

### Community 45 - "AppDelegate"
Cohesion: 0.10
Nodes (8): AppDelegate, SceneDelegate, RunnerTests, Flutter, flutter_local_notifications, Testing, UIKit, UserNotifications

### Community 46 - "app.dart"
Cohesion: 0.10
Nodes (10): appSupportedLocales, build, createState, locale, pseudoLocale, _router, detectPlatform, devicePlatformProvider (+2 more)

### Community 47 - "pg_contract_test.dart"
Cohesion: 0.14
Nodes (11): call, conn, enabled, env, main, pull, push, row (+3 more)

### Community 48 - "sync_engine_test.dart"
Cohesion: 0.18
Nodes (10): SyncEngine, db, Device, engine, main, name, now, row (+2 more)

### Community 49 - "package:material_ui/material_ui.dart"
Cohesion: 0.12
Nodes (9): CalendarScreen, EmptyState, build, MeScreen, _DraftChips, _SectionList, AdaptiveShell, build (+1 more)

### Community 50 - "fake_server.dart"
Cohesion: 0.14
Nodes (13): SyncErrorCode, apiFor, apply, device, failWith, FakeServer, _k, pull (+5 more)

### Community 51 - "data/pubspec.yaml"
Cohesion: 0.12
Nodes (15): dependencies, drift, remindme_core, remindme_platform, description, dev_dependencies, build_runner, drift_dev (+7 more)

### Community 52 - "Table"
Cohesion: 0.26
Nodes (13): BookingDetails, Imports, Items, Lists, OccurrenceLog, Outbox, Recurrences, Reminders (+5 more)

### Community 53 - "app_theme.dart"
Cohesion: 0.14
Nodes (10): buildTheme, copyWith, dark, lerp, of, pick, RemindColors, scheme (+2 more)

### Community 54 - "row_codec.dart"
Cohesion: 0.17
Nodes (9): ColumnKind, columns, dataColumns, keyColumns, metaColumns, name, RowCodec, table (+1 more)

### Community 55 - "package:remindme_core/remindme_core.dart"
Cohesion: 0.14
Nodes (10): main, main, main, main, d, main, main, main (+2 more)

### Community 56 - "quick_add_sheet.dart"
Cohesion: 0.12
Nodes (15): _canSave, createState, dispose, _Draft, _drafts, fallbackTitle, picks, result (+7 more)

### Community 57 - "ids.dart"
Cohesion: 0.17
Nodes (8): bytes, digest, _format, hex, inboxListId, ms, _random, uuidV7

### Community 58 - "core/pubspec.yaml"
Cohesion: 0.15
Nodes (12): dependencies, crypto, rrule, timezone, description, dev_dependencies, test, environment (+4 more)

### Community 59 - "platform/pubspec.yaml"
Cohesion: 0.18
Nodes (10): dependencies, remindme_core, description, dev_dependencies, test, environment, sdk, name (+2 more)

### Community 60 - "quick_add_test.dart"
Cohesion: 0.22
Nodes (8): enterText, main, openQuickAdd, phone, pumpAndSettle, rows, runAsync, tap

### Community 61 - "analysis_options.yaml"
Cohesion: 0.22
Nodes (8): analyzer, exclude, language, include, strict-casts, strict-raw-types, linter, rules

### Community 62 - "main.dart"
Cohesion: 0.15
Nodes (8): db, deviceId, launchTap, local, locale, main, os, tz

### Community 63 - "client/analysis_options.yaml"
Cohesion: 0.22
Nodes (8): analyzer, exclude, language, include, strict-casts, strict-raw-types, linter, rules

### Community 64 - "window_size.dart"
Cohesion: 0.22
Nodes (6): expanded, expandedMin, fromWidth, mediumMin, of, WindowSize

### Community 66 - "pubspec.yaml"
Cohesion: 0.25
Nodes (7): dev_dependencies, lints, environment, sdk, name, publish_to, workspace

### Community 67 - "items_repository.dart"
Cohesion: 0.03
Nodes (64): addReminder, allDay, completedAt, completeOccurrence, create, _db, delete, deviceId (+56 more)

### Community 79 - "pack.dart"
Cohesion: 0.05
Nodes (38): conjunctions, contains, dateOrderByRegion, dateOrderDefault, dateOrderFor, DayPart, dayParts, defaultTime (+30 more)

### Community 80 - "engine.dart"
Cohesion: 0.05
Nodes (34): _apply, byDay, byMonthDay, characters0, datePack, explicit24, _Facts, _firstOccurrence (+26 more)

### Community 81 - "result.dart"
Cohesion: 0.06
Nodes (29): ambiguities, Ambiguity, AmbiguityKind, calendar, chosen, end, hashCode, kind (+21 more)

### Community 82 - "providers.dart"
Cohesion: 0.11
Nodes (18): bundledNluPacks, deviceId, deviceIdProvider, inboxRouteId, nluPackKey, now, openAppDatabase, primary (+10 more)

### Community 83 - "lunar.dart"
Cohesion: 0.07
Nodes (29): _dateFromJd, day, fromSolar, fromWire, hashCode, _jdFromDate, leap, _leapMonthOffset (+21 more)

### Community 84 - "item_detail_screen.dart"
Cohesion: 0.12
Nodes (14): createState, _delete, didUpdateWidget, dispose, id, item, _notes, _notesBaseClock (+6 more)

### Community 85 - "with"
Cohesion: 0.07
Nodes (37): runs-on, steps, runs-on, steps, runs-on, steps, PGHOST, PGPASSWORD (+29 more)

### Community 86 - "recurrence.dart"
Cohesion: 0.08
Nodes (19): LunarSystem, AfterCompletion, between, both, day, fromRow, fromWire, intervalDays (+11 more)

### Community 87 - "_"
Cohesion: 0.08
Nodes (25): _, addDays, addMonths, compareTo, date, day, daysSince, hashCode (+17 more)

### Community 88 - "months"
Cohesion: 0.08
Nodes (25): months, apr, april, aug, august, dec, december, feb (+17 more)

### Community 89 - "weekdays"
Cohesion: 0.09
Nodes (23): weekdays, chúa nhật, chủ nhật, cn, cuối tuần, t2, t3, t4 (+15 more)

### Community 90 - "formatters.dart"
Cohesion: 0.10
Nodes (15): civil, _context, date, dayHeader, Fmt, _locale, of, time (+7 more)

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

### Community 96 - "eval.dart"
Cohesion: 0.12
Nodes (13): accuracy, byDialect, _canon, correct, dangerous, dangerousRate, data, evaluateNlu (+5 more)

### Community 97 - "weekdays"
Cohesion: 0.12
Nodes (17): weekdays, fri, friday, mon, monday, saturday, sunday, thu (+9 more)

### Community 98 - "regions"
Cohesion: 0.12
Nodes (16): date_order, default, regions, AU, CA, FM, GB, IE (+8 more)

### Community 99 - "helpers.dart"
Cohesion: 0.18
Nodes (9): container, db, pump, pumpAndSettle, pumpApp, pumpWidget, settleReminders, testNow (+1 more)

### Community 100 - "en.yaml"
Cohesion: 0.13
Nodes (14): conjunctions, filler_tails, fillers, lang, list_separators, next_modifiers, next, next week (+6 more)

### Community 101 - "nlu_test.dart"
Cohesion: 0.16
Nodes (9): ctx, en, main, p, pack, vi, engine, langs (+1 more)

### Community 102 - "parsers/pubspec.yaml"
Cohesion: 0.14
Nodes (13): dependencies, remindme_core, yaml, description, dev_dependencies, test, environment, sdk (+5 more)

### Community 103 - "vi.yaml"
Cohesion: 0.11
Nodes (17): conjunctions, date_order, default, dates, re, type, filler_tails, fillers (+9 more)

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

### Community 109 - "device_time.dart"
Cohesion: 0.18
Nodes (7): find, resolveLocale, sup, deviceRegion, deviceTimeZone, etcZoneFor, h

### Community 110 - "Comparable"
Cohesion: 0.33
Nodes (5): CivilDate, CivilDateTime, CivilTime, Hlc, When

### Community 111 - "meridiem"
Cohesion: 0.40
Nodes (5): meridiem, a.m., am, p.m., pm

### Community 112 - "Gói ngữ pháp NLU (`<lang>.yaml`)"
Cohesion: 0.40
Nodes (4): Gói ngữ pháp NLU (`<lang>.yaml`), Mơ hồ thì hỏi, Mẫu, Từ vựng

### Community 114 - "dates"
Cohesion: 0.50
Nodes (4): dates, re, type, value

### Community 115 - "recurrence"
Cohesion: 0.50
Nodes (4): recurrence, re, type, value

### Community 116 - "planner.dart"
Cohesion: 0.03
Nodes (56): allDay, allDayTime, at, base, body, contentHash, date, deviceTz (+48 more)

### Community 117 - "meridiem"
Cohesion: 0.67
Nodes (3): meridiem, am, pm

### Community 118 - "months"
Cohesion: 0.67
Nodes (3): months, chạp, giêng

### Community 119 - "next_modifiers"
Cohesion: 0.67
Nodes (3): next_modifiers, tuần sau, tuần tới

### Community 120 - "parts"
Cohesion: 0.67
Nodes (3): parts, re, type

### Community 121 - "local_notifications.dart"
Cohesion: 0.06
Nodes (23): _android, _apple, cancel, cancelAll, _category, _channelAlarm, channelAlarms, _channelDefault (+15 more)

### Community 123 - "reminders.dart"
Cohesion: 0.10
Nodes (18): describeReminderOffset, fallback, forOccurrence, forSnooze, fromSubtags, into, l, labels (+10 more)

### Community 124 - "reminder_binding.dart"
Cohesion: 0.10
Nodes (14): _askedKey, build, child, createState, _dbSub, didChangeAppLifecycleState, dispose, _formatKey (+6 more)

### Community 125 - "scheduler.dart"
Cohesion: 0.09
Nodes (21): Recurrence, ReminderPlanner, cancelAll, cancelled, db, _exdates, horizonEnd, locale (+13 more)

### Community 126 - "tz.dart"
Cohesion: 0.12
Nodes (12): dayBounds, dstAdjusted, ensureInitialized, isValid, _loc, _offsetMs, _ready, ResolvedInstant (+4 more)

### Community 127 - "scheduler_test.dart"
Cohesion: 0.10
Nodes (16): AppDatabase, ItemsRepository, ListsRepository, day, item, main, db, items (+8 more)

### Community 128 - "actions.dart"
Cohesion: 0.13
Nodes (12): done, handle, itemId, NotificationActionHandler, NotificationActionIds, NotificationPayload, occurrenceAt, reminderId (+4 more)

### Community 129 - "testing.dart"
Cohesion: 0.15
Nodes (11): NotificationHealth, cancel, cancelAll, health, healthValue, maxPending, openExactAlarmSettings, pending (+3 more)

### Community 130 - "package:remindme_data/remindme_data.dart"
Cohesion: 0.33
Nodes (5): at0, fallback, forOccurrence, forSnooze, main

### Community 131 - "SyncApi"
Cohesion: 0.50
Nodes (4): OfflineSyncApi, SyncApi, FakeApi, PgSyncApi

### Community 132 - "NotificationScheduler"
Cohesion: 0.50
Nodes (4): LocalNotificationScheduler, NoopNotificationScheduler, NotificationScheduler, InMemoryNotificationScheduler

### Community 134 - "schedule_editor.dart"
Cohesion: 0.10
Nodes (16): body, build, icon, title, item, overdue, _byday, item (+8 more)

### Community 135 - "lists_repository.dart"
Cohesion: 0.11
Nodes (15): create, _db, delete, engine, id, isInbox, _items, _lists (+7 more)

### Community 136 - "itemsRepositoryProvider"
Cohesion: 0.16
Nodes (18): itemProvider, itemsRepositoryProvider, listItemsProvider, listsProvider, listsRepositoryProvider, remindersProvider, _onTap, build (+10 more)

### Community 137 - "package:remindme_data/remindme_data.dart"
Cohesion: 0.12
Nodes (7): db, _handle, onNotificationActionInBackground, main, openLists, phone, vi

### Community 138 - "search_screen.dart"
Cohesion: 0.14
Nodes (9): build, build, createState, dispose, _query, _results, _seq, build (+1 more)

### Community 139 - "lists_screen.dart"
Cohesion: 0.14
Nodes (12): askListName, _confirmDelete, _controller, createState, dispose, id, initial, _ListNameDialog (+4 more)

### Community 140 - "nowProvider"
Cohesion: 0.24
Nodes (12): deviceRegionProvider, deviceTimeZoneProvider, nluEngineProvider, nowProvider, recurrenceProvider, todaySectionsProvider, build, ScheduleEditor (+4 more)

### Community 141 - "ConsumerState"
Cohesion: 0.24
Nodes (8): RemindMeApp, _RemindMeAppState, ReminderBinding, _Editor, _EditorState, QuickAddSheet, SearchScreen, _SearchScreenState

### Community 142 - "reminders_test.dart"
Cohesion: 0.20
Nodes (5): en, main, phone, NotificationTap, main

### Community 143 - "today_test.dart"
Cohesion: 0.22
Nodes (6): create, en, main, phone, seedDay, today

### Community 144 - "build"
Cohesion: 0.32
Nodes (7): hasRemindersProvider, notificationHealthProvider, notificationSchedulerProvider, didChangeDependencies, _run, build, _ReminderHealthCard

### Community 145 - "schedule_editor_test.dart"
Cohesion: 0.25
Nodes (6): chip, main, openDetail, phone, seedNoDate, seedTimed

### Community 147 - "Map"
Cohesion: 0.29
Nodes (5): b, _fold, foldForSearch, groups, toString

### Community 148 - "_ReminderBindingState"
Cohesion: 0.47
Nodes (5): appDatabaseProvider, launchNotificationTapProvider, notificationTapsProvider, initState, _ReminderBindingState

### Community 149 - "NotificationTexts"
Cohesion: 0.67
Nodes (3): AppNotificationTexts, NotificationTexts, Texts

## Knowledge Gaps
- **979 isolated node(s):** `_byday`, `l`, `locale`, `parts`, `n` (+974 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1788 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **22 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `_` connect `_` to `hlc.dart`, `Comparable`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `_byday`, `l`, `locale` to the rest of the system?**
  _979 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UX: kiến trúc thông tin, luồng, màn hình` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Why does `AppDatabase` connect `scheduler_test.dart` to `database.dart`, `sync_engine.dart`, `sync_engine_test.dart`, `providers.dart`, `scheduler.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Should `Hướng dẫn tích hợp với nền tảng khác` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Why does `CivilDate` connect `Comparable` to `quick_add_sheet.dart`, `lunar.dart`, `planner.dart`, `_`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Should `4. User stories và tiêu chí chấp nhận (MVP = P0)` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._