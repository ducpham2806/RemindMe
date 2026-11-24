import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../items/item_tile.dart';

/// Tìm kiếm (S2): không phân biệt hoa thường/dấu, trên tiêu đề, ghi chú, tag. Chạy trên DB local (offline).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  List<ItemView>? _results;
  int _seq = 0;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final seq = ++_seq;
    final r = q.trim().isEmpty ? null : await ref.read(itemsRepositoryProvider).search(q);
    if (mounted && seq == _seq) setState(() => _results = r);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('searchField'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l.searchHint, border: InputBorder.none),
          onChanged: _search,
        ),
      ),
      body: results == null
          ? const SizedBox.shrink()
          : results.isEmpty
              ? EmptyState(icon: Icons.search_off, title: l.searchNoResults)
              : ListView(
                  padding: const EdgeInsetsDirectional.only(bottom: Tokens.space8),
                  children: [for (final i in results) ItemTile(key: ValueKey(i.rowKey), item: i)],
                ),
    );
  }
}
