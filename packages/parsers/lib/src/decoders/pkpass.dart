import 'dart:convert';

import 'package:archive/archive.dart';

import '../extract/candidate.dart';
import 'bcbp.dart';

/// Apple Wallet `.pkpass` (zip có `pass.json`), E1.1. Thẻ lên máy bay có mã BCBP thì lấy BCBP làm gốc (chính xác hơn),
/// trường của pass chỉ bổ sung giờ, cổng, nhà ga. Chữ ký của pass không kiểm (chỉ đọc nội dung người dùng tự chia sẻ).
class PkpassDecoder {
  const PkpassDecoder();

  List<Candidate> decodeZip(List<int> bytes, {required DateTime reference}) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      return const [];
    }
    final file = archive.files.where((f) => f.name == 'pass.json').firstOrNull;
    if (file == null) return const [];
    return decodePassJson(utf8.decode(file.content, allowMalformed: true), reference: reference);
  }

  List<Candidate> decodePassJson(String json, {required DateTime reference}) {
    final Map<String, Object?> pass;
    try {
      pass = (jsonDecode(json) as Map).cast<String, Object?>();
    } on Object {
      return const [];
    }
    final style = ['boardingPass', 'eventTicket', 'generic', 'coupon', 'storeCard'].where(pass.containsKey).firstOrNull;
    if (style == null || style == 'coupon' || style == 'storeCard') return const [];
    final body = (pass[style]! as Map).cast<String, Object?>();
    final fields = <_Field>[
      for (final group in ['headerFields', 'primaryFields', 'secondaryFields', 'auxiliaryFields', 'backFields'])
        for (final f in (body[group] as List<Object?>? ?? const []))
          if (f is Map) _Field(group, '${f['key'] ?? ''}', '${f['label'] ?? ''}', f['value']),
    ];
    String? find(RegExp re) {
      for (final f in fields) {
        if (re.hasMatch(f.key) || re.hasMatch(f.label)) {
          final v = f.text;
          if (v != null) return v;
        }
      }
      return null;
    }

    final relevant = LocalTime.fromIso(pass['relevantDate'] as String?);
    final provider = (pass['organizationName'] as String?)?.trim();
    final message = _barcodeMessage(pass);

    if (style == 'boardingPass') {
      final transit = '${body['transitType'] ?? ''}';
      final bcbp = message == null ? null : const BcbpDecoder().decode(message, reference: reference);
      final gate = find(RegExp('gate', caseSensitive: false));
      final terminal = find(RegExp('terminal', caseSensitive: false));
      final departTime = find(RegExp(r'depart|boarding.?time|^time$', caseSensitive: false));
      final start = LocalTime.fromIso(departTime) ?? relevant;
      if (bcbp != null && bcbp.isNotEmpty) {
        final first = bcbp.first.fields;
        // BCBP chỉ có ngày: nếu pass có giờ cùng ngày thì dùng.
        final startsAt = start != null && start.hasTime && first.startsAt != null && start.local.startsWith(first.startsAt!.local)
            ? start
            : first.startsAt;
        return [
          Candidate(
            kind: CandidateKind.booking,
            bookingType: BookingType.flight,
            source: 'pkpass+bcbp',
            confidence: 0.99,
            fields: CandidateFields(
              provider: provider,
              confirmationCode: first.confirmationCode,
              carrierCode: first.carrierCode,
              number: first.number,
              origin: Place(code: first.origin?.code, terminal: terminal, gate: gate),
              destination: first.destination,
              startsAt: startsAt,
              seat: first.seat ?? find(RegExp('seat', caseSensitive: false)),
            ),
          ),
          ...bcbp.skip(1),
        ];
      }
      final primary = fields.where((f) => f.group == 'primaryFields').toList();
      String? code(_Field? f) => f?.text != null && RegExp(r'^[A-Z]{3}$').hasMatch(f!.text!) ? f.text : null;
      final flight = find(RegExp(r'flight', caseSensitive: false));
      final fm = flight == null ? null : RegExp(r'^([A-Z0-9]{2})\s*0*(\d{1,4}[A-Z]?)$').firstMatch(flight.replaceAll(' ', ''));
      return [
        Candidate(
          kind: CandidateKind.booking,
          bookingType: switch (transit) {
            'PKTransitTypeTrain' => BookingType.train,
            'PKTransitTypeBus' => BookingType.bus,
            'PKTransitTypeBoat' => BookingType.ferry,
            _ => BookingType.flight,
          },
          source: 'pkpass',
          confidence: 0.9,
          fields: CandidateFields(
            provider: provider,
            confirmationCode: find(RegExp(r'pnr|confirmation|booking|record|reference', caseSensitive: false)),
            carrierCode: fm?[1],
            number: fm?[2] ?? flight,
            origin: Place(code: code(primary.firstOrNull), name: primary.firstOrNull?.label.trim().isEmpty ?? true ? null : primary.first.label, terminal: terminal, gate: gate),
            destination: Place(
                code: code(primary.length > 1 ? primary[1] : null),
                name: primary.length > 1 && primary[1].label.trim().isNotEmpty ? primary[1].label : null),
            startsAt: start,
            seat: find(RegExp('seat', caseSensitive: false)),
            carriage: find(RegExp(r'coach|carriage|car\b', caseSensitive: false)),
          ),
        ),
      ];
    }

    // eventTicket / generic: vé sự kiện, thẻ khác có thời điểm.
    final title = (pass['description'] as String?)?.trim() ?? fields.where((f) => f.group == 'primaryFields').firstOrNull?.text;
    return [
      Candidate(
        kind: style == 'eventTicket' ? CandidateKind.booking : CandidateKind.event,
        bookingType: style == 'eventTicket' ? BookingType.eventTicket : null,
        source: 'pkpass',
        confidence: 0.9,
        fields: CandidateFields(
          title: title,
          provider: provider,
          startsAt: LocalTime.fromIso(find(RegExp(r'date|start|time', caseSensitive: false))) ?? relevant,
          locationText: find(RegExp(r'venue|location|address', caseSensitive: false)),
          seat: find(RegExp('seat', caseSensitive: false)),
          confirmationCode: find(RegExp(r'order|confirmation|booking|ticket.?(no|number|id)', caseSensitive: false)),
        ),
      ),
    ];
  }

  static String? _barcodeMessage(Map<String, Object?> pass) {
    final list = pass['barcodes'];
    final b = list is List && list.isNotEmpty ? list.first : pass['barcode'];
    return b is Map ? b['message'] as String? : null;
  }
}

class _Field {
  _Field(this.group, this.key, this.label, this.value);
  final String group;
  final String key;
  final String label;
  final Object? value;
  String? get text {
    final v = value;
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }
}
