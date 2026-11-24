import 'dart:convert';

import '../extract/candidate.dart';
import '../nlu/pack.dart';
import 'airports.dart';
import 'document.dart';
import 'generic.dart';
import 'slots.dart';
import 'values.dart';
import 'vocabulary.dart';

/// Trường mẫu nhà cung cấp có thể điền (khóa của `fields` trong mẫu JSON, `templates/template.schema.json`).
const templateFieldNames = {
  'confirmation_code', 'flight_number', 'carrier_code', 'number', 'origin', 'destination', 'terminal', 'gate', 'seat', 'carriage',
  'class', 'passenger_count', 'total', 'departure_date', 'departure_time', 'arrival_date', 'arrival_time', 'check_in_date',
  'check_in_time', 'check_out_date', 'check_out_time', 'property', 'address',
};

/// Trường dùng chung cho mọi khối lặp (in 1 lần ở đầu tài liệu): không thấy trong khối thì tìm cả tài liệu.
const _headerFields = {'confirmation_code', 'passenger_count', 'total', 'property', 'address', 'class'};

enum TemplateValueType { text, date, time, iata, money, int, flightNumber }

class TemplateField {
  TemplateField({this.anchors = const [], this.right = true, this.below = true, this.pattern, this.group, this.type = TemplateValueType.text, this.nth = 1});

  factory TemplateField.fromJson(Map<String, Object?> j) {
    final dir = (j['dir'] as String?) ?? 'right|below';
    return TemplateField(
      anchors: [for (final a in (j['anchors'] as List<Object?>? ?? const [])) '$a'],
      right: dir.contains('right'),
      below: dir.contains('below'),
      pattern: j['pattern'] == null ? null : RegExp(j['pattern']! as String, unicode: true),
      group: j['group'] as int?,
      type: switch (j['type'] as String? ?? 'text') {
        'text' => TemplateValueType.text,
        'date' => TemplateValueType.date,
        'time' => TemplateValueType.time,
        'iata' => TemplateValueType.iata,
        'money' => TemplateValueType.money,
        'int' => TemplateValueType.int,
        'flight_number' => TemplateValueType.flightNumber,
        final t => throw FormatException('type không hỗ trợ: $t'),
      },
      nth: j['nth'] as int? ?? 1,
    );
  }

  /// Nhãn in trên tài liệu; rỗng = tìm [pattern]/[type] trong cả khối, lấy lần thứ [nth].
  final List<String> anchors;
  final bool right;
  final bool below;
  final RegExp? pattern;
  /// Nhóm của [pattern] làm giá trị (mặc định: nhóm 1 nếu có, không thì cả chuỗi khớp).
  final int? group;
  final TemplateValueType type;
  final int nth;
}

/// Mẫu khai báo cho 1 loại tài liệu của 1 nhà cung cấp (on-device-extraction.md §4.2). Cập nhật qua CDN, không cần phát hành app;
/// app chỉ nhận mẫu có chữ ký hợp lệ (E4.4, chưa làm).
class ProviderTemplate {
  ProviderTemplate({
    required this.id,
    required this.docType,
    required this.version,
    required this.anyText,
    required this.senderDomains,
    required this.minScore,
    required this.fields,
    this.repeatStart = const [],
    this.dateOrder,
  });

  factory ProviderTemplate.fromJson(Map<String, Object?> j) {
    final match = (j['match'] as Map<String, Object?>?) ?? const {};
    final fields = <String, TemplateField>{};
    for (final e in ((j['fields'] as Map<String, Object?>?) ?? const {}).entries) {
      if (!templateFieldNames.contains(e.key)) throw FormatException('mẫu ${j['id']}: trường không hỗ trợ: ${e.key}');
      fields[e.key] = TemplateField.fromJson((e.value! as Map).cast<String, Object?>());
    }
    final repeat = j['repeat_block'] as Map<String, Object?>?;
    return ProviderTemplate(
      id: j['id']! as String,
      docType: DocType.parse(j['doc_type']! as String) ?? (throw FormatException('doc_type: ${j['doc_type']}')),
      version: j['version']! as int,
      anyText: [for (final r in (match['any_text'] as List<Object?>? ?? const [])) RegExp(r! as String, unicode: true)],
      senderDomains: [for (final d in (match['sender_domains'] as List<Object?>? ?? const [])) (d! as String).toLowerCase()],
      minScore: match['min_score'] as int? ?? 2,
      fields: fields,
      repeatStart: [for (final s in (repeat?['start'] as List<Object?>? ?? const [])) '$s'],
      dateOrder: j['date_order'] as String?,
    );
  }

