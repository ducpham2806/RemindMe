import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../items/item_tile.dart';

/// Hôm nay (UX §2.1): Quá hạn · Hôm nay · Chưa đặt giờ · Đã xong. Đọc stream từ DB local (offline-first).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(nowProvider)();
    final sections = ref.watch(todaySectionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.navToday),
            Text(Fmt.of(context).dayHeader(now), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: switch (sections) {
        AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.wb_sunny_outlined, title: l.todayEmptyTitle, body: l.todayEmptyBody),
        AsyncData(:final value) => _SectionList(sections: value),
        AsyncError() => EmptyState(icon: Icons.error_outline, title: l.loadError),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.sections});
  final TodaySections sections;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final children = <Widget>[
      ..._section(context, l.sectionOverdue, sections.overdue, overdue: true),
      ..._section(context, l.sectionToday, sections.today),
      ..._section(context, l.sectionNoTime, sections.noTime),
      ..._section(context, l.sectionDone, sections.doneToday),
    ];
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: Tokens.space8),
      children: children,
    );
  }

  List<Widget> _section(BuildContext context, String title, List<ItemView> items, {bool overdue = false}) {
    if (items.isEmpty) return const [];
    final theme = Theme.of(context);
    return [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space4, Tokens.screenMargin, Tokens.space1),
        child: Semantics(
          header: true,
          child: Text(title,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: overdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant)),
        ),
      ),
      for (final i in items) ItemTile(item: i, overdue: overdue),
    ];
  }
}
