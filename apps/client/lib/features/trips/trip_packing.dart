import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart' show uuidV7;
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Tên nhóm hành lý theo ngôn ngữ giao diện (giá trị lưu là mã nhóm, data-model: trips.packing).
String packingGroupName(AppLocalizations l, String group) => switch (group) {
      'documents' => l.packingGroupDocuments,
      'devices' => l.packingGroupDevices,
      'personal' => l.packingGroupPersonal,
      'clothes' => l.packingGroupClothes,
      _ => l.packingGroupOther,
    };

/// Danh sách gợi ý (UX §2.5): tạo bằng ngôn ngữ đang dùng, sau đó là nội dung của người dùng.
List<PackingItem> packingTemplate(AppLocalizations l, String Function() newId) => [
      PackingItem(id: newId(), text: l.packingTplId, group: 'documents'),
      PackingItem(id: newId(), text: l.packingTplTickets, group: 'documents'),
      PackingItem(id: newId(), text: l.packingTplCharger, group: 'devices'),
      PackingItem(id: newId(), text: l.packingTplPowerBank, group: 'devices'),
      PackingItem(id: newId(), text: l.packingTplMedicine, group: 'personal'),
      PackingItem(id: newId(), text: l.packingTplJacket, group: 'personal'),
    ];

/// Tab Hành lý của chi tiết chuyến (Figma 23): thẻ tiến độ, món theo nhóm, chạm để đánh dấu, chạm giữ để sửa/bỏ.
/// Chưa có checklist thì mời dùng danh sách gợi ý.
class PackingTab extends ConsumerWidget {
  const PackingTab({super.key, required this.trip});
  final TripSummary trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = trip.packing;
    if (items == null || items.isEmpty) {
      return Container(
        key: const Key('packingEmpty'),
        padding: const EdgeInsetsDirectional.all(Tokens.space5),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.packingEmptyTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Tokens.space1),
            Text(l.packingEmptyBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: Tokens.space4),
            FilledButton(
              key: const Key('packingUseTemplate'),
              onPressed: () {
                final now = ref.read(nowProvider)().millisecondsSinceEpoch;
                ref.read(tripsRepositoryProvider).setPacking(trip.id, packingTemplate(l, () => uuidV7(nowMillis: now)));
              },
              child: Text(l.packingUseTemplate),
            ),
          ],
        ),
      );
    }

    final done = items.where((i) => i.done).length;
    final groups = [for (final g in PackingItem.groups) if (items.any((i) => i.group == g)) g];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('packingProgress'),
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l.packingProgressTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                  Text('$done/${items.length}', key: const Key('packingCount'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
                ],
              ),
              const SizedBox(height: Tokens.space3),
              Semantics(
                label: l.packingProgressLabel(done, items.length),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: done / items.length,
                    minHeight: 4,
                    color: scheme.primary,
                    backgroundColor: scheme.surface,
                  ),
                ),
              ),
              const SizedBox(height: Tokens.space3),
              Text(l.packingRemaining(items.length - done), key: const Key('packingRemaining'), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(top: Tokens.space5, bottom: Tokens.space2),
            child: Semantics(header: true, child: Text(packingGroupName(l, g), style: theme.textTheme.labelLarge)),
          ),
          for (final i in items.where((i) => i.group == g))
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: Tokens.space2),
              child: _PackingRow(
                item: i,
                onToggle: () => ref.read(tripsRepositoryProvider).setPacking(trip.id, [
                  for (final x in items) x.id == i.id ? x.copyWith(done: !x.done) : x,
                ]),
                onEdit: () => editPackingItem(context, ref, trip, item: i),
              ),
            ),
        ],
      ],
    );
  }
}

class _PackingRow extends StatelessWidget {
  const _PackingRow({required this.item, required this.onToggle, required this.onEdit});
  final PackingItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: InkWell(
          key: Key('packing-${item.id}'),
          onTap: onToggle,
          onLongPress: onEdit,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.space2, vertical: Tokens.space1),
            child: Row(
              children: [
                Checkbox(value: item.done, onChanged: (_) => onToggle()),
                const SizedBox(width: Tokens.space1),
                Expanded(
                  child: Text(
                    item.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: item.done ? TextDecoration.lineThrough : null,
                      color: item.done ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet thêm/sửa 1 món: tên + nhóm; khi sửa có "Bỏ khỏi danh sách" (Hoàn tác ở snackbar).
Future<void> editPackingItem(BuildContext context, WidgetRef ref, TripSummary trip, {PackingItem? item}) async {
  final l = AppLocalizations.of(context);
  final repo = ref.read(tripsRepositoryProvider);
  final result = await showAppSheet<({bool remove, String text, String group})>(context, (_) => _PackingSheet(item: item));
  if (result == null) return;
  final current = trip.packing ?? const <PackingItem>[];
  if (result.remove && item != null) {
    await repo.setPacking(trip.id, [for (final x in current) if (x.id != item.id) x]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.packingRemoved(item.text)),
      action: SnackBarAction(key: const Key('packingUndo'), label: l.undo, onPressed: () => repo.setPacking(trip.id, current)),
    ));
  } else if (item == null) {
    await repo.addPacking(trip.id, result.text, group: result.group);
  } else {
    await repo.setPacking(trip.id, [for (final x in current) x.id == item.id ? x.copyWith(text: result.text, group: result.group) : x]);
  }
}

class _PackingSheet extends StatefulWidget {
  const _PackingSheet({this.item});
  final PackingItem? item;

  @override
  State<_PackingSheet> createState() => _PackingSheetState();
}

class _PackingSheetState extends State<_PackingSheet> {
  late final _text = TextEditingController(text: widget.item?.text);
  late String _group = widget.item?.group ?? 'other';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final t = _text.text.trim();
    if (t.isNotEmpty) Navigator.pop(context, (remove: false, text: t, group: _group));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final item = widget.item;
    return AppSheet(
      title: item == null ? l.packingAddTitle : l.packingEditTitle,
      primaryLabel: l.packingSave,
      primaryKey: const Key('packingSave'),
      onPrimary: _text.text.trim().isEmpty ? null : _save,
      children: [
        TextField(
          key: const Key('packingText'),
          controller: _text,
          autofocus: item == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l.packingNameHint),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
        ),
        Text(l.packingGroupLabel, style: Theme.of(context).textTheme.labelLarge),
        Wrap(
          spacing: Tokens.space2,
          runSpacing: Tokens.space2,
          children: [
            for (final g in PackingItem.groups)
              ChoiceChip(
                key: Key('packingGroup-$g'),
                label: Text(packingGroupName(l, g)),
                selected: _group == g,
                onSelected: (_) => setState(() => _group = g),
              ),
          ],
        ),
        if (item != null)
          TextButton.icon(
            key: const Key('packingRemove'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, (remove: true, text: item.text, group: item.group)),
            icon: const Icon(Icons.delete_outline),
            label: Text(l.packingRemove),
          ),
      ],
    );
  }
}
