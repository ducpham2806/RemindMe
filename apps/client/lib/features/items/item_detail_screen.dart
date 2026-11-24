import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

/// Chi tiết item (UX §2.3), phần S2: tiêu đề, ghi chú, ưu tiên, xong/chưa xong, xóa.
/// Thời gian, lặp, nhắc, list, tag, checklist thêm ở S3+ (cần engine nhắc và recurrence).
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final item = ref.watch(itemProvider(id));
    return switch (item) {
      AsyncData(:final value?) => _Editor(key: ValueKey(id), item: value),
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
  const _Editor({super.key, required this.item});
  final ItemView item;

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final item = widget.item;
    final when = Fmt.of(context).when(item, today: ref.watch(todayWindowProvider));
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('itemDone'),
            tooltip: item.isDone ? l.itemMarkOpen : l.itemMarkDone,
            icon: Icon(item.isDone ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: () => _repo.setDone(item.id, done: !item.isDone),
          ),
          IconButton(key: const Key('itemDelete'), tooltip: l.itemDelete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(Tokens.screenMargin),
        children: [
          TextField(
            key: const Key('itemTitle'),
            controller: _title,
            focusNode: _titleFocus,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(labelText: l.itemTitleLabel),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTitle(),
          ),
          if (when != null) ...[
            const SizedBox(height: Tokens.space3),
            ListTile(contentPadding: EdgeInsetsDirectional.zero, leading: const Icon(Icons.schedule), title: Text(when)),
          ],
          const SizedBox(height: Tokens.space4),
          Text(l.itemPriorityLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: Tokens.space2),
          SegmentedButton<int>(
            key: const Key('itemPriority'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text(l.priorityNone)),
              ButtonSegment(value: 1, label: Text(l.priorityLow)),
              ButtonSegment(value: 2, label: Text(l.priorityMedium)),
              ButtonSegment(value: 3, label: Text(l.priorityHigh)),
            ],
            selected: {item.priority},
            onSelectionChanged: (s) => _repo.setPriority(item.id, s.single),
          ),
          const SizedBox(height: Tokens.space4),
          TextField(
            key: const Key('itemNotes'),
            controller: _notes,
            focusNode: _notesFocus,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(labelText: l.itemNotesLabel, alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
