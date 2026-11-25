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
import '../common/empty_state.dart';
import '../common/text_prompt.dart';

/// Tab Chuyến đi (US-20, Figma 20): lọc Sắp tới / Đã qua, thẻ chuyến (ngày, số ngày, nơi đến, tuyến, vài chặng đầu, "Xem lịch trình"),
/// thẻ "Thêm vé hoặc đặt phòng" (→ Nhập từ tệp), dòng hạn mức chuyến đi từ cache `quota_status`.
class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  bool _past = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trips = ref.watch(tripsProvider).value ?? const [];
    final today = CivilDate.of(ref.watch(nowProvider)()).toIso();
    final upcoming = [...trips.where((t) => t.activeOn(today))];
    final past = [...trips.where((t) => !t.activeOn(today))].reversed.toList();
    final shown = _past ? past : upcoming;
    final quota = ref.watch(cachedQuotaProvider).value;
    final limit = quota?.limit(EntitlementKey.maxActiveTrips);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space6),
          children: [
            Row(
              children: [
                Expanded(child: Semantics(header: true, child: Text(l.navTrips, style: theme.textTheme.headlineLarge))),
                IconButton(
                  key: const Key('tripsAdd'),
                  tooltip: l.tripsAddBookingTitle,
                  icon: AppIcon(AppIcons.plus, size: 22, color: theme.colorScheme.primary),
                  onPressed: () => context.push('/import'),
                ),
              ],
            ),
            Text(l.tripsTagline, style: theme.textTheme.bodySmall),
            const SizedBox(height: Tokens.space4),
            Wrap(
              spacing: Tokens.space2,
              runSpacing: Tokens.space2,
              children: [
                _FilterChip(key: const Key('tripsUpcoming'), label: l.tripsUpcoming(upcoming.length), selected: !_past, onTap: () => setState(() => _past = false)),
                _FilterChip(key: const Key('tripsPast'), label: l.tripsPast, selected: _past, onTap: () => setState(() => _past = true)),
              ],
            ),
            const SizedBox(height: Tokens.space4),
            if (trips.isEmpty)
              EmptyState(icon: Icons.luggage_outlined, title: l.tripsEmptyTitle, body: l.tripsEmptyBody)
            else if (shown.isEmpty)
              EmptyState(icon: Icons.history, title: _past ? l.tripsPastEmpty : l.tripsEmptyTitle)
            else
              for (final t in shown) Padding(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space4), child: _TripCard(trip: t, active: !_past)),
            _AddBookingCard(onTap: () => context.push('/import')),
            if (limit != null && limit != unlimited) ...[
              const SizedBox(height: Tokens.space4),
              Text(
                l.tripsQuotaUsage(l.planName(quota!.plan), upcoming.length, limit),
                key: const Key('tripsQuota'),
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (upcoming.length >= limit)
                Text(l.tripsQuotaFull, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : scheme.surface,
        borderRadius: BorderRadius.circular(Tokens.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Tokens.radiusSm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(Tokens.space2),
            child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: selected ? scheme.onPrimary : scheme.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

/// Thẻ chuyến đi (Figma 20): phần tóm tắt nền travel nhạt + tối đa 3 chặng đầu + nút "Xem lịch trình".
class _TripCard extends ConsumerWidget {
  const _TripCard({required this.trip, required this.active});
  final TripSummary trip;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final segments = ref.watch(tripSegmentsProvider(trip.id)).value ?? const <TripSegment>[];
    final range = tripDateRange(context, trip, ref.read(nowProvider)());
    final days = trip.startsOn == null
        ? null
        : CivilDate.parse(trip.endsOn ?? trip.startsOn!).daysSince(CivilDate.parse(trip.startsOn!)) + 1;
    final flight = segments.where((s) => s.bookingType == 'flight' || s.bookingType == 'train' || s.bookingType == 'bus').firstOrNull;
    String? code(Map<String, Object?>? p) => (p?['code'] ?? p?['name']) as String?;
    final from = code(flight?.origin), to = code(segments.where((s) => s.destination != null).lastOrNull?.destination);
    void open() => context.go('/trips/${trip.id}');
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(Tokens.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('trip-${trip.id}'),
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: active ? colors.travelContainer : scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(Tokens.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(Tokens.space5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Tokens.space3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (range != null)
                          DecoratedBox(
                            decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusSm)),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.all(Tokens.space2),
                              child: Text(range.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: colors.travel)),
                            ),
                          ),
                        if (days != null)
                          Text(l.tripDays(days), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: colors.travel)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(trip.destination ?? trip.title ?? l.navTrips,
                        style: theme.textTheme.headlineLarge?.copyWith(fontSize: 32, height: 46 / 32)),
                    if (from != null && to != null && from != to) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: Text(from, style: theme.textTheme.titleMedium?.copyWith(color: colors.travel))),
                          AppIcon(AppIcons.plane, size: 22, color: colors.travel),
                          const SizedBox(width: 10),
                          Text(to, style: theme.textTheme.titleMedium?.copyWith(color: colors.travel)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in segments.take(3))
                    Padding(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space4), child: _SegmentLine(segment: s)),
                  Material(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(Tokens.radiusMd),
                    child: InkWell(
                      key: Key('tripOpen-${trip.id}'),
                      borderRadius: BorderRadius.circular(Tokens.radiusMd),
                      onTap: open,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(AppIcons.trip, size: 20, color: scheme.primary),
                            const SizedBox(width: Tokens.space2),
                            Text(l.tripViewItinerary, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 chặng trên thẻ chuyến: icon loại + "tên · ngày, giờ" + dòng phụ (nơi đi → nơi đến, hoặc số đêm · giờ nhận phòng).
class _SegmentLine extends StatelessWidget {
  const _SegmentLine({required this.segment});
  final TripSegment segment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final travel = RemindColors.of(context).travel;
    final i = segment.item;
    String? hm(DateTime? utc, String? tz) {
      if (utc == null || tz == null || !TimeZones.isValid(tz)) return null;
      final w = TimeZones.toWall(utc, tz).time!;
      return MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay(hour: w.hour, minute: w.minute), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    }

    String place(Map<String, Object?>? p) => ((p?['name'] ?? p?['city'] ?? p?['code']) as String?) ?? '';
    final hotel = segment.bookingType == 'hotel';
    final when = i.startsAt != null && i.tz != null && TimeZones.isValid(i.tz!)
        ? [Fmt.of(context).date(DateTime.parse(TimeZones.toWall(i.startsAt!, i.tz!).date.toIso())), ?hm(i.startsAt, i.tz)].join(', ')
        : null;
    final String? sub;
    if (hotel) {
      final nights = i.startsAt != null && i.endsAt != null && i.tz != null && TimeZones.isValid(i.tz!)
          ? TimeZones.toWall(i.endsAt!, i.tz!).date.daysSince(TimeZones.toWall(i.startsAt!, i.tz!).date)
          : null;
      sub = [if (nights != null && nights > 0) l.tripNights(nights), if (hm(i.startsAt, i.tz) case final t?) l.tripCheckInAt(t)].join(' · ');
    } else if (segment.origin != null || segment.destination != null) {
      sub = '${place(segment.origin)} → ${place(segment.destination)}';
    } else {
      sub = null;
    }
    return Row(
      children: [
        switch (segment.bookingType) {
          'flight' => AppIcon(AppIcons.plane, size: 22, color: travel),
          'hotel' => AppIcon(AppIcons.hotel, size: 22, color: travel),
          final t => Icon(TripDetailScreen.iconFor(t), size: 22, color: travel),
        },
        const SizedBox(width: Tokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text([i.title, if (!hotel) ?when].join(' · '), style: theme.textTheme.titleSmall),
              if (sub != null && sub.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(sub, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AddBookingCard extends StatelessWidget {
  const _AddBookingCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('tripsAddBooking'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          child: Row(
            children: [
              AppIcon(AppIcons.plus, size: 25, color: scheme.primary),
              const SizedBox(width: Tokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.tripsAddBookingTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: Tokens.space1),
                    Text(l.tripsAddBookingBody, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronSmall, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// "20 thg 12 – 24 thg 12" theo CLDR; 1 ngày thì chỉ 1 ngày.
String? tripDateRange(BuildContext context, TripSummary t, DateTime now) {
  if (t.startsOn == null) return null;
  final fmt = Fmt.of(context);
  final s = fmt.date(DateTime.parse(t.startsOn!), now: now);
  if (t.endsOn == null || t.endsOn == t.startsOn) return s;
  return AppLocalizations.of(context).tripDates(s, fmt.date(DateTime.parse(t.endsOn!), now: now));
}

/// Khoảng trống > [minGap] giữa 2 đặt chỗ có giờ (UX §2.5): id đặt chỗ đứng trước → (lúc rảnh từ, múi giờ nơi đó).
/// Lưu trú, thuê xe không chiếm thời gian (đang ở khách sạn vẫn đi chơi được).
Map<String, (DateTime, String)> freeGapsAfter(List<TripSegment> segments, {Duration minGap = const Duration(hours: 3)}) {
  final timed = [
    for (final s in segments)
      if (s.item.startsAt != null && s.item.tz != null && s.bookingType != 'hotel' && s.bookingType != 'car_rental') s,
  ];
  final out = <String, (DateTime, String)>{};
  for (var i = 0; i + 1 < timed.length; i++) {
    final a = timed[i], b = timed[i + 1];
    final free = a.item.endsAt ?? a.item.startsAt!;
    if (b.item.startsAt!.difference(free) <= minGap) continue;
    final tz = (a.destination?['tz'] as String?) ?? a.item.tz!;
    out[a.item.id] = (free, TimeZones.isValid(tz) ? tz : a.item.tz!);
  }
  return out;
}

/// Chi tiết chuyến đi (UX §2.5): timeline theo giờ địa phương của từng điểm (giờ đi theo nơi đi, giờ đến theo nơi đến).
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final trip = (ref.watch(tripsProvider).value ?? const <TripSummary>[]).where((t) => t.id == id).firstOrNull;
    final segments = ref.watch(tripSegmentsProvider(id)).value ?? const <TripSegment>[];
    final now = ref.read(nowProvider)();
    final fmt = Fmt.of(context);
    final range = trip == null ? null : tripDateRange(context, trip, now);
    String? lastDay;
    final children = <Widget>[
      if (range != null)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space2),
          child: Text(range, style: Theme.of(context).textTheme.titleMedium),
        ),
    ];
    final gaps = freeGapsAfter(segments);
    for (final s in segments) {
      final wall = _startWall(s);
      final day = wall?.date.toIso();
      if (day != null && day != lastDay) {
        lastDay = day;
        children.add(Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space4, Tokens.screenMargin, Tokens.space1),
          child: Text(fmt.dayHeader(DateTime.parse(day)), style: Theme.of(context).textTheme.labelLarge),
        ));
      }
      children.add(ListTile(
        key: Key('tripSegment-${s.item.id}'),
        leading: Icon(_icon(s.bookingType)),
        title: Text(s.item.title),
        subtitle: _times(context, s) == null ? null : Text(_times(context, s)!),
        onTap: () => context.push('/item/${s.item.id}'),
      ));
      if (gaps[s.item.id] case (final from, final tz)) {
        children.add(ListTile(
          key: Key('tripAddActivity-${s.item.id}'),
          leading: const Icon(Icons.add),
          title: Text(l.tripAddActivity),
          onTap: () => _addActivity(context, ref, from, tz),
        ));
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(trip?.title ?? l.navTrips),
        actions: [
          PopupMenuButton<String>(
            key: const Key('tripMenu'),
            onSelected: (action) async {
              final repo = ref.read(tripsRepositoryProvider);
              if (action == 'rename') {
                final name = await askText(context, title: l.tripRename, initial: trip?.title, hint: l.tripNameHint, fieldKey: const Key('tripName'));
                if (name != null) await repo.rename(id, name);
                return;
              }
              if (!await _confirmDelete(context)) return;
              await repo.delete(id);
              if (context.mounted) context.go('/trips');
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(l.tripRename)),
              PopupMenuItem(value: 'delete', child: Text(l.tripDelete)),
            ],
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space6), children: children),
    );
  }

  /// Tạo việc trong chuyến ở đầu khoảng trống (tròn lên giờ kế tiếp theo giờ nơi đó), nhắc đúng giờ như Quick Add; mở chi tiết để chỉnh giờ.
  Future<void> _addActivity(BuildContext context, WidgetRef ref, DateTime from, String tz) async {
    final l = AppLocalizations.of(context);
    final title = await askText(context, title: l.tripAddActivity, hint: l.tripActivityHint, fieldKey: const Key('tripActivityName'));
    if (title == null) return;
    final wall = TimeZones.toWall(from, tz);
    final t = wall.time!;
    final rounded = t.minute == 0 ? wall : CivilDateTime(t.hour == 23 ? wall.date.addDays(1) : wall.date, CivilTime(t.hour == 23 ? 0 : t.hour + 1, 0));
    final id = await ref.read(itemsRepositoryProvider).create(
          title: title,
          startsAt: TimeZones.toUtc(rounded, tz).utc,
          tz: tz,
          tripId: this.id,
          reminderOffsets: const [0],
        );
    if (context.mounted) await context.push('/item/$id');
  }

  static CivilDateTime? _startWall(TripSegment s) {
    final i = s.item;
    if (i.startsAt != null && i.tz != null) return TimeZones.toWall(i.startsAt!, i.tz!);
    if (i.startDate != null) return CivilDateTime(CivilDate.parse(i.startDate!));
    return null;
  }

  /// "10:30 → 12:40": giờ đến theo múi giờ nơi đến (chuyến bay qua múi giờ).
  static String? _times(BuildContext context, TripSegment s) {
    final i = s.item;
    if (i.startsAt == null || i.tz == null) return null;
    String hm(DateTime utc, String tz) {
      final w = TimeZones.toWall(utc, tz);
      return MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: w.time!.hour, minute: w.time!.minute),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    }

    final start = hm(i.startsAt!, i.tz!);
    if (i.endsAt == null) return start;
    final endTz = (s.destination?['tz'] as String?) ?? i.tz!;
    return '$start → ${hm(i.endsAt!, TimeZones.isValid(endTz) ? endTz : i.tz!)}';
  }

  static IconData iconFor(String? type) => _icon(type);

  static IconData _icon(String? type) => switch (type) {
        'flight' => Icons.flight,
        'train' => Icons.train,
        'bus' => Icons.directions_bus,
        'hotel' => Icons.hotel,
        'ferry' => Icons.directions_boat,
        'car_rental' => Icons.directions_car,
        _ => Icons.event,
      };

  Future<bool> _confirmDelete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.tripDelete),
            content: Text(l.tripDeleteBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
              TextButton(key: const Key('tripDeleteConfirm'), onPressed: () => Navigator.pop(context, true), child: Text(l.itemDelete)),
            ],
          ),
        ) ??
        false;
  }
}
