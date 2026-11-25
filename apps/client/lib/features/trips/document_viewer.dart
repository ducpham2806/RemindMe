import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:remindme_parsers/remindme_parsers.dart';

import '../../core/l10n/formatters.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../import/import_decode.dart';
import '../import/import_providers.dart';

/// Bản gốc đọc lại trên máy: (tên tệp, các mục). null = không có bản gốc trên máy này. Lỗi giải mã → AsyncError.
final originalDocumentProvider =
    FutureProvider.autoDispose.family<({String name, List<Candidate> items})?, (String, String)>((ref, key) async {
  final (importId, lang) = key;
  final file = await ref.read(originalsStoreProvider).read(importId);
  if (file == null) return null;
  final preview = await ref.read(importDecoderProvider)(ImportRequest(
    name: file.name,
    bytes: file.bytes,
    packSources: await ref.read(nluPackSourcesProvider(lang).future),
    airportsTsv: await ref.read(airportsTsvProvider.future),
    now: ref.read(nowProvider)(),
    region: ref.read(deviceRegionProvider),
  ));
  return (name: file.name, items: preview.candidates);
});

/// Tài liệu gốc (Figma 28): đọc lại tệp đã nhập ngay trên máy và hiện từng mục dạng vé/xác nhận, không cần mạng
/// và không cần app khác (Android thường không mở được .pkpass/.eml). Nút trên thanh tiêu đề chuyển tệp cho app khác.
class DocumentViewerScreen extends ConsumerWidget {
  const DocumentViewerScreen({super.key, required this.importId});
  final String importId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final doc = ref.watch(originalDocumentProvider((importId, lang)));
    final data = doc.value;
    final items = data?.items ?? const <Candidate>[];

    Future<void> openExternal() async {
      final ok = await ref.read(originalsStoreProvider).open(importId);
      if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.docsOpenFailed)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.docViewerTitle),
        actions: [
          if (data != null)
            IconButton(
              key: const Key('docViewerExternal'),
              tooltip: l.docViewerOpenExternal,
              icon: const Icon(Icons.open_in_new),
              onPressed: openExternal,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, Tokens.space2, Tokens.screenMargin, Tokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.docViewerFooter, style: theme.textTheme.bodySmall),
              const SizedBox(height: Tokens.space3),
              FilledButton.icon(
                key: const Key('docViewerBack'),
                icon: AppIcon(AppIcons.back, size: 18, color: theme.colorScheme.onPrimary),
                label: Text(l.docViewerBack),
                onPressed: () => context.canPop() ? context.pop() : context.go('/trips'),
              ),
            ],
          ),
        ),
      ),
      body: doc.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(Tokens.screenMargin, 0, Tokens.screenMargin, Tokens.space5),
              children: [
                if (data != null) Text(data.name, key: const Key('docViewerName'), style: theme.textTheme.bodySmall),
                const SizedBox(height: Tokens.space4),
                if (data == null || doc.hasError || items.isEmpty)
                  Container(
                    key: const Key('docViewerUnreadable'),
                    padding: const EdgeInsetsDirectional.all(Tokens.space4),
                    decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusMd)),
                    child: Text(data == null && !doc.hasError ? l.docsNoOriginal : l.docViewerUnreadable, style: theme.textTheme.bodyMedium),
                  )
                else ...[
                  Text(l.docViewerMeta(items.length), style: theme.textTheme.bodySmall),
                  for (final (i, c) in items.indexed) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: Tokens.space5, bottom: Tokens.space2),
                      child: Text(l.docViewerSection(i + 1, items.length, _kind(l, c)), style: theme.textTheme.labelMedium),
                    ),
                    KeyedSubtree(key: Key('docViewerItem-$i'), child: _ItemCard(c: c)),
                  ],
                ],
              ],
            ),
    );
  }

  static String _kind(AppLocalizations l, Candidate c) => switch ((c.kind, c.bookingType)) {
        (_, BookingType.flight) => l.docKindFlight,
        (_, BookingType.train) => l.docKindTrain,
        (_, BookingType.bus) => l.docKindBus,
        (_, BookingType.hotel) => l.docKindHotel,
        (CandidateKind.booking, _) => l.docKindBooking,
        (CandidateKind.appointment, _) => l.docKindAppointment,
        (CandidateKind.event, _) => l.docKindEvent,
        _ => l.docKindTask,
      };
}