  factory ProviderTemplate.parse(String json) => ProviderTemplate.fromJson((jsonDecode(json) as Map).cast<String, Object?>());

  final String id;
  final DocType docType;
  final int version;
  final List<RegExp> anyText;
  final List<String> senderDomains;
  final int minScore;
  final Map<String, TemplateField> fields;
  /// Nhãn mở đầu mỗi khối lặp (chặng bay): mỗi khối ra 1 candidate.
  final List<String> repeatStart;
  /// Thứ tự ngày số của nhà cung cấp (`dmy` | `mdy` | `ymd`), thắng thứ tự theo vùng.
  final String? dateOrder;

  /// Mỗi `any_text` khớp +1, tên miền người gửi khớp +2.
  int score(TextDocument doc) {
    final text = doc.text;
    var s = anyText.where((r) => r.hasMatch(text)).length;
    final domain = doc.senderDomain?.toLowerCase();
    if (domain != null && senderDomains.any((d) => domain == d || domain.endsWith('.$d'))) s += 2;
    return s;
  }
}

/// Đọc tài liệu theo mẫu đã khớp → [Slots] cho từng khối.
class TemplateReader {
  TemplateReader(this.template, this.packs, {this.airports, this.region});
  final ProviderTemplate template;
  final List<GrammarPack> packs;
  final AirportIndex? airports;
  final String? region;

  List<Slots> read(TextDocument doc) {
    final reader = ValueReader(packs, region: region, airports: airports, language: doc.language, dateOrder: template.dateOrder);
    final blocks = _blocks(doc);
    return [
      for (final (from, to) in blocks) _slots(doc, reader, from, to),
    ];
  }

  List<(int, int)> _blocks(TextDocument doc) {
    if (template.repeatStart.isEmpty) return [(0, doc.lines.length)];
    final starts = <int>{};
    for (final a in template.repeatStart) {
      for (final h in doc.findAnchor(a)) {
        starts.add(h.line);
      }
    }
    final sorted = starts.toList()..sort();
    if (sorted.isEmpty) return [(0, doc.lines.length)];
    return [for (var i = 0; i < sorted.length; i++) (sorted[i], i + 1 < sorted.length ? sorted[i + 1] : doc.lines.length)];
  }

  Slots _slots(TextDocument doc, ValueReader reader, int from, int to) {
    final s = Slots();
    const c = Slot.template;
    for (final e in template.fields.entries) {
      var v = _value(doc, reader, e.value, from, to);
      if (v == null && _headerFields.contains(e.key) && (from, to) != (0, doc.lines.length)) {
        v = _value(doc, reader, e.value, 0, doc.lines.length);
      }
      if (v == null) continue;
      switch (e.key) {
        case 'confirmation_code':
          s.confirmationCode = Slot(v as String, c);
        case 'flight_number':
          final f = v as FlightNumber;
          s.carrierCode = Slot(f.carrier, c);
          s.number = Slot(f.number, c);
        case 'carrier_code':
          s.carrierCode = Slot(v as String, c);
        case 'number':
          s.number = Slot(v as String, c);
        case 'origin':
          s.origin = Slot(v as String, c);
        case 'destination':
          s.destination = Slot(v as String, c);
        case 'terminal':
          s.originTerminal = Slot(v as String, c);
        case 'gate':
          s.gate = Slot(v as String, c);
        case 'seat':
          s.seat = Slot(v as String, c);
        case 'carriage':
          s.carriage = Slot(v as String, c);
        case 'class':
          s.travelClass = Slot(v as String, c);
        case 'passenger_count':
          s.passengerCount = Slot(v as int, c);
        case 'total':
          s.price = Slot(v as Price, c);
        case 'departure_date':
          s.departureDate = Slot(v as DocDate, c);
        case 'departure_time':
          s.departureTime = Slot(v as DocTime, c);
        case 'arrival_date':
          s.arrivalDate = Slot(v as DocDate, c);
        case 'arrival_time':
          s.arrivalTime = Slot(v as DocTime, c);
        case 'check_in_date':
          s.checkInDate = Slot(v as DocDate, c);
        case 'check_in_time':
          s.checkInTime = Slot(v as DocTime, c);
        case 'check_out_date':
          s.checkOutDate = Slot(v as DocDate, c);
        case 'check_out_time':
          s.checkOutTime = Slot(v as DocTime, c);
        case 'property':
          s.property = Slot(v as String, c);
        case 'address':
          s.address = Slot(v as String, c);
      }
    }
    return s;
  }

