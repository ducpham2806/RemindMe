/// Entitlement từ RPC `quota_status()` (pricing-entitlements.md §2). App không hard-code giá trị (AGENTS quy tắc 4):
/// chỉ biết tên key, giá trị luôn lấy từ server rồi cache 24h (ADR-008).
abstract final class EntitlementKey {
  static const maxRemindersPerDay = 'max_reminders_per_day';
  static const maxRecurringSeries = 'max_recurring_series';
  static const maxActiveAppointments = 'max_active_appointments';
  static const maxActiveTrips = 'max_active_trips';
  static const smartImportsPerMonth = 'smart_imports_per_month';
  static const maxImportPages = 'max_import_pages';
  static const maxOriginalsMb = 'max_originals_mb';
  static const maxLists = 'max_lists';
  static const maxActiveDevices = 'max_active_devices';
  static const maxDevicesPerClass = 'max_devices_per_class';
  static const featureWatchApp = 'feature_watch_app';
  static const featureAltCalendars = 'feature_alt_calendars';
  static const featureEnhancedVoice = 'feature_enhanced_voice';
}

const unlimited = -1;

class QuotaStatus {
  const QuotaStatus({
    required this.plan,
    required this.limits,
    required this.usage,
    required this.features,
    this.periodEnd,
    required this.fetchedAt,
  });

  factory QuotaStatus.fromJson(Map<String, Object?> json, {required DateTime fetchedAt}) => QuotaStatus(
        plan: json['plan'] as String,
        periodEnd: json['period_end'] == null ? null : DateTime.parse(json['period_end'] as String),
        limits: _intMap(json['limits']),
        usage: _intMap(json['usage']),
        features: _intMap(json['features']),
        fetchedAt: fetchedAt,
      );

  static const cacheTtl = Duration(hours: 24);

  final String plan;
  final DateTime? periodEnd;
  final Map<String, int> limits;
  final Map<String, int> usage;
  final Map<String, int> features;
  final DateTime fetchedAt;

  bool isStale(DateTime now) => now.difference(fetchedAt) > cacheTtl;

  /// Thiếu key thì coi là 0 (đóng mặc định, giống `app.limit_for` trên server).
  int limit(String key) => limits[key] ?? 0;

  int used(String key) => usage[key] ?? 0;

  bool isUnlimited(String key) => limit(key) == unlimited;

  /// Thêm [adding] có vượt giới hạn không. Vượt khi offline thì app tạo item ở `pending_quota` (ADR-008).
  bool wouldExceed(String key, {int adding = 1}) => !isUnlimited(key) && used(key) + adding > limit(key);

  int featureLevel(String key) => features[key] ?? 0;

  Map<String, Object?> toJson() => {
        'plan': plan,
        'period_end': periodEnd?.toIso8601String(),
        'limits': limits,
        'usage': usage,
        'features': features,
      };

  static Map<String, int> _intMap(Object? raw) =>
      (raw as Map<String, Object?>? ?? const {}).map((k, v) => MapEntry(k, (v as num).toInt()));
}
