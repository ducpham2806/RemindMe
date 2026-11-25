import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// "Việc chuẩn bị" ở chi tiết item (Figma 04): x/y, chạm để đánh dấu, chạm giữ để sửa/xóa (Hoàn tác), ô thêm dòng cuối danh sách.
/// Ghi cả mảng `items.checklist` mỗi lần đổi (data-model: LWW theo trường).
class ChecklistSection extends ConsumerStatefulWidget {
  const ChecklistSection({super.key, required this.item});
  final ItemView item;

  @override
  ConsumerState<ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends ConsumerState<ChecklistSection> {
  final _add = TextEditingController();
  final _addFocus = FocusNode();

  @override
  void dispose() {
    _add.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  ItemsRepository get _repo => ref.read(itemsRepositoryProvider);
  List<ChecklistItem> get _items => widget.item.checklist;

  Future<void> _write(List<ChecklistItem> items) => _repo.setChecklist(widget.item.id, items);

  Future<void> _submit() async {
    final t = _add.text.trim();
    if (t.isEmpty) return;
    _add.clear();
    await _write([..._items, ChecklistItem(t)]);
    _addFocus.requestFocus();
  }

  Future<void> _edit(int index) async {
    final l = AppLocalizations.of(context);
    final before = _items;
    final result = await showAppSheet<({bool remove, String text})>(context, (_) => _LineSheet(text: before[index].text));
    if (result == null || !mounted) return;
    if (result.remove) {
      await _write([...before]..removeAt(index));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.packingRemoved(before[index].text)),
        action: SnackBarAction(key: const Key('checklistUndo'), label: l.undo, onPressed: () => _write(before)),
      ));
    } else {
      await _write([for (final (i, c) in before.indexed) i == index ? c.copyWith(text: result.text) : c]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _items;
    final done = items.where((c) => c.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: Tokens.space5, bottom: Tokens.space3),
          child: Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(l.checklistTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)))),
              if (items.isNotEmpty)
                Semantics(
                  label: l.checklistCountLabel(done, items.length),
                  excludeSemantics: true,
                  child: Text('$done/${items.length}', key: const Key('checklistCount'), style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
        for (final (i, c) in items.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: Tokens.space2),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(Tokens.radiusMd),
              clipBehavior: Clip.antiAlias,
              child: MergeSemantics(
                child: InkWell(
                  key: Key('checklist-$i'),
                  onTap: () => _write([for (final (j, x) in items.indexed) j == i ? x.copyWith(done: !x.done) : x]),
                  onLongPress: () => _edit(i),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space2, vertical: Tokens.space2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: c.done,
                          shape: const CircleBorder(),
                          onChanged: (_) => _write([for (final (j, x) in items.indexed) j == i ? x.copyWith(done: !x.done) : x]),
                        ),
                        const SizedBox(width: Tokens.space1),
                        Expanded(
                          child: Text(
                            c.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: c.done ? TextDecoration.lineThrough : null,
                              color: c.done ? scheme.onSurfaceVariant : scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space4, vertical: Tokens.space1),
          decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
          child: Row(
            children: [
              Icon(Icons.add, color: scheme.primary, size: 22),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: TextField(
                  key: const Key('checklistAdd'),
                  controller: _add,
                  focusNode: _addFocus,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(hintText: l.checklistAddHint, border: InputBorder.none, filled: false),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineSheet extends StatefulWidget {
  const _LineSheet({required this.text});
  final String text;

  @override
  State<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends State<_LineSheet> {
  late final _text = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final t = _text.text.trim();
    if (t.isNotEmpty) Navigator.pop(context, (remove: false, text: t));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppSheet(
      title: l.checklistEditTitle,
      primaryLabel: l.checklistSave,
      primaryKey: const Key('checklistSave'),
      onPrimary: _text.text.trim().isEmpty ? null : _save,
      children: [
        TextField(
          key: const Key('checklistText'),
          controller: _text,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        TextButton.icon(
          key: const Key('checklistRemove'),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, (remove: true, text: widget.text)),
          icon: const Icon(Icons.delete_outline),
          label: Text(l.checklistRemove),
        ),
      ],
    );
  }
}
