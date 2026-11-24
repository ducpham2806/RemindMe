import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Một dòng item (UX §2.1): ô đánh dấu xong, tiêu đề, dòng "khi nào". Vuốt từ đầu dòng = Xong (có Hoàn tác).
class ItemTile extends ConsumerWidget {
  const ItemTile({super.key, required this.item, this.overdue = false});

  final ItemView item;
  final bool overdue;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(itemsRepositoryProvider);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final done = !item.isDone;
    final occ = item.occurrenceAt;
    // Lần của chuỗi lặp: chỉ đóng/mở lần này (occurrence_log), không đóng cả chuỗi.
    Future<void> set(bool value) => occ == null
        ? repo.setDone(item.id, done: value)
        : (value ? repo.completeOccurrence(item.id, occ) : repo.reopenOccurrence(item.id, occ));
    await set(done);
    if (done && messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l.itemMarkedDone),
          action: SnackBarAction(label: l.undo, onPressed: () => set(false)),
        ));
    }
  }

  Widget? _trailing(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recurring = item.isOccurrence || (ref.watch(recurringIdsProvider).value?.contains(item.id) ?? false);
    final icons = [
      if (recurring) Icon(Icons.repeat, size: 18, color: theme.colorScheme.onSurfaceVariant, semanticLabel: l.recurCustom),
      if (item.priority >= 3) Icon(Icons.priority_high, color: theme.colorScheme.error, semanticLabel: l.priorityHigh),
    ];
    return icons.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final when = Fmt.of(context).when(item, today: ref.watch(todayWindowProvider));
    final tile = ListTile(
      key: Key('item-${item.rowKey}'),
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.screenMargin),
      leading: Checkbox(
        value: item.isDone,
        semanticLabel: item.isDone ? l.itemMarkOpen : l.itemMarkDone,
        onChanged: (_) => _toggle(context, ref),
      ),
      title: Text(
        item.title,
        style: item.isDone
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough, color: theme.colorScheme.onSurfaceVariant)
            : null,
      ),
      subtitle: when == null
          ? null
          : Text(when, style: overdue ? TextStyle(color: theme.colorScheme.error) : null),
      trailing: _trailing(context, ref),
      onTap: () => context.push('/item/${item.id}'),
    );
    if (item.isDone) return tile;
    return Dismissible(
      key: ValueKey('dismiss-${item.rowKey}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: theme.colorScheme.primaryContainer,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: Tokens.screenMargin),
        child: Icon(Icons.check, color: theme.colorScheme.onPrimaryContainer),
      ),
      confirmDismiss: (_) async {
        await _toggle(context, ref);
        return false; // stream DB tự bỏ dòng; không để Dismissible giữ widget đã gỡ
      },
      child: tile,
    );
  }
}
