import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

/// Một dòng item (UX §2.1): ô đánh dấu xong, tiêu đề, dòng "khi nào". Vuốt từ đầu dòng = Xong (có Hoàn tác).
class ItemTile extends ConsumerWidget {
  const ItemTile({super.key, required this.item, this.overdue = false, this.inset = true});

  final ItemView item;
  final bool overdue;
  /// Thêm lề màn hình hai bên (false khi thẻ đã nằm trong vùng có lề, như tab Lịch).
  final bool inset;

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

  List<Widget> _badges(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recurring = item.isOccurrence || (ref.watch(recurringIdsProvider).value?.contains(item.id) ?? false);
    return [
      if (recurring) Icon(Icons.repeat, size: 16, color: theme.colorScheme.onSurfaceVariant, semanticLabel: l.recurCustom),
      if (item.priority >= 3) Icon(Icons.priority_high, size: 18, color: theme.colorScheme.error, semanticLabel: l.priorityHigh),
    ];
  }

  /// Vòng đánh dấu xong 23dp (Figma): viền xám, quá hạn viền đỏ nhạt; đã xong thì tô primary + dấu ✓.
  Widget _check(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = RemindColors.of(context);
    return Semantics(
      container: true,
      button: true,
      checked: item.isDone,
      label: item.isDone ? l.itemMarkOpen : l.itemMarkDone,
      excludeSemantics: true,
      child: InkResponse(
        key: Key('check-${item.rowKey}'),
        radius: 22,
        onTap: () => _toggle(context, ref),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space1),
          child: item.isDone
              ? Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
                  child: Icon(Icons.check, size: 16, color: scheme.onPrimary),
                )
              : AppIcon(AppIcons.check, color: overdue ? colors.checkOverdue : colors.checkOutline),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayWindowProvider);
    final fmt = Fmt.of(context);
    // Giờ trong hôm nay hiện ở bên phải (Figma 01); ngày khác thì ghi ở dòng phụ.
    final timedToday = item.startsAt != null && !item.allDay && !item.startsAt!.isBefore(today.startUtc) && item.startsAt!.isBefore(today.endUtc);
    final listName = item.listId == null
        ? null
        : (ref.watch(listsProvider).value ?? const <ListSummary>[]).where((s) => s.id == item.listId).firstOrNull?.name;
    final subtitle = [?listName, if (!timedToday) ?fmt.when(item, today: today)].join(' · ');
    final accent = overdue ? scheme.error : scheme.primary;
    final badges = _badges(context, ref);
    final card = Card(
      key: Key('item-${item.rowKey}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/item/${item.id}'),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 14, 10),
          child: Row(
            children: [
              _check(context, ref),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                        color: item.isDone ? scheme.onSurfaceVariant : null,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: Tokens.space1),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: overdue ? scheme.error : scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              ...badges.map((b) => Padding(padding: const EdgeInsetsDirectional.only(start: Tokens.space1), child: b)),
              if (timedToday)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: Tokens.space3),
                  child: Text(
                    fmt.time(item.startsAt!),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: item.isDone ? scheme.onSurfaceVariant : accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final tile = Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: inset ? Tokens.screenMargin : 0, vertical: Tokens.space1),
      child: card,
    );
    if (item.isDone) return tile;
    return Dismissible(
      key: ValueKey('dismiss-${item.rowKey}'),
      direction: DismissDirection.startToEnd,
      background: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: inset ? Tokens.screenMargin : 0, vertical: Tokens.space1),
        child: DecoratedBox(
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: Tokens.space4),
              child: Icon(Icons.check, color: scheme.primary),
            ),
          ),
        ),
      ),
      confirmDismiss: (_) async {
        await _toggle(context, ref);
        return false; // stream DB tự bỏ dòng; không để Dismissible giữ widget đã gỡ
      },
      child: tile,
    );
  }
}
