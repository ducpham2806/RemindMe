import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/text_prompt.dart';
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
  final Map<int, String> _titles = {};

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
      if (!mounted) return;
      setState(() {
        _request = req;
        _preview = preview;
        _titles.clear();
        _selected = [for (final c in preview.candidates) !c.done || preview.candidates.every((x) => x.done)];
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _titleOf(int i) => _titles[i] ?? _preview!.candidates[i].fields.title ?? fallbackTitle(_preview!.candidates[i]);

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final preview = _preview!;
    final tz = ref.read(deviceTimeZoneProvider);
    final drafts = [
      for (var i = 0; i < preview.candidates.length; i++)
        if (_selected[i] && _titleOf(i) != null)
          toImportedItem(preview.candidates[i], title: _titleOf(i)!, deviceTz: tz, confirmationLine: l.importBookingCode),
    ];
    setState(() => _busy = true);
    final result = await ref.read(importsRepositoryProvider).commit(
          ImportRecord(
            kind: preview.recordKind,
            bytes: _request!.bytes.length,
            docLanguage: preview.docLanguage,
            docType: preview.format == ImportFormat.csv || preview.format == ImportFormat.xlsx || preview.format == ImportFormat.markdown
                ? 'todo_list'
                : null,
          ),
          drafts,
          deviceTz: tz,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.importAdded(result.itemIds.length))));
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
        for (var i = 0; i < preview.candidates.length; i++) _tile(context, i, preview.candidates[i]),
      ],
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
      for (final issue in c.issues) ?_issueText(l, issue),
      // Tầng luật T2: trường đọc theo nhãn/mẫu chung (độ tin cậy < 0,7) cần người dùng xem lại (E5.1).
      if (c.fieldConfidence.values.any((v) => v < 0.7)) l.importCheckFields,
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
          Icon(_icon(c), color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: () async {
        final t = await askText(context, title: l.importItemName, initial: title, fieldKey: const Key('importName'));
        if (t != null) setState(() => _titles[i] = t);
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
