import 'dart:convert';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';
import 'package:remindme_platform/remindme_platform.dart';

import '../platform/device_time.dart';

/// Mở DB local của app (file `remindme.sqlite` trong thư mục dữ liệu app, do drift_flutter chọn theo nền tảng).
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'remindme'));

/// DB local. `main()` mở trước rồi override; test override bằng DB in-memory.
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override trong main() hoặc test'));

/// `device_id` của lần cài này (InstallInfo.deviceId), đọc trong `main()` trước runApp.
final deviceIdProvider = Provider<String>((ref) => throw UnimplementedError('override trong main() hoặc test'));

/// Múi giờ IANA của máy (`deviceTimeZone()`), đọc trong `main()` trước runApp.
final deviceTimeZoneProvider = Provider<String>((ref) => throw UnimplementedError('override trong main() hoặc test'));

/// Vùng của máy (ISO 3166-1) hoặc null; quyết định đọc 03/04 là ngày 3 tháng 4 hay ngày 4 tháng 3.
final deviceRegionProvider = Provider<String?>((ref) => deviceRegion());

/// Gói NLU có sẵn trong app (packages/parsers/nlu/packs).
const bundledNluPacks = {'en', 'vi'};

/// Gói NLU theo ngôn ngữ: gói chính = ngôn ngữ giao diện (nếu có gói), gói phụ = en cho câu pha tiếng Anh.
/// Khóa dạng 'vi+en'. Ngôn ngữ giọng nói riêng (voice-and-text-input.md §2) thêm ở V2.
String nluPackKey(String languageCode) {
  final primary = bundledNluPacks.contains(languageCode) ? languageCode : 'en';
  return primary == 'en' ? 'en' : '$primary+en';
}

final nluEngineProvider = FutureProvider.family<NluEngine, String>((ref, key) async => NluEngine([
      for (final lang in key.split('+'))
        // cache: false: provider đã giữ engine; cache của rootBundle giữ Future của zone cũ (lỗi trong test).
        GrammarPack.fromYaml(await rootBundle.loadString('packages/remindme_parsers/nlu/packs/$lang.yaml', cache: false)),
    ]));

/// Gói ngôn ngữ ở dạng YAML (để gửi sang isolate giải mã tệp): gói của ngôn ngữ giao diện trước, rồi các gói còn lại.
/// Nhập bảng thử mọi gói để khớp tên cột (on-device-extraction.md §6).
final nluPackSourcesProvider = FutureProvider.family<Map<String, String>, String>((ref, languageCode) async {
  final order = [if (bundledNluPacks.contains(languageCode)) languageCode, ...bundledNluPacks.where((l) => l != languageCode)];
  return {
    for (final lang in order) lang: await rootBundle.loadString('packages/remindme_parsers/nlu/packs/$lang.yaml', cache: false),
  };
});

/// Từ điển sân bay IATA → múi giờ cho tầng luật T2 (packages/parsers/data/airports.tsv, ~260 KB), gửi sang isolate giải mã dạng chuỗi.
/// `load` + `utf8.decode` thay vì `loadString`: tệp > 50 KB thì `loadString` mở thêm 1 isolate chỉ để giải mã UTF-8.
final airportsTsvProvider = FutureProvider<String>((ref) async {
  final data = await rootBundle.load('packages/remindme_parsers/data/airports.tsv');
  return utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
});

final importsRepositoryProvider = Provider<ImportsRepository>((ref) => ImportsRepository(
      ref.watch(syncEngineProvider),
      ref.watch(itemsRepositoryProvider),
      ref.watch(listsRepositoryProvider),
      trips: ref.watch(tripsRepositoryProvider),
      now: ref.watch(nowProvider),
    ));

final tripsRepositoryProvider =
    Provider<TripsRepository>((ref) => TripsRepository(ref.watch(syncEngineProvider), now: ref.watch(nowProvider)));