  Object? _value(TextDocument doc, ValueReader reader, TemplateField f, int from, int to) {
    Object? parseAll(String text, {required bool first}) {
      final all = _parse(doc, reader, f, text);
      if (all.isEmpty) return null;
      return first ? all.first : (all.length >= f.nth ? all[f.nth - 1] : null);
    }

    if (f.anchors.isEmpty) {
      final found = <Object>[];
      for (var i = from; i < to; i++) {
        if (f.type == TemplateValueType.iata) {
          found.addAll(reader.airportsIn(doc, i).where((m) => m.strong).map((m) => m.code));
        } else {
          found.addAll(_parse(doc, reader, f, doc.lines[i].text));
        }
      }
      return found.length >= f.nth ? found[f.nth - 1] : null;
    }
    for (final a in f.anchors) {
      for (final h in doc.findAnchor(a, from: from, to: to)) {
        if (f.right) {
          for (final r in doc.rightOf(h)) {
            final v = parseAll(doc.regionText(r), first: true);
            if (v != null) return v;
          }
        }
        if (f.below) {
          for (final r in doc.below(h, maxLines: 1)) {
            final v = parseAll(doc.regionText(r), first: true);
            if (v != null) return v;
          }
        }
      }
    }
    return null;
  }

  List<Object> _parse(TextDocument doc, ValueReader reader, TemplateField f, String text) {
    String pick(RegExpMatch m) => f.group != null ? (m[f.group!] ?? '') : (m.groupCount >= 1 && m[1] != null ? m[1]! : m[0]!);
    final scoped = f.pattern == null ? [text] : [for (final m in f.pattern!.allMatches(text)) pick(m)];
    final out = <Object>[];
    for (final t in scoped) {
      switch (f.type) {
        case TemplateValueType.text:
          final v = t.trim();
          if (v.isNotEmpty) out.add(v);
        case TemplateValueType.date:
          out.addAll(reader.dates(t));
        case TemplateValueType.time:
          out.addAll(reader.times(t));
        case TemplateValueType.iata:
          out.addAll(RegExp(r'(?<![A-Za-z])[A-Z]{3}(?![A-Za-z])').allMatches(t).map((m) => m[0]!).where((c) => airports?.contains(c) ?? true));
        case TemplateValueType.money:
          out.addAll(reader.money(t).map((m) => m.price));
        case TemplateValueType.int:
          final n = int.tryParse(RegExp(r'\d+').firstMatch(t)?[0] ?? '');
          if (n != null) out.add(n);
        case TemplateValueType.flightNumber:
          out.addAll(reader.flightNumbers(t));
      }
    }
    return out;
  }
}

/// Kết quả tầng luật T2 cho 1 tài liệu.
class RuleExtraction {
  const RuleExtraction({required this.docType, required this.candidates, this.templateId, this.scores = const {}});
  final DocType docType;
  final List<Candidate> candidates;
  /// `id@version` của mẫu đã dùng (telemetry E5.4: không kèm giá trị trường).
  final String? templateId;
  final Map<DocType, int> scores;
}

/// Tầng luật T2 (on-device-extraction.md §4): mẫu nhà cung cấp khớp nhất → không có thì phân loại + extractor chung.
/// Kết quả qua cùng [CandidateAssembler] (kiểm tra logic, confidence).
class RuleEngine {
  RuleEngine({required this.packs, this.airports, this.templates = const [], this.region});
  final List<GrammarPack> packs;
  final AirportIndex? airports;
  final List<ProviderTemplate> templates;
  final String? region;

  RuleExtraction extract(TextDocument doc, {required DateTime reference}) {
    final assembler = CandidateAssembler(airports: airports, reference: reference);
    ProviderTemplate? best;
    var bestScore = 0;
    for (final t in templates) {
      final s = t.score(doc);
      if (s >= t.minScore && s > bestScore) (best, bestScore) = (t, s);
    }
    if (best != null) {
      final src = 'template:${best.id}';
      final c = [
        for (final s in TemplateReader(best, packs, airports: airports, region: region).read(doc)) ?assembler.assemble(best.docType, s, source: src),
      ];
      if (c.isNotEmpty) return RuleExtraction(docType: best.docType, candidates: c, templateId: '${best.id}@${best.version}');
    }
    final reader = ValueReader(packs, region: region, airports: airports, language: doc.language);
    final cls = DocClassifier(packs).classify(doc, reader: reader);
    return RuleExtraction(
      docType: cls.type,
      scores: cls.scores,
      candidates: genericCandidates(cls.type, doc, packs: packs, reference: reference, airports: airports, region: region),
    );
  }
}
