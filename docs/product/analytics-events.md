# Analytics & telemetry: danh mục sự kiện và consent

> TL;DR: Một danh mục sự kiện duy nhất cho product analytics (PostHog EU) và telemetry kỹ thuật. Không bao giờ gửi nội dung người dùng
> (tiêu đề, ghi chú, giá trị trường trích xuất, audio, văn bản STT). Consent theo vùng: EU/UK/BR... opt-in, nơi khác opt-out.
> Đây là nguồn chuẩn cho tên event; tài liệu khác chỉ link tới đây.

## 1. Consent
| Loại | Mặc định EU/EEA/UK/CH, BR, KR | Mặc định nơi khác | Ghi chú |
|---|---|---|---|
| Crash/lỗi (Sentry, Crashlytics) | Bật (lợi ích chính đáng, đã scrub PII); tắt được | Bật | Ghi trong Privacy Policy |
| Telemetry độ tin cậy nhắc (`reminder.*`) | Hỏi khi onboarding (giải thích: giúp nhắc kêu đúng giờ trên máy bạn) | Bật, tắt được | Không có nội dung |
| Product analytics (PostHog) | **Tắt tới khi đồng ý** | Bật, tắt được | Màn consent dịch theo locale |
| Chất lượng trích xuất/NLU (`extract.*`, `nlu.*`) | Tắt tới khi đồng ý | Bật, tắt được | Chỉ tên trường, không có giá trị |
| "Gửi mẫu để cải thiện" | Hỏi từng lần | Hỏi từng lần | Bản đã che, xem trước |
- Danh sách vùng opt-in là remote config (theo `region` của profile và storefront). Luật cụ thể: `docs/security-privacy.md` §4.
- ID: `analytics_id` ngẫu nhiên (không phải user id), đổi được khi người dùng "Đặt lại ID quảng cáo/analytics".

## 2. Thuộc tính chung (mọi event)
`app_version`, `platform`, `os_version`, `device_class` (low/mid/high), `oem`, `ui_locale`, `region`, `plan` (free/plus), `days_since_install`.

## 3. Danh mục sự kiện
| Nhóm | Event | Thuộc tính riêng | Dùng cho |
|---|---|---|---|
| onboarding | `onboarding_step` | `step`, `goals[]` | Phễu onboarding |
| | `permission_result` | `perm` (notif/exact_alarm/mic/camera/calendar/speech), `granted` | Tỷ lệ cấp quyền |
| capture | `item_created` | `kind`, `source` (manual/voice/image/pdf/xlsx/md/email/ics/pkpass/import), `has_reminder`, `has_recurrence`, `recurrence_kind` | North Star, nguồn nhập |
| | `quick_add_completed` | `ms_to_save`, `chips_edited[]`, `input` (text/voice) | KPI "nhập nhanh" (PRD §2) |
| nlu | `nlu_parsed` | `lang`, `pack_version`, `fields_found[]`, `ambiguous` | Chất lượng gói ngữ pháp |
| voice | `voice_session` | `voice_locale`, `region_hint`, `engine` (os_ondevice/os_online/whisper/phowhisper), `ms_latency`, `chips_edited[]`, `language_switch` | Đánh giá theo vùng (`voice-and-text-input.md` §7) |
| extract | `import_completed` | `kind`, `doc_type`, `doc_language`, `template_id`, `template_version`, `tier_used`, `fields_found[]`, `fields_edited[]`, `ms_total`, `saved` | KPI trích xuất, ưu tiên viết mẫu |
| reminder | `notification_scheduled` | `count`, `horizon_end`, `truncated` | Rolling window |
| | `notification_fired` | `late_ms` (= fired_at - due_at), `channel`, `dst_adjusted` | NFR ±60 s |
| | `notification_action` | `action` (done/snooze_10/snooze_60/open), `surface` (phone/watch) | Hành vi |
| | `exact_alarm_state` | `granted` | Android 14+ |
| trip | `trip_created` | `segments`, `auto_grouped` | Tính năng chuyến đi |
| monetization | `paywall_shown` | `trigger` (key quota), `variant` | Paywall |
| | `purchase_completed` | `period` (P1M/P3M/P1Y), `storefront`, `trial` | Doanh thu (số tiền lấy từ RevenueCat, không từ app) |
| | `quota_blocked` | `key`, `limit` | Cân chỉnh giới hạn |
| i18n | `locale_changed` | `from`, `to`, `setting` (ui/format/voice/holiday) | Nhu cầu ngôn ngữ |
| sync | `sync_error` | `code`, `attempts` | Độ ổn định |
| account | `session_claimed` | `replaced_count`, `same_device`, `device_class`, `plan` | Tần suất đổi máy / dùng chung tài khoản (ADR-013) |
| | `session_revoked_shown` | `pending_changes` (số), `reason` | Ảnh hưởng của giới hạn 1 thiết bị |

## 4. Quy tắc
- Thêm event mới: thêm vào bảng này trong cùng PR, có reviewer kiểm tra không chứa nội dung người dùng.
- Không dùng tên tự do; property dạng enum hoặc số. Mảng `fields_*` chỉ chứa **tên trường**.
- Dashboard bắt buộc: KPI PRD §2 theo quốc gia; `late_ms` theo OEM/OS; intent accuracy theo `voice_locale` × `region_hint`;
  `fields_edited` theo `template_id`; phễu paywall theo storefront.
