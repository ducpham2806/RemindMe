import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../common/text_prompt.dart';
import '../items/item_tile.dart';
import '../quick_add/quick_add_sheet.dart';

/// Màu nhấn của list theo thứ tự (Figma 10): Hộp thư xám, list người dùng xoay vòng primary / travel / lunar / warning / danger.
(Color, Color) listAccent(BuildContext context, ListSummary s, int index) {
  final scheme = Theme.of(context).colorScheme;
  final c = RemindColors.of(context);
  if (s.isInbox) return (scheme.onSurfaceVariant, scheme.surfaceContainerLowest);
  final palette = [
    (scheme.primary, scheme.primaryContainer),
    (c.travel, c.travelContainer),
    (c.onWarningContainer, c.warningContainer),
    (c.lunar, c.lunarContainer),
    (scheme.error, scheme.errorContainer),
  ];
  return palette[(index - 1) % palette.length];
}

/// Tôi → Danh sách (S2, Figma 10): thẻ từng list với số việc đang mở, quá hạn, hôm nay; chạm giữ để đổi tên/xóa (việc về Hộp thư).
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await askListName(context, title: AppLocalizations.of(context).listsNew);
    if (name != null) await ref.read(listsRepositoryProvider).create(name);
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, ListSummary s) async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(listsRepositoryProvider);
    final action = await showAppSheet<String>(
      context,
      (context) => AppSheet(
        title: s.name!,
        children: [
          SheetOption(key: const Key('listRename'), icon: AppIcons.edit, title: l.listsRename, onTap: () => Navigator.of(context).pop('rename')),
          SheetOption(key: const Key('listDelete'), icon: AppIcons.close, title: l.listsDelete, onTap: () => Navigator.of(context).pop('delete')),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'rename') {
      final name = await askListName(context, title: l.listsRename, initial: s.name);
      if (name != null) await repo.rename(s.id!, name);
    } else if (await _confirmDelete(context)) {
      await repo.delete(s.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lists = ref.watch(listsProvider).value ?? const <ListSummary>[];
    final nf = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    final open = lists.fold<int>(0, (n, s) => n + s.openCount);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.meLists),
        actions: [
          IconButton(key: const Key('newList'), tooltip: l.listsNew, onPressed: () => _create(context, ref), icon: AppIcon(AppIcons.plus, size: 22, color: scheme.primary)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space6),
        children: [
          Text(l.listsSubtitle(open, lists.length), style: theme.textTheme.bodySmall),
          const SizedBox(height: Tokens.space4),
          Container(
            padding: const EdgeInsetsDirectional.all(Tokens.space4),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.listsIntroTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(l.listsIntroBody, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: Tokens.space4),
          for (final (i, s) in lists.indexed) ...[
            _ListCard(
              key: Key('list-${s.id ?? inboxRouteId}'),
              summary: s,
              accent: listAccent(context, s, i),
              count: nf.format(s.openCount),
              onTap: () => context.go('/me/lists/${s.isInbox ? inboxRouteId : s.id}'),
              onLongPress: s.isInbox ? null : () => _menu(context, ref, s),
            ),
            const SizedBox(height: Tokens.space3),
          ],
          TextButton.icon(
            key: const Key('newListBottom'),
            onPressed: () => _create(context, ref),
            icon: AppIcon(AppIcons.plus, size: 18, color: scheme.primary),
            label: Text(l.listsNew),
          ),
          if (lists.length > 1) Text(l.listsLongPressHint, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.listsDelete),
            content: Text(l.listsDeleteBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.itemDelete)),
            ],
          ),
        ) ??
        false;
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({super.key, required this.summary, required this.accent, required this.count, required this.onTap, this.onLongPress});
  final ListSummary summary;
  final (Color, Color) accent;
  final String count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = summary;
    final parts = [if (s.overdue > 0) l.listsOverdue(s.overdue), if (s.today > 0) l.listsToday(s.today)];
    final hint = parts.isNotEmpty ? parts.join(' · ') : (s.isInbox && s.openCount > 0 ? l.listsInboxHint : l.listsOpenCount(s.openCount));
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space4, 14, Tokens.space3, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: s.isInbox ? scheme.surfaceContainerLowest : accent.$2, borderRadius: BorderRadius.circular(12)),
                child: AppIcon(s.isInbox ? AppIcons.inbox : AppIcons.list, size: 20, color: accent.$1),
              ),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.isInbox ? l.listsInbox : s.name!, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(hint, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Text(count, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, color: s.openCount == 0 ? scheme.onSurfaceVariant : accent.$1)),
              ),
              const SizedBox(width: Tokens.space2),
              AppIcon(AppIcons.chevronSmall, size: 17, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại nhập tên list; null nếu hủy hoặc tên rỗng.
Future<String?> askListName(BuildContext context, {required String title, String? initial}) async {
  return askText(context, title: title, initial: initial, hint: AppLocalizations.of(context).listsNameHint, fieldKey: const Key('listName'));
}

/// Việc đang mở của 1 list (Figma 11): nhóm Quá hạn / Hôm nay / Sắp tới / Chưa đặt giờ, nút "Thêm vào" + tên list.
class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, required this.id});
  /// id list, hoặc [inboxRouteId].
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lists = ref.watch(listsProvider).value ?? const <ListSummary>[];
    final summary = lists.where((s) => id == inboxRouteId ? s.isInbox : s.id == id).firstOrNull;
    final name = summary == null ? '' : (summary.isInbox ? l.listsInbox : summary.name!);
    final items = ref.watch(listItemsProvider(id));
    final day = ref.watch(todayWindowProvider);
    final listId = summary == null || summary.isInbox ? null : summary.id;
    void add() => showQuickAdd(context, listId: listId);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [IconButton(key: const Key('listAdd'), tooltip: l.listAddTo(name), onPressed: add, icon: AppIcon(AppIcons.plus, size: 22, color: scheme.primary))],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space3),
          child: FilledButton.icon(
            key: const Key('listAddBottom'),
            onPressed: add,
            icon: AppIcon(AppIcons.plus, size: 20, color: scheme.onPrimary),
            label: Text(l.listAddTo(name)),
          ),
        ),
      ),
      body: switch (items) {
        AsyncData(:final value) when value.isEmpty => EmptyState(icon: Icons.checklist, title: l.listsEmptyItems),
        AsyncData(:final value) => _grouped(context, value, day, summary),
        AsyncError() => EmptyState(icon: Icons.error_outline, title: l.loadError),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _grouped(BuildContext context, List<ItemView> items, DayWindow day, ListSummary? summary) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    bool timed(ItemView i) => i.startsAt != null && !i.allDay;
    String? date(ItemView i) => i.startDate;
    final overdue = [
      for (final i in items)
        if (timed(i) ? i.startsAt!.isBefore(day.startUtc) : (date(i) != null && date(i)!.compareTo(day.localDate) < 0)) i,
    ];
    final today = [
      for (final i in items)
        if (timed(i) ? !i.startsAt!.isBefore(day.startUtc) && i.startsAt!.isBefore(day.endUtc) : date(i) == day.localDate) i,
    ];
    final none = [for (final i in items) if (!timed(i) && date(i) == null) i];
    final upcoming = [for (final i in items) if (!overdue.contains(i) && !today.contains(i) && !none.contains(i)) i];
    Widget section(String title, List<ItemView> list, {bool late = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space4, Tokens.screenMargin, Tokens.space1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: theme.textTheme.labelLarge?.copyWith(color: late ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant)),
                  ),
                  Text(l.todaySectionCount(list.length), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            for (final i in list) ItemTile(key: ValueKey(i.rowKey), item: i, overdue: late),
          ],
        );
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: Tokens.space5),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.screenMargin),
          child: Text(
            [l.listDetailSubtitle(items.length), if (overdue.isNotEmpty) l.listsOverdue(overdue.length)].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (overdue.isNotEmpty) section(l.sectionOverdue, overdue, late: true),
        if (today.isNotEmpty) section(l.sectionToday, today),
        if (upcoming.isNotEmpty) section(l.sectionUpcoming, upcoming),
        if (none.isNotEmpty) section(l.sectionNoTime, none),
      ],
    );
  }
}
