import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/reminders.dart';
import '../../l10n/app_localizations.dart';
import '../schedule/date_time_sheet.dart';

/// Quick Add (UX §2.2): gõ câu tự nhiên, NLU (V1) phân tích ngay khi gõ và hiện chip thời điểm / lặp / tag / ưu tiên.
/// Mơ hồ thì hiện lựa chọn, không đoán im lặng (voice-and-text-input.md §5). Mic (V2) thêm sau.
Future<void> showQuickAdd(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const QuickAddSheet(),
    );

/// Một việc đã phân tích + lựa chọn của người dùng ở các chip mơ hồ.
class _Draft {
  _Draft(this.result, this.fallbackTitle);
  final NluResult result;
  final String fallbackTitle;
  final Map<int, int> picks = {};
  /// Người dùng chạm chip thời điểm và chọn lại ngày/giờ: thay kết quả phân tích.
  CivilDateTime? manualWhen;
  /// Độ lệch nhắc (phút, âm = trước); null = không nhắc. Mặc định theo cài đặt Thông báo & nhắc (đúng giờ).
  int? reminder = 0;

  String get title => result.title.isEmpty ? fallbackTitle : result.title;

  /// Thời điểm sau khi áp lựa chọn: chip giờ đổi giờ (và ngày nếu giờ đó rơi sang mai), chip ngày đổi ngày.
  CivilDateTime? get when {
    if (manualWhen != null) return manualWhen;
    var w = result.when;
    if (w == null) return null;
    final hasDateAmb = result.ambiguities.any((a) => a.kind != AmbiguityKind.meridiem);
    for (final e in picks.entries) {
      final a = result.ambiguities[e.key], o = a.options[e.value];
      w = a.kind == AmbiguityKind.meridiem ? CivilDateTime(hasDateAmb ? w!.date : o.date, o.time) : CivilDateTime(o.date, w!.time);
    }
    return w;
  }
}

