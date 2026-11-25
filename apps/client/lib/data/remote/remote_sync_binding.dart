import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';
import 'remote_sync.dart';

/// Khi có server: đồng bộ lúc mở app, khi app trở lại, vài giây sau mỗi thay đổi local (gom nhiều lần sửa), và định kỳ
/// khi app đang mở. Không có server ([remoteSyncProvider] null) thì không làm gì.
class RemoteSyncBinding extends ConsumerStatefulWidget {
  const RemoteSyncBinding({super.key, required this.child});
  final Widget child;

  static const debounce = Duration(seconds: 3);
  static const period = Duration(minutes: 15);

  @override
  ConsumerState<RemoteSyncBinding> createState() => _RemoteSyncBindingState();
}

class _RemoteSyncBindingState extends ConsumerState<RemoteSyncBinding> with WidgetsBindingObserver {
  RemoteSync? _sync;
  StreamSubscription<void>? _outboxSub;
  Timer? _debounce, _periodic;

  @override
  void initState() {
    super.initState();
    _sync = ref.read(remoteSyncProvider);
    if (_sync == null) return;
    WidgetsBinding.instance.addObserver(this);
    final db = ref.read(appDatabaseProvider);
    _outboxSub = db.tableUpdates(TableUpdateQuery.onTable(db.outbox)).listen((_) => _soon());
    _periodic = Timer.periodic(RemoteSyncBinding.period, (_) => _now());
    _now();
  }

  void _soon() {
    _debounce?.cancel();
    _debounce = Timer(RemoteSyncBinding.debounce, _now);
  }

  void _now() {
    unawaited(_sync?.run().then((_) {
      if (mounted) ref.invalidate(cachedQuotaProvider);
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _now();
  }

  @override
  void dispose() {
    if (_sync != null) WidgetsBinding.instance.removeObserver(this);
    _outboxSub?.cancel();
    _debounce?.cancel();
    _periodic?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
