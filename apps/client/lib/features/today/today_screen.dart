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
      body: Column(
        children: [
          const _ReminderHealthCard(),
          Expanded(child: _body(context, l, sections)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, AsyncValue<TodaySections> sections) {
    return switch (sections) {
      AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.wb_sunny_outlined, title: l.todayEmptyTitle, body: l.todayEmptyBody),
        AsyncData(:final value) => _SectionList(sections: value),
        AsyncError() => EmptyState(icon: Icons.error_outline, title: l.loadError),
        _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// UX §6b: thiếu quyền thông báo / báo thức chính xác thì nhắc có thể không kêu. Chỉ hiện khi đã có nhắc.
class _ReminderHealthCard extends ConsumerWidget {
  const _ReminderHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(notificationHealthProvider).value;
    final has = ref.watch(hasRemindersProvider).value ?? false;
    if (health == null || health.ok || !has) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const Key('reminderHealthCard'),
      color: theme.colorScheme.errorContainer,
      margin: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, 0),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Tokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.remindersMayNotRingTitle, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
            const SizedBox(height: Tokens.space1),
            Text(l.remindersMayNotRingBody, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () async {
                  final os = ref.read(notificationSchedulerProvider);
                  if (!health.notificationsAllowed) {
                    await os.requestPermission();
                  } else {
                    await os.openExactAlarmSettings();
                  }
                  ref.invalidate(notificationHealthProvider);
                },
                child: Text(l.remindersAllow),
              ),
            ),
          ],
        ),
      ),
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
      for (final i in items) ItemTile(key: ValueKey(i.rowKey), item: i, overdue: overdue),
    ];
  }
}