/// Lưu 1 việc đã phân tích từ câu tự nhiên (Thêm nhanh, onboarding C32). Trả id item.
/// [reminder]: độ lệch nhắc (phút); có thời điểm thì thêm nhắc, null = không nhắc.
Future<String> saveParsedItem(WidgetRef ref,
    {required String title, CivilDateTime? when, RecurrenceSpec? recurrence, List<String> tags = const [], int? priority, int? reminder}) async {
  final repo = ref.read(itemsRepositoryProvider);
  final tz = ref.read(deviceTimeZoneProvider);
  final today = CivilDate.of(ref.read(nowProvider)());
  // Âm lịch chưa có ngày ("đi chùa rằm"): lần đầu tiên từ hôm nay.
  if (when == null && recurrence != null) {
    when = Recurrence.fromRow(recurrence.toPayload()).nextAfter(CivilDateTime(today), CivilDateTime(today.addDays(-1)));
  }
  // Giờ tường theo múi giờ của máy → UTC (DateTime local của Dart dùng tzdata của OS).
  final local = when == null ? null : DateTime(when.date.year, when.date.month, when.date.day, when.time?.hour ?? 0, when.time?.minute ?? 0);
  // "#congviec" khớp list "Công việc" thì việc vào list đó (UX §2.2); tag vẫn giữ.
  String? listId;
  for (final t in tags) {
    listId = await ref.read(listsRepositoryProvider).matchTag(t);
    if (listId != null) break;
  }
  return repo.create(
    listId: listId,
    title: title,
    startsAt: when?.time == null ? null : local!.toUtc(),
    startDate: when != null && when.time == null ? when.date.toIso() : null,
    tz: when == null ? null : tz,
    priority: priority ?? 0,
    tags: tags,
    recurrence: recurrence?.toPayload(),
    recurrenceStart: recurrence == null ? null : (local ?? DateTime(today.year, today.month, today.day)).toUtc(),
    // Có thời điểm thì mặc định nhắc (chip 🔔 trong UX §2.2), đổi được ở chip.
    reminderOffsets: when == null || reminder == null ? const [] : [reminder],
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _text = TextEditingController();
  List<_Draft> _drafts = const [];
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _reparse(NluEngine? engine) {
    final raw = _text.text.trim();
    if (raw.isEmpty) {
      setState(() => _drafts = const []);
      return;
    }
    if (engine == null) {
      setState(() => _drafts = [_Draft(NluResult(title: raw), raw)..reminder = ref.read(defaultReminderProvider).value ?? 0]);
      return;
    }
    final ctx = NluContext(now: ref.read(nowProvider)(), region: ref.read(deviceRegionProvider));
    final reminder = ref.read(defaultReminderProvider).value ?? 0;
    setState(() => _drafts = [for (final r in engine.parseAll(raw, ctx)) _Draft(r, raw)..reminder = reminder]);
  }

  bool get _canSave => !_saving && _drafts.isNotEmpty && _drafts.every((d) => d.title.trim().isNotEmpty);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    for (final d in _drafts) {
      await saveParsedItem(ref,
          title: d.title, when: d.when, recurrence: d.result.recurrence, tags: d.result.tags, priority: d.result.priority, reminder: d.reminder);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final key = nluPackKey(Localizations.localeOf(context).languageCode);
    final engine = ref.watch(nluEngineProvider(key)).value;
    // Gói tải xong sau khi người dùng đã gõ: phân tích lại.
    ref.listen(nluEngineProvider(key), (_, next) => _reparse(next.value));
    final today = CivilDate.of(ref.watch(nowProvider)());
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final understood = _drafts.isNotEmpty && _drafts.every((d) => d.when != null);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: Tokens.screenMargin,
        end: Tokens.screenMargin,
        bottom: MediaQuery.viewInsetsOf(context).bottom + Tokens.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.quickAddTitle, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, height: 29 / 20)),
                ),
              ),
              IconButton(
                key: const Key('quickAddClose'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: AppIcon(AppIcons.close, size: 22, color: scheme.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(l.quickAddSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: Tokens.space4),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space4, vertical: Tokens.space2),
            decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
            child: TextField(
              key: const Key('quickAddField'),
              controller: _text,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 23, height: 33 / 23, fontWeight: FontWeight.w500),
              decoration: InputDecoration(hintText: l.quickAddHint, border: InputBorder.none, filled: false),
              onChanged: (_) => _reparse(engine),
              onSubmitted: (_) => _save(),
            ),
          ),
          // Chip có thể dài (nhiều việc, chữ lớn): phần này cuộn, ô nhập và nút Lưu luôn thấy.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_drafts.length > 1) ...[
                    const SizedBox(height: Tokens.space3),
                    Text(l.quickAddFoundN(_drafts.length), style: theme.textTheme.labelLarge),
                  ],
                  for (final (i, d) in _drafts.indexed)
                    _DraftChips(
                      key: Key('draft-$i'),
                      draft: d,
                      showTitle: _drafts.length > 1,
                      today: today,
                      onChanged: () => setState(() {}),
                    ),
                  if (understood) ...[
                    const SizedBox(height: Tokens.space3),
                    Row(
                      children: [
                        AppIcon(AppIcons.tick, size: 16, color: RemindColors.of(context).success),
                        const SizedBox(width: Tokens.space2),
                        Expanded(child: Text(l.quickAddUnderstood, style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant))),
                      ],
                    ),
                  ],
                  const SizedBox(height: Tokens.space4),
                  Row(
                    children: [
                      for (final (i, (icon, label, onTap)) in <(AppIcons, String, VoidCallback?)>[
                        (AppIcons.mic, l.quickAddVoice, null),
                        (AppIcons.camera, l.quickAddCamera, null),
                        (AppIcons.image, l.quickAddPhoto, null),
                        (AppIcons.file, l.quickAddFile, () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push('/import');
                        }),
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: Tokens.space2),
                        Expanded(child: _InputMethod(icon: icon, label: label, onTap: onTap)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.space4),
          FilledButton.icon(
            key: const Key('quickAddSave'),
            icon: AppIcon(AppIcons.tick, size: 20, color: _canSave ? scheme.onPrimary : scheme.onSurfaceVariant),
            onPressed: _canSave ? _save : null,
            label: Text(_drafts.length > 1 ? l.quickAddSaveAll : l.quickAddSave),
          ),
        ],
      ),
    );
  }
}

