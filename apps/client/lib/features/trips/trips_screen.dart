import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
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
import '../../data/reminders.dart' show describeReminderOffset;
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';
import '../items/item_tile.dart';
import '../common/text_prompt.dart';
import 'trip_documents.dart';
import 'trip_packing.dart';

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

/// Chi tiết chuyến đi (UX §2.5, Figma 21): theo từng ngày của chuyến, giờ theo nơi diễn ra (giờ đi theo nơi đi, giờ đến theo nơi đến).
/// Chuyến bay: giờ đi/đến lớn + mã sân bay, thời lượng, mã đặt chỗ (sao chép), nhắc; khách sạn: thẻ nhận phòng và trả phòng.
/// Ngày chưa có gì: dòng gợi ý; khoảng trống > 3h giữa 2 chặng: "Thêm hoạt động".
class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key, required this.id, this.initialTab = 'itinerary'});
  final String id;
  /// 'itinerary' | 'docs' | 'packing'.
  final String initialTab;

  static IconData iconFor(String? type) => switch (type) {
        'flight' => Icons.flight,
        'train' => Icons.train,
        'bus' => Icons.directions_bus,
        'hotel' => Icons.hotel,
        'ferry' => Icons.directions_boat,
        'car_rental' => Icons.directions_car,
        _ => Icons.event,
      };

  static CivilDateTime? _wall(DateTime? utc, String? tz) => utc == null || tz == null || !TimeZones.isValid(tz) ? null : TimeZones.toWall(utc, tz);

  static String? _destTz(TripSegment s) {
    final tz = s.destination?['tz'] as String?;
    return tz != null && TimeZones.isValid(tz) ? tz : s.item.tz;
  }

  static bool _onDay(TripSegment s, CivilDate d) {
    final i = s.item;
    final a = _wall(i.startsAt, i.tz)?.date ?? (i.startDate == null ? null : CivilDate.parse(i.startDate!));
    if (a == null) return false;
    final b = _wall(i.endsAt, _destTz(s) ?? i.tz)?.date ?? a;
    // Khách sạn chiếm cả các đêm ở giữa (đang ở thì không coi là ngày trống).
    return !d.isBefore(a) && !d.isAfter(s.bookingType == 'hotel' ? b : a);
  }

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late String _tab = widget.initialTab;

  String get id => widget.id;
  static CivilDateTime? _wall(DateTime? utc, String? tz) => TripDetailScreen._wall(utc, tz);
  static String? _destTz(TripSegment s) => TripDetailScreen._destTz(s);
  static bool _onDay(TripSegment s, CivilDate d) => TripDetailScreen._onDay(s, d);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = RemindColors.of(context);
    final trip = (ref.watch(tripsProvider).value ?? const <TripSummary>[]).where((t) => t.id == id).firstOrNull;
    final segments = ref.watch(tripSegmentsProvider(id)).value ?? const <TripSegment>[];
    final now = ref.read(nowProvider)();
    final range = trip == null ? null : tripDateRange(context, trip, now);
    final start = trip?.startsOn == null ? null : CivilDate.parse(trip!.startsOn!);
    final end = trip?.endsOn == null ? start : CivilDate.parse(trip!.endsOn!);
    final days = start == null ? null : end!.daysSince(start) + 1;
    final gaps = freeGapsAfter(segments);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Sự kiện theo ngày địa phương: mỗi chặng ở ngày bắt đầu; khách sạn thêm thẻ trả phòng ở ngày kết thúc.
    final byDay = <String, List<Widget>>{};
    void add(CivilDate d, Widget w) => byDay.putIfAbsent(d.toIso(), () => []).add(w);
    for (final s in segments) {
      final i = s.item;
      final startWall = _wall(i.startsAt, i.tz) ?? (i.startDate == null ? null : CivilDateTime(CivilDate.parse(i.startDate!)));
      if (startWall == null) continue;
      if (s.bookingType == 'hotel') {
        add(startWall.date, _HotelCard(segment: s, checkOut: false));
        final out = _wall(i.endsAt, _destTz(s) ?? i.tz);
        if (out != null && out.date != startWall.date) add(out.date, _HotelCard(segment: s, checkOut: true));
      } else if (s.bookingType != null) {
        add(startWall.date, _LegCard(segment: s));
      } else {
        add(startWall.date, KeyedSubtree(key: Key('tripSegment-${i.id}'), child: ItemTile(key: ValueKey(i.rowKey), item: i, inset: false)));
      }
      if (gaps[i.id] case (final from, final tz)) {
        add(startWall.date, ListTile(
          key: Key('tripAddActivity-${i.id}'),
          contentPadding: EdgeInsetsDirectional.zero,
          leading: Icon(Icons.add, color: scheme.primary),
          title: Text(l.tripAddActivity, style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary)),
          onTap: () => _addActivity(context, from, tz),
        ));
      }
    }
    final zones = {for (final s in segments) ?s.item.tz, for (final s in segments) ?_destTz(s)}.where(TimeZones.isValid).toSet();
    String offsetOf(String tz) => utcOffsetLabel(now, tz);

    final dayList = <Widget>[];
    if (start != null) {
      for (var n = 0; n < days!; n++) {
        final d = start.addDays(n);
        final items = byDay.remove(d.toIso()) ?? const <Widget>[];
        if (items.isEmpty) continue;
        dayList.add(_dayHeader(context, d, l.tripDayN(n + 1), locale));
        for (final w in items) {
          dayList.add(Padding(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space3), child: w));
        }
      }
      final empty = [for (var n = 0; n < days; n++) if (!segments.any((s) => _onDay(s, start.addDays(n)))) start.addDays(n)];
      for (final d in empty) {
        dayList.add(Padding(
          padding: const EdgeInsetsDirectional.only(bottom: Tokens.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.tripEmptyDay(Fmt.of(context).date(DateTime(d.year, d.month, d.day), now: now)), style: theme.textTheme.bodySmall),
              Text(l.tripEmptyDayHint, style: theme.textTheme.bodySmall),
            ],
          ),
        ));
      }
    }
    // Ngày ngoài khoảng của chuyến (dữ liệu cũ): vẫn hiện, không đánh số ngày.
    for (final e in (byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
      dayList.add(_dayHeader(context, CivilDate.parse(e.key), null, locale));
      for (final w in e.value) {
        dayList.add(Padding(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space3), child: w));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space4),
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('tripBack'),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        icon: AppIcon(AppIcons.back, size: 22, color: scheme.onSurface),
                        onPressed: () => context.canPop() ? context.pop() : context.go('/trips'),
                      ),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(trip?.destination ?? trip?.title ?? l.navTrips,
                              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 27, height: 39 / 27)),
                        ),
                      ),
                      PopupMenuButton<String>(
                        key: const Key('tripMenu'),
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (action) async {
                          final repo = ref.read(tripsRepositoryProvider);
                          if (action == 'rename') {
                            final name = await askText(context, title: l.tripRename, initial: trip?.title, hint: l.tripNameHint, fieldKey: const Key('tripName'));
                            if (name != null) await repo.rename(id, name);
                            return;
                          }
                          if (!context.mounted || !await _confirmDelete(context)) return;
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
                  if (trip?.destination != null && trip?.title != null)
                    Text(trip!.title!, key: const Key('tripTitle'), style: theme.textTheme.titleSmall),
                  Text([?range, if (days != null) l.tripDays(days)].join(' · '), style: theme.textTheme.bodySmall),
                  const SizedBox(height: Tokens.space3),
                  Wrap(
                    spacing: Tokens.space2,
                    runSpacing: Tokens.space2,
                    children: [
                      _FilterChip(
                          key: const Key('tripTab-itinerary'),
                          label: l.tripTabItinerary,
                          selected: _tab == 'itinerary',
                          onTap: () => setState(() => _tab = 'itinerary')),
                      _FilterChip(
                          key: const Key('tripTab-docs'),
                          label: switch (documentSegments(segments).length) {
                            0 => l.tripTabDocsEmpty,
                            final n => l.tripTabDocs(n),
                          },
                          selected: _tab == 'docs',
                          onTap: () => setState(() => _tab = 'docs')),
                      _FilterChip(
                          key: const Key('tripTab-packing'),
                          label: switch (trip?.packing) {
                            final p? when p.isNotEmpty => l.tripTabPacking(p.where((x) => x.done).length, p.length),
                            _ => l.tripTabPackingEmpty,
                          },
                          selected: _tab == 'packing',
                          onTap: () => setState(() => _tab = 'packing')),
                    ],
                  ),
                  const SizedBox(height: Tokens.space4),
                  if (_tab == 'packing')
                    if (trip != null) PackingTab(trip: trip) else const SizedBox.shrink()
                  else if (_tab == 'docs')
                    DocumentsTab(segments: segments)
                  else ...[
                  if (zones.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(color: colors.travelContainer, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(Tokens.space3),
                        child: Row(
                          children: [
                            AppIcon(AppIcons.globe, size: 18, color: colors.travel),
                            const SizedBox(width: Tokens.space2),
                            Expanded(
                              child: Text(
                                zones.length == 1 ? l.tripLocalTime(offsetOf(zones.single)) : l.calendarLocalTimeNote,
                                style: theme.textTheme.labelSmall?.copyWith(color: colors.travel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: Tokens.space4),
                  ...dayList,
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space3, Tokens.screenMargin, Tokens.space3),
              child: FilledButton.icon(
                key: Key(switch (_tab) { 'packing' => 'packingAdd', 'docs' => 'docsAdd', _ => 'tripAddToItinerary' }),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsetsDirectional.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radiusMd)),
                  textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                icon: AppIcon(AppIcons.plus, size: 20, color: scheme.onPrimary),
                label: Text(switch (_tab) { 'packing' => l.packingAdd, 'docs' => l.docsAdd, _ => l.tripAddToItinerary }),
                onPressed: switch (_tab) {
                  'packing' => trip == null ? null : () => editPackingItem(context, ref, trip),
                  'docs' => () => context.push('/import'),
                  _ => () => _addMenu(context, start),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayHeader(BuildContext context, CivilDate d, String? dayN, String locale) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: Tokens.space2, bottom: Tokens.space3),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(DateFormat.MMMMEEEEd(locale).format(DateTime(d.year, d.month, d.day)), style: theme.textTheme.labelMedium),
            ),
          ),
          if (dayN != null)
            Text(dayN, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _addMenu(BuildContext context, CivilDate? start) async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(key: const Key('tripAddMenuActivity'), leading: const Icon(Icons.add_task), title: Text(l.tripAddActivity), onTap: () => Navigator.pop(context, 'activity')),
            ListTile(
                key: const Key('tripAddMenuImport'),
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(l.tripsAddBookingTitle),
                onTap: () => Navigator.pop(context, 'import')),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'import') {
      await context.push('/import');
    } else if (choice == 'activity') {
      final title = await askText(context, title: l.tripAddActivity, hint: l.tripActivityHint, fieldKey: const Key('tripActivityName'));
      if (title == null) return;
      final itemId = await ref.read(itemsRepositoryProvider).create(title: title, startDate: start?.toIso(), tripId: id);
      if (context.mounted) await context.push('/item/$itemId');
    }
  }

  /// Tạo việc trong chuyến ở đầu khoảng trống (tròn lên giờ kế tiếp theo giờ nơi đó), nhắc đúng giờ như Quick Add; mở chi tiết để chỉnh giờ.
  Future<void> _addActivity(BuildContext context, DateTime from, String tz) async {
    final l = AppLocalizations.of(context);
    final title = await askText(context, title: l.tripAddActivity, hint: l.tripActivityHint, fieldKey: const Key('tripActivityName'));
    if (title == null) return;
    final wall = TimeZones.toWall(from, tz);
    final t = wall.time!;
    final rounded = t.minute == 0 ? wall : CivilDateTime(t.hour == 23 ? wall.date.addDays(1) : wall.date, CivilTime(t.hour == 23 ? 0 : t.hour + 1, 0));
    final itemId = await ref.read(itemsRepositoryProvider).create(
          title: title,
          startsAt: TimeZones.toUtc(rounded, tz).utc,
          tz: tz,
          tripId: id,
          reminderOffsets: const [0],
        );
    if (context.mounted) await context.push('/item/$itemId');
  }

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

String _hm(BuildContext context, CivilDateTime w) => MaterialLocalizations.of(context)
    .formatTimeOfDay(TimeOfDay(hour: w.time!.hour, minute: w.time!.minute), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));

/// Hàng mã đặt chỗ + nút sao chép (Figma 21).
class TripCodeRow extends StatelessWidget {
  const TripCodeRow({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, Tokens.space1, Tokens.space1, Tokens.space1),
        child: Row(
          children: [
            Expanded(child: Text(l.tripBookingCode, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant))),
            SelectableText(code, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            IconButton(
              key: Key('tripCopy-$code'),
              tooltip: l.tripCopyCode,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy_outlined, size: 18, color: theme.colorScheme.primary),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ScaffoldMessenger.maybeOf(context)
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l.tripCodeCopied)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Chặng bay/tàu/xe: giờ đi – thời lượng – giờ đến, mã nơi đi/đến, mã đặt chỗ, nhắc, "Xem chi tiết".
class _LegCard extends ConsumerWidget {
  const _LegCard({required this.segment});
  final TripSegment segment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final travel = RemindColors.of(context).travel;
    final i = segment.item;
    final dep = TripDetailScreen._wall(i.startsAt, i.tz);
    final arr = TripDetailScreen._wall(i.endsAt, TripDetailScreen._destTz(segment));
    final dur = i.startsAt != null && i.endsAt != null ? i.endsAt!.difference(i.startsAt!) : null;
    String place(Map<String, Object?>? p) => [?(p?['code'] as String?), ?((p?['name'] ?? p?['city']) as String?)].join(' · ');
    final reminders = ref.watch(remindersProvider(i.id)).value ?? const [];
    final offsets = [for (final r in reminders) if (r.offsetMinutes != null) r.offsetMinutes!]..sort();
    Widget icon(double size) => segment.bookingType == 'flight'
        ? AppIcon(AppIcons.plane, size: size, color: travel)
        : Icon(TripDetailScreen.iconFor(segment.bookingType), size: size, color: travel);
    final big = theme.textTheme.headlineLarge?.copyWith(fontSize: 26, height: 38 / 26);
    final small = theme.textTheme.bodySmall;
    return Material(
      key: Key('tripSegment-${i.id}'),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(Tokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              icon(22),
              const SizedBox(width: 10),
              Expanded(child: Text(i.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
            ]),
            if (dep != null) ...[
              const SizedBox(height: Tokens.space3),
              Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_hm(context, dep), style: big),
                      Text(place(segment.origin), style: small),
                    ]),
                  ),
                  Expanded(
                    child: Column(children: [
                      icon(20),
                      if (dur != null)
                        Text(l.tripDuration(dur.inHours, dur.inMinutes % 60),
                            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (arr != null) Text(_hm(context, arr), style: big),
                      Text(place(segment.destination), style: small, textAlign: TextAlign.end),
                    ]),
                  ),
                ],
              ),
            ],
            if (segment.confirmationCode != null) ...[const SizedBox(height: Tokens.space3), TripCodeRow(code: segment.confirmationCode!)],
            if (offsets.isNotEmpty) ...[
              const SizedBox(height: Tokens.space3),
              Row(children: [
                Icon(Icons.schedule, size: 16, color: scheme.primary),
                const SizedBox(width: Tokens.space2),
                Expanded(
                  child: Text([for (final o in offsets) describeReminderOffset(l, o)].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant)),
                ),
              ]),
            ],
            const SizedBox(height: Tokens.space3),
            Material(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(Tokens.radiusMd),
              child: InkWell(
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
                onTap: () => context.push('/item/${i.id}'),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.description_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: Tokens.space2),
                    Text(l.tripOpenDetails, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.primary)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ nhận phòng / trả phòng.
class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.segment, required this.checkOut});
  final TripSegment segment;
  final bool checkOut;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final travel = RemindColors.of(context).travel;
    final i = segment.item;
    final tz = i.tz;
    final inWall = TripDetailScreen._wall(i.startsAt, tz);
    final outWall = TripDetailScreen._wall(i.endsAt, TripDetailScreen._destTz(segment) ?? tz);
    final at = checkOut ? outWall : inWall;
    final nights = inWall != null && outWall != null ? outWall.date.daysSince(inWall.date) : null;
    final title = [if (at != null) _hm(context, at), checkOut ? l.tripCheckOut : l.tripCheckIn].join(' · ');
    final sub = [i.title, if (!checkOut && nights != null && nights > 0) l.tripNights(nights)].join(' · ');
    return Material(
      key: Key(checkOut ? 'tripCheckOut-${i.id}' : 'tripSegment-${i.id}'),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/item/${i.id}'),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(Tokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                AppIcon(AppIcons.hotel, size: 24, color: travel),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15, height: 22 / 15)),
                    const SizedBox(height: 3),
                    Text(sub, style: theme.textTheme.bodySmall),
                  ]),
                ),
              ]),
              if (!checkOut && segment.confirmationCode != null) ...[
                const SizedBox(height: Tokens.space3),
                TripCodeRow(code: segment.confirmationCode!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
