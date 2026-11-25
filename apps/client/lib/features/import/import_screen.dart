import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
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
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decode(ImportRequest req) async {
    setState(() => _busy = true);
    try {
      final preview = await ref.read(importDecoderProvider)(req);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.importAdded(result.itemIds.length + result.updatedItemIds.length))));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final preview = _preview;
    final reviewing = !_busy && preview != null && preview.candidates.isNotEmpty;
    final count = reviewing ? _selected.where((s) => s).length : 0;
    final missingTitle = reviewing && [for (var i = 0; i < _selected.length; i++) if (_selected[i]) i].any((i) => _titleOf(i) == null);
    return Scaffold(
      appBar: AppBar(title: Text(reviewing ? l.importReviewTitle : l.importTitle)),
      bottomNavigationBar: !reviewing
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(Tokens.space4),
                child: FilledButton(
                  key: const Key('importAdd'),
                  onPressed: count == 0 || missingTitle ? null : _save,
                  child: Text(l.importAdd(count)),
                ),
              ),
            ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : reviewing
              ? _review(context, preview)
              : _message(context, preview),
    );
  }

  Widget _message(BuildContext context, ImportPreview? preview) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, text) = switch (preview) {
      _ when _failed => (Icons.error_outline, l.importFailed),
      null => (Icons.upload_file_outlined, l.importIntro),
      ImportPreview(format: ImportFormat.unsupported) => (Icons.hourglass_empty, l.importUnsupported),
      _ => (Icons.search_off, l.importNothingFound),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(Tokens.screenMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: Tokens.space4),
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            if (preview == null && !_failed) ...[
              const SizedBox(height: Tokens.space2),
              Text(l.importFormats, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: Tokens.space6),
            FilledButton.icon(
              key: const Key('importPick'),
              icon: const Icon(Icons.folder_open),
              label: Text(preview == null && !_failed ? l.importPickFile : l.importPickAnother),
              onPressed: _pick,
            ),
          ],
        ),
      ),
    );
  }

  Widget _review(BuildContext context, ImportPreview preview) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTable = preview.format == ImportFormat.csv || preview.format == ImportFormat.xlsx;
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: Tokens.space6),
      children: [
        ListTile(
          title: Text(l.importFound(preview.candidates.length), style: theme.textTheme.titleMedium),
          subtitle: preview.subject == null ? null : Text(preview.subject!),
        ),
        if (preview.pendingAttachments.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(l.importPendingAttachments(preview.pendingAttachments.length, preview.pendingAttachments.join(', '))),
          ),
        if (preview.sheetNames.length > 1)
          ListTile(
            title: Text(l.importSheet),
            trailing: DropdownButton<int>(
              key: const Key('importSheet'),
              value: preview.sheetIndex,
              items: [
                for (var i = 0; i < preview.sheetNames.length; i++) DropdownMenuItem(value: i, child: Text(preview.sheetNames[i])),
              ],
              onChanged: (i) => i == null ? null : _decode(_request!.copyWith(sheetIndex: i)),
            ),
          ),
        if (isTable && (preview.dateOrderAmbiguous || _request!.dateOrder != null))
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.screenMargin, vertical: Tokens.space2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.importDateOrderQuestion, style: theme.textTheme.bodyMedium),
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
            ),
          ),
        const Divider(),
        for (var k = 0; k < preview.trips.length; k++) _tripRow(context, k, preview.trips[k]),
        for (var i = 0; i < preview.candidates.length; i++) _tile(context, i, _candidate(i)),
      ],
    );
  }

  /// "Gộp vào: [Chuyến Hà Nội ▾]" (UX §2.4).
  Widget _tripRow(BuildContext context, int k, TripSuggestion s) {
    final l = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.luggage_outlined),
      title: Text(l.importTripLabel),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tripDropdown(context, k, s),
          if (!_canCreateTrip(k))
            Text(
              l.importTripLimit(_quota!.limit(EntitlementKey.maxActiveTrips)),
              key: Key('importTripLimit-$k'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _tripDropdown(BuildContext context, int k, TripSuggestion s) {
    final l = AppLocalizations.of(context);
    return DropdownButton<String>(
      key: Key('importTrip-$k'),
      isExpanded: true,
      value: _tripChoice[k] ?? _noTrip,
      items: [
        DropdownMenuItem(
          value: _newTrip,
          enabled: _canCreateTrip(k),
          child: Text(l.importTripNew(_newTripTitle(context, s)), overflow: TextOverflow.ellipsis),
        ),
        for (final t in _activeTrips)
          DropdownMenuItem(value: t.id, child: Text(t.title ?? l.navTrips, overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: _noTrip, child: Text(l.importTripNone)),
      ],
      onChanged: (v) => setState(() => _tripChoice[k] = v ?? _noTrip),
    );
  }

  Widget _tile(BuildContext context, int i, Candidate c) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = _titleOf(i);
    final tz = ref.read(deviceTimeZoneProvider);
    final today = CivilDate.of(ref.read(nowProvider)());
    final f = c.fields;
    final start = resolveLocalTime(c.kind == CandidateKind.task ? (f.due ?? f.startsAt) : (f.startsAt ?? f.checkIn ?? f.due), tz);
    final lines = <String>[
      if (start != null) Fmt.of(context).civil(start.wall(), today: today),
      if (c.listName != null) l.importListName(c.listName!),
      if (c.checklist.isNotEmpty) l.importChecklistCount(c.checklist.length),
      if (f.confirmationCode != null && c.kind != CandidateKind.task) l.importBookingCode(f.confirmationCode!),
      if (_matches.length > i && _matches[i] != null) _matches[i]!.duplicate ? l.importDuplicate : l.importWillUpdate,
      for (final issue in c.issues) ?_issueText(l, issue),
      // Tầng luật T2: trường đọc theo nhãn/mẫu chung (độ tin cậy thấp) cần người dùng xem lại; sửa ở form thì hết (E5.1).
      if (needsCheck(c)) l.importCheckFields,
    ];
    return ListTile(
      key: Key('importItem-$i'),
      leading: Checkbox(
        key: Key('importCheck-$i'),
        value: _selected[i],
        onChanged: (v) => setState(() => _selected[i] = v ?? false),
      ),
      title: Text(
        title ?? l.importNoTitle,
        style: title == null ? TextStyle(color: theme.colorScheme.error, fontStyle: FontStyle.italic) : null,
      ),
      subtitle: lines.isEmpty ? null : Text(lines.join('\n')),
      isThreeLine: lines.length > 1,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.done) Chip(label: Text(l.importDoneTag), visualDensity: VisualDensity.compact),
          if (c.rrule != null) Icon(Icons.repeat, size: 18, color: theme.colorScheme.onSurfaceVariant),
          if (needsCheck(c)) Icon(Icons.info_outline, key: Key('importWarn-$i'), size: 18, color: RemindColors.of(context).warning),
          Icon(_icon(c), color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: () async {
        final edited = await editCandidate(context, c, today: today, title: title);
        if (edited != null) setState(() => _edits[i] = edited);
      },
    );
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
