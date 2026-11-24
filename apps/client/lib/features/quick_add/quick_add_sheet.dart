import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/l10n/recurrence_text.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../data/reminders.dart';
import '../../l10n/app_localizations.dart';

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

  String get title => result.title.isEmpty ? fallbackTitle : result.title;

  /// Thời điểm sau khi áp lựa chọn: chip giờ đổi giờ (và ngày nếu giờ đó rơi sang mai), chip ngày đổi ngày.
  CivilDateTime? get when {
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
      setState(() => _drafts = [_Draft(NluResult(title: raw), raw)]);
      return;
    }
    final ctx = NluContext(now: ref.read(nowProvider)(), region: ref.read(deviceRegionProvider));
    setState(() => _drafts = [for (final r in engine.parseAll(raw, ctx)) _Draft(r, raw)]);
  }

  bool get _canSave => !_saving && _drafts.isNotEmpty && _drafts.every((d) => d.title.trim().isNotEmpty);

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repo = ref.read(itemsRepositoryProvider);
    final tz = ref.read(deviceTimeZoneProvider);
    final today = CivilDate.of(ref.read(nowProvider)());
    for (final d in _drafts) {
      var when = d.when;
      final rec = d.result.recurrence;
      // Âm lịch chưa có ngày ("đi chùa rằm"): lần đầu tiên từ hôm nay.
      if (when == null && rec != null) {
        when = Recurrence.fromRow(rec.toPayload()).nextAfter(CivilDateTime(today), CivilDateTime(today.addDays(-1)));
      }
      // Giờ tường theo múi giờ của máy → UTC (DateTime local của Dart dùng tzdata của OS).
      final local = when == null
          ? null
          : DateTime(when.date.year, when.date.month, when.date.day, when.time?.hour ?? 0, when.time?.minute ?? 0);
      await repo.create(
        title: d.title,
        startsAt: when?.time == null ? null : local!.toUtc(),
        startDate: when != null && when.time == null ? when.date.toIso() : null,
        tz: when == null ? null : tz,
        priority: d.result.priority ?? 0,
        tags: d.result.tags,
        recurrence: rec?.toPayload(),
        recurrenceStart: rec == null ? null : (local ?? DateTime(today.year, today.month, today.day)).toUtc(),
        // Có thời điểm thì mặc định nhắc đúng giờ (chip 🔔 trong UX §2.2); sửa ở màn chi tiết.
        reminderOffsets: when == null ? const [] : const [0],
      );
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
          TextField(
            key: const Key('quickAddField'),
            controller: _text,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l.quickAddHint),
            onChanged: (_) => _reparse(engine),
            onSubmitted: (_) => _save(),
          ),
          // Chip có thể dài (nhiều việc, chữ lớn): phần này cuộn, ô nhập và nút Lưu luôn thấy.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_drafts.length > 1) ...[
                    const SizedBox(height: Tokens.space3),
                    Text(l.quickAddFoundN(_drafts.length), style: Theme.of(context).textTheme.labelLarge),
                  ],
                  for (final (i, d) in _drafts.indexed)
                    _DraftChips(
                      key: Key('draft-$i'),
                      draft: d,
                      showTitle: _drafts.length > 1,
                      today: today,
                      onPick: (amb, option) => setState(() => d.picks[amb] = option),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Tokens.space3),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              key: const Key('quickAddSave'),
              onPressed: _canSave ? _save : null,
              child: Text(_drafts.length > 1 ? l.quickAddSaveAll : l.quickAddSave),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftChips extends StatelessWidget {
  const _DraftChips({super.key, required this.draft, required this.showTitle, required this.today, required this.onPick});
  final _Draft draft;
  final bool showTitle;
  final CivilDate today;
  final void Function(int ambiguity, int option) onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = Fmt.of(context);
    final r = draft.result;
    final when = draft.when;
    final chips = <Widget>[
      if (when != null) Chip(key: const Key('chipWhen'), avatar: const Icon(Icons.event, size: 18), label: Text(fmt.civil(when, today: today))),
      if (when != null || r.recurrence != null)
        Chip(key: const Key('chipReminder'), avatar: const Icon(Icons.notifications_outlined, size: 18), label: Text(describeReminderOffset(l, 0))),
      if (r.recurrence != null)
        Chip(key: const Key('chipRepeat'), avatar: const Icon(Icons.repeat, size: 18), label: Text(describeRecurrence(context, r.recurrence!.toPayload()))),
      for (final t in r.tags) Chip(avatar: const Icon(Icons.tag, size: 18), label: Text(t)),
      if (r.priority != null)
        Chip(
          avatar: const Icon(Icons.flag_outlined, size: 18),
          label: Text(switch (r.priority!) { 1 => l.priorityLow, 2 => l.priorityMedium, _ => l.priorityHigh }),
        ),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Tokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) Text(draft.title, style: Theme.of(context).textTheme.titleSmall),
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
                    onSelected: (_) => onPick(ai, oi),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
