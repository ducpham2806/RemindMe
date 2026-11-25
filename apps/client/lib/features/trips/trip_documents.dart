import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import 'trips_screen.dart';

/// Đặt chỗ hiện ở tab Tài liệu: mọi item có loại đặt chỗ.
List<TripSegment> documentSegments(List<TripSegment> segments) => [for (final s in segments) if (s.bookingType != null) s];

/// Tab Tài liệu của chi tiết chuyến (Figma 22): mỗi đặt chỗ 1 thẻ (loại + số hiệu, ngày + tuyến, tệp gốc, mã đặt chỗ sao chép được,
/// mở tệp gốc bằng app của hệ điều hành). Bản gốc chỉ nằm trên máy đã nhập ([OriginalsStore]); dữ liệu đặt chỗ có ở mọi máy.
class DocumentsTab extends ConsumerWidget {
  const DocumentsTab({super.key, required this.segments});
  final List<TripSegment> segments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final docs = documentSegments(segments);
    if (docs.isEmpty) {
      return Container(
        key: const Key('docsEmpty'),
        padding: const EdgeInsetsDirectional.all(Tokens.space5),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.docsEmptyTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Tokens.space1),
            Text(l.docsEmptyBody, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }
    final imports = {for (final s in docs) ?s.importId};
    final files = [for (final id in imports) if (ref.watch(originalNameProvider(id)).value != null) id].length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('docsOffline'),
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Tokens.radiusMd)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.download_outlined, size: 22, color: colors.success),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.docsOfflineTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colors.success)),
                    const SizedBox(height: 2),
                    Text(l.docsOfflineBody, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: Tokens.space5, bottom: Tokens.space3),
          child: Row(
            children: [
              Semantics(header: true, child: Text(l.docsHeader, style: theme.textTheme.labelLarge)),
              const SizedBox(width: Tokens.space2),
              Expanded(
                child: Text(l.docsSummary(docs.length, files),
                    key: const Key('docsSummary'), textAlign: TextAlign.end, style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        ),
        for (final s in docs)
          Padding(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space3), child: _DocCard(segment: s)),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: Tokens.space1),
          child: Text(l.docsFooter, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _DocCard extends ConsumerWidget {
  const _DocCard({required this.segment});
  final TripSegment segment;

  static AppIcons? _icon(String? type) => switch (type) {
        'flight' => AppIcons.plane,
        'hotel' => AppIcons.hotel,
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = segment;
    final i = s.item;
    final now = ref.read(nowProvider)();
    final fmt = Fmt.of(context);
    final number = [?s.carrierCode, ?s.number].join();
    final title = switch (s.bookingType) {
      'flight' when number.isNotEmpty => l.docsFlight(number),
      'train' when number.isNotEmpty => l.docsTrain(number),
      'bus' when number.isNotEmpty => l.docsBus(number),
      'hotel' => l.docsHotel,
      _ => i.title,
    };
    String? day(DateTime? utc, String? tz) {
      if (utc == null) return i.startDate == null ? null : fmt.date(DateTime.parse(i.startDate!), now: now);
      final w = tz != null && TimeZones.isValid(tz) ? TimeZones.toWall(utc, tz).date : CivilDate(utc.year, utc.month, utc.day);
      return fmt.date(DateTime(w.year, w.month, w.day), now: now);
    }

    String? code(Map<String, Object?>? p) => (p?['code'] ?? p?['name']) as String?;
    final from = code(s.origin), to = code(s.destination);
    final start = day(i.startsAt, i.tz);
    final sub = s.bookingType == 'hotel'
        ? [
            if (start != null) switch (day(i.endsAt, (s.destination?['tz'] as String?) ?? i.tz)) {
              final end? when end != start => l.tripDates(start, end),
              _ => start,
            },
            if (title != i.title) i.title,
          ]
        : [?start, if (from != null && to != null) l.tripRouteShort(from, to), if (title != i.title && number.isEmpty) i.title];
    final importId = s.importId;
    final fileName = importId == null ? null : ref.watch(originalNameProvider(importId)).value;
    final icon = _icon(s.bookingType);

    return Material(
      key: Key('doc-${i.id}'),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusLg),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Tokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
                  alignment: Alignment.center,
                  child: icon != null
                      ? AppIcon(icon, size: 24, color: scheme.primary)
                      : Icon(TripDetailScreen.iconFor(s.bookingType), size: 24, color: scheme.primary),
                ),
                const SizedBox(width: Tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (sub.isNotEmpty) Text(sub.join(' · '), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space3),
            Text(fileName ?? l.docsNoOriginal, key: Key('docFile-${i.id}'), style: theme.textTheme.bodySmall),
            if (s.confirmationCode != null) ...[
              const SizedBox(height: Tokens.space3),
              TripCodeRow(code: s.confirmationCode!),
            ],
            const SizedBox(height: Tokens.space1),
            InkWell(
              key: Key(fileName != null ? 'docOpen-${i.id}' : 'docDetails-${i.id}'),
              borderRadius: BorderRadius.circular(Tokens.radiusSm),
              onTap: () => context.push(fileName == null || importId == null ? '/item/${i.id}' : '/document/$importId'),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: Tokens.space3),
                child: Row(
                  children: [
                    AppIcon(AppIcons.file, size: 20, color: scheme.primary),
                    const SizedBox(width: Tokens.space2),
                    Expanded(
                      child: Text(fileName != null ? l.docsOpenOriginal : l.docsOpenDetails,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
                    ),
                    AppIcon(AppIcons.chevronSmall, size: 18, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
