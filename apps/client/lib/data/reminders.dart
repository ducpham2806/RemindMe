import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';

import '../l10n/app_localizations.dart';
import '../platform/local_notifications.dart';

/// Chuỗi trong thông báo theo ngôn ngữ app và cài đặt 12/24h (AGENTS 5b). Giờ hiển thị theo giờ máy lúc lập lịch;
/// đổi múi giờ / ngôn ngữ / 12-24h thì lập lịch lại (reminder-engine.md §1).
class AppNotificationTexts implements NotificationTexts {
  AppNotificationTexts(this.l, {required this.localeTag, required this.use24h});
  final AppLocalizations l;
  final String localeTag;
  final bool use24h;

  String _time(DateTime utc) => (use24h ? DateFormat.Hm(localeTag) : DateFormat.jm(localeTag)).format(utc.toLocal());

  @override
  ({String title, String body}) forOccurrence(PlannerItem item, DateTime occurrenceAt, int offsetMinutes) {
    final allDay = item.allDay || item.startsAt == null;
    final when = allDay ? l.itemAllDay : _time(occurrenceAt);
    // `offset_minutes` âm = trước giờ của item (data-model.md).
    final body = switch (-offsetMinutes) {
      <= 0 => when,
      final m when m % 1440 == 0 => l.notifInDays(m ~/ 1440, when),
      final m when m % 60 == 0 => l.notifInHours(m ~/ 60, when),
      final m => l.notifInMinutes(m, when),
    };
    return (title: item.title, body: body);
  }

  @override
  ({String title, String body}) forSnooze(PlannerItem item) => (title: item.title, body: l.notifSnoozedBody);

  @override
  ({String title, String body}) fallback() => (title: l.notifFallbackTitle, body: l.notifFallbackBody);

  NotificationLabels get labels => NotificationLabels(
        done: l.notifActionDone,
        snooze10: l.notifActionSnooze10,
        snooze60: l.notifActionSnooze60,
        channelReminders: l.notifChannelReminders,
        channelAlarms: l.notifChannelAlarms,
        channelQuiet: l.notifChannelQuiet,
      );
}

/// Mô tả 1 mốc nhắc ("Đúng giờ", "Trước 15 phút"...). [minutes] theo `offset_minutes`: âm = trước giờ của item.
String describeReminderOffset(AppLocalizations l, int minutes) => switch (-minutes) {
      <= 0 => l.reminderAtTime,
      final m when m % 1440 == 0 => l.reminderDaysBefore(m ~/ 1440),
      final m when m % 60 == 0 => l.reminderHoursBefore(m ~/ 60),
      final m => l.reminderMinutesBefore(m),
    };

/// Các mốc có sẵn khi thêm nhắc (`offset_minutes`, âm = trước giờ của item).
const reminderPresets = [0, -10, -30, -60, -1440];

const _uiLocaleKey = 'ui_locale';

/// Cài đặt ở Tôi → Thông báo & nhắc (Figma C51), lưu trên máy ([LocalPrefs]).
/// [defaultReminderPref]: mốc nhắc mặc định của việc mới (`offset_minutes`, hoặc [prefNoReminder]); [allDayTimePref]: giờ kêu
/// của việc cả ngày ("HH:mm", reminder-engine.md §5).
const defaultReminderPref = 'default_reminder', allDayTimePref = 'all_day_time', prefNoReminder = 'none';

/// Giờ kêu mặc định của việc cả ngày khi người dùng chưa chọn (reminder-engine.md §5).
final defaultAllDayTime = CivilTime(9);

/// Giờ yên lặng (reminder-engine.md §5b): [quietHoursPref] = 'HH:mm-HH:mm' (khung đã chọn, giữ cả khi tắt),
/// [quietHoursOnPref] = '1' khi bật.
const quietHoursPref = 'quiet_hours', quietHoursOnPref = 'quiet_hours_on';

/// Khung gợi ý khi người dùng chưa chọn.
final suggestedQuietHours = QuietHours(CivilTime(22), CivilTime(7));

/// Cài đặt giờ yên lặng: bật hay không + khung (gợi ý nếu chưa chọn).
Future<({bool on, QuietHours window})> quietHoursSettingOf(AppDatabase db) async {
  final prefs = LocalPrefs(db);
  return (on: await prefs.get(quietHoursOnPref) == '1', window: QuietHours.parse(await prefs.get(quietHoursPref)) ?? suggestedQuietHours);
}

/// Khung đang áp cho planner; null khi tắt.
Future<QuietHours?> quietHoursOf(AppDatabase db) async {
  final s = await quietHoursSettingOf(db);
  return s.on ? s.window : null;
}

/// Đọc [allDayTimePref]; sai định dạng thì dùng mặc định.
Future<CivilTime> allDayTimeOf(AppDatabase db) async {
  final v = await LocalPrefs(db).get(allDayTimePref);
  try {
    return v == null ? defaultAllDayTime : CivilTime.parse(v);
  } on FormatException {
    return defaultAllDayTime;
  }
}

/// Lập lịch lại toàn bộ (dùng cả ở app lẫn isolate nền sau khi bấm nút trên thông báo).
Future<ScheduleReport> rescheduleReminders({
  required AppDatabase db,
  required NotificationScheduler os,
  required String deviceTz,
  required Locale locale,
  required bool use24h,
  DateTime Function()? now,
}) async {
  final l = lookupAppLocalizations(locale);
  final tag = locale.toLanguageTag();
  // Isolate nền không có cây widget: lưu ngôn ngữ để nó dùng lại.
  await db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: _uiLocaleKey, value: tag));
  return ReminderScheduler(
    db: db,
    os: os,
    planner: ReminderPlanner(
      deviceTz: deviceTz,
      maxPending: os.maxPending,
      allDayTime: await allDayTimeOf(db),
      quietHours: await quietHoursOf(db),
    ),
    texts: AppNotificationTexts(l, localeTag: tag, use24h: use24h),
    locale: tag,
    now: now,
  ).reschedule();
}

/// Ngôn ngữ app đã lưu (cho isolate nền); null nếu app chưa lập lịch lần nào.
Future<Locale?> savedUiLocale(AppDatabase db) async {
  final v = (await (db.select(db.syncState)..where((s) => s.key.equals(_uiLocaleKey))).getSingleOrNull())?.value;
  if (v == null) return null;
  final parts = v.split('-');
  return Locale.fromSubtags(languageCode: parts.first, countryCode: parts.length > 1 ? parts.last : null);
}