final tripsProvider = StreamProvider<List<TripSummary>>((ref) => ref.watch(tripsRepositoryProvider).watchTrips());

final tripSegmentsProvider =
    StreamProvider.family<List<TripSegment>, String>((ref, id) => ref.watch(tripsRepositoryProvider).watchSegments(id));

final recurringIdsProvider = StreamProvider<Set<String>>((ref) => ref.watch(itemsRepositoryProvider).watchRecurringIds());

/// Lập lịch thông báo của OS (`LocalNotificationScheduler` trên Android/iOS/macOS); `main()` khởi tạo rồi override.
final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) => throw UnimplementedError('override trong main() hoặc test'));

/// Bấm thông báo / nút khi app đang chạy.
final notificationTapsProvider = Provider<Stream<NotificationTap>>((ref) => const Stream.empty());

/// Lần bấm thông báo đã mở app (app đang tắt).
final launchNotificationTapProvider = Provider<NotificationTap?>((ref) => null);

final notificationHealthProvider = FutureProvider<NotificationHealth>((ref) => ref.watch(notificationSchedulerProvider).health());

/// Có ít nhất 1 nhắc (chỉ khi đó mới hiện thẻ "Nhắc nhở có thể không kêu").
final hasRemindersProvider = StreamProvider<bool>((ref) => ref.watch(itemsRepositoryProvider).watchHasReminders());

final recurrenceProvider =
    StreamProvider.family<Map<String, Object?>?, String>((ref, itemId) => ref.watch(itemsRepositoryProvider).watchRecurrence(itemId));

final listsRepositoryProvider =
    Provider<ListsRepository>((ref) => ListsRepository(ref.watch(syncEngineProvider), now: ref.watch(nowProvider)));

final listsProvider = StreamProvider<List<ListSummary>>((ref) => ref.watch(listsRepositoryProvider).watchLists());

/// Việc của 1 list; khóa 'inbox' = Inbox ảo (việc chưa thuộc list nào).
final listItemsProvider = StreamProvider.family<List<ItemView>, String>(
    (ref, id) => ref.watch(listsRepositoryProvider).watchItems(id == inboxRouteId ? null : id));

const inboxRouteId = 'inbox';

final remindersProvider = StreamProvider.family<List<Reminder>, String>((ref, itemId) => ref.watch(itemsRepositoryProvider).watchReminders(itemId));

/// Giờ hiện tại; test override để cố định ngày.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// API đồng bộ. Tới khi có project Supabase (STATE "Tiếp theo" mục 6) app chạy offline: mọi thay đổi nằm trong outbox.
final syncApiProvider = Provider<SyncApi>((ref) => const OfflineSyncApi());

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final deviceId = ref.watch(deviceIdProvider);
  final now = ref.watch(nowProvider);
  return SyncEngine(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(syncApiProvider),
    clock: HlcClock(deviceId, now: () => now().millisecondsSinceEpoch),
    deviceId: deviceId,
    now: now,
  );
});

final itemsRepositoryProvider =
    Provider<ItemsRepository>((ref) => ItemsRepository(ref.watch(syncEngineProvider), now: ref.watch(nowProvider)));

/// Ngày đang xem trên màn Hôm nay, theo giờ máy.
final todayWindowProvider = Provider<DayWindow>((ref) => DayWindow.ofLocal(ref.watch(nowProvider)()));

final todaySectionsProvider =
    StreamProvider<TodaySections>((ref) => ref
        .watch(itemsRepositoryProvider)
        .watchToday(ref.watch(todayWindowProvider), deviceTz: ref.watch(deviceTimeZoneProvider)));

/// Hạn mức lấy ở lần sync gần nhất (null khi chưa sync lần nào).
final cachedQuotaProvider = FutureProvider<QuotaStatus?>((ref) => ref.watch(syncEngineProvider).cachedQuota());

/// Gói ngày lễ có sẵn trong app (packages/core/data/holidays, ADR-017).
const bundledHolidayRegions = {'VN', 'US', 'GB'};

