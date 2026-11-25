import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/setting_row.dart';
import '../../data/providers.dart';
import '../../data/reminders.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../schedule/snooze_sheet.dart';
import 'schedule_editor.dart';

/// Chi tiết item (UX §2.3, Figma 04): list + trạng thái (chạm để xong/mở lại), tên, ghi chú, thẻ Ngày & giờ / Nhắc / Lặp / Danh sách / Ưu tiên.
/// Tự lưu khi rời trường (không có nút Lưu). Checklist, tag chưa có.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.id, this.reminderId, this.occurrence});
  final String id;
  /// Mở từ thông báo: nhắc và lần nhắc vừa kêu (cho nút Hoãn nhắc).
  final String? reminderId;
  final DateTime? occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final item = ref.watch(itemProvider(id));
    return switch (item) {
      AsyncData(:final value?) => _Editor(key: ValueKey(id), item: value, reminderId: reminderId, occurrence: occurrence),
      AsyncData() => Scaffold(
          appBar: AppBar(),
          body: EmptyState(icon: Icons.inbox_outlined, title: l.itemNotFound),
        ),
      AsyncError() => Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.error_outline, title: l.loadError)),
      _ => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
    };
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.item, this.reminderId, this.occurrence});
  final ItemView item;
  final String? reminderId;
  final DateTime? occurrence;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _title = TextEditingController(text: widget.item.title);
  late final _notes = TextEditingController(text: widget.item.notes ?? '');
  final _titleFocus = FocusNode();
  final _notesFocus = FocusNode();
  String? _notesBaseClock;

  // Giữ repo từ initState: dispose() còn lưu thay đổi cuối, lúc đó không dùng ref được nữa.
  late final ItemsRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(itemsRepositoryProvider);
    _repo.notesClock(widget.item.id).then((c) => _notesBaseClock = c);
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) _saveTitle();
    });
    _notesFocus.addListener(() {
      if (!_notesFocus.hasFocus) _saveNotes();
    });
  }

  @override
  void didUpdateWidget(_Editor old) {
    super.didUpdateWidget(old);
    // Thay đổi từ máy khác (qua sync) vào khi người dùng không sửa trường đó.
    if (!_titleFocus.hasFocus && widget.item.title != _title.text) _title.text = widget.item.title;
    if (!_notesFocus.hasFocus && (widget.item.notes ?? '') != _notes.text) _notes.text = widget.item.notes ?? '';
  }

  @override
  void dispose() {
    _saveTitle();
    _saveNotes();
    _title.dispose();
    _notes.dispose();
    _titleFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _saveTitle() {
    final t = _title.text.trim();
    if (t.isEmpty) {
      _title.text = widget.item.title; // tiêu đề bắt buộc: bỏ thay đổi rỗng
    } else if (t != widget.item.title) {
      _repo.rename(widget.item.id, t);
    }
  }

  void _saveNotes() {
    if (_notes.text == (widget.item.notes ?? '')) return;
    _repo.setNotes(widget.item.id, _notes.text, baseClock: _notesBaseClock);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.itemDeleteConfirmTitle),
        content: Text(l.itemDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.itemDelete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.delete(widget.item.id);
    if (mounted && context.canPop()) context.pop();
  }

  Future<void> _pickPriority() async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in const [0, 1, 2, 3])
              ListTile(
                key: Key('priority-$p'),
                leading: Icon(p == widget.item.priority ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(_priorityName(l, p)),
                onTap: () => Navigator.pop(context, p),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await _repo.setPriority(widget.item.id, picked);
  }

  /// Nhắc + lần nhắc có thể hoãn: lần vừa kêu (mở từ thông báo) hoặc việc 1 lần đang tới giờ (trong 1 giờ tới / đã qua trong ngày).
  (String, DateTime)? _snoozeTarget(List<Reminder> reminders, DateTime now) {
    if (widget.item.isDone || reminders.isEmpty) return null;
    if (widget.reminderId != null && reminders.any((r) => r.id == widget.reminderId)) {
      return (widget.reminderId!, widget.occurrence ?? widget.item.startsAt ?? now);
    }
    final at = widget.item.startsAt;
    final recurring = ref.watch(recurrenceProvider(widget.item.id)).value != null;
    if (at == null || widget.item.allDay || recurring) return null;
    final diff = at.difference(now);
    if (diff > const Duration(hours: 1) || diff < const Duration(hours: -24)) return null;
    return (reminders.first.id, at);
  }

  static String _priorityName(AppLocalizations l, int p) => switch (p) {
        1 => l.priorityLow,
        2 => l.priorityMedium,
        3 => l.priorityHigh,
        _ => l.priorityNone,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = widget.item;
    final lists = ref.watch(listsProvider).value ?? const <ListSummary>[];
    final list = lists.where((s) => item.listId == null ? s.isInbox : s.id == item.listId).firstOrNull;
    final listName = list == null || list.isInbox ? l.listsInbox : list.name!;
    final snoozeTarget = _snoozeTarget(ref.watch(remindersProvider(item.id)).value ?? const [], ref.watch(nowProvider)());
    Widget pill(String text, {required Color bg, required Color fg, Key? key, VoidCallback? onTap}) => Material(
          key: key,
          color: bg,
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(Tokens.space2),
              child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: fg)),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(l.itemDetailTitle),
        actions: [
          IconButton(key: const Key('itemDelete'), tooltip: l.itemDelete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: Tokens.space2,
            children: [
              pill(listName, bg: scheme.primaryContainer, fg: scheme.primary),
              if (snoozeTarget != null)
                pill(l.snoozeTitle, key: const Key('itemSnooze'), bg: scheme.surface, fg: scheme.primary, onTap: () => snoozeItem(context, ref, item: item, reminderId: snoozeTarget.$1, occurrence: snoozeTarget.$2)),
              Semantics(
                button: true,
                toggled: item.isDone,
                label: item.isDone ? l.itemMarkOpen : l.itemMarkDone,
                excludeSemantics: true,
                child: pill(
                  item.isDone ? l.itemStatusDone : l.itemStatusOpen,
                  key: const Key('itemDone'),
                  bg: item.isDone ? RemindColors.of(context).travelContainer : scheme.surface,
                  fg: item.isDone ? RemindColors.of(context).success : scheme.onSurfaceVariant,
                  onTap: () => _repo.setDone(item.id, done: !item.isDone),
                ),
              ),
            ],
          ),
          const SizedBox(height: Tokens.space4),
          TextField(
            key: const Key('itemTitle'),
            controller: _title,
            focusNode: _titleFocus,
            minLines: 1,
            maxLines: 4,
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28, height: 41 / 28),
            decoration: InputDecoration(hintText: l.itemTitleLabel, border: InputBorder.none, filled: false, isCollapsed: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTitle(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.itemNotesLabel, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, height: 1.5, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
                const SizedBox(height: Tokens.space2),
                TextField(
                  key: const Key('itemNotes'),
                  controller: _notes,
                  focusNode: _notesFocus,
                  minLines: 2,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  decoration: const InputDecoration(border: InputBorder.none, filled: false, isCollapsed: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScheduleEditor(item: item, between: _RemindersSection(item: item)),
                SettingRow(key: const Key('itemList'), icon: AppIcons.list, label: l.itemListLabel, value: listName, onTap: () => _pickList(lists, list)),
                SettingRow(
                  key: const Key('itemPriority'),
                  icon: AppIcons.flag,
                  label: l.itemPriorityLabel,
                  value: _priorityName(l, item.priority),
                  onTap: _pickPriority,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickList(List<ListSummary> lists, ListSummary? current) {
    final l = AppLocalizations.of(context);
    String name(ListSummary s) => s.isInbox ? l.listsInbox : s.name!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in lists)
              ListTile(
                leading: Icon(s == current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(name(s)),
                onTap: () {
                  Navigator.pop(context);
                  _repo.setList(widget.item.id, s.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Nhắc của item: mỗi mốc là 1 chip (xóa được), "Thêm nhắc" mở danh sách mốc có sẵn.
class _RemindersSection extends ConsumerWidget {
  const _RemindersSection({required this.item});
  final ItemView item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final repo = ref.read(itemsRepositoryProvider);
    final reminders = ref.watch(remindersProvider(item.id)).value ?? const [];
    final used = {for (final r in reminders) r.offsetMinutes ?? 0};
    return SettingRow(
      key: const Key('itemReminders'),
      icon: AppIcons.bell,
      label: l.itemRemindersLabel,
      enabled: item.isScheduled,
      child: !item.isScheduled
          ? Text(l.reminderNeedsDate, style: theme.textTheme.bodySmall)
          : Wrap(
              spacing: Tokens.space2,
              runSpacing: Tokens.space2,
              children: [
                for (final r in reminders)
                  InputChip(
                    key: Key('reminder-${r.offsetMinutes ?? 0}'),
                    label: Text(describeReminderOffset(l, r.offsetMinutes ?? 0)),
                    deleteButtonTooltipMessage: l.reminderRemove,
                    onDeleted: () => repo.removeReminder(r.id),
                  ),
                PopupMenuButton<int>(
                  key: const Key('reminderAdd'),
                  tooltip: l.reminderAdd,
                  onSelected: (m) => repo.addReminder(item.id, offsetMinutes: m),
                  itemBuilder: (context) => [
                    for (final m in reminderPresets)
                      if (!used.contains(m)) PopupMenuItem(value: m, child: Text(describeReminderOffset(l, m))),
                  ],
                  child: Chip(avatar: Icon(Icons.add, size: 18, color: theme.colorScheme.primary), label: Text(l.reminderAdd)),
                ),
              ],
            ),
    );
  }
}

