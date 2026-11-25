import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../items/item_tile.dart';

/// Tìm kiếm (S2, Figma 09): không phân biệt hoa thường/dấu, trên tiêu đề, ghi chú, tag. Chạy trên DB local (offline).
/// Lọc theo list có trong kết quả; nhóm Hôm nay / Sắp tới / Trước đó / Chưa đặt giờ / Đã hoàn thành.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  List<ItemView>? _results;
  String _filter = 'all';
  int _seq = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    final r = q.trim().isEmpty ? null : await ref.read(itemsRepositoryProvider).search(q);
    if (mounted && seq == _seq) {
      setState(() {
        _results = r;
        _filter = 'all';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lists = ref.watch(listsProvider).value ?? const <ListSummary>[];
    final inbox = lists.where((s) => s.isInbox).firstOrNull;
    String listKey(ItemView i) => i.listId == null || i.listId == inbox?.id ? inboxRouteId : i.listId!;
    String listName(String key) => key == inboxRouteId ? l.listsInbox : (lists.where((s) => s.id == key).firstOrNull?.name ?? '');
    final all = _results;
    final keys = {for (final i in all ?? const <ItemView>[]) listKey(i)};
    final shown = all == null ? null : [for (final i in all) if (_filter == 'all' || listKey(i) == _filter) i];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(end: Tokens.screenMargin),
          child: TextField(
            key: const Key('searchField'),
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: l.searchHint,
              filled: true,
              fillColor: scheme.surface,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd), borderSide: BorderSide.none),
              prefixIcon: Padding(padding: const EdgeInsetsDirectional.all(12), child: AppIcon(AppIcons.search, size: 20, color: scheme.onSurfaceVariant)),
              prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('searchClear'),
                      tooltip: l.searchClear,
                      onPressed: () {
                        _query.clear();
                        _search('');
                      },
                      icon: AppIcon(AppIcons.close, size: 18, color: scheme.onSurfaceVariant),
                    ),
            ),
            onChanged: _search,
          ),
        ),
      ),
      body: shown == null
          ? ListView(
              padding: const EdgeInsetsDirectional.all(Tokens.screenMargin),
              children: [_tip(context)],
            )
          : all!.isEmpty
              ? EmptyState(icon: Icons.search_off, title: l.searchNoResults)
              : ListView(
                  padding: const EdgeInsetsDirectional.only(bottom: Tokens.space8),
                  children: [
                    if (keys.length > 1)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: Tokens.screenMargin),
                        child: Row(
                          children: [
                            for (final (i, k) in ['all', ...keys].indexed) ...[
                              if (i > 0) const SizedBox(width: Tokens.space2),
                              ChoiceChip(
                                key: Key('searchFilter-$k'),
                                label: Text(k == 'all' ? l.searchAll : listName(k)),
                                selected: _filter == k,
                                showCheckmark: false,
                                selectedColor: scheme.primary,
                                labelStyle: theme.textTheme.labelMedium?.copyWith(color: _filter == k ? scheme.onPrimary : scheme.onSurfaceVariant),
                                backgroundColor: scheme.surface,
                                side: BorderSide.none,
                                onSelected: (_) => setState(() => _filter = k),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, 0),
                      child: Text(l.searchCount(shown.length, _query.text.trim()), key: const Key('searchCount'), style: theme.textTheme.bodySmall),
                    ),
                    ..._groups(context, shown),
                    Padding(padding: const EdgeInsetsDirectional.all(Tokens.screenMargin), child: _tip(context)),
                  ],
                ),
    );
  }

  List<Widget> _groups(BuildContext context, List<ItemView> items) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final day = ref.watch(todayWindowProvider);
    int bucket(ItemView i) {
      if (i.isDone) return 4;
      final timed = i.startsAt != null && !i.allDay;
      if (!timed && i.startDate == null) return 3;
      final cmp = timed
          ? (i.startsAt!.isBefore(day.startUtc) ? -1 : (i.startsAt!.isBefore(day.endUtc) ? 0 : 1))
          : i.startDate!.compareTo(day.localDate).sign;
      return switch (cmp) { 0 => 0, 1 => 1, _ => 2 };
    }

    final titles = [l.sectionToday, l.sectionUpcoming, l.sectionPast, l.sectionNoTime, l.sectionDone];
    return [
      for (var b = 0; b < titles.length; b++)
        if (items.where((i) => bucket(i) == b).toList() case final group when group.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space4, Tokens.screenMargin, Tokens.space1),
            child: Text(titles[b], style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          for (final i in group) ItemTile(key: ValueKey(i.rowKey), item: i, overdue: b == 2),
        ],
    ];
  }

  Widget _tip(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const Key('searchTip'),
      padding: const EdgeInsetsDirectional.all(Tokens.space4),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.searchTipTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
          const SizedBox(height: Tokens.space1),
          Text(l.searchTipBody, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