/// Giờ tường in trên tài liệu ('YYYY-MM-DD' hoặc 'YYYY-MM-DDTHH:mm'); giữ nguyên giờ nơi diễn ra, không đổi sang giờ máy.
DateTime? _wall(LocalTime? t) => t == null ? null : DateTime.tryParse(t.local.length > 16 ? t.local.substring(0, 16) : t.local);
bool _hasTime(LocalTime? t) => t != null && t.local.contains('T');

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.c});
  final Candidate c;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final travel = RemindColors.of(context).travel;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final mat = MaterialLocalizations.of(context);
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    String date(DateTime d) => DateFormat.yMd(locale).format(d);
    String time(DateTime d) => mat.formatTimeOfDay(TimeOfDay(hour: d.hour, minute: d.minute), alwaysUse24HourFormat: h24);
    String when(LocalTime? t) {
      final d = _wall(t);
      if (d == null) return '';
      return _hasTime(t) ? '${date(d)} · ${time(d)}' : date(d);
    }

    final f = c.fields;
    final number = [?f.carrierCode, ?f.number].join();
    final small = theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant);
    final transport = c.bookingType == BookingType.flight || c.bookingType == BookingType.train || c.bookingType == BookingType.bus;
    final hotel = c.bookingType == BookingType.hotel;

    Widget header(Widget icon, String label, String title) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: Tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall?.copyWith(color: travel, fontWeight: FontWeight.w600)),
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        );

    final children = <Widget>[];
    if (transport) {
      final dep = _wall(f.startsAt), arr = _wall(f.endsAt);
      children
        ..add(header(
            c.bookingType == BookingType.flight
                ? AppIcon(AppIcons.plane, size: 26, color: travel)
                : Icon(c.bookingType == BookingType.train ? Icons.train : Icons.directions_bus, size: 26, color: travel),
            l.docETicket, [?f.provider, if (number.isNotEmpty) number].join(' · ')))
        ..add(const SizedBox(height: Tokens.space4))
        ..add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _place(context, f.origin, CrossAxisAlignment.start)),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6),
              child: Icon(Icons.arrow_forward, size: 22, color: travel, textDirection: Directionality.of(context)),
            ),
            Expanded(child: _place(context, f.destination, CrossAxisAlignment.end)),
          ],
        ))
        ..add(const SizedBox(height: Tokens.space3))
        ..add(Row(
          children: [
            Expanded(child: Text(when(f.startsAt), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
            if (arr != null && _hasTime(f.endsAt))
              Text(
                // Ngày đến khác ngày đi thì ghi cả ngày.
                l.docArrives(dep != null && DateUtils.isSameDay(dep, arr) ? time(arr) : when(f.endsAt)),
                style: theme.textTheme.bodyMedium?.copyWith(color: travel, fontWeight: FontWeight.w500),
              ),
          ],
        ));
      if (f.confirmationCode != null) {
        children
          ..add(const Divider(height: Tokens.space6))
          ..add(Text(l.docCodeUpper(f.confirmationCode!), style: small));
      }
    } else if (hotel) {
      final inT = f.checkIn ?? f.startsAt, outT = f.checkOut ?? f.endsAt;
      final a = _wall(inT), b = _wall(outT);
      final nights = a != null && b != null ? DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays : null;
      final fmt = Fmt.of(context);
      children
        ..add(header(AppIcon(AppIcons.hotel, size: 26, color: travel), l.docHotelLabel, f.title ?? f.provider ?? ''))
        ..add(const SizedBox(height: Tokens.space3));
      if (a != null) {
        children.add(Text(
          [b == null ? date(a) : l.tripDates(fmt.date(a), fmt.date(b)), if (nights != null && nights > 0) l.tripNights(nights)].join(' · '),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ));
      }
      children
        ..add(const SizedBox(height: Tokens.space3))
        ..add(Row(
          children: [
            Expanded(child: _labeled(context, l.tripCheckIn, when(inT))),
            Expanded(child: _labeled(context, l.tripCheckOut, when(outT))),
          ],
        ));
      if (f.confirmationCode != null) {
        children
          ..add(const Divider(height: Tokens.space6))
          ..add(Row(children: [
            Expanded(child: Text(l.tripBookingCode, style: small)),
            Text(f.confirmationCode!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]));
      }
    } else {
      children
        ..add(Text(f.title ?? f.provider ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)))
        ..add(Text(when(f.startsAt ?? f.due ?? f.checkIn), style: theme.textTheme.bodyMedium));
      if (f.locationText != null || f.department != null) children.add(Text([?f.department, ?f.locationText].join(' · '), style: small));
      if (f.confirmationCode != null) children.add(Text(l.docCodeUpper(f.confirmationCode!), style: small));
    }

    return Container(
      padding: const EdgeInsetsDirectional.all(Tokens.space4),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(Tokens.radiusLg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _place(BuildContext context, Place? p, CrossAxisAlignment align) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(p?.code ?? p?.name ?? '', style: theme.textTheme.titleLarge?.copyWith(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w700)),
        if (p?.code != null && p?.name != null)
          Text(p!.name!, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _labeled(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
