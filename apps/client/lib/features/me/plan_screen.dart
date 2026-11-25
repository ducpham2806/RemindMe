import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

/// Tôi → Gói & mức sử dụng (Figma C46, pricing-entitlements.md §2): tên gói, từng hạn mức (giới hạn và số đã dùng đều từ
/// `quota_status` của server, cache sau mỗi lần đồng bộ), số thiết bị đang hoạt động. Kéo xuống để đồng bộ lại.
/// Mua trong app (RevenueCat) chưa có: nút Nâng cấp / Khôi phục mờ.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  /// Hạn mức hiển thị, theo thứ tự Figma.
  static const keys = [
    EntitlementKey.maxRemindersPerDay,
    EntitlementKey.maxRecurringSeries,
    EntitlementKey.maxActiveAppointments,
    EntitlementKey.maxActiveTrips,
    EntitlementKey.smartImportsPerMonth,
    EntitlementKey.maxLists,
  ];

  static String label(AppLocalizations l, String key) => switch (key) {
        EntitlementKey.maxRemindersPerDay => l.planUsageReminders,
        EntitlementKey.maxRecurringSeries => l.planUsageSeries,
        EntitlementKey.maxActiveAppointments => l.planUsageAppointments,
        EntitlementKey.maxActiveTrips => l.planUsageTrips,
        EntitlementKey.smartImportsPerMonth => l.planUsageImports,
        _ => l.planUsageLists,
      };

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(remoteSyncProvider)?.run();
    ref.invalidate(cachedQuotaProvider);
    ref.invalidate(accountSessionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = Fmt.of(context);
    final nf = NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag());
    final quota = ref.watch(cachedQuotaProvider).value;
    final online = ref.watch(remoteSyncProvider) != null;
    final small = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant);

    if (quota == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.planTitle)),
        body: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            children: [
              const SizedBox(height: Tokens.space10),
              EmptyState(icon: Icons.cloud_off_outlined, title: l.planNoData, body: online ? l.planNoDataBody : l.planOffline),
            ],
          ),
        ),
      );
    }

    final plus = quota.plan != 'free';
    final planName = plus ? l.planPlus : l.planFree;
    final sessions = ref.watch(accountSessionsProvider).value;
    final devicesUsed = sessions == null || sessions.isEmpty ? 1 : sessions.where((s) => s.active).length;
    final tz = ref.watch(deviceTimeZoneProvider);
    final today = TimeZones.toWall(ref.watch(nowProvider)().toUtc(), tz).date;
    final resetOn = DateTime(today.year, today.month + 1);
    String count(int n) => nf.format(n);

    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space6),
          children: [
            Semantics(header: true, child: Text(l.planTitle, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 28, height: 38 / 28))),
            const SizedBox(height: Tokens.space4),
            Container(
              key: const Key('planCard'),
              padding: const EdgeInsetsDirectional.all(18),
              decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.planCardName(planName),
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, height: 32 / 22, fontWeight: FontWeight.w600, color: scheme.primary)),
                  const SizedBox(height: Tokens.space1),
                  Text(plus ? l.planPlusTagline : l.planFreeTagline, style: theme.textTheme.bodyMedium),
                  if (plus && quota.periodEnd != null)
                    Text(l.planRenews(fmt.numericDate(quota.periodEnd!.toLocal())), style: small),
                ],
              ),
            ),
            const SizedBox(height: Tokens.space4),
            Text(l.planUpdatedAt(fmt.time(quota.fetchedAt.toUtc())), style: small),
            const SizedBox(height: Tokens.space2),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(Tokens.space4, Tokens.space2, Tokens.space4, Tokens.space4),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusXl)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final k in keys) _UsageRow(key: Key('planUsage-$k'), label: label(l, k), used: quota.used(k), limit: quota.limit(k), count: count),
                ],
              ),
            ),
            const SizedBox(height: Tokens.space4),
            Container(
              key: const Key('planDevices'),
              padding: const EdgeInsetsDirectional.all(Tokens.space4),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quota.isUnlimited(EntitlementKey.maxActiveDevices)
                        ? l.planUnlimited(count(devicesUsed))
                        : l.planDevices(count(devicesUsed), count(quota.limit(EntitlementKey.maxActiveDevices))),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (quota.featureLevel(EntitlementKey.featureEnhancedVoice) > 0 && quota.featureLevel(EntitlementKey.featureAltCalendars) > 0)
                    Padding(padding: const EdgeInsetsDirectional.only(top: Tokens.space1), child: Text(l.planIncluded, style: small)),
                ],
              ),
            ),
            const SizedBox(height: Tokens.space3),
            if (!quota.isUnlimited(EntitlementKey.smartImportsPerMonth)) Text(l.planImportsReset(fmt.numericDate(resetOn)), style: small),
            const SizedBox(height: Tokens.space4),
            if (!plus) ...[
              FilledButton(key: const Key('planUpgrade'), onPressed: null, child: Text(l.planUpgrade)),
              const SizedBox(height: Tokens.space3),
            ],
            OutlinedButton(key: const Key('planRestore'), onPressed: null, child: Text(l.planRestore)),
            const SizedBox(height: Tokens.space2),
            Text(l.planStoreSoon, textAlign: TextAlign.center, style: small),
            const SizedBox(height: Tokens.space4),
            Text(l.planDowngradeNote, style: small),
          ],
        ),
      ),
    );
  }
}

/// Một hạn mức: tên, "4 / 10 đã dùng" (hoặc không giới hạn), thanh tiến độ (≥ 80% màu warning, design-system §6 QuotaMeter).
class _UsageRow extends StatelessWidget {
  const _UsageRow({super.key, required this.label, required this.used, required this.limit, required this.count});
  final String label;
  final int used, limit;
  final String Function(int) count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final noLimit = limit == unlimited;
    final ratio = noLimit ? 0.0 : (limit <= 0 ? 1.0 : (used / limit).clamp(0.0, 1.0));
    final color = !noLimit && ratio >= 0.8 ? colors.warning : scheme.primary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Tokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(noLimit ? l.planUnlimited(count(used)) : l.planUsed(count(used), count(limit)),
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: color)),
          if (!noLimit) ...[
            const SizedBox(height: Tokens.space1),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: ratio, minHeight: 4, color: color, backgroundColor: colors.primaryTrack),
            ),
          ],
        ],
      ),
    );
  }
}
