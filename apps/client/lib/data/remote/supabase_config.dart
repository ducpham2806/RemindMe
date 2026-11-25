/// Cấu hình project Supabase, truyền lúc build: `flutter run --dart-define-from-file=env/dev.json`.
/// URL và publishable key là thông tin công khai theo thiết kế của Supabase (RLS + RPC mới là lớp bảo vệ); không có
/// secret nào trong app (AGENTS quy tắc 7). Không truyền thì app chạy offline như trước.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