/// Nút cách nhập (Nói / Chụp / Ảnh / Tệp). Chưa làm thì mờ, đọc là "Sắp có".
class _InputMethod extends StatelessWidget {
  const _InputMethod({required this.icon, required this.label, this.onTap});
  final AppIcons icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: enabled ? label : [label, AppLocalizations.of(context).meComingSoon].join(' · '),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(Tokens.space3),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('quickAddMethod-${icon.name}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Tokens.space3),
              child: Column(
                children: [
                  AppIcon(icon, size: 22, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 7),
                  Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftChips extends StatelessWidget {
  const _DraftChips({super.key, required this.draft, required this.showTitle, required this.today, required this.onChanged});
  final _Draft draft;
  final bool showTitle;
  final CivilDate today;
  final VoidCallback onChanged;

  Future<void> _pickWhen(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final current = draft.when;
    final picked = await showDateTimeSheet(context,
        today: today,
        tz: container.read(deviceTimeZoneProvider),
        now: container.read(nowProvider)(),
        region: container.read(holidayRegionProvider).value ?? container.read(deviceRegionProvider),
        date: current?.date,
        time: current == null ? CivilTime(9) : current.time);
    if (picked == null) return;
    draft.manualWhen = CivilDateTime(picked.date, picked.time);
    onChanged();
  }

  Future<void> _pickReminder(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<(int?,)>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in <int?>[...reminderPresets, null])
              ListTile(
                key: Key('quickAddReminder-${m ?? 'none'}'),
                leading: Icon(m == draft.reminder ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(m == null ? l.quickAddNoReminder : describeReminderOffset(l, m)),
                onTap: () => Navigator.of(context).pop((m,)),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    draft.reminder = picked.$1;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final r = draft.result;
    final when = draft.when;
    final chips = <Widget>[
      if (when != null)
        _Pill(key: const Key('chipWhen'), icon: AppIcons.calendar, label: fmt.civil(when, today: today), onTap: () => _pickWhen(context)),
      for (final t in r.tags) _Pill(icon: AppIcons.list, label: t),
      if (when != null || r.recurrence != null)
        _Pill(
          key: const Key('chipReminder'),
          icon: AppIcons.bell,
          label: draft.reminder == null ? l.quickAddNoReminder : describeReminderOffset(l, draft.reminder!),
          onTap: () => _pickReminder(context),
        ),
      if (r.recurrence != null)
        _Pill(key: const Key('chipRepeat'), icon: AppIcons.repeat, label: describeRecurrence(context, r.recurrence!.toPayload())),
      if (r.priority != null)
        _Pill(
          materialIcon: Icons.flag_outlined,
          label: switch (r.priority!) { 1 => l.priorityLow, 2 => l.priorityMedium, _ => l.priorityHigh },
        ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Tokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[Text(draft.title, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: Tokens.space2)],
          if (chips.isNotEmpty) Wrap(spacing: Tokens.space2, runSpacing: Tokens.space2, children: chips),
          for (final (ai, a) in r.ambiguities.indexed) ...[
            const SizedBox(height: Tokens.space2),
            Wrap(
              spacing: Tokens.space2,
              runSpacing: Tokens.space2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l.quickAddDidYouMean, style: Theme.of(context).textTheme.bodySmall),
                for (final (oi, o) in a.options.indexed)
                  ChoiceChip(
                    key: Key('amb-$ai-$oi'),
                    label: Text(fmt.civil(o, today: today)),
                    selected: (draft.picks[ai] ?? a.chosen) == oi,
                    onSelected: (_) {
                      draft
                        ..picks[ai] = oi
                        ..manualWhen = null;
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip kết quả phân tích (Figma 02): nền primaryContainer, icon + chữ màu primary; chạm được thì mở bộ chọn.
class _Pill extends StatelessWidget {
  const _Pill({super.key, this.icon, this.materialIcon, required this.label, this.onTap});
  final AppIcons? icon;
  final IconData? materialIcon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) AppIcon(icon!, size: 17, color: scheme.primary) else Icon(materialIcon, size: 17, color: scheme.primary),
              const SizedBox(width: 7),
              Flexible(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: scheme.primary))),
            ],
          ),
        ),
      ),
    );
  }
}
