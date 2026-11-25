import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_platform/remindme_platform.dart';

import '../l10n/app_localizations.dart';
import '../platform/local_notifications.dart';
import 'providers.dart';
import 'remote/remote_sync.dart';
import 'reminders.dart';

const _askedKey = 'notification_permission_asked';

/// Ghi là đã hỏi quyền thông báo (màn onboarding C33 tự hỏi, hoặc người dùng chọn "Để sau"): binding không hỏi lại.
Future<void> markNotificationPermissionAsked(AppDatabase db) =>
    db.into(db.syncState).insertOnConflictUpdate(SyncStateCompanion.insert(key: _askedKey, value: '1'));

/// Giữ thông báo đã lập lịch khớp dữ liệu (reminder-engine.md §1): lập lại khi DB đổi (gồm sau sync pull), khi app mở lại,
/// khi đổi ngôn ngữ hoặc 12/24h. Xử lý bấm thông báo / nút Xong-Hoãn khi app đang chạy.
class ReminderBinding extends ConsumerStatefulWidget {
  const ReminderBinding({super.key, required this.router, required this.child});
  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<ReminderBinding> createState() => _ReminderBindingState();
}

class _ReminderBindingState extends ConsumerState<ReminderBinding> with WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<void>? _dbSub;
  StreamSubscription<NotificationTap>? _tapSub;
  String? _formatKey;
  bool _running = false, _again = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final db = ref.read(appDatabaseProvider);
    _dbSub = db
        .tableUpdates(TableUpdateQuery.onAllTables([db.items, db.reminders, db.recurrences, db.occurrenceLog, db.syncState]))
        // sync_state: cài đặt giờ nhắc việc cả ngày (LocalPrefs) đổi thì lập lại.
        .listen((_) => _soon());
    _tapSub = ref.read(notificationTapsProvider).listen(_onTap);
    final launch = ref.read(launchNotificationTapProvider);
    if (launch != null) WidgetsBinding.instance.addPostFrameCallback((_) => _onTap(launch));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final key = '${Localizations.localeOf(context).toLanguageTag()}|${MediaQuery.alwaysUse24HourFormatOf(context)}';
    if (key != _formatKey) {
      final first = _formatKey == null;
      _formatKey = key;
      final os = ref.read(notificationSchedulerProvider);
      // iOS đăng ký nút theo ngôn ngữ lúc khởi tạo: đổi ngôn ngữ thì đăng ký lại.
      if (!first && os is LocalNotificationScheduler) unawaited(os.init(_texts().labels));
      _soon();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationHealthProvider);
      _soon();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _dbSub?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

  AppNotificationTexts _texts() => AppNotificationTexts(AppLocalizations.of(context),
      localeTag: Localizations.localeOf(context).toLanguageTag(), use24h: MediaQuery.alwaysUse24HourFormatOf(context));

  void _soon() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), _run);
  }

  Future<void> _run() async {
    if (!mounted) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      final db = ref.read(appDatabaseProvider);
      final os = ref.read(notificationSchedulerProvider);
      // Tài khoản đã đăng nhập ở máy khác (UX §3.7): hủy mọi thông báo, không lập lại tới khi đăng nhập lại.
      if (ref.read(remoteSyncProvider)?.state == RemoteSyncState.revoked) {
        await os.cancelAll();
        await db.delete(db.scheduledNotifications).go();
        return;
      }
      final report = await rescheduleReminders(
        db: db,
        os: os,
        deviceTz: ref.read(deviceTimeZoneProvider),
        locale: Localizations.localeOf(context),
        use24h: MediaQuery.alwaysUse24HourFormatOf(context),
        now: ref.read(nowProvider),
      );
      // Hỏi quyền thông báo 1 lần, khi đã có nhắc đầu tiên (reminder-engine.md §2). Đang onboarding thì để màn C33 giải thích rồi mới hỏi.
      if (report.total > 0 && ref.read(onboardingDoneProvider) && !(await os.health()).notificationsAllowed) {
        final asked = await (db.select(db.syncState)..where((s) => s.key.equals(_askedKey))).getSingleOrNull();
        if (asked == null) {
          await db.into(db.syncState).insert(SyncStateCompanion.insert(key: _askedKey, value: '1'));
          await os.requestPermission();
        }
      }
      if (mounted) ref.invalidate(notificationHealthProvider);
    } finally {
      _running = false;
      if (_again && mounted) {
        _again = false;
        _soon();
      }
    }
  }

  Future<void> _onTap(NotificationTap tap) async {
    if (tap.actionId != null) {
      await NotificationActionHandler(ref.read(itemsRepositoryProvider), now: ref.read(nowProvider)).handle(tap.actionId, tap.payload);
      return; // DB đổi → tự lập lịch lại
    }
    final p = NotificationPayload.tryParse(tap.payload);
    if (p != null && mounted) {
      unawaited(widget.router.push('/item/${p.itemId}?reminder=${p.reminderId}&at=${p.occurrenceAt.millisecondsSinceEpoch}'));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
