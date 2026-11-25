import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../quick_add/quick_add_sheet.dart';
import 'candidate_editor.dart';
import 'import_decode.dart';
import 'import_mapper.dart';
import 'import_providers.dart';

/// Nhập từ tệp → màn Xem lại (E5, bản đầu cho decoder T0): chọn mục, sửa tên, chọn thứ tự ngày/trang tính của bảng, rồi thêm.
/// Tệp chỉ được đọc trên máy (ADR-010); không lưu bản gốc.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportRequest? _request;
  ImportPreview? _preview;
  bool _busy = false;
  bool _failed = false;
  /// Tên tệp đang đọc (màn 14/25).
  String? _fileName;
  /// Người dùng bấm Hủy khi đang đọc: bỏ kết quả giải mã.
  bool _cancelled = false;
  /// Kết quả sau khi lưu (màn 26).
  ({List<String> titles, String? tripId, bool pending})? _saved;
  List<bool> _selected = const [];
  /// Đề xuất người dùng đã sửa ở form (E5.1), theo vị trí trong danh sách.
  final Map<int, Candidate> _edits = {};

  Candidate _candidate(int i) => _edits[i] ?? _preview!.candidates[i];

  /// Đặt chỗ đã có trong máy (cùng thứ tự đề xuất): trùng thì mặc định bỏ chọn, đổi giờ thì cập nhật item cũ.
  List<BookingMatch?> _matches = const [];
  /// Chuyến đi còn hoạt động, để gợi ý gộp đặt chỗ mới vào.
  List<TripSummary> _activeTrips = const [];
  /// Lựa chọn cho từng gợi ý chuyến đi: [_newTrip], [_noTrip] hoặc id chuyến có sẵn.
  final Map<int, String> _tripChoice = {};
  static const _newTrip = 'new', _noTrip = 'none';
  /// Hạn mức từ cache `quota_status` (null = chưa sync lần nào, để server quyết khi sync).
  QuotaStatus? _quota;
  /// Số chuyến mới còn tạo được (giới hạn `max_active_trips` trừ chuyến đang hoạt động trên máy); null = không giới hạn/chưa biết.
  int? _tripRoom;

  int _newTripsExcept(int k) => _tripChoice.entries.where((e) => e.key != k && e.value == _newTrip).length;

  bool _canCreateTrip(int k) => _tripRoom == null || _tripChoice[k] == _newTrip || _newTripsExcept(k) < _tripRoom!;

  Future<void> _pick() async {
    final file = await ref.read(filePickerProvider)();
    if (file == null || !mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _busy = true;
      _failed = false;
      _cancelled = false;
      _fileName = file.name;
      _preview = null;
    });
    try {
      final packs = await ref.read(nluPackSourcesProvider(lang).future);
      final airports = await ref.read(airportsTsvProvider.future);
      final req = ImportRequest(
        name: file.name,
        bytes: file.bytes,
        packSources: packs,
        airportsTsv: airports,
        now: ref.read(nowProvider)(),
        region: ref.read(deviceRegionProvider),
      );
      await _decode(req);
    } on Object {
      if (mounted && !_cancelled) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decode(ImportRequest req) async {
    setState(() => _busy = true);
    try {
      final preview = await ref.read(importDecoderProvider)(req);
      if (_cancelled) return;
      final trips = ref.read(tripsRepositoryProvider);
      final existing = await trips.bookingsWithCodes({for (final c in preview.candidates) ?c.fields.confirmationCode});
      final today = CivilDate.of(ref.read(nowProvider)()).toIso();
      final active = [for (final t in await trips.trips()) if (t.activeOn(today)) t];
      final quota = await ref.read(syncEngineProvider).cachedQuota();
      if (!mounted) return;
      final matches = matchExistingBookings(preview.candidates, existing, deviceTz: ref.read(deviceTimeZoneProvider));
      setState(() {
        _request = req;
        _preview = preview;
        _edits.clear();
        _matches = matches;
        _activeTrips = active;
        _quota = quota;
        _tripRoom = quota == null || quota.isUnlimited(EntitlementKey.maxActiveTrips)
            ? null
            : (quota.limit(EntitlementKey.maxActiveTrips) - active.length).clamp(0, 1 << 20);
        _selected = [
          for (var i = 0; i < preview.candidates.length; i++)
            (!preview.candidates[i].done || preview.candidates.every((x) => x.done)) && !(matches[i]?.duplicate ?? false),
        ];
        _tripChoice.clear();
        for (var k = 0; k < preview.trips.length; k++) {
          final choice = _defaultTrip(preview.trips[k], matches, active);
          // Hết lượt chuyến đi: vé vẫn lưu, chỉ không gộp (không để server từ chối chuyến khi sync).
          _tripChoice[k] = choice == _newTrip && !_canCreateTrip(k) ? _noTrip : choice;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Đặt chỗ đã thuộc 1 chuyến → chuyến đó; khoảng ngày chồng chuyến đang có → chuyến đó; chắc là chuyến mới → tạo; vé lẻ → không gộp.
  static String _defaultTrip(TripSuggestion s, List<BookingMatch?> matches, List<TripSummary> active) {
    for (final i in s.indices) {
      if (matches[i]?.tripId case final id? when active.any((t) => t.id == id)) return id;
    }
    final overlap = active.where((t) => t.overlaps(s.startsOn, s.endsOn)).firstOrNull;
    if (overlap != null) return overlap.id;
    return s.confident ? _newTrip : _noTrip;
  }

  String _newTripTitle(BuildContext context, TripSuggestion s) {
    final l = AppLocalizations.of(context);
    return s.destination != null
        ? l.tripTitleTo(s.destination!)
        : l.tripTitleOn(Fmt.of(context).date(DateTime.parse(s.startsOn), now: ref.read(nowProvider)()));
  }

  String? _titleOf(int i) => _candidate(i).fields.title ?? fallbackTitle(_candidate(i));

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final preview = _preview!;
    final tz = ref.read(deviceTimeZoneProvider);
    final labels = ImportNoteLabels(
      bookingCode: l.importBookingCode,
      seat: l.importSeat,
      carriage: l.importCarriage,
      department: l.importDepartment,
      queueNumber: l.importQueueNumber,
    );
    // Chuyến đi được chọn (chỉ khi có ít nhất 1 mục của nó được chọn) → TripDraft; mục trỏ tới bằng tripIndex.
    final trips = <TripDraft>[];
    final tripOf = <int, int>{};
    for (var k = 0; k < preview.trips.length; k++) {
      final s = preview.trips[k], choice = _tripChoice[k] ?? _noTrip;
      final members = s.indices.where((i) => _selected[i]).toList();
      if (choice == _noTrip || members.isEmpty) continue;
      trips.add(TripDraft(
        existingTripId: choice == _newTrip ? null : choice,
        title: choice == _newTrip ? _newTripTitle(context, s) : null,
        destination: s.destination,
        startsOn: s.startsOn,
        endsOn: s.endsOn,
      ));
      for (final i in members) {
        tripOf[i] = trips.length - 1;
      }
    }
    final drafts = [
      for (var i = 0; i < preview.candidates.length; i++)
        if (_selected[i] && _titleOf(i) != null)
          toImportedItem(
            _candidate(i),
            title: _titleOf(i)!,
            deviceTz: tz,
            labels: labels,
            defaults: i < preview.reminderDefaults.length ? preview.reminderDefaults[i] : null,
            tripIndex: tripOf[i],
            updateItemId: _matches.length > i && !(_matches[i]?.duplicate ?? true) ? _matches[i]!.itemId : null,
          ),
    ];
    setState(() => _busy = true);
    final result = await ref.read(importsRepositoryProvider).commit(
          ImportRecord(
            kind: preview.recordKind,
            bytes: _request!.bytes.length,
            docLanguage: preview.docLanguage,
            docType: preview.docType?.wire ??
                (preview.format == ImportFormat.csv || preview.format == ImportFormat.xlsx || preview.format == ImportFormat.markdown
                    ? 'todo_list'
                    : null),
            tierUsed: preview.tierUsed,
            templateId: preview.templateId?.split('@').first,
            templateVersion: int.tryParse(preview.templateId?.split('@').last ?? ''),
          ),
          drafts,
          deviceTz: tz,
          trips: trips,
          quota: _quota,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = (
        titles: [for (var i = 0; i < preview.candidates.length; i++) if (_selected[i] && _titleOf(i) != null) _titleOf(i)!],
        tripId: result.tripIds.firstOrNull,
        pending: result.pendingQuota,
      );
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  /// Mục đang chọn đầu tiên còn trường phải kiểm tra: nút chính mở form của mục này thay vì lưu (Figma 15).
  int? get _firstToCheck {
    for (var i = 0; i < _selected.length; i++) {
      if (_selected[i] && keysToCheck(_candidate(i)).isNotEmpty) return i;
    }
    return null;
  }

  Future<void> _edit(int i) async {
    final edited = await editCandidate(context, _candidate(i), today: CivilDate.of(ref.read(nowProvider)()), title: _titleOf(i));
    if (edited != null && mounted) setState(() => _edits[i] = edited);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final preview = _preview;
    final reviewing = !_busy && preview != null && preview.candidates.isNotEmpty;
    final count = reviewing ? _selected.where((s) => s).length : 0;
    final missingTitle = reviewing && [for (var i = 0; i < _selected.length; i++) if (_selected[i]) i].any((i) => _titleOf(i) == null);
    final toCheck = reviewing ? _firstToCheck : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(_saved != null
            ? l.importSavedTitle
            : reviewing
                ? l.importReviewTitle
                : _busy && preview == null
                    ? l.importReadingTitle
                    : _failed || preview != null
                        ? l.importUnreadTitle
                        : l.importTitle),
      ),
      bottomNavigationBar: _saved != null
          ? _savedButtons(context)
          : !reviewing
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.importUnsavedNote, style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: Tokens.space3),
                    FilledButton.icon(
                      key: const Key('importAdd'),
                      icon: AppIcon(AppIcons.tick, size: 20, color: theme.colorScheme.onPrimary),
                      label: Text(toCheck != null ? l.importCheckToContinue : l.importAdd(count)),
                      onPressed: toCheck != null
                          ? () => _edit(toCheck)
                          : count == 0 || missingTitle
                              ? null
                              : _save,
                    ),
                  ],
                ),
              ),
            ),
      body: _saved != null
          ? _savedView(context)
          : _busy && preview == null
              ? _reading(context)
              : _busy
                  ? const Center(child: CircularProgressIndicator())
                  : reviewing
                      ? _review(context, preview)
                      : preview == null && !_failed
                          ? _intro(context)
                          : _unread(context, preview),
    );
  }

  TextStyle? _small(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurfaceVariant);

  Widget _box(BuildContext context, {required Widget child, Color? color, EdgeInsetsGeometry? padding, Key? key}) => Container(
        key: key,
        padding: padding ?? const EdgeInsetsDirectional.all(Tokens.space4),
        decoration: BoxDecoration(color: color ?? Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
        child: child,
      );

  Widget _infoCard(BuildContext context, AppIcons icon, String title, String body, Color fg, Color bg) => _box(
        context,
        color: bg,
        child: Row(
          children: [
            AppIcon(icon, size: 22, color: fg),
            const SizedBox(width: Tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: fg)),
                  Text(body, style: _small(context)),
                ],
              ),
            ),
          ],
        ),
      );

  /// Màn 13: chọn nguồn. Chụp / thư viện ảnh chờ OCR trên máy (Sắp có); tệp và bảng tính mở bộ chọn tệp.
  Widget _intro(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    Widget source(Key key, AppIcons? icon, IconData? material, String title, String hint, {VoidCallback? onTap}) => Padding(
          padding: const EdgeInsetsDirectional.only(top: Tokens.space3),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(Tokens.radiusXl),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: key,
              onTap: onTap,
              child: Opacity(
                opacity: onTap == null ? 0.55 : 1,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space4, 14, Tokens.space3, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: icon != null ? AppIcon(icon, size: 20, color: scheme.primary) : Icon(material, size: 20, color: scheme.primary),
                      ),
                      const SizedBox(width: Tokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            Text(onTap == null ? [l.meComingSoon, hint].join(' · ') : hint, style: _small(context)),
                          ],
                        ),
                      ),
                      if (onTap != null) AppIcon(AppIcons.chevronSmall, size: 17, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space6),
      children: [
        _box(
          context,
          color: scheme.primaryContainer,
          padding: const EdgeInsetsDirectional.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.importHeadline, style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, height: 1.3)),
              const SizedBox(height: Tokens.space2),
              Text(l.importHeadlineBody, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space5),
        Text(l.importFromWhere, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        source(const Key('importCamera'), AppIcons.camera, null, l.importCamera, l.importCameraHint),
        source(const Key('importPhotos'), AppIcons.image, null, l.importPhotos, l.importPhotosHint),
        source(const Key('importPick'), AppIcons.file, null, l.importFileRow, l.importFormats, onTap: _pick),
        source(const Key('importPickSheet'), null, Icons.table_chart_outlined, l.importSpreadsheet, l.importSheetHint, onTap: _pick),
        const SizedBox(height: Tokens.space4),
        _infoCard(context, AppIcons.shield, l.importOnDevice, l.importOnDeviceBody, colors.travel, colors.travelContainer),
      ],
    );
  }

  /// Màn 14: đang giải mã trên máy, có thể hủy.
  Widget _reading(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space6),
      children: [
        _box(
          context,
          key: const Key('importReading'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIcon(AppIcons.file, size: 22, color: scheme.primary),
                  const SizedBox(width: Tokens.space3),
                  Expanded(child: Text(_fileName ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: Tokens.space4),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(minHeight: 6)),
              const SizedBox(height: Tokens.space2),
              Text(l.importReadingBody, style: _small(context)),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space4),
        _infoCard(context, AppIcons.shield, l.importOnDevice, l.importOnDeviceReview, scheme.primary, scheme.primaryContainer),
        const SizedBox(height: Tokens.space5),
        OutlinedButton.icon(
          key: const Key('importCancel'),
          onPressed: () => setState(() {
            _cancelled = true;
            _busy = false;
          }),
          icon: AppIcon(AppIcons.close, size: 18, color: scheme.primary),
          label: Text(l.importCancel),
        ),
      ],
    );
  }

  /// Màn 25: không đọc được / không tìm thấy gì / định dạng chưa hỗ trợ. Không tạo gì, không tính lượt.
  Widget _unread(BuildContext context, ImportPreview? preview) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final reason = switch (preview) {
      _ when _failed => l.importFailed,
      ImportPreview(format: ImportFormat.unsupported) => l.importUnsupported,
      _ => l.importNothingFound,
    };
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space6),
      children: [
        _box(
          context,
          key: const Key('importUnread'),
          padding: const EdgeInsetsDirectional.all(Tokens.space5),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.warningContainer, borderRadius: BorderRadius.circular(18)),
                child: AppIcon(AppIcons.alert, size: 30, color: colors.onWarningContainer),
              ),
              const SizedBox(height: Tokens.space4),
              Text(l.importUnreadHeadline, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: Tokens.space2),
              Text(reason, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (_fileName != null) ...[
          const SizedBox(height: Tokens.space4),
          _box(
            context,
            child: Row(
              children: [
                AppIcon(AppIcons.file, size: 22, color: scheme.onSurfaceVariant),
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fileName!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(l.importNotCounted, style: _small(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Tokens.space5),
        Text(l.importTips, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: Tokens.space2),
        for (final t in [l.importTip1, l.importTip2])
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Tokens.space1),
            child: Text('• $t', style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: Tokens.space5),
        FilledButton.icon(
          key: const Key('importPick'),
          icon: AppIcon(AppIcons.file, size: 20, color: scheme.onPrimary),
          label: Text(l.importPickAnother),
          onPressed: _pick,
        ),
        const SizedBox(height: Tokens.space3),
        FilledButton.tonalIcon(
          key: const Key('importManual'),
          style: FilledButton.styleFrom(backgroundColor: scheme.primaryContainer, foregroundColor: scheme.primary),
          icon: AppIcon(AppIcons.edit, size: 20, color: scheme.primary),
          label: Text(l.importManual),
          onPressed: () => showQuickAdd(context),
        ),
      ],
    );
  }

  /// Màn 26: đã lưu.
  Widget _savedView(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = RemindColors.of(context);
    final saved = _saved!;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space6),
      children: [
        _box(
          context,
          key: const Key('importSaved'),
          padding: const EdgeInsetsDirectional.all(Tokens.space5),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.travelContainer, shape: BoxShape.circle),
                child: AppIcon(AppIcons.tick, size: 30, color: colors.travel),
              ),
              const SizedBox(height: Tokens.space4),
              Text(l.importAdded(saved.titles.length), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: Tokens.space2),
              Text(l.importSavedBody, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Tokens.space4),
        _box(
          context,
          child: Column(
            children: [
              for (final (i, t) in saved.titles.indexed) ...[
                if (i > 0) const Divider(height: Tokens.space5),
                Row(
                  children: [
                    Expanded(child: Text(t, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                    AppIcon(AppIcons.tick, size: 18, color: colors.travel),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (saved.pending) ...[
          const SizedBox(height: Tokens.space4),
          _infoCard(context, AppIcons.alert, l.mePlanUsage, l.importPendingQuotaNote, colors.onWarningContainer, colors.warningContainer),
        ],
      ],
    );
  }

  Widget _savedButtons(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final trip = _saved!.tripId;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (trip != null) ...[
              FilledButton.icon(
                key: const Key('importOpenTrip'),
                icon: AppIcon(AppIcons.trip, size: 20, color: scheme.onPrimary),
                label: Text(l.importOpenTrip),
                onPressed: () => context.go('/trips/$trip'),
              ),
              const SizedBox(height: Tokens.space3),
            ],
            (trip == null ? FilledButton.new : OutlinedButton.new)(
              key: const Key('importDone'),
              onPressed: _close,
              child: Text(l.settingsDone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _review(BuildContext context, ImportPreview preview) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = RemindColors.of(context);
    final isTable = preview.format == ImportFormat.csv || preview.format == ImportFormat.xlsx;
    final needCheck = [for (var i = 0; i < _selected.length; i++) if (_selected[i] && keysToCheck(_candidate(i)).isNotEmpty) i];
    final selected = _selected.where((s) => s).length;
    const gap = SizedBox(height: Tokens.space4);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
      children: [
        Text(l.importReviewHint, style: theme.textTheme.bodySmall),
        gap,
        _sourceCard(context, preview),
        if (preview.sheetNames.length > 1) ...[
          gap,
          Row(
            children: [
              Expanded(child: Text(l.importSheet, style: theme.textTheme.titleSmall)),
              DropdownButton<int>(
                key: const Key('importSheet'),
                value: preview.sheetIndex,
                items: [
                  for (var i = 0; i < preview.sheetNames.length; i++) DropdownMenuItem(value: i, child: Text(preview.sheetNames[i])),
                ],
                onChanged: (i) => i == null ? null : _decode(_request!.copyWith(sheetIndex: i)),
              ),
            ],
          ),
        ],
        if (isTable && (preview.dateOrderAmbiguous || _request!.dateOrder != null)) ...[
          gap,
          Text(l.importDateOrderQuestion, style: theme.textTheme.titleSmall),
          const SizedBox(height: Tokens.space2),
          Wrap(
            spacing: Tokens.space2,
            runSpacing: Tokens.space2,
            children: [
              for (final (order, label) in [('dmy', l.importDateOrderDmy), ('mdy', l.importDateOrderMdy)])
                ChoiceChip(
                  key: Key('importOrder-$order'),
                  label: Text(label),
                  selected: preview.dateOrder == order,
                  onSelected: (_) => _decode(_request!.copyWith(dateOrder: order)),
                ),
            ],
          ),
        ],
        if (needCheck.isNotEmpty) ...[
          gap,
          _banner(
            context,
            key: const Key('importNeedsCheck'),
            background: colors.warningContainer,
            foreground: colors.onWarningContainer,
            icon: AppIcons.alert,
            title: l.importNeedsCheck(needCheck.length),
            hint: l.importNeedsCheckHint,
            onTap: () => _edit(needCheck.first),
          ),
        ] else if (_edits.isNotEmpty && selected > 0) ...[
          gap,
          _banner(
            context,
            key: const Key('importReady'),
            background: colors.travelContainer,
            foreground: colors.travel,
            icon: AppIcons.tick,
            title: l.importReady,
            hint: l.importReadyHint(selected),
          ),
        ],
        for (var i = 0; i < preview.candidates.length; i++) ...[gap, _card(context, i, _candidate(i))],
        for (var k = 0; k < preview.trips.length; k++) ...[gap, _tripCard(context, k, preview.trips[k])],
        ?_quotaCard(context),
      ],
    );
  }

  /// Tệp nguồn: tên, tiêu đề email, số mục tìm thấy, tệp đính kèm chưa đọc được.
  Widget _sourceCard(BuildContext context, ImportPreview preview) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondary = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsetsDirectional.all(Tokens.space3),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          AppIcon(AppIcons.file, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_request!.name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
                if (preview.subject != null) Text(preview.subject!, style: secondary),
                Text(l.importFound(preview.candidates.length), style: secondary),
                if (preview.pendingAttachments.isNotEmpty)
                  Text(l.importPendingAttachments(preview.pendingAttachments.length, preview.pendingAttachments.join(', ')), style: secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner(
    BuildContext context, {
    required Key key,
    required Color background,
    required Color foreground,
    required AppIcons icon,
    required String title,
    required String hint,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Row(
            children: [
              AppIcon(icon, size: 22, color: foreground),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
                    const SizedBox(height: Tokens.space1),
                    Text(hint, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Gộp vào: Chuyến Hà Nội ›" (UX §2.4, Figma 15): chạm để chọn chuyến mới / có sẵn / không gộp.
  Widget _tripCard(BuildContext context, int k, TripSuggestion s) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = RemindColors.of(context);
    final choice = _tripChoice[k] ?? _noTrip;
    final fmt = Fmt.of(context);
    final now = ref.read(nowProvider)();
    final first = fmt.date(DateTime.parse(s.startsOn), now: now);
    final range = s.endsOn == s.startsOn ? first : l.tripDates(first, fmt.date(DateTime.parse(s.endsOn), now: now));
    final title = switch (choice) {
      _newTrip => l.importTripNew(_newTripTitle(context, s)),
      _noTrip => l.importTripNone,
      _ => _activeTrips.where((t) => t.id == choice).firstOrNull?.title ?? l.navTrips,
    };
    final secondary = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant);
    return Material(
      color: colors.travelContainer,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('importTrip-$k'),
        onTap: () => _chooseTrip(k, s),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          child: Row(
            children: [
              AppIcon(AppIcons.trip, size: 25, color: colors.travel),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.importTripLabel, style: secondary),
                    Text(title, key: Key('importTripChoice-$k'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(range, style: secondary),
                    if (!_canCreateTrip(k))
                      Text(l.importTripLimit(_quota!.limit(EntitlementKey.maxActiveTrips)), key: Key('importTripLimit-$k'), style: secondary),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevron, size: 18, color: colors.travel),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseTrip(int k, TripSuggestion s) async {
    final l = AppLocalizations.of(context);
    final current = _tripChoice[k] ?? _noTrip;
    final options = [
      (_newTrip, l.importTripNew(_newTripTitle(context, s)), _canCreateTrip(k)),
      for (final t in _activeTrips) (t.id, t.title ?? l.navTrips, true),
      (_noTrip, l.importTripNone, true),
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.screenMargin),
                child: Text(l.importTripChoose, style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final (value, label, enabled) in options)
                ListTile(
                  key: Key('importTripOption-$k-$value'),
                  enabled: enabled,
                  leading: Icon(value == current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _tripChoice[k] = picked);
  }

  /// Hạn mức lịch hẹn đang hoạt động theo cache `quota_status` (không có cache hoặc không giới hạn thì không hiện).
  Widget? _quotaCard(BuildContext context) {
    final quota = _quota;
    if (quota == null || quota.isUnlimited(EntitlementKey.maxActiveAppointments)) return null;
    final adding = [
      for (var i = 0; i < _selected.length; i++)
        if (_selected[i] && _candidate(i).kind != CandidateKind.task && !(_matches.length > i && _matches[i] != null)) i,
    ].length;
    if (adding == 0) return null;
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final room = (quota.limit(EntitlementKey.maxActiveAppointments) - quota.used(EntitlementKey.maxActiveAppointments)).clamp(0, 1 << 20);
    final left = room - adding;
    final secondary = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Tokens.space4),
      child: Container(
        key: const Key('importQuota'),
        padding: const EdgeInsetsDirectional.all(14),
        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        child: Row(
          children: [
            AppIcon(left < 0 ? AppIcons.alert : AppIcons.tick, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: Tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.importApptRoom(room), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: Tokens.space1),
                  Text(left < 0 ? l.importApptOver(-left) : l.importApptAfter(adding, left), style: secondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, int i, Candidate c) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = RemindColors.of(context);
    final fmt = Fmt.of(context);
    final title = _titleOf(i);
    final tz = ref.read(deviceTimeZoneProvider);
    final today = CivilDate.of(ref.read(nowProvider)());
    final f = c.fields;
    final isHotel = c.bookingType == BookingType.hotel;
    final start = resolveLocalTime(c.kind == CandidateKind.task ? (f.due ?? f.startsAt) : (f.startsAt ?? f.checkIn ?? f.due), tz);
    final end = c.kind == CandidateKind.task ? null : resolveLocalTime(isHotel ? f.checkOut : f.endsAt, tz);
    String? code(Place? p) => p?.code;
    final from = code(f.origin), to = code(f.destination);
    final route = from != null && to != null;
    final secondary = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant);
    final when = [
      if (start != null) fmt.civil(start.wall(), today: today),
      if (end != null)
        switch (c.bookingType) {
          BookingType.hotel => [l.tripCheckOut, fmt.civil(end.wall(), today: today)].join(' · '),
          BookingType.flight || BookingType.train || BookingType.bus || BookingType.ferry => l.calendarArrives(fmt.civil(end.wall(), today: today)),
          _ => [l.importFieldEnd, fmt.civil(end.wall(), today: today)].join(' · '),
        },
    ];
    final footer = [
      if (f.confirmationCode != null && c.kind != CandidateKind.task) l.importBookingCode(f.confirmationCode!),
      if (c.listName != null) l.importListName(c.listName!),
      if (c.checklist.isNotEmpty) l.importChecklistCount(c.checklist.length),
      if (c.done) l.importDoneTag,
      if (_matches.length > i && _matches[i] != null) _matches[i]!.duplicate ? l.importDuplicate : l.importWillUpdate,
    ];
    final issues = [for (final issue in c.issues) ?_issueText(l, issue)];
    final toCheck = keysToCheck(c);
    final checked = checkedKeys(_preview!.candidates[i], c);
    final labels = (toCheck.isNotEmpty ? toCheck : checked).map((k) => fieldLabel(l, c, k)).join(', ');
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('importItem-$i'),
        onTap: () => _edit(i),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space4, Tokens.space2, Tokens.space2, Tokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    key: Key('importCheck-$i'),
                    value: _selected[i],
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    onChanged: (v) => setState(() => _selected[i] = v ?? false),
                  ),
                  const SizedBox(width: Tokens.space1),
                  Expanded(
                    child: Text(
                      title ?? l.importNoTitle,
                      style: title == null
                          ? theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error, fontStyle: FontStyle.italic)
                          : theme.textTheme.titleMedium?.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (c.rrule != null) Icon(Icons.repeat, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  IconButton(
                    key: Key('importEdit-$i'),
                    tooltip: l.importEdit,
                    icon: AppIcon(AppIcons.edit, size: 20, color: theme.colorScheme.primary),
                    onPressed: () => _edit(i),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: Tokens.space2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (route) ...[
                      const SizedBox(height: Tokens.space1),
                      Row(
                        children: [
                          Expanded(child: Text(from, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 25, height: 36 / 25))),
                          AppIcon(AppIcons.plane, size: 24, color: colors.travel),
                          const SizedBox(width: 10),
                          Text(to, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 25, height: 36 / 25)),
                        ],
                      ),
                    ],
                    if (when.isNotEmpty) ...[
                      const SizedBox(height: Tokens.space2),
                      Row(
                        children: [
                          if (!route) ...[_typeIcon(context, c), const SizedBox(width: 10)],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(when.first, style: theme.textTheme.titleSmall),
                                for (final w in when.skip(1)) Text(w, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    for (final issue in issues)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: Tokens.space1),
                        child: Text(issue, style: secondary?.copyWith(color: colors.onWarningContainer)),
                      ),
                    if (labels.isNotEmpty) ...[
                      const SizedBox(height: Tokens.space3),
                      _checkTile(context, i, done: toCheck.isEmpty, labels: labels),
                    ],
                    if (footer.isNotEmpty) ...[
                      const SizedBox(height: Tokens.space3),
                      Text(footer.join(' · '), style: secondary),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ô "Cần kiểm tra: Bắt đầu, Kết thúc ›" (vàng) hoặc "Đã kiểm tra" (xanh) trong thẻ mục.
  Widget _checkTile(BuildContext context, int i, {required bool done, required String labels}) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = RemindColors.of(context);
    final fg = done ? colors.travel : colors.onWarningContainer;
    return Material(
      color: done ? colors.travelContainer : colors.warningContainer,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key(done ? 'importChecked-$i' : 'importWarn-$i'),
        onTap: () => _edit(i),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space3),
          child: Row(
            children: [
              AppIcon(done ? AppIcons.tick : AppIcons.alert, size: 18, color: fg),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(done ? l.importCheckedTile(labels) : l.importCheckTile(labels),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: fg)),
                    Text(done ? l.importCheckedTileHint : l.importCheckTileHint,
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronSmall, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeIcon(BuildContext context, Candidate c) {
    final color = RemindColors.of(context).travel;
    return switch (c.bookingType) {
      BookingType.flight => AppIcon(AppIcons.plane, size: 24, color: color),
      BookingType.hotel => AppIcon(AppIcons.hotel, size: 24, color: color),
      _ => Icon(_icon(c), size: 24, color: c.kind == CandidateKind.task ? Theme.of(context).colorScheme.onSurfaceVariant : color),
    };
  }

  static String? _issueText(AppLocalizations l, String issue) => switch (issue) {
        'past_date' => l.importIssuePastDate,
        'arrival_next_day' => l.importIssueNextDay,
        'date_order_ambiguous' => l.importIssueDateOrder,
        'check_out_before_check_in' => l.importIssueCheckOut,
        _ => null,
      };

  static IconData _icon(Candidate c) => switch (c.bookingType) {
        BookingType.flight => Icons.flight,
        BookingType.train => Icons.train,
        BookingType.bus => Icons.directions_bus,
        BookingType.hotel => Icons.hotel,
        BookingType.ferry => Icons.directions_boat,
        BookingType.carRental => Icons.directions_car,
        BookingType.restaurant => Icons.restaurant,
        BookingType.eventTicket => Icons.confirmation_number_outlined,
        BookingType.tour || BookingType.other => Icons.event,
        null => c.kind == CandidateKind.task ? Icons.check_circle_outline : Icons.event,
      };
}
