import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

/// Mở DB local của app (file `remindme.sqlite` trong thư mục dữ liệu app, do drift_flutter chọn theo nền tảng).
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'remindme'));

/// DB local. `main()` mở trước rồi override; test override bằng DB in-memory.
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override trong main() hoặc test'));

/// `device_id` của lần cài này (InstallInfo.deviceId), đọc trong `main()` trước runApp.
final deviceIdProvider = Provider<String>((ref) => throw UnimplementedError('override trong main() hoặc test'));

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
