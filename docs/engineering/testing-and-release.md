# Kiểm thử, CI/CD và phát hành

> TL;DR: Kim tự tháp test: unit (Dart/TS/pgTAP) → widget/golden theo locale → integration trên thiết bị → device farm.
> Eval riêng cho trích xuất và NLU chạy trong CI. Phát hành: fastlane, version theo ngày, staged rollout, cờ tính năng qua remote config.
> Thiết bị và OS tối thiểu theo ADR-011 (iOS 17+, Android 8.0+).

## 1. Ma trận thiết bị
| Nhóm | Thiết bị tối thiểu cho QA | Lý do |
|---|---|---|
| Android OEM "khó" | Xiaomi/Redmi (HyperOS), OPPO/Realme (ColorOS), vivo (Funtouch/OriginOS), Samsung (One UI), Huawei không GMS | Kill nền, thông báo trễ |
| Android chuẩn | Pixel (bản Android mới nhất, có Gemini Nano) | Tham chiếu, T3 |
| Android thấp | Máy RAM 3-4 GB, Android 8-10 | OS tối thiểu, hiệu năng |
| iOS | iPhone đời cũ nhất chạy iOS 17; iPhone 15 Pro+ (Apple Intelligence); iPad | Rolling window, T3, layout tablet |
| Watch | Apple Watch (watchOS mới), Wear OS (Pixel Watch/Galaxy Watch), 1 đồng hồ chỉ mirror (Xiaomi/Huawei) | Mirror, app watch |
Device farm (Firebase Test Lab / BrowserStack / AWS Device Farm) cho integration test hằng đêm; thiết bị thật trong tay cho test giờ kêu.

## 2. Các tầng test
| Tầng | Công cụ | Phạm vi | Chạy khi |
|---|---|---|---|
| Unit Dart | `dart test` / `flutter test` | NLU (fixtures theo gói ngôn ngữ), recurrence + hệ lịch, DST (`reminder-engine.md` §5), quota client, decoder, bộ máy luật | Mỗi PR |
| Unit TS | Vitest | Worker: webhook, hộp thư, xuất ICS (fixtures recurrence chung với Dart) | Mỗi PR |
| DB | pgTAP (`tools/db-test.sh`: Postgres thuần + shim Supabase; hoặc `supabase test db`) | RLS, `sync_push` (merge `field_clock`, quota, từ chối ghi ngoài RPC), `sync_pull`, cascade xóa tài khoản | Mỗi PR |
| Eval trích xuất | Harness E3.5 | `on-device-extraction.md` §11 | Mỗi PR đụng `packages/parsers` |
| Eval NLU | Fixtures `nlu/<lang>.json` | Ngưỡng `voice-and-text-input.md` §7 | Mỗi PR đụng gói ngôn ngữ |
| Widget + golden | `flutter test` + golden | Màn chính × locale (en-US, vi-VN, de-DE, ja-JP, pseudo-locale; ar khi bật RTL) × sáng/tối × chữ 100%/200% | Mỗi PR |
| Integration | `integration_test` + Patrol (cho dialog quyền/thông báo hệ thống) | Onboarding, Quick Add, import, paywall (sandbox), sync 2 thiết bị | Hằng đêm trên device farm |
| Giờ kêu | App test riêng lập 50 nhắc rải 24h, đo `late_ms`; chạy qua đêm có Doze, có/không sạc | Mỗi OEM trong §1 | Mỗi sprint từ S3 + trước release |
| Sync/xung đột | Test 2 client giả lập offline sửa cùng item/ghi chú | Merge LWW theo trường, màn xung đột | Mỗi PR đụng sync |
| Accessibility | Checklist + TalkBack/VoiceOver theo kịch bản; `flutter test` semantics; kiểm tra tương phản token | Mọi màn P0 | Mỗi sprint + gate S8 |
| Bản địa hóa | CI kiểm ARB (thiếu key, ICU, placeholder, độ dài); pseudo-locale; LQA trên ảnh chụp | `i18n-l10n.md` §8-9 | Mỗi PR + trước bật locale |
| Bảo mật | gitleaks, dependency scan, threat model review, pen-test bên ngoài | `security-privacy.md` §2 | Mỗi PR / trước production |

**Kịch bản accessibility (pass = hoàn thành không cần nhìn màn hình):** tạo nhắc bằng VoiceOver/TalkBack; đánh dấu xong từ thông báo;
mở mã đặt chỗ từ thông báo; đổi ngôn ngữ app. Tiêu chí: mọi control có label, thứ tự đọc đúng, vùng chạm ≥ 48dp, tương phản AA.

## 3. CI/CD
- GitHub Actions: lint (gồm lint chuỗi hard-code) → unit/DB/eval → build Android (AAB) + iOS (IPA) → upload nội bộ.
  Đã có (`.github/workflows/ci.yml`): job `docs-and-lint` (`check-docs`, `validate-fixtures`, `lint-hardcoded-strings`); job `db` (`tools/db-test.sh` + contract test
  `packages/data/test/pg_contract_test.dart`); job `flutter` (`check-arb`, `pseudo-arb --check`, `lint-platform-checks`, `flutter analyze`, test từng package, test widget).
  Commit message kiểm bằng hook `tools/hooks/commit-msg` (cài: `tools/install-hooks.sh`).
- Code signing: Android upload key trong Play App Signing, keystore trong secret CI; iOS bằng fastlane `match` (repo cert riêng, mã hóa).
- fastlane: `beta` (TestFlight + Play internal), `release` (metadata đa ngôn ngữ từ `fastlane/metadata/<locale>/`, ảnh chụp tự động L5).
- Version: `YYYY.MM.patch` (ví dụ `2027.04.1`), build number tăng tự động. Changelog sinh từ commit `feat/fix`, dịch qua TMS cho store.
- Watch app và widget build cùng pipeline với app chính.

## 4. Phát hành
- Kênh: internal → closed test (beta tester theo thị trường) → open test → production **staged rollout** (Play 5% → 20% → 50% → 100%;
  App Store phased release 7 ngày). Dừng rollout nếu crash-free < 99,5% hoặc `late_ms` p95 xấu đi.
- Cờ tính năng (remote config): bật/tắt locale, T3, mẫu mới, paywall variant, giới hạn quota.
- Checklist review store: chuỗi giải thích quyền đã dịch; tài khoản demo cho reviewer; Privacy Nutrition Label / Data Safety khớp `security-privacy.md` §3;
  paywall đủ thông tin; nút xóa tài khoản; lý do dùng exact alarm (Android) nếu bị hỏi.
- Hotfix: nhánh `hotfix/*` từ tag release, test rút gọn (unit + golden + giờ kêu trên 2 OEM), expedited review nếu lỗi nhắc không kêu.
- Dữ liệu không cần phát hành app: mẫu nhà cung cấp, gói NLU, ngày lễ (CDN có chữ ký, `api-spec.md` §2), có rollback về bản đóng gói.
