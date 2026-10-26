class SupabaseConfig {
  // Sử dụng defaultValue để tự động dùng cấu hình có sẵn của dự án khi chạy `flutter run` bình thường.
  // Nếu truyền thêm `--dart-define-from-file`, Flutter sẽ ưu tiên ghi đè bằng giá trị trong file.
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qngjaaqlnnipmsutjccb.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuZ2phYXFsbm5pcG1zdXRqY2NiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MDI0OTQsImV4cCI6MjEwNzM3ODQ5NH0.Xfu0uaROLek6b98V7m5L_sXtKUcapQJefXl0BSbcjuo',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
