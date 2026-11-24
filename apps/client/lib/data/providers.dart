import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

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

final recurringIdsProvider = StreamProvider<Set<String>>((ref) => ref.watch(itemsRepositoryProvider).watchRecurringIds());

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
    StreamProvider<TodaySections>((ref) => ref.watch(itemsRepositoryProvider).watchToday(ref.watch(todayWindowProvider)));

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
}