/// Nạp gói ngày lễ của [region] có sẵn trong app và đăng ký cho lặp "ngày làm việc" ([HolidayCalendars]); null = chưa có gói.
/// `main()` và isolate nền gọi trước khi lập lịch nhắc.
Future<HolidayCalendar?> loadBundledHolidays(String? region) async {
  final r = region?.toUpperCase();
  if (r == null || !bundledHolidayRegions.contains(r)) return null;
  if (HolidayCalendars.of(r) case final c?) return c;
  final data = await rootBundle.load('packages/remindme_core/data/holidays/$r.json');
  final c = HolidayCalendar.parse(utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
  HolidayCalendars.register(c);
  return c;
}

/// Cài đặt chỉ trên máy ở màn Ngôn ngữ & vùng (UX §1), tới khi có đồng bộ `profiles.region`/`calendar_systems`.
/// Giá trị: [prefAuto] (theo máy/ngôn ngữ, mặc định), [prefNone], hoặc mã vùng ('VN') / hệ lịch ('lunar_vi').
const holidayRegionPref = 'holiday_region', calendarSystemPref = 'calendar_system';
const prefAuto = 'auto', prefNone = 'none';

final holidayRegionSettingProvider = FutureProvider<String>((ref) async => await ref.watch(localPrefsProvider).get(holidayRegionPref) ?? prefAuto);
final calendarSystemSettingProvider =
    FutureProvider<String>((ref) async => await ref.watch(localPrefsProvider).get(calendarSystemPref) ?? prefAuto);

/// Vùng tính ngày lễ theo cài đặt; null = không dùng ngày lễ.
String? effectiveHolidayRegion(String setting, String? deviceRegion) =>
    setting == prefAuto ? deviceRegion?.toUpperCase() : (setting == prefNone ? null : setting);

/// Hệ âm lịch phụ theo cài đặt; [prefAuto] = suy theo ngôn ngữ giao diện (vi/zh/ko).
LunarSystem? effectiveLunarSystem(String setting, String languageCode) {
  if (setting == prefNone) return null;
  if (setting != prefAuto) return LunarSystem.values.where((s) => s.wire == setting).firstOrNull;
  return switch (languageCode) {
    'vi' => LunarSystem.vi,
    'zh' => LunarSystem.zh,
    'ko' => LunarSystem.ko,
    _ => null,
  };
}

/// Vùng ngày lễ đang dùng (cài đặt hoặc vùng máy).
final holidayRegionProvider = FutureProvider<String?>(
    (ref) async => effectiveHolidayRegion(await ref.watch(holidayRegionSettingProvider.future), ref.watch(deviceRegionProvider)));

/// Ngày lễ của vùng đang dùng; null = không dùng, hoặc vùng chưa có gói.
final holidayCalendarProvider = FutureProvider<HolidayCalendar?>((ref) async => loadBundledHolidays(await ref.watch(holidayRegionProvider.future)));

/// Mọi gói ngày lễ có sẵn (cho danh sách chọn quốc gia).
final bundledHolidayCalendarsProvider = FutureProvider<List<HolidayCalendar>>(
    (ref) async => [for (final r in bundledHolidayRegions.toList()..sort()) ?await loadBundledHolidays(r)]);

/// Gợi ý dời việc khỏi ngày nghỉ lễ (US-12b): ngày nghỉ lễ gần nhất trong 7 ngày tới (chưa bị "Để nguyên") có việc 1 lần đang hẹn.
class HolidayHint {
  const HolidayHint({required this.holiday, required this.tasks, required this.moveTo});
  final Holiday holiday;
  final List<ItemView> tasks;
  /// Ngày làm việc kế tiếp (bỏ cuối tuần + ngày nghỉ lễ của vùng).
  final CivilDate moveTo;
}

const holidayHintDismissedPref = 'holiday_hint_dismissed';

final localPrefsProvider = Provider<LocalPrefs>((ref) => LocalPrefs(ref.watch(appDatabaseProvider)));

final holidayHintProvider = StreamProvider<HolidayHint?>((ref) async* {
  final cal = await ref.watch(holidayCalendarProvider.future);
  if (cal == null) {
    yield null;
    return;
  }
  final today = CivilDate.of(ref.watch(nowProvider)());
  final dismissed = await ref.watch(localPrefsProvider).getSet(holidayHintDismissedPref);
  final byDate = <String, Holiday>{
    for (final h in cal.between(today, today.addDays(7)).reversed)
      if (h.dayOff && !dismissed.contains(h.date.toIso())) h.date.toIso(): h,
  };
  yield* ref.watch(itemsRepositoryProvider).watchOpenTasksOn(byDate.keys.toSet(), deviceTz: ref.watch(deviceTimeZoneProvider)).map((tasks) {
    for (final d in byDate.keys.toList()..sort()) {
      final hits = [for (final t in tasks) if (_dayOf(t, ref.read(deviceTimeZoneProvider)) == d) t];
      if (hits.isNotEmpty) return HolidayHint(holiday: byDate[d]!, tasks: hits, moveTo: nextWorkday(CivilDate.parse(d), cal.region));
    }
    return null;
  });
});

String? _dayOf(ItemView i, String deviceTz) {
  if (i.startDate != null && (i.allDay || i.startsAt == null)) return i.startDate;
  if (i.startsAt != null) return TimeZones.toWall(i.startsAt!, deviceTz).date.toIso();
  return null;
}

/// Số item theo ngày của lưới tháng (khóa: ngày đầu và cuối lưới 'YYYY-MM-DD|YYYY-MM-DD').
final calendarCountsProvider = StreamProvider.family<Map<String, int>, String>((ref, range) {
  final [from, to] = range.split('|');
  return ref
      .watch(itemsRepositoryProvider)
      .watchCountsByDay(CivilDate.parse(from), CivilDate.parse(to), deviceTz: ref.watch(deviceTimeZoneProvider));
});

/// Loại đặt chỗ, múi giờ nơi đến, tên chuyến cho thẻ lịch hẹn; khóa: id item nối bằng '|'.
final bookingInfoProvider = FutureProvider.family<Map<String, ({String? bookingType, String? destinationTz, String? tripTitle})>, String>(
    (ref, ids) {
  ref.watch(tripsProvider);
  return ref.watch(tripsRepositoryProvider).bookingInfo(ids.isEmpty ? const [] : ids.split('|'));
});

/// Item của 1 ngày bất kỳ ('YYYY-MM-DD', theo giờ máy) cho màn Lịch.
final daySectionsProvider = StreamProvider.family<TodaySections, String>((ref, iso) {
  final d = CivilDate.parse(iso);
  return ref
      .watch(itemsRepositoryProvider)
      .watchToday(DayWindow.ofLocal(DateTime(d.year, d.month, d.day)), deviceTz: ref.watch(deviceTimeZoneProvider));
});

final itemProvider = StreamProvider.family<ItemView?, String>((ref, id) => ref.watch(itemsRepositoryProvider).watchItem(id));

/// SyncApi khi chưa có server: báo lỗi mạng, SyncEngine giữ nguyên outbox.
class OfflineSyncApi implements SyncApi {
  const OfflineSyncApi();

  @override
  Future<List<MutationResult>> push(String deviceId, List<Mutation> mutations) =>
      Future.error(const SyncException(SyncErrorCode.network, 'offline: chưa cấu hình server'));

  @override
  Future<PullPage> pull(int since, {int limit = 500}) =>
      Future.error(const SyncException(SyncErrorCode.network, 'offline: chưa cấu hình server'));

  @override
  Future<Map<String, Object?>> quotaStatus() =>
      Future.error(const SyncException(SyncErrorCode.network, 'offline: chưa cấu hình server'));
}
