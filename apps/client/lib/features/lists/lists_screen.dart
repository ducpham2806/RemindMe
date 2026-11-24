import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../common/text_prompt.dart';
import '../items/item_tile.dart';

/// Tôi → Danh sách (S2): Inbox + list người dùng, số việc đang mở; tạo, đổi tên, xóa (việc về Inbox).
class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lists = ref.watch(listsProvider).value ?? const [];
    final repo = ref.read(listsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.meLists)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newList'),
        icon: const Icon(Icons.add),
        label: Text(l.listsNew),
        onPressed: () async {
          final name = await askListName(context, title: l.listsNew);
          if (name != null) await repo.create(name);
        },
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: Tokens.space10 * 2),
        children: [
          for (final s in lists)
            ListTile(
              key: Key('list-${s.id ?? inboxRouteId}'),
              leading: Icon(s.isInbox ? Icons.inbox_outlined : Icons.list_alt_outlined),
              title: Text(s.isInbox ? l.listsInbox : s.name!),
              subtitle: Text(l.listsOpenCount(s.openCount)),
              onTap: () => context.go('/me/lists/${s.isInbox ? inboxRouteId : s.id}'),
              trailing: s.isInbox
                  ? null
                  : PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'rename') {
                          final name = await askListName(context, title: l.listsRename, initial: s.name);
                          if (name != null) await repo.rename(s.id!, name);
                        } else if (await _confirmDelete(context)) {
                          await repo.delete(s.id!);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'rename', child: Text(l.listsRename)),
                        PopupMenuItem(value: 'delete', child: Text(l.listsDelete)),
                      ],
                    ),
            ),
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

/// Hộp thoại nhập tên list; null nếu hủy hoặc tên rỗng.
Future<String?> askListName(BuildContext context, {required String title, String? initial}) async {
  return askText(context, title: title, initial: initial, hint: AppLocalizations.of(context).listsNameHint, fieldKey: const Key('listName'));
}

/// Việc đang mở của 1 list.
class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, required this.id});
  /// id list, hoặc [inboxRouteId].
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lists = ref.watch(listsProvider).value ?? const <ListSummary>[];
    final summary = lists.where((s) => id == inboxRouteId ? s.isInbox : s.id == id).firstOrNull;
    final items = ref.watch(listItemsProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(summary == null ? '' : (summary.isInbox ? l.listsInbox : summary.name!))),
      body: switch (items) {
        AsyncData(:final value) when value.isEmpty => EmptyState(icon: Icons.checklist, title: l.listsEmptyItems),
        AsyncData(:final value) => ListView(children: [for (final i in value) ItemTile(key: ValueKey(i.rowKey), item: i)]),
        AsyncError() => EmptyState(icon: Icons.error_outline, title: l.loadError),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
