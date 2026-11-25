import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_core/remindme_core.dart';
import 'package:remindme_data/remindme_data.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/empty_state.dart';

/// Tab Chuyến đi (US-20): các chuyến theo ngày đi, chuyến đã qua ở cuối.
class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripsProvider).value ?? const [];
    final today = CivilDate.of(ref.watch(nowProvider)()).toIso();
    final ordered = [...trips.where((t) => t.activeOn(today)), ...trips.where((t) => !t.activeOn(today)).toList().reversed];
    return Scaffold(
      appBar: AppBar(title: Text(l.navTrips)),
      body: ordered.isEmpty
          ? EmptyState(icon: Icons.luggage_outlined, title: l.tripsEmptyTitle, body: l.tripsEmptyBody)
          : ListView(
              children: [
                for (final t in ordered)
                  ListTile(
                    key: Key('trip-${t.id}'),
                    leading: Icon(Icons.luggage_outlined, color: t.activeOn(today) ? null : Theme.of(context).disabledColor),
                    title: Text(t.title ?? l.navTrips),
                    subtitle: Text([?tripDateRange(context, t, ref.read(nowProvider)()), l.tripsItemCount(t.itemCount)].join(' · ')),
                    onTap: () => context.go('/trips/${t.id}'),
                  ),
              ],
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
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(trip?.title ?? l.navTrips),
        actions: [
          PopupMenuButton<String>(
            key: const Key('tripMenu'),
            onSelected: (_) async {
              if (!await _confirmDelete(context)) return;
              await ref.read(tripsRepositoryProvider).delete(id);
              if (context.mounted) context.go('/trips');
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l.tripDelete))],
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsetsDirectional.only(bottom: Tokens.space6), children: children),
    );
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
