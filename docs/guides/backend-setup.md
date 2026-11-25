# Backend Supabase: cấu hình và chạy app với server

> Nguồn chuẩn cho: project Supabase đang dùng, cách áp migration, cách build app có server, test với server thật.
> Giao thức RPC: `architecture/api-spec.md` §1. Bảng/quy tắc dữ liệu: `architecture/data-model.md`.

## 1. Project

| Môi trường | Project ref | Region | Ghi chú |
|---|---|---|---|
| dev | `msgamxrlohgszgpvvyfd` (tên RemindMe) | `ap-southeast-1` | Tạo 2026-11-25, đã áp migrations 01-08 |

Region chọn lúc tạo, không đổi được. Đề xuất region cho bản chính thức vẫn chờ chủ dự án duyệt (STATE "Tiếp theo" mục 1).

## 2. Migrations

- Nguồn: `supabase/migrations/*.sql`, áp theo thứ tự tên tệp. Có Supabase CLI: `supabase db push`. Không có: áp từng tệp
  (SQL editor hoặc Supabase MCP `apply_migration`, mỗi tệp 1 migration cùng tên).
- Test trước khi áp: `tools/db-test.sh` (Postgres thuần + shim) và contract test (`packages/data/test/pg_contract_test.dart`).
- Sau khi áp: xem Security Advisor. Cảnh báo "authenticated SECURITY DEFINER function" cho 7 RPC (`sync_push`, `sync_pull`,
  `quota_status`, `profile_init`, `session_claim`, `session_status`, `session_end`) là cố ý: mọi ghi đi qua RPC (ADR-012).

## 3. Auth

- Đăng nhập đầu tiên là **ẩn danh** (S1): Authentication → Sign In / Providers → bật "Allow anonymous sign-ins".
  Chưa bật thì app vẫn chạy offline, trạng thái đồng bộ là `signedOut`.
- **Email + mã (OTP), không mật khẩu** (app: Tôi → Tài khoản & thiết bị, `lib/data/remote/account.dart`):
  - Máy đang ẩn danh + email mới: `updateUser(email)` → mã loại `email_change` → user ẩn danh thành tài khoản email, cùng id, giữ dữ liệu.
  - Email đã có tài khoản: `signInWithOtp` → mã loại `email` → app hỏi rồi thay dữ liệu trên máy bằng dữ liệu tài khoản (`SyncEngine.resetLocalData`),
    nêu máy sẽ bị đăng xuất theo `session_status.will_replace`. Hủy thì đăng xuất tài khoản đó, máy quay về ẩn danh mới.
  - Đăng xuất: `session_end` → `signOut` → xóa dữ liệu tài khoản khỏi máy → ẩn danh mới.
  - **Email template phải chứa mã**: Authentication → Email Templates, ở "Magic Link" và "Change Email Address" thêm `{{ .Token }}`
    (mặc định chỉ có link, app không mở link). Ví dụ nội dung: `<p>Mã đăng nhập RemindMe / Your RemindMe code: <b>{{ .Token }}</b></p>`.
  - SMTP mặc định của Supabase giới hạn vài email mỗi giờ và chỉ để thử: trước khi ra mắt cấu hình SMTP riêng (Authentication → SMTP).
    Không gửi thử tới địa chỉ không có thật (thư bị trả lại làm Supabase hạn chế project).
- Google, Apple: làm sau (`integrations/integration-guide.md`), cũng liên kết vào user ẩn danh (`linkIdentity`) để không mất dữ liệu.

## 4. Build app có server

URL và publishable key (`sb_publishable_…`) là thông tin công khai; bảo vệ nằm ở RLS + RPC. Không đưa service role key
hay secret nào vào app (AGENTS quy tắc 7).

```bash
cd apps/client && flutter run --dart-define-from-file=env/dev.json
```

Không truyền `--dart-define-from-file` thì app chạy offline như trước (test và CI dùng cách này).
Luồng trong app (`lib/data/remote/`): đăng nhập ẩn danh nếu chưa có phiên → `profile_init` (ngôn ngữ, vùng, múi giờ của máy)
→ `session_claim` → `SyncEngine.sync()`. Đồng bộ lúc mở app, khi app trở lại, 3 giây sau thay đổi cuối, và 15 phút một lần.
Máy chưa có vùng thì chưa tạo profile (`regionMissing`): người dùng chọn quốc gia ở Ngôn ngữ & vùng.

## 5. Test với server thật

```bash
cd apps/client && REMINDME_LIVE=1 flutter test test/live_supabase_test.dart --dart-define-from-file=env/dev.json
```

Test tạo 1 user ẩn danh mỗi lần chạy. Dọn trên project **dev** (xóa dây chuyền profile và dữ liệu của user đó):
`delete from auth.users where is_anonymous and created_at > now() - interval '1 hour';`
